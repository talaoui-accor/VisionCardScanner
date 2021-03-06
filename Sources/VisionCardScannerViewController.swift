//
//  VisionScanViewController.swift
//  CreditCardScanner
//
//  Created by Tarik ALAOUI on 16/05/2021.
//

import AVFoundation
import Foundation
import Vision
import UIKit

public class VisionCardScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, VisionCardScannerProtocol {

  enum Constants {
    static let cardWidthRatio: Float = 85.60
    static let cardHeightRatio: Float = 53.98
    static let expireInPattern: String = #"(\d{2}\/\d{2})"#
    static let namePattern: String = #"([A-z]{2,}\h([A-z.]+\h)?[A-z]{2,})"#
  }

  private let lock = NSLock()

  private let paymentCardAspectRatio: Float = Constants.cardWidthRatio / Constants.cardHeightRatio

  private var selectedCard = VisionCardScannerEntity()
  private var predictedCardInfo: [Candidate: PredictedCount] = [:]

  private let requestHandler = VNSequenceRequestHandler()
  private var rectangleDrawing: CAShapeLayer?
  private var paymentCardRectangleObservation: VNRectangleObservation?

  // MARK: - VideoSession Capture

  private let captureSession = AVCaptureSession()
  private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
    let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
    preview.videoGravity = .resizeAspect
    return preview
  }()

  private let videoOutput = AVCaptureVideoDataOutput()
  private var isFound: Bool = false

  // MARK: - Bound for scanner (centered rect)

  private var rectangleOnScreen: CGRect {
    let width = CGFloat(previewLayer.frame.width) * CGFloat(Constants.cardWidthRatio) / 100
    let height: CGFloat = width * CGFloat(Constants.cardHeightRatio) / 100
    let x: CGFloat = (previewLayer.frame.width - width) / 2
    let y: CGFloat = (previewLayer.frame.height - height) / 2

    return CGRect(x: x, y: y, width: width, height: height)
  }

  // MARK: - Instance dependencies

  private var resultsHandler: VisionCardScannerCompletion?

  // MARK: - Initializers

  public init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    view = UIView()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupCaptureSession()
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer.frame = view.bounds
    addCaptureArea()
  }

  // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

  @objc
  private func done() {
    self.dismiss(animated: true, completion: nil)
  }
  
  public func captureOutput(_ output: AVCaptureOutput,
                            didOutput sampleBuffer: CMSampleBuffer,
                            from connection: AVCaptureConnection) {
    guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      debugPrint("unable to get image from sample buffer")
      return
    }
    if let paymentCardRectangleObservation = self.paymentCardRectangleObservation {
      handleObservedPaymentCard(paymentCardRectangleObservation, in: frame)
    } else if let paymentCardRectangleObservation = detectPaymentCard(frame: frame) {
      self.paymentCardRectangleObservation = paymentCardRectangleObservation
    }
  }

  // MARK: - Camera setup

  private func setupCaptureSession() {
    addCameraInput()
    addPreviewLayer()
    addVideoOutput()
    addNavigationBar()
  }

  private func addCaptureArea() {
    DispatchQueue.main.async {
      self.rectangleDrawing?.removeFromSuperlayer()
      let colorRect = self.isFound == true ? UIColor.green.cgColor : UIColor.yellow.cgColor
      self.rectangleDrawing = self.createCenterRectArea(color: colorRect)
      if let rectangleDrawing = self.rectangleDrawing {
        self.view.layer.addSublayer(rectangleDrawing)
      }
    }
  }

  private func addNavigationBar() {
    let screenSize: CGRect = UIScreen.main.bounds
    let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 44))
    let navItem = UINavigationItem(title: "Scanner votre carte")
    let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: nil, action: #selector(done))
    navItem.rightBarButtonItem = doneItem
    navBar.setItems([navItem], animated: false)
    self.view.addSubview(navBar)
  }
  
  private func addCameraInput() {
    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
    let cameraInput = try! AVCaptureDeviceInput(device: device)
    captureSession.addInput(cameraInput)
  }

  private func addPreviewLayer() {
    view.layer.addSublayer(previewLayer)
  }

  private func addVideoOutput() {
    videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
    captureSession.addOutput(videoOutput)
    guard let connection = videoOutput.connection(with: AVMediaType.video),
          connection.isVideoOrientationSupported else { return }
    connection.videoOrientation = .portrait
  }

  private func startRunning() {
    captureSession.startRunning()
  }

  private func createCenterRectArea(color: CGColor?) -> CAShapeLayer {
    let boundingBoxPath = CGPath(roundedRect: rectangleOnScreen, cornerWidth: 10, cornerHeight: 10, transform: nil)
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = boundingBoxPath
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = color != nil ? color : UIColor.green.cgColor
    shapeLayer.lineWidth = 5
    shapeLayer.borderWidth = 5
    shapeLayer.cornerRadius = 5
    return shapeLayer
  }

  // MARK: - Payment Card Processing

  private func detectPaymentCard(frame: CVImageBuffer) -> VNRectangleObservation? {
    let rectangleDetectionRequest = VNDetectRectanglesRequest()
    rectangleDetectionRequest.minimumAspectRatio = paymentCardAspectRatio * 0.95
    rectangleDetectionRequest.maximumAspectRatio = paymentCardAspectRatio * 1.10
    let textDetectionRequest = VNDetectTextRectanglesRequest()

    try? requestHandler.perform([rectangleDetectionRequest, textDetectionRequest], on: frame)

    guard let rectangle = (rectangleDetectionRequest.results as? [VNRectangleObservation])?.first,
          let text = (textDetectionRequest.results as? [VNTextObservation])?.first,
          rectangle.boundingBox.contains(text.boundingBox) else {
      return nil
    }

    return rectangle
  }

  private func trackPaymentCard(for observation: VNRectangleObservation, in frame: CVImageBuffer) -> VNRectangleObservation? {

    let request = VNTrackRectangleRequest(rectangleObservation: observation)
    request.trackingLevel = .fast

    try? requestHandler.perform([request], on: frame)

    guard let trackedRectangle = (request.results as? [VNRectangleObservation])?.first else {
      return nil
    }
    return trackedRectangle
  }

  private func handleObservedPaymentCard(_ observation: VNRectangleObservation, in frame: CVImageBuffer) {
    if let _ = trackPaymentCard(for: observation, in: frame) {
      DispatchQueue.global(qos: .userInitiated).async {
        if self.extractPaymentCardNumber(frame: frame, rectangle: observation),
           let _ = self.selectedCard.numberCard,
           let _ = self.selectedCard.expireIn {
          DispatchQueue.main.async {
            self.resultsHandler?(self.selectedCard)
            self.captureSession.stopRunning()
            self.resultsHandler = nil
          }
        }
      }
    } else {
      paymentCardRectangleObservation = nil
    }
  }

  private func extractPaymentCardNumber(frame: CVImageBuffer, rectangle: VNRectangleObservation) -> Bool {

    let cardPositionInImage = VNImageRectForNormalizedRect(rectangle.boundingBox, CVPixelBufferGetWidth(frame), CVPixelBufferGetHeight(frame))
    let ciImage = CIImage(cvImageBuffer: frame)
    let croppedImage = ciImage.cropped(to: cardPositionInImage)

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let stillImageRequestHandler = VNImageRequestHandler(ciImage: croppedImage, options: [:])
    try? stillImageRequestHandler.perform([request])

    guard let texts = request.results as? [VNRecognizedTextObservation], texts.count > 0 else {
      return false
    }

    let recognizedStrings = texts.compactMap { observation in
      observation.topCandidates(1).first?.string
    }

    let response = VisionCardScannerEntity()
    for result in texts {
      if let resultCandidate = result.topCandidates(1).first,
         resultCandidate.confidence > 0.5 {
        let resultStr = resultCandidate.string
        let text = resultStr.replacingOccurrences(of: " ", with: "")

        if text.count > 12,
           CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: text)) {
          isFound = true
          response.numberCard = text
        } else if text.count == 5,
                  let matches = VSUtilities.regex(in: text, pattern: Constants.expireInPattern),
                  matches.count == 1,
                  matches[0].first == text {
          response.expireIn = text
        }
      }
    }

    for recognized in recognizedStrings {
      if let text = VSUtilities.detectNameHolder(in: recognized) {
        response.name = text
      }
    }
    
    // Name
    if let name = response.name {
      lock.lock()
      let count = predictedCardInfo[.name(name), default: 0]
      predictedCardInfo[.name(name)] = count + 1
      if count > 4 {
        selectedCard.name = name
      }
      lock.unlock()
    }
    
    // ExpireDate
    if let date = response.expireIn {
      lock.lock()
      let count = predictedCardInfo[.expireDate(date), default: 0]
      predictedCardInfo[.expireDate(date)] = count + 1
      if count > 2 {
        selectedCard.expireIn = date
      }
      lock.unlock()
    }

    // Number
    if let number = response.numberCard {
      lock.lock()
      let count = predictedCardInfo[.number(number), default: 0]
      predictedCardInfo[.number(number)] = count + 1
      if count > 2 {
        selectedCard.numberCard = number
      }
      lock.unlock()
    }

    response.debugString = recognizedStrings.joined(separator: ",")

    if selectedCard.numberCard != nil,
       let numberCard = selectedCard.numberCard,
       VSUtilities.luhnCheck(number: numberCard) {
      selectedCard.cardType = detectKindOfCard(numberCard)
      selectedCard.debugString = response.debugString
      selectedCard.name = response.name
      return true
    }

    return false
  }

  private func detectKindOfCard(_ numberCard: String) -> CardType {
    for card in CardType.allCards {
      if (VSUtilities.matchesRegex(regex: card.regex, text: numberCard)) {
        return card
      }
    }
    return .Unknown
  }
  
  // MARK: - VisionCardScannerProtocol
  
  public func startScanning(resultsHandler: @escaping VisionCardScannerCompletion) {
    self.resultsHandler = resultsHandler
    startRunning()
  }
}

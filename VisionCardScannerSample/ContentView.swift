//
//  ContentView.swift
//  CreditCardScanner
//
//  Created by Tarik ALAOUI on 16/05/2021.
//

import SwiftUI

struct ContentView: View {
  
  @State var numberCB: String = ""
  @State var typeCB: String = ""
  @State var expireDateCB: String = ""
  @State var debugString: String = ""
  @State var isPresented: Bool = false
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    Section {
      VStack {
        Text("Card Number").font(.caption)
        Text("\(numberCB)").font(.title2)
        Text("Expired In : \(expireDateCB)").font(.title3).lineSpacing(20)
        Text("Type: \(typeCB)").font(.title2)
        Text("\(debugString)").font(.caption2)
        Button("Scanner") {
          self.isPresented.toggle()
        }
      }.sheet(isPresented: $isPresented) {
        ScannerView(delegate: self, isPresented: $isPresented)
      }
    }
  }
}

// MARK: - ScannerViewController

struct ScannerView: UIViewControllerRepresentable {
  var isPresented: Binding<Bool>
  typealias UIViewControllerType = VisionCardScannerViewController
  private var delegate: ContentView?
  
  init(delegate: ContentView, isPresented: Binding<Bool>) {
    self.delegate = delegate
    self.isPresented = isPresented
  }
  
  func makeUIViewController(context: Context) -> VisionCardScannerViewController {
    let visionScanViewController = VisionCardScannerViewController()
    visionScanViewController.startScanning { paymentCardNumber in
      guard let paymentCardNumber = paymentCardNumber else { return }
      if let numberCard = paymentCardNumber.numberCard,
         let expireIn = paymentCardNumber.expireIn {
        delegate?.expireDateCB = expireIn
        delegate?.numberCB = numberCard
        delegate?.debugString = paymentCardNumber.debugString ?? ""
        delegate?.typeCB = paymentCardNumber.cardType?.rawValue ?? ""
        self.isPresented.wrappedValue = false
      }
    }
    return visionScanViewController
  }
  func updateUIViewController(_ uiViewController: VisionCardScannerViewController, context: Context) { }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

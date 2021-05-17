//
//  VisionCardScannerProtocol.swift
//  CreditCardScanner
//
//  Created by Tarik ALAOUI on 17/05/2021.
//

import Foundation
import UIKit

// MARK: - VisionCardScannerProtocol

public protocol VisionCardScannerProtocol: UIViewController {
  func startScanning(resultsHandler: @escaping VisionCardScannerCompletion)
}

//
//  VisionCardScannerProtocol.swift
//  CreditCardScanner
//
//  Created by Tarik ALAOUI on 17/05/2021.
//

import Foundation

// MARK: - VisionCardScannerProtocol

public protocol VisionCardScannerProtocol {
  func startScanning(resultsHandler: @escaping VisionCardScannerCompletion)
}

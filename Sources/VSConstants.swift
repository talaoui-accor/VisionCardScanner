//
//  VSConstants.swift
//  CreditCardScanner
//
//  Created by Tarik ALAOUI on 17/05/2021.
//

import Foundation

public typealias VisionCardScannerCompletion = ((VisionCardScannerEntity?) -> Void)

typealias PredictedCount = Int

enum CardType: String {
  case Unknown, Amex, Visa, MasterCard, Diners, Discover, JCB, Elo, Hipercard, UnionPay
  
  static let allCards = [Amex, Visa, MasterCard, Diners, Discover, JCB, Elo, Hipercard, UnionPay]
  
  var regex : String {
    switch self {
    case .Amex:
      return "^3[47][0-9]{5,}$"
    case .UnionPay:
      return "^(62|88)[0-9]{5,}$"
    case .Visa:
      return "^4[0-9]{6,}([0-9]{3})?$"
    case .Hipercard:
      return "^(606282|3841)[0-9]{5,}$"
    case .Discover:
      return "^6(?:011|5[0-9]{2})[0-9]{3,}$"
    case .MasterCard:
      return "^(5[1-5][0-9]{4}|677189)[0-9]{5,}$"
    case .Diners:
      return "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$"
    case .JCB:
      return "^(?:2131|1800|35[0-9]{3})[0-9]{3,}$"
    case .Elo:
      return "^((((636368)|(438935)|(504175)|(451416)|(636297))[0-9]{0,10})|((5067)|(4576)|(4011))[0-9]{0,12})$"
    default:
      return ""
    }
  }
}

enum Constants {
  static let cardWidthRatio:Float = 85.60
  static let cardHeightRatio:Float = 53.98
  static let expireInPattern: String = #"(\d{2}\/\d{2})"#
  static let namePattern: String = #"([A-z]{2,}\h([A-z.]+\h)?[A-z]{2,})"#
}

enum Candidate: Hashable {
  case number(String)
  case name(String)
  case expireDate(String)
}

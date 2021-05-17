//
//  VSUtilities.swift
//  CreditCardScanner
//
//  Created by Tarik ALAOUI on 17/05/2021.
//

import Foundation

final class VSUtilities {

  // MARK: - Luhn

  static func luhnCheck(number: String) -> Bool {
    guard number.count > 12, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: number)) else {
      return false
    }
    var digits = number
    let checksum = digits.removeLast()
    let sum = digits.reversed()
      .enumerated()
      .map { (index, element) -> Int in
        if (index % 2) == 0 {
          let doubled = Int(String(element))! * 2
          return doubled > 9
            ? Int(String(String(doubled).first!))! + Int(String(String(doubled).last!))!
            : doubled
        } else {
          return Int(String(element))!
        }
      }
      .reduce(0) { (res, next) in res + next }
    let checkDigitCalc = (sum * 9) % 10
    return Int(String(checksum))! == checkDigitCalc
  }

  // MARK: - Regex

  static func regex(in testString: String, pattern: String) -> [[String]]? {
    let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    let stringRange = NSRange(location: 0, length: testString.utf16.count)
    let matches = regex.matches(in: testString, range: stringRange)
    var result: [[String]] = []
    for match in matches {
      var groups: [String] = []
      for rangeIndex in 1 ..< match.numberOfRanges {
        groups.append((testString as NSString).substring(with: match.range(at: rangeIndex)))
      }
      if !groups.isEmpty {
        result.append(groups)
      }
    }
    return result
  }

  static func matchesRegex(regex: String!, text: String!) -> Bool {
    do {
      let regex = try NSRegularExpression(pattern: regex, options: [.caseInsensitive])
      let nsString = text as NSString
      let match = regex.firstMatch(in: text, options: [], range: NSMakeRange(0, nsString.length))
      return (match != nil)
    } catch {
      return false
    }
  }
  
  static func detectNameHolder(in text: String) -> String? {
    let excludes: [String] = ["VISA", "VIS", "BANQUE", "PREMIERE", "PREMIUM", "AMERICAN","BRED", "POPULAIRE","BOURSORAMA", "BUSINESS", "EXPIRE", "A FIN", "FIN", "MASTER","CARD", "MEMBER", "DEPUIS", "MEMBRE"]
    var isExcluded: Bool = false
    let textClean = text.trimmingCharacters(in: CharacterSet.whitespaces)
    let textNumber = text.replacingOccurrences(of: " ", with: "")
    for exclude in excludes {
      if text.localizedCaseInsensitiveContains(exclude) {
        isExcluded = true
      } else if textNumber.count > 12,
                CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: textNumber)) {
        isExcluded = true
      } else if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: textClean)) {
        isExcluded = true
      } else if text.count == 5,
                let matches = VSUtilities.regex(in: text, pattern: #"(\d{2}\/\d{2})"#),
                matches.count == 1,
                matches[0].first == text {
        isExcluded = true
      } else if text.count < 8 {
        isExcluded = true
      }
    }
    if !isExcluded {
      print(text)
    }
    return isExcluded ? nil : text
  }
}

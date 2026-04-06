//
//  PriceInputParserService.swift
//  Armory Inventory
//
//  Created by Codex on 4/5/26.
//

import Foundation

protocol PriceInputParsing {
    func purchasePriceCents(from text: String) -> Int?
}

struct PriceInputParserService: PriceInputParsing {
    func purchasePriceCents(from text: String) -> Int? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }

        let separators = CharacterSet(charactersIn: ".,")
        let allowedScalars = trimmedText.unicodeScalars.filter { scalar in
            CharacterSet.decimalDigits.contains(scalar) || separators.contains(scalar)
        }
        let sanitized = String(String.UnicodeScalarView(allowedScalars))
        guard !sanitized.isEmpty else {
            return nil
        }

        let lastPeriodIndex = sanitized.lastIndex(of: ".")
        let lastCommaIndex = sanitized.lastIndex(of: ",")
        let decimalSeparatorIndex = [lastPeriodIndex, lastCommaIndex].compactMap { $0 }.max()

        let normalizedText: String
        if let decimalSeparatorIndex {
            let fractionalStart = sanitized.index(after: decimalSeparatorIndex)
            let fractionalDigits = sanitized.distance(from: fractionalStart, to: sanitized.endIndex)
            guard fractionalDigits > 0, fractionalDigits <= 2 else {
                return nil
            }

            let integerPart = sanitized[..<decimalSeparatorIndex].filter(\.isNumber)
            let fractionalPart = sanitized[fractionalStart...].filter(\.isNumber)
            normalizedText = integerPart.isEmpty ? "0.\(fractionalPart)" : "\(integerPart).\(fractionalPart)"
        } else {
            normalizedText = String(sanitized.filter(\.isNumber))
        }

        guard let amount = Decimal(string: normalizedText), amount >= 0 else {
            return nil
        }

        return NSDecimalNumber(decimal: amount * 100).intValue
    }
}

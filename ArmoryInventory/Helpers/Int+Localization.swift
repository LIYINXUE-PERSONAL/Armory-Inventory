//
//  Int+Localization.swift
//  Armory Inventory
//
//  Created by Codex on 5/1/26.
//

import Foundation

extension Int {
    var localizedCountString: String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = !Locale.current.identifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
            .hasPrefix("zh")

        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

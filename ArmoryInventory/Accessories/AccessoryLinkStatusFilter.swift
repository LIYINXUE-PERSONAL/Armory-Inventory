//
//  AccessoryLinkStatusFilter.swift
//  Armory Inventory
//
//  Created by Codex on 9/3/26.
//

import Foundation

enum AccessoryLinkStatusFilter: String, CaseIterable, Identifiable {
    case all
    case linked
    case unlinked

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return String(localized: "All Statuses")
        case .linked:
            return String(localized: "Linked")
        case .unlinked:
            return String(localized: "Unlinked")
        }
    }
}

//
//  AccessoriesViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 5/20/26.
//

import Foundation

struct AccessoryCategory: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let shortDescription: String
    let detailDescription: String
    let examples: [String]
}

final class AccessoriesViewModel {
    let topLevelCategories: [AccessoryCategory] = [
        AccessoryCategory(
            id: "optics",
            name: String(localized: "Optics"),
            systemImage: "scope",
            shortDescription: String(localized: "Scopes, red dots, and magnifiers"),
            detailDescription: String(localized: "Optics include sighting systems used to improve target acquisition and precision across different firearm setups."),
            examples: [
                String(localized: "LPVO"),
                String(localized: "Red Dot"),
                String(localized: "Holographic Sight"),
                String(localized: "Magnifier"),
            ]
        ),
        AccessoryCategory(
            id: "magazines",
            name: String(localized: "Magazines"),
            systemImage: "rectangle.stack.fill.badge.plus",
            shortDescription: String(localized: "Spare mags and loadout essentials"),
            detailDescription: String(localized: "Magazine tracking helps you manage capacity, platform compatibility, and quantity on hand."),
            examples: [
                String(localized: "Pistol Magazine"),
                String(localized: "AR-15 Magazine"),
                String(localized: "AK Magazine"),
                String(localized: "Drum Magazine"),
            ]
        ),
        AccessoryCategory(
            id: "attachments",
            name: String(localized: "Attachments"),
            systemImage: "hand.raised.fill",
            shortDescription: String(localized: "Mounted accessories grouped by attachment type"),
            detailDescription: String(localized: "Attachments include mounted accessories such as stocks, grips, lasers, lights, hand stops, and similar hardware. They can be categorized later using an Attachment Type field instead of separate screens."),
            examples: [
                String(localized: "Stock"),
                String(localized: "Grip"),
                String(localized: "Laser"),
                String(localized: "Light"),
                String(localized: "Hand Stop"),
                String(localized: "Bipod"),
            ]
        ),
        AccessoryCategory(
            id: "parts",
            name: String(localized: "Parts"),
            systemImage: "gearshape.2.fill",
            shortDescription: String(localized: "Core components and replacement assemblies"),
            detailDescription: String(localized: "Parts cover major firearm components you install, swap, or keep on hand, such as barrels, triggers, receivers, recoil systems, and other internal assemblies."),
            examples: [
                String(localized: "Barrel"),
                String(localized: "Trigger"),
                String(localized: "Bolt Carrier Group"),
                String(localized: "Charging Handle"),
                String(localized: "Slide"),
                String(localized: "Recoil System"),
            ]
        ),
        AccessoryCategory(
            id: "kits",
            name: String(localized: "Kits"),
            systemImage: "shippingbox.fill",
            shortDescription: String(localized: "Grouped parts, optics, and attachments"),
            detailDescription: String(localized: "Kits group unlinked parts, optics, and attachments so complete assemblies can be linked to firearms together while preserving direct item tracking."),
            examples: [
                String(localized: "Upper Receiver Kit"),
                String(localized: "Lower Receiver Kit"),
                String(localized: "Optics Kit"),
                String(localized: "Custom Kit")
            ]
        ),
    ]

    func totalValueText(optics: [Optic], magazines: [Magazine], attachments: [Attachment], parts: [Part]) -> String {
        let totalCents =
            optics.reduce(0) { $0 + max(0, $1.purchasePriceCents) } +
            magazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) } +
            attachments.reduce(0) { $0 + max(0, $1.purchasePriceCents) } +
            parts.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

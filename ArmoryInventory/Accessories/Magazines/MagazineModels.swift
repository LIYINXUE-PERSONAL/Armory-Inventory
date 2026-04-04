//
//  MagazineModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

@Model
final class Magazine {
    var id: UUID?
    var brand: String
    var modelName: String
    var count: Int
    var capacity: Int
    var purchaseDate: Date
    var purchasePriceCents: Int
    var color: FirearmColor.RawValue?
    var colorDetail: String?
    var notes: String?
    var sortOrder: Int
    var createdAt: Date

    @Relationship var caliber: Caliber?
    @Relationship var firearm: Firearm?

    init(
        id: UUID? = UUID(),
        brand: String,
        modelName: String,
        count: Int = 1,
        capacity: Int,
        purchaseDate: Date = .now,
        purchasePriceCents: Int,
        color: FirearmColor? = nil,
        colorDetail: String? = nil,
        notes: String? = nil,
        caliber: Caliber? = nil,
        firearm: Firearm? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.count = count
        self.capacity = capacity
        self.purchaseDate = purchaseDate
        self.purchasePriceCents = purchasePriceCents
        self.color = color?.rawValue
        self.colorDetail = colorDetail
        self.notes = notes
        self.caliber = caliber
        self.firearm = firearm
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var displayName: String {
        "\(brand) \(modelName)"
    }

    var capacityText: String {
        "\(capacity) rounds"
    }

    var countText: String {
        count == 1 ? "1 magazine" : "\(count) magazines"
    }

    var magazineColor: FirearmColor? {
        guard let color else {
            return nil
        }
        return FirearmColor(rawValue: color) ?? .other
    }

    var colorDisplayName: String? {
        guard let magazineColor else {
            return nil
        }
        if magazineColor == .other, let colorDetail, !colorDetail.isEmpty {
            return colorDetail
        }
        return magazineColor.displayName
    }

    var purchasePriceText: String {
        let amount = Decimal(purchasePriceCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

//
//  PartModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/5/26.
//

import Foundation
import SwiftData

enum PartType: String, Codable, CaseIterable, Identifiable {
    case barrel
    case trigger
    case slide
    case boltCarrierGroup
    case chargingHandle
    case upperReceiver
    case lowerReceiver
    case recoilSystem
    case internals
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barrel:
            return "Barrel"
        case .trigger:
            return "Trigger"
        case .slide:
            return "Slide"
        case .boltCarrierGroup:
            return "Bolt Carrier Group"
        case .chargingHandle:
            return "Charging Handle"
        case .upperReceiver:
            return "Upper Receiver"
        case .lowerReceiver:
            return "Lower Receiver"
        case .recoilSystem:
            return "Recoil System"
        case .internals:
            return "Internals"
        case .other:
            return "Other"
        }
    }

    static func displayOrder(for names: [String]) -> [String] {
        let enumOrder = allCases.map(\.displayName)
        let knownNames = enumOrder.filter(names.contains)
        let customNames = names.filter { !enumOrder.contains($0) }.sorted()
        return knownNames + customNames
    }
}

@Model
final class Part {
    var id: UUID?
    var brand: String
    var modelName: String
    var type: PartType.RawValue
    var typeDetail: String?
    var color: FirearmColor.RawValue?
    var colorDetail: String?
    var purchaseDate: Date
    var purchasePriceCents: Int
    var notes: String?
    var sortOrder: Int
    var createdAt: Date

    @Relationship var firearm: Firearm?

    init(
        id: UUID? = UUID(),
        brand: String,
        modelName: String,
        type: PartType,
        typeDetail: String? = nil,
        color: FirearmColor? = nil,
        colorDetail: String? = nil,
        purchaseDate: Date = .now,
        purchasePriceCents: Int,
        notes: String? = nil,
        firearm: Firearm? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.type = type.rawValue
        self.typeDetail = typeDetail
        self.color = color?.rawValue
        self.colorDetail = colorDetail
        self.purchaseDate = purchaseDate
        self.purchasePriceCents = purchasePriceCents
        self.notes = notes
        self.firearm = firearm
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var partType: PartType {
        PartType(rawValue: type) ?? .other
    }

    var typeDisplayName: String {
        if partType == .other, let typeDetail, !typeDetail.isEmpty {
            return typeDetail
        }
        return partType.displayName
    }

    var displayName: String {
        "\(brand) \(modelName)"
    }

    var partColor: FirearmColor? {
        guard let color else {
            return nil
        }
        return FirearmColor(rawValue: color) ?? .other
    }

    var colorDisplayName: String? {
        guard let partColor else {
            return nil
        }
        if partColor == .other, let colorDetail, !colorDetail.isEmpty {
            return colorDetail
        }
        return partColor.displayName
    }

    var purchasePriceText: String {
        let amount = Decimal(purchasePriceCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

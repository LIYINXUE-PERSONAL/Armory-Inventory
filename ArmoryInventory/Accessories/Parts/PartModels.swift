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
            return String(localized: "Barrel")
        case .trigger:
            return String(localized: "Trigger")
        case .slide:
            return String(localized: "Slide")
        case .boltCarrierGroup:
            return String(localized: "Bolt Carrier Group")
        case .chargingHandle:
            return String(localized: "Charging Handle")
        case .upperReceiver:
            return String(localized: "Upper Receiver")
        case .lowerReceiver:
            return String(localized: "Lower Receiver")
        case .recoilSystem:
            return String(localized: "Recoil System")
        case .internals:
            return String(localized: "Internals")
        case .other:
            return String(localized: "Other")
        }
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
    var barrelLengthInches: Double?
    var purchaseDate: Date
    var purchasePriceCents: Int
    var notes: String?
    var sortOrder: Int
    var createdAt: Date

    @Relationship var firearm: Firearm?
    @Relationship var caliber: Caliber?

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
        barrelLengthInches: Double? = nil,
        caliber: Caliber? = nil,
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
        self.barrelLengthInches = barrelLengthInches
        self.purchaseDate = purchaseDate
        self.purchasePriceCents = purchasePriceCents
        self.notes = notes
        self.firearm = firearm
        self.caliber = caliber
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

    var supportsFirearmConfiguration: Bool {
        [.barrel, .slide, .upperReceiver].contains(partType)
    }
}

//
//  AttachmentModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

enum AttachmentType: String, Codable, CaseIterable, Identifiable {
    case stock
    case grip
    case laser
    case light
    case handStop
    case bipod
    case slingMount
    case muzzleDevice
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stock:
            return "Stock"
        case .grip:
            return "Grip"
        case .laser:
            return "Laser"
        case .light:
            return "Light"
        case .handStop:
            return "Hand Stop"
        case .bipod:
            return "Bipod"
        case .slingMount:
            return "Sling Mount"
        case .muzzleDevice:
            return "Muzzle Device"
        case .other:
            return "Other"
        }
    }
}

@Model
final class Attachment {
    var id: UUID?
    var brand: String
    var modelName: String
    var type: AttachmentType.RawValue
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
        type: AttachmentType,
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

    var attachmentType: AttachmentType {
        AttachmentType(rawValue: type) ?? .other
    }

    var typeDisplayName: String {
        if attachmentType == .other, let typeDetail, !typeDetail.isEmpty {
            return typeDetail
        }
        return attachmentType.displayName
    }

    var displayName: String {
        "\(brand) \(modelName)"
    }

    var attachmentColor: FirearmColor? {
        guard let color else {
            return nil
        }
        return FirearmColor(rawValue: color) ?? .other
    }

    var colorDisplayName: String? {
        guard let attachmentColor else {
            return nil
        }
        if attachmentColor == .other, let colorDetail, !colorDetail.isEmpty {
            return colorDetail
        }
        return attachmentColor.displayName
    }

    var purchasePriceText: String {
        let amount = Decimal(purchasePriceCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

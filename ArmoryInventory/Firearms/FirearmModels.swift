//
//  FirearmModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

enum FirearmType: String, Codable, CaseIterable, Identifiable {
    case rifle
    case pistol
    case shotgun
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rifle:
            return "Rifle"
        case .pistol:
            return "Pistol"
        case .shotgun:
            return "Shotgun"
        case .other:
            return "Other"
        }
    }
}

enum FirearmAction: String, Codable, CaseIterable, Identifiable {
    case semiAuto
    case selectFire
    case bolt
    case pump
    case lever
    case breakAction
    case singleShot
    case revolver
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .semiAuto:
            return "Semi-Auto"
        case .selectFire:
            return "Select-Fire"
        case .bolt:
            return "Bolt Action"
        case .pump:
            return "Pump Action"
        case .lever:
            return "Lever Action"
        case .breakAction:
            return "Break Action"
        case .singleShot:
            return "Single Shot"
        case .revolver:
            return "Revolver"
        case .other:
            return "Other"
        }
    }
}

enum FirearmColor: String, Codable, CaseIterable, Identifiable {
    case black
    case flatDarkEarth
    case odGreen
    case gray
    case silver
    case stainless
    case fdeCamo
    case bronze
    case tan
    case white
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black:
            return "Black"
        case .flatDarkEarth:
            return "Flat Dark Earth"
        case .odGreen:
            return "OD Green"
        case .gray:
            return "Gray"
        case .silver:
            return "Silver"
        case .stainless:
            return "Stainless"
        case .fdeCamo:
            return "Camo"
        case .bronze:
            return "Bronze"
        case .tan:
            return "Tan"
        case .white:
            return "White"
        case .other:
            return "Other"
        }
    }
}

@Model
final class Firearm {
    var id: UUID?
    var brand: String
    var modelName: String
    var nickname: String?
    @Attribute(.unique) var serialNumber: String?
    var purchaseDate: Date
    var lastCleanedDate: Date?
    var purchasePriceCents: Int
    var type: FirearmType.RawValue
    var action: FirearmAction.RawValue
    var actionDetail: String?
    var color: FirearmColor.RawValue?
    var colorDetail: String?
    var barrelLengthInches: Double?
    var notes: String?
    var sortOrder: Int
    var createdAt: Date

    @Relationship var caliber: Caliber?
    @Relationship(inverse: \Optic.firearm) var optics: [Optic]
    @Relationship(inverse: \Magazine.firearm) var magazines: [Magazine]
    @Relationship(inverse: \Attachment.firearm) var attachments: [Attachment]
    @Relationship(inverse: \Part.firearm) var parts: [Part]

    init(
        id: UUID? = UUID(),
        brand: String,
        modelName: String,
        nickname: String? = nil,
        serialNumber: String? = nil,
        purchaseDate: Date = .now,
        lastCleanedDate: Date? = nil,
        purchasePriceCents: Int,
        type: FirearmType,
        action: FirearmAction,
        actionDetail: String? = nil,
        color: FirearmColor? = nil,
        colorDetail: String? = nil,
        barrelLengthInches: Double? = nil,
        notes: String? = nil,
        caliber: Caliber? = nil,
        optics: [Optic] = [],
        magazines: [Magazine] = [],
        attachments: [Attachment] = [],
        parts: [Part] = [],
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.nickname = nickname
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.lastCleanedDate = lastCleanedDate
        self.purchasePriceCents = purchasePriceCents
        self.type = type.rawValue
        self.action = action.rawValue
        self.actionDetail = actionDetail
        self.color = color?.rawValue
        self.colorDetail = colorDetail
        self.barrelLengthInches = barrelLengthInches
        self.notes = notes
        self.caliber = caliber
        self.optics = optics
        self.magazines = magazines
        self.attachments = attachments
        self.parts = parts
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var firearmType: FirearmType {
        FirearmType(rawValue: type) ?? .other
    }

    var displayName: String {
        "\(brand) \(modelName)"
    }

    var firearmAction: FirearmAction {
        FirearmAction(rawValue: action) ?? .other
    }

    var actionDisplayName: String {
        if firearmAction == .other, let actionDetail, !actionDetail.isEmpty {
            return actionDetail
        }
        return firearmAction.displayName
    }

    var firearmColor: FirearmColor? {
        guard let color else {
            return nil
        }
        return FirearmColor(rawValue: color) ?? .other
    }

    var colorDisplayName: String? {
        guard let firearmColor else {
            return nil
        }
        if firearmColor == .other, let colorDetail, !colorDetail.isEmpty {
            return colorDetail
        }
        return firearmColor.displayName
    }

    var subtitle: String {
        if let nickname, !nickname.isEmpty {
            return "\"\(nickname)\""
        }
        return firearmType.displayName
    }

    var roundsText: String? {
        guard let caliber else {
            return nil
        }
        let quantity = caliber.ammoTypes.reduce(0) { $0 + max(0, $1.quantity) }
        return AmmoType.roundsText(for: quantity)
    }

    var barrelLengthText: String? {
        guard let barrelLengthInches else {
            return nil
        }
        let formattedValue = barrelLengthInches.formatted(
            .number.precision(.fractionLength(0...2))
        )
        return "\(formattedValue) in"
    }

    var purchasePriceText: String {
        let amount = Decimal(purchasePriceCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    var lastCleanedDateText: String? {
        lastCleanedDate?.formatted(date: .abbreviated, time: .omitted)
    }

    var totalCardValueCents: Int {
        let opticsValue = optics.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let magazinesValue = magazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let attachmentsValue = attachments.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let partsValue = parts.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        return max(0, purchasePriceCents) + opticsValue + magazinesValue + attachmentsValue + partsValue
    }

    var totalCardValueText: String {
        let amount = Decimal(totalCardValueCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

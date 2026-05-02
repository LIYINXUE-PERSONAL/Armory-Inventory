//
//  FirearmModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

struct FirearmMagazinePatternReference: Codable, Hashable, Identifiable {
    let id: String
    let kind: MagazinePatternKind
    let displayName: String?

    init(id: String, kind: MagazinePatternKind, displayName: String?) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
    }

    init(pattern: MagazinePattern) {
        self.id = pattern.id
        self.kind = pattern.kind
        self.displayName = pattern.kind == .catalog ? nil : pattern.displayName
    }

    var resolvedDisplayName: String {
        if kind == .catalog, let pattern = MagazinePatternCatalog.pattern(id: id) {
            return pattern.displayName
        }

        if let displayName, !displayName.isEmpty {
            return displayName
        }

        return id
    }
}

enum FirearmType: String, Codable, CaseIterable, Identifiable {
    case rifle
    case pistol
    case shotgun
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rifle:
            return String(localized: "Rifle")
        case .pistol:
            return String(localized: "Pistol")
        case .shotgun:
            return String(localized: "Shotgun")
        case .other:
            return String(localized: "Other")
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
            return String(localized: "Semi-Auto")
        case .selectFire:
            return String(localized: "Select-Fire")
        case .bolt:
            return String(localized: "Bolt Action")
        case .pump:
            return String(localized: "Pump Action")
        case .lever:
            return String(localized: "Lever Action")
        case .breakAction:
            return String(localized: "Break Action")
        case .singleShot:
            return String(localized: "Single Shot")
        case .revolver:
            return String(localized: "Revolver")
        case .other:
            return String(localized: "Other")
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
            return String(localized: "Black")
        case .flatDarkEarth:
            return String(localized: "Flat Dark Earth")
        case .odGreen:
            return String(localized: "OD Green")
        case .gray:
            return String(localized: "Gray")
        case .silver:
            return String(localized: "Silver")
        case .stainless:
            return String(localized: "Stainless")
        case .fdeCamo:
            return String(localized: "Camo")
        case .bronze:
            return String(localized: "Bronze")
        case .tan:
            return String(localized: "Tan")
        case .white:
            return String(localized: "White")
        case .other:
            return String(localized: "Other")
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
    var supportedMagazinePatternsData: String?
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
        supportedMagazinePatterns: [FirearmMagazinePatternReference] = [],
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
        self.supportedMagazinePatternsData = Self.encodeMagazinePatterns(supportedMagazinePatterns)
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
            return String.localizedStringWithFormat(
                String(localized: "“%@”"),
                nickname
            )
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
        return "\(formattedValue) \(String(localized: "in."))"
    }

    var purchasePriceText: String {
        let amount = Decimal(purchasePriceCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    var lastCleanedDateText: String? {
        lastCleanedDate?.formatted(date: .abbreviated, time: .omitted)
    }

    var nicknameTextForSnapshot: String? {
        guard let nickname, !nickname.isEmpty else {
            return nil
        }
        return nickname
    }

    var serialNumberTextForSnapshot: String? {
        guard let serialNumber, !serialNumber.isEmpty else {
            return nil
        }
        return serialNumber
    }

    var notesTextForSnapshot: String {
        notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var supportedMagazinePatterns: [FirearmMagazinePatternReference] {
        get { Self.decodeMagazinePatterns(from: supportedMagazinePatternsData) }
        set { supportedMagazinePatternsData = Self.encodeMagazinePatterns(newValue) }
    }

    var supportedMagazinePatternIDs: Set<String> {
        Set(supportedMagazinePatterns.map(\.id))
    }

    func totalLinkedMagazineCount(using magazines: [Magazine]) -> Int {
        magazines.reduce(0) { $0 + max(0, $1.count) }
    }

    func totalLinkedMagazineCapacity(using magazines: [Magazine]) -> Int {
        magazines.reduce(0) { $0 + $1.totalRoundCapacity }
    }

    func linkedMagazineCountText(using magazines: [Magazine]) -> String {
        let totalCount = totalLinkedMagazineCount(using: magazines)
        return String.localizedStringWithFormat(
            String(localized: "magazineCount"),
            Int64(totalCount),
            totalCount.localizedCountString
        )
    }

    func linkedMagazineCapacityText(using magazines: [Magazine]) -> String {
        AmmoType.roundsText(for: totalLinkedMagazineCapacity(using: magazines))
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

    private static func encodeMagazinePatterns(_ patterns: [FirearmMagazinePatternReference]) -> String? {
        guard !patterns.isEmpty,
              let data = try? JSONEncoder().encode(patterns),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }

    private static func decodeMagazinePatterns(from value: String?) -> [FirearmMagazinePatternReference] {
        guard let value,
              let data = value.data(using: .utf8),
              let patterns = try? JSONDecoder().decode([FirearmMagazinePatternReference].self, from: data) else {
            return []
        }

        return patterns
    }
}

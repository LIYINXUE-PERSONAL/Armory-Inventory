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
    var patternID: String?
    var patternKind: MagazinePatternKind.RawValue?
    var patternDisplayName: String?
    var patternSupportedCaliberNamesData: String?
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
        patternID: String? = nil,
        patternKind: MagazinePatternKind? = nil,
        patternDisplayName: String? = nil,
        patternSupportedCaliberNames: [String] = [],
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
        self.patternID = patternID
        self.patternKind = patternKind?.rawValue
        self.patternDisplayName = patternDisplayName
        self.patternSupportedCaliberNamesData = Self.encodePatternSupportedCaliberNames(patternSupportedCaliberNames)
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

    var storedPatternKind: MagazinePatternKind? {
        guard let patternKind else {
            return nil
        }

        return MagazinePatternKind(rawValue: patternKind)
    }

    var resolvedPattern: MagazinePattern {
        MagazinePatternMigration.resolvedPattern(for: self)
    }

    var supportedCaliberNames: [String] {
        let patternCalibers = resolvedPattern.compatibility.supportedCaliberNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !patternCalibers.isEmpty {
            return patternCalibers
        }

        guard let caliberName = caliber?.name.trimmingCharacters(in: .whitespacesAndNewlines),
              !caliberName.isEmpty else {
            return []
        }

        return [caliberName]
    }

    var storedPatternSupportedCaliberNames: [String] {
        get { Self.decodePatternSupportedCaliberNames(from: patternSupportedCaliberNamesData) }
        set { patternSupportedCaliberNamesData = Self.encodePatternSupportedCaliberNames(newValue) }
    }

    var caliberDisplayText: String {
        let names = supportedCaliberNames
        guard !names.isEmpty else {
            return "No Caliber"
        }

        return names.joined(separator: ", ")
    }

    var capacityText: String {
        String.localizedStringWithFormat(
            String(localized: "magazineCapacityText"),
            Int64(capacity)
        )
    }

    var countText: String {
        String.localizedStringWithFormat(
            String(localized: "magazineCount"),
            Int64(count)
        )
    }

    var countCapacityText: String {
        String.localizedStringWithFormat(
            String(localized: "magazineCountAndCapacity"),
            Int64(count),
            Int64(capacity)
        )
    }

    var totalRoundCapacity: Int {
        max(0, count) * max(0, capacity)
    }

    var totalRoundCapacityText: String {
        AmmoType.roundsText(for: totalRoundCapacity)
    }

    func linkedFirearms(from firearms: [Firearm]) -> [Firearm] {
        var linkedByID: [PersistentIdentifier: Firearm] = [:]

        for firearm in firearms {
            let matchesPattern = firearm.supportedMagazinePatternIDs.contains(resolvedPattern.id)
            let matchesLegacyLink = firearm.magazines.contains { $0.persistentModelID == persistentModelID }
            guard matchesPattern || matchesLegacyLink else {
                continue
            }

            linkedByID[firearm.persistentModelID] = firearm
        }

        return linkedByID.values.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
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

    private static func encodePatternSupportedCaliberNames(_ caliberNames: [String]) -> String? {
        let normalizedNames = caliberNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !normalizedNames.isEmpty,
              let data = try? JSONEncoder().encode(normalizedNames),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }

    private static func decodePatternSupportedCaliberNames(from value: String?) -> [String] {
        guard let value,
              let data = value.data(using: .utf8),
              let names = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

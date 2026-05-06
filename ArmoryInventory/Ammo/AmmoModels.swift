//
//  Caliber.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation
import SwiftData

enum KnownCaliber: String, CaseIterable, Codable, Hashable {
    case lr22 = ".22 LR"
    case rem223 = ".223 Rem"
    case nato556 = "5.56 NATO"
    case blackout300 = ".300 Blackout"
    case creedmoor65 = "6.5 Creedmoor"
    case x39_762 = "7.62x39"
    case win308 = ".308 Win"
    case acp380 = ".380 ACP"
    case mm9 = "9mm"
    case sw40 = ".40 S&W"
    case acp45 = ".45 ACP"
    case gauge12 = "12 Gauge"

    var displayName: String { rawValue }

    var normalizedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

@Model
final class Caliber {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .nullify, inverse: \Firearm.caliber) var firearms: [Firearm] = []
    @Relationship(deleteRule: .cascade, inverse: \AmmoType.caliber) var ammoTypes: [AmmoType] = []
    @Relationship(deleteRule: .cascade, inverse: \AmmoAdjustmentRecord.caliber) var adjustmentRecords: [AmmoAdjustmentRecord] = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class AmmoType {
    var brand: String
    var productName: String?
    var bulletType: String
    var grain: Int
    var loadDetail: String?
    var quantity: Int
    var centsPerRound: Int

    @Relationship var caliber: Caliber?
    @Relationship(deleteRule: .nullify, inverse: \AmmoAdjustmentRecord.ammoType) var adjustmentRecords: [AmmoAdjustmentRecord] = []

    init(
        brand: String,
        productName: String? = nil,
        bulletType: String,
        grain: Int,
        loadDetail: String? = nil,
        quantity: Int = 0,
        centsPerRound: Int = 0,
        caliber: Caliber? = nil
    ) {
        self.brand = brand
        self.productName = productName
        self.bulletType = bulletType
        self.grain = grain
        self.loadDetail = loadDetail
        self.quantity = quantity
        self.centsPerRound = centsPerRound
        self.caliber = caliber
    }

    var loadDescription: String {
        if let loadDetail, !loadDetail.isEmpty {
            return "\(bulletType) \(loadDetail)"
        }
        if grain <= 0 {
            return bulletType
        }
        return "\(bulletType) \(grain)gr"
    }

    var totalValueText: String {
        let amount = Decimal(quantity * centsPerRound) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    static func roundsText(for quantity: Int) -> String {
        String.localizedStringWithFormat(
            String(localized: "%lld Rounds"),
            Int64(quantity),
            quantity.localizedCountString
        )
    }
}

enum AmmoAdjustmentKind: String, Codable {
    case purchase = "purchaseIn"
    case consumption
}

@Model
final class AmmoAdjustmentRecord {
    var quantity: Int
    var occurredAt: Date
    var kind: AmmoAdjustmentKind.RawValue

    @Relationship var caliber: Caliber?
    @Relationship var ammoType: AmmoType?

    init(
        quantity: Int,
        occurredAt: Date = .now,
        kind: AmmoAdjustmentKind,
        caliber: Caliber? = nil,
        ammoType: AmmoType? = nil
    ) {
        self.quantity = quantity
        self.occurredAt = occurredAt
        self.kind = kind.rawValue
        self.caliber = caliber
        self.ammoType = ammoType
    }

    var adjustmentKind: AmmoAdjustmentKind {
        AmmoAdjustmentKind(rawValue: kind) ?? .consumption
    }
}

enum CommonAmmoCatalog {
    static let defaultCalibers: [KnownCaliber] = KnownCaliber.allCases

    static let defaultCaliberNames: [String] = defaultCalibers.map(\.displayName)

    static let commonBrands: [String] = [
        "AAC",
        "Barnes",
        "Belom",
        "Blazer",
        "Browning",
        "PMC",
        "CCI",
        "Fiocchi",
        "Federal",
        "Gorilla",
        "Hornady",
        "Igman",
        "Magtech",
        "Norma",
        "PPU",
        "Remington",
        "Sellier & Bellot",
        "SIG Sauer",
        "Speer",
        "Underwood",
        "Winchester"
    ].sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    static let commonBulletTypes: [String] = [
        "FMJ",
        "TMJ",
        "JHP",
        "SP",
        "BTHP",
        "BTSP",
        "CPHP",
        "LRN",
        "RN",
        "Semi-Wadcutter",
        "Wadcutter",
        "Bonded JHP",
        "FTX",
        "ELD",
        "XTP",
        "SST",
        "V-MAX"
    ]

    static let commonShotgunTypes: [String] = [
        "Slug",
        "Buckshot",
        "Birdshot"
    ]

    static func bulletTypes(for caliberName: String) -> [String] {
        isShotgunCaliber(caliberName) ? commonShotgunTypes : commonBulletTypes
    }

    static func isShotgunCaliber(_ caliberName: String) -> Bool {
        caliberName.localizedCaseInsensitiveContains("gauge")
    }

    static func grainRange(for caliberName: String) -> ClosedRange<Int>? {
        guard let referenceRange = referenceGrainRangesByCaliber[caliberName] else {
            return nil
        }

        let expandedLowerBound = max(1, Int(floor(Double(referenceRange.lowerBound) * 0.8)))
        let expandedUpperBound = Int(ceil(Double(referenceRange.upperBound) * 1.2))
        return expandedLowerBound...expandedUpperBound
    }

    static func referenceGrainRange(for caliberName: String) -> ClosedRange<Int>? {
        referenceGrainRangesByCaliber[caliberName]
    }

    static func referenceGrainRange(for caliber: KnownCaliber) -> ClosedRange<Int>? {
        referenceGrainRangesByCaliber[caliber.displayName]
    }

    private static let referenceGrainRangesByCaliber: [String: ClosedRange<Int>] = [
        KnownCaliber.mm9.displayName: 115...150,
        KnownCaliber.rem223.displayName: 55...77,
        KnownCaliber.nato556.displayName: 55...77,
        KnownCaliber.blackout300.displayName: 110...220,
        KnownCaliber.acp45.displayName: 185...230,
        KnownCaliber.sw40.displayName: 155...205,
        KnownCaliber.acp380.displayName: 85...99,
        KnownCaliber.lr22.displayName: 32...45,
        KnownCaliber.x39_762.displayName: 123...124,
        KnownCaliber.win308.displayName: 150...180,
        KnownCaliber.creedmoor65.displayName: 120...147
    ]

}

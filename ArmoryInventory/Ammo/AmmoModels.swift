//
//  Caliber.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation
import SwiftData

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
        String(localized: "\(quantity) Rounds")
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
    static let defaultCaliberNames: [String] = [
        ".22 LR",
        ".223 Rem",
        "5.56 NATO",
        ".300 Blackout",
        "6.5 Creedmoor",
        "7.62x39",
        ".308 Win",
        ".380 ACP",
        "9mm",
        ".40 S&W",
        ".45 ACP",
        "12 Gauge"
    ]

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

    private static let referenceGrainRangesByCaliber: [String: ClosedRange<Int>] = [
        "9mm": 115...150,
        ".223 Rem": 55...77,
        "5.56 NATO": 55...77,
        ".300 Blackout": 110...220,
        ".45 ACP": 185...230,
        ".40 S&W": 155...205,
        ".380 ACP": 85...99,
        ".22 LR": 32...45,
        "7.62x39": 123...124,
        ".308 Win": 150...180,
        "6.5 Creedmoor": 120...147
    ]

}

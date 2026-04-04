//
//  AmmoTestSupport.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData
@testable import ArmoryInventory

final class AmmoChangeServiceMock: AmmoChangeServicing {
    private(set) var appliedChange: (ammo: AmmoType, delta: Int, occurredAt: Date)?
    private(set) var recordedInitialPurchase: (quantity: Int, ammo: AmmoType)?
    var summaryResult = AmmoChangeSummary(
        purchased: 0,
        consumed: 0,
        purchasedAmountCents: 0,
        consumedAmountCents: 0
    )

    func applyChange(to ammo: AmmoType, delta: Int, occurredAt: Date, in context: ModelContext) {
        appliedChange = (ammo, delta, occurredAt)
    }

    func recordInitialPurchase(quantity: Int, for ammo: AmmoType, in context: ModelContext) {
        recordedInitialPurchase = (quantity, ammo)
    }

    func summary(for caliber: Caliber, within range: AmmoChangeRange, taxRate: Double) -> AmmoChangeSummary {
        summaryResult
    }
}

struct FixedInventoryTaxRateProvider: InventoryTaxRateProviding {
    let firearmsTaxRate: Double
    let ammoTaxRate: Double
    let accessoriesTaxRate: Double

    init(firearmsTaxRate: Double = 0, ammoTaxRate: Double = 0, accessoriesTaxRate: Double = 0) {
        self.firearmsTaxRate = firearmsTaxRate
        self.ammoTaxRate = ammoTaxRate
        self.accessoriesTaxRate = accessoriesTaxRate
    }

    func taxRate(for category: InventoryTaxCategory) -> Double {
        switch category {
        case .firearms:
            return firearmsTaxRate
        case .ammo:
            return ammoTaxRate
        case .accessories:
            return accessoriesTaxRate
        }
    }
}

@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([
        Caliber.self,
        AmmoType.self,
        AmmoAdjustmentRecord.self,
        Firearm.self,
        Optic.self,
        Magazine.self,
        Attachment.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
}

//
//  AmmoChangeService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

struct AmmoChangeRange {
    let start: Date
    let end: Date
}

struct AmmoChangeSummary {
    let purchased: Int
    let consumed: Int
    let purchasedAmountCents: Int
    let consumedAmountCents: Int
}

protocol AmmoChangeServicing {
    func applyChange(to ammo: AmmoType, delta: Int, occurredAt: Date, in context: ModelContext)
    func recordInitialPurchase(quantity: Int, for ammo: AmmoType, in context: ModelContext)
    func summary(for caliber: Caliber, within range: AmmoChangeRange, taxRate: Double) -> AmmoChangeSummary
}

final class AmmoChangeService: AmmoChangeServicing {
    func applyChange(to ammo: AmmoType, delta: Int, occurredAt: Date, in context: ModelContext) {
        guard delta != 0 else {
            return
        }

        context.insert(
            AmmoAdjustmentRecord(
                quantity: abs(delta),
                occurredAt: occurredAt,
                kind: delta > 0 ? .purchase : .consumption,
                caliber: ammo.caliber,
                ammoType: ammo
            )
        )

        ammo.quantity = max(0, ammo.quantity + delta)
        saveContext(context)
    }

    func recordInitialPurchase(quantity: Int, for ammo: AmmoType, in context: ModelContext) {
        guard quantity > 0 else {
            return
        }

        context.insert(
            AmmoAdjustmentRecord(
                quantity: quantity,
                kind: .purchase,
                caliber: ammo.caliber,
                ammoType: ammo
            )
        )
    }

    func summary(for caliber: Caliber, within range: AmmoChangeRange, taxRate: Double) -> AmmoChangeSummary {
        caliber.adjustmentRecords.reduce(
            into: AmmoChangeSummary(
                purchased: 0,
                consumed: 0,
                purchasedAmountCents: 0,
                consumedAmountCents: 0
            )
        ) { partialResult, record in
            guard record.occurredAt >= range.start, record.occurredAt < range.end else {
                return
            }

            let baseAmountCents = max(0, record.quantity) * max(0, record.ammoType?.centsPerRound ?? 0)
            let totalAmountCents = taxedAmountCents(baseAmountCents: baseAmountCents, taxRate: taxRate)

            switch record.adjustmentKind {
            case .purchase:
                partialResult = AmmoChangeSummary(
                    purchased: partialResult.purchased + max(0, record.quantity),
                    consumed: partialResult.consumed,
                    purchasedAmountCents: partialResult.purchasedAmountCents + totalAmountCents,
                    consumedAmountCents: partialResult.consumedAmountCents
                )
            case .consumption:
                partialResult = AmmoChangeSummary(
                    purchased: partialResult.purchased,
                    consumed: partialResult.consumed + max(0, record.quantity),
                    purchasedAmountCents: partialResult.purchasedAmountCents,
                    consumedAmountCents: partialResult.consumedAmountCents + totalAmountCents
                )
            }
        }
    }

    private func taxedAmountCents(baseAmountCents: Int, taxRate: Double) -> Int {
        Int((Double(baseAmountCents) * (1 + max(0, taxRate) / 100)).rounded())
    }

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
        } catch {
            print("Save error: \(error)")
        }
    }
}

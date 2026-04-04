//
//  AddAmmoTypeViewModel.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation
import SwiftData

final class AddAmmoTypeViewModel {
    private let ammoChangeService: AmmoChangeServicing

    init(ammoChangeService: AmmoChangeServicing = AppServices.shared.resolve()) {
        self.ammoChangeService = ammoChangeService
    }

    static func initialGrain(for caliber: Caliber) -> Int {
        CommonAmmoCatalog.referenceGrainRange(for: caliber.name)?.lowerBound ?? 0
    }

    func isShotgunCaliber(_ caliber: Caliber) -> Bool {
        CommonAmmoCatalog.isShotgunCaliber(caliber.name)
    }

    func bulletTypes(for caliber: Caliber) -> [String] {
        CommonAmmoCatalog.bulletTypes(for: caliber.name)
    }

    func loadDetailTitle(for caliber: Caliber, bulletType: String) -> String {
        guard isShotgunCaliber(caliber) else {
            return "Grain"
        }
        return bulletType == "Slug" ? "Grain" : "Size"
    }

    func loadDetailPlaceholder(for caliber: Caliber, bulletType: String) -> String {
        guard isShotgunCaliber(caliber) else {
            return "Grain"
        }
        switch bulletType {
        case "Slug":
            return "Grain"
        case "Buckshot":
            return "00, 000, #1"
        case "Birdshot":
            return "#4, #6, #7.5"
        default:
            return "Detail"
        }
    }

    func grainRange(for caliber: Caliber) -> ClosedRange<Int>? {
        CommonAmmoCatalog.grainRange(for: caliber.name)
    }

    func typicalGrainRange(for caliber: Caliber) -> ClosedRange<Int>? {
        CommonAmmoCatalog.referenceGrainRange(for: caliber.name)
    }

    func resolvedBrand(selectedBrand: String, customBrand: String, isCustomBrand: Bool) -> String {
        let rawValue = isCustomBrand ? customBrand : selectedBrand
        return rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resolvedProductName(_ productName: String) -> String? {
        let trimmedValue = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    func resolvedBulletType(selectedBulletType: String, customBulletType: String, isCustomBulletType: Bool) -> String {
        let rawValue = isCustomBulletType ? customBulletType : selectedBulletType
        return rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resolvedLoadDetail(for caliber: Caliber, bulletType: String, loadDetailText: String) -> String? {
        guard isShotgunCaliber(caliber) else {
            return nil
        }

        let trimmedValue = loadDetailText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    func resolvedGrain(grainRange: ClosedRange<Int>?, selectedGrainValue: Int, customGrainText: String) -> Int? {
        if grainRange != nil {
            return selectedGrainValue
        }
        return Int(customGrainText)
    }

    func canAdd(
        quantityText: String,
        centsPerRoundText: String,
        resolvedBrand: String,
        resolvedBulletType: String,
        resolvedGrain: Int?,
        resolvedLoadDetail: String?,
        isShotgun: Bool
    ) -> Bool {
        guard let qty = Int(quantityText), qty >= 0 else { return false }
        guard let centsPerRound = Int(centsPerRoundText), centsPerRound >= 0 else { return false }
        if isShotgun {
            if resolvedBulletType != "Slug" {
                guard resolvedLoadDetail != nil else { return false }
            }
        } else {
            guard resolvedGrain != nil else { return false }
        }
        return !resolvedBrand.isEmpty && !resolvedBulletType.isEmpty && centsPerRound >= 0
    }

    func addAmmo(
        caliber: Caliber,
        resolvedBrand: String,
        resolvedProductName: String?,
        resolvedBulletType: String,
        resolvedGrain: Int?,
        resolvedLoadDetail: String?,
        quantityText: String,
        centsPerRoundText: String,
        to context: ModelContext
    ) -> Bool {
        guard let qty = Int(quantityText), let centsPerRound = Int(centsPerRoundText) else {
            return false
        }

        let grain: Int
        if isShotgunCaliber(caliber) {
            grain = 0
        } else if let resolvedGrain {
            grain = resolvedGrain
        } else {
            return false
        }

        let ammo = AmmoType(
            brand: resolvedBrand,
            productName: resolvedProductName,
            bulletType: resolvedBulletType,
            grain: grain,
            loadDetail: resolvedLoadDetail,
            quantity: max(0, qty),
            centsPerRound: max(0, centsPerRound),
            caliber: caliber
        )
        context.insert(ammo)
        ammoChangeService.recordInitialPurchase(quantity: qty, for: ammo, in: context)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }
}

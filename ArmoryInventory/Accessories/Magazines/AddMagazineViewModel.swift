//
//  AddMagazineViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

final class AddMagazineViewModel {
    private let priceInputParser: PriceInputParsing

    init(priceInputParser: PriceInputParsing = PriceInputParserService()) {
        self.priceInputParser = priceInputParser
    }

    func initialPurchasePriceText(for magazine: Magazine?) -> String {
        magazine.map {
            (Decimal($0.purchasePriceCents) / 100).formatted(.number.precision(.fractionLength(2)))
        } ?? "0.00"
    }

    func trimmedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func optionalValue(_ value: String) -> String? {
        let trimmedValue = trimmedValue(value)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    func purchasePriceCents(from text: String) -> Int? {
        priceInputParser.purchasePriceCents(from: text)
    }

    func capacity(from text: String) -> Int? {
        let trimmedText = trimmedValue(text)
        guard let value = Int(trimmedText), value > 0 else {
            return nil
        }
        return value
    }

    func count(from text: String) -> Int? {
        let trimmedText = trimmedValue(text)
        guard let value = Int(trimmedText), value > 0 else {
            return nil
        }
        return value
    }

    func resolvedColorDetail(selectedColor: FirearmColor?, customColor: String) -> String? {
        guard selectedColor == .other else {
            return nil
        }

        let colorDetail = trimmedValue(customColor)
        return colorDetail.isEmpty ? nil : colorDetail
    }

    func linkedFirearm(for magazine: Magazine?, unlinkFirearm: Bool) -> Firearm? {
        unlinkFirearm ? nil : magazine?.firearm
    }

    func purchasePriceWithTaxText(purchasePriceCents: Int?, taxRate: Double) -> String {
        guard let purchasePriceCents else {
            return "--"
        }

        let multiplier = 1 + (taxRate / 100)
        let total = (Decimal(purchasePriceCents) / 100) * Decimal(multiplier)
        return total.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    func isReadOnly(hasMagazine: Bool, isEditing: Bool) -> Bool {
        hasMagazine && !isEditing
    }

    func showsPurchaseSection(showValueInDetails: Bool, isReadOnly: Bool) -> Bool {
        showValueInDetails || !isReadOnly
    }

    func primaryButtonTitle(hasMagazine: Bool, isEditing: Bool) -> String {
        if !hasMagazine {
            return "Add"
        }

        return isEditing ? "Save" : "Edit"
    }

    func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Magazine>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highestSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1
        return highestSortOrder + 1
    }

    func canAdd(
        brand: String,
        modelName: String,
        countText: String,
        capacityText: String,
        selectedColor: FirearmColor?,
        colorDetail: String?,
        purchasePriceText: String
    ) -> Bool {
        guard !trimmedValue(brand).isEmpty else { return false }
        guard !trimmedValue(modelName).isEmpty else { return false }
        guard count(from: countText) != nil else { return false }
        guard capacity(from: capacityText) != nil else { return false }
        guard purchasePriceCents(from: purchasePriceText) != nil else { return false }
        if selectedColor == .other, colorDetail == nil {
            return false
        }
        return true
    }

    func addMagazine(
        brand: String,
        modelName: String,
        count: Int,
        capacity: Int,
        purchaseDate: Date,
        purchasePriceCents: Int,
        color: FirearmColor?,
        colorDetail: String?,
        notes: String?,
        caliber: Caliber?,
        firearm: Firearm? = nil,
        canAdd: Bool,
        to context: ModelContext
    ) -> Bool {
        guard canAdd else {
            return false
        }

        let magazine = Magazine(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            count: count,
            capacity: capacity,
            purchaseDate: purchaseDate,
            purchasePriceCents: purchasePriceCents,
            color: color,
            colorDetail: colorDetail,
            notes: notes,
            caliber: caliber,
            firearm: firearm,
            sortOrder: nextSortOrder(in: context)
        )
        MagazinePatternMigration.applyResolvedPattern(to: magazine)
        context.insert(magazine)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func updateMagazine(
        _ magazine: Magazine,
        brand: String,
        modelName: String,
        count: Int,
        capacity: Int,
        purchaseDate: Date,
        purchasePriceCents: Int,
        color: FirearmColor?,
        colorDetail: String?,
        notes: String?,
        caliber: Caliber?,
        firearm: Firearm?,
        canSave: Bool,
        in context: ModelContext
    ) -> Bool {
        guard canSave else {
            return false
        }

        magazine.brand = trimmedValue(brand)
        magazine.modelName = trimmedValue(modelName)
        magazine.count = count
        magazine.capacity = capacity
        magazine.purchaseDate = purchaseDate
        magazine.purchasePriceCents = purchasePriceCents
        magazine.color = color?.rawValue
        magazine.colorDetail = colorDetail
        magazine.notes = notes
        magazine.caliber = caliber
        magazine.firearm = firearm
        MagazinePatternMigration.applyResolvedPattern(to: magazine)

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

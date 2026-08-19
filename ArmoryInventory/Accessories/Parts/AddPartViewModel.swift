//
//  AddPartViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/5/26.
//

import Foundation
import SwiftData

final class AddPartViewModel {
    private let priceInputParser: PriceInputParsing

    init(priceInputParser: PriceInputParsing = PriceInputParserService()) {
        self.priceInputParser = priceInputParser
    }

    func initialPurchasePriceText(for part: Part?) -> String {
        part.map {
            (Decimal($0.purchasePriceCents) / 100).formatted(.number.precision(.fractionLength(2)))
        } ?? "0.00"
    }

    func initialBarrelLengthText(for part: Part?) -> String {
        part?.barrelLengthInches?.formatted(.number.precision(.fractionLength(0...2))) ?? ""
    }

    func barrelLength(from text: String) -> Double? {
        let text = trimmedValue(text)
        guard !text.isEmpty else { return nil }
        guard let value = Double(text), value > 0 else { return nil }
        return value
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

    func resolvedTypeDetail(selectedType: PartType, customType: String) -> String? {
        guard selectedType == .other else {
            return nil
        }

        let typeDetail = trimmedValue(customType)
        return typeDetail.isEmpty ? nil : typeDetail
    }

    func resolvedColorDetail(selectedColor: FirearmColor?, customColor: String) -> String? {
        guard selectedColor == .other else {
            return nil
        }

        let colorDetail = trimmedValue(customColor)
        return colorDetail.isEmpty ? nil : colorDetail
    }

    func linkedFirearm(for part: Part?, unlinkFirearm: Bool) -> Firearm? {
        unlinkFirearm ? nil : part?.firearm
    }

    func purchasePriceWithTaxText(purchasePriceCents: Int?, taxRate: Double) -> String {
        guard let purchasePriceCents else {
            return "--"
        }

        let multiplier = 1 + (taxRate / 100)
        let total = (Decimal(purchasePriceCents) / 100) * Decimal(multiplier)
        return total.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    func isReadOnly(hasPart: Bool, isEditing: Bool) -> Bool {
        hasPart && !isEditing
    }

    func showsPurchaseSection(showValueInDetails: Bool, isReadOnly: Bool) -> Bool {
        showValueInDetails || !isReadOnly
    }

    func primaryButtonTitle(hasPart: Bool, isEditing: Bool) -> String {
        if !hasPart {
            return String(localized: "Add")
        }

        return isEditing ? String(localized: "Save") : String(localized: "Edit")
    }

    func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Part>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highestSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1
        return highestSortOrder + 1
    }

    func canAdd(
        brand: String,
        modelName: String,
        selectedType: PartType,
        typeDetail: String?,
        selectedColor: FirearmColor?,
        colorDetail: String?,
        purchasePriceText: String,
        barrelLengthText: String = ""
    ) -> Bool {
        guard !trimmedValue(brand).isEmpty else { return false }
        guard !trimmedValue(modelName).isEmpty else { return false }
        guard purchasePriceCents(from: purchasePriceText) != nil else { return false }
        if !trimmedValue(barrelLengthText).isEmpty && barrelLength(from: barrelLengthText) == nil { return false }
        if selectedType == .other, typeDetail == nil {
            return false
        }
        if selectedColor == .other, colorDetail == nil {
            return false
        }
        return true
    }

    func addPart(
        brand: String,
        modelName: String,
        type: PartType,
        typeDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        purchaseDate: Date,
        purchasePriceCents: Int,
        notes: String?,
        barrelLengthInches: Double? = nil,
        caliber: Caliber? = nil,
        firearm: Firearm? = nil,
        canAdd: Bool,
        to context: ModelContext
    ) -> Bool {
        guard canAdd else {
            return false
        }

        let part = Part(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            type: type,
            typeDetail: typeDetail,
            color: color,
            colorDetail: colorDetail,
            purchaseDate: purchaseDate,
            purchasePriceCents: purchasePriceCents,
            notes: notes,
            barrelLengthInches: type.supportsFirearmConfiguration ? barrelLengthInches : nil,
            caliber: type.supportsFirearmConfiguration ? caliber : nil,
            firearm: firearm,
            sortOrder: nextSortOrder(in: context)
        )
        context.insert(part)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func updatePart(
        _ part: Part,
        brand: String,
        modelName: String,
        type: PartType,
        typeDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        purchaseDate: Date,
        purchasePriceCents: Int,
        notes: String?,
        barrelLengthInches: Double? = nil,
        caliber: Caliber? = nil,
        firearm: Firearm?,
        canSave: Bool,
        in context: ModelContext
    ) -> Bool {
        guard canSave else {
            return false
        }

        part.brand = trimmedValue(brand)
        part.modelName = trimmedValue(modelName)
        part.type = type.rawValue
        part.typeDetail = typeDetail
        part.color = color?.rawValue
        part.colorDetail = colorDetail
        part.purchaseDate = purchaseDate
        part.purchasePriceCents = purchasePriceCents
        part.notes = notes
        part.barrelLengthInches = type.supportsFirearmConfiguration ? barrelLengthInches : nil
        part.caliber = type.supportsFirearmConfiguration ? caliber : nil
        part.firearm = firearm

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

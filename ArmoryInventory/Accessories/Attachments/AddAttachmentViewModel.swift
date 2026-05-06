//
//  AddAttachmentViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

final class AddAttachmentViewModel {
    private let priceInputParser: PriceInputParsing

    init(priceInputParser: PriceInputParsing = PriceInputParserService()) {
        self.priceInputParser = priceInputParser
    }

    func initialPurchasePriceText(for attachment: Attachment?) -> String {
        attachment.map {
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

    func resolvedTypeDetail(selectedType: AttachmentType, customType: String) -> String? {
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

    func linkedFirearm(for attachment: Attachment?, unlinkFirearm: Bool) -> Firearm? {
        unlinkFirearm ? nil : attachment?.firearm
    }

    func purchasePriceWithTaxText(purchasePriceCents: Int?, taxRate: Double) -> String {
        guard let purchasePriceCents else {
            return "--"
        }

        let multiplier = 1 + (taxRate / 100)
        let total = (Decimal(purchasePriceCents) / 100) * Decimal(multiplier)
        return total.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    func isReadOnly(hasAttachment: Bool, isEditing: Bool) -> Bool {
        hasAttachment && !isEditing
    }

    func showsPurchaseSection(showValueInDetails: Bool, isReadOnly: Bool) -> Bool {
        showValueInDetails || !isReadOnly
    }

    func primaryButtonTitle(hasAttachment: Bool, isEditing: Bool) -> String {
        if !hasAttachment {
            return String(localized: "Add")
        }

        return isEditing ? String(localized: "Save") : String(localized: "Edit")
    }

    func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Attachment>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highestSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1
        return highestSortOrder + 1
    }

    func canAdd(
        brand: String,
        modelName: String,
        selectedType: AttachmentType,
        typeDetail: String?,
        selectedColor: FirearmColor?,
        colorDetail: String?,
        purchasePriceText: String
    ) -> Bool {
        guard !trimmedValue(brand).isEmpty else { return false }
        guard !trimmedValue(modelName).isEmpty else { return false }
        guard purchasePriceCents(from: purchasePriceText) != nil else { return false }
        if selectedType == .other, typeDetail == nil {
            return false
        }
        if selectedColor == .other, colorDetail == nil {
            return false
        }
        return true
    }

    func addAttachment(
        brand: String,
        modelName: String,
        type: AttachmentType,
        typeDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        purchaseDate: Date,
        purchasePriceCents: Int,
        notes: String?,
        firearm: Firearm? = nil,
        canAdd: Bool,
        to context: ModelContext
    ) -> Bool {
        guard canAdd else {
            return false
        }

        let attachment = Attachment(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            type: type,
            typeDetail: typeDetail,
            color: color,
            colorDetail: colorDetail,
            purchaseDate: purchaseDate,
            purchasePriceCents: purchasePriceCents,
            notes: notes,
            firearm: firearm,
            sortOrder: nextSortOrder(in: context)
        )
        context.insert(attachment)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func updateAttachment(
        _ attachment: Attachment,
        brand: String,
        modelName: String,
        type: AttachmentType,
        typeDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        purchaseDate: Date,
        purchasePriceCents: Int,
        notes: String?,
        firearm: Firearm?,
        canSave: Bool,
        in context: ModelContext
    ) -> Bool {
        guard canSave else {
            return false
        }

        attachment.brand = trimmedValue(brand)
        attachment.modelName = trimmedValue(modelName)
        attachment.type = type.rawValue
        attachment.typeDetail = typeDetail
        attachment.color = color?.rawValue
        attachment.colorDetail = colorDetail
        attachment.purchaseDate = purchaseDate
        attachment.purchasePriceCents = purchasePriceCents
        attachment.notes = notes
        attachment.firearm = firearm

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

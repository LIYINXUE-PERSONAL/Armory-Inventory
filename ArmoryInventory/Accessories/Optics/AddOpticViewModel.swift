//
//  AddOpticViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

final class AddOpticViewModel {
    private let priceInputParser: PriceInputParsing

    init(priceInputParser: PriceInputParsing = PriceInputParserService()) {
        self.priceInputParser = priceInputParser
    }

    func initialPurchasePriceText(for optic: Optic?) -> String {
        optic.map {
            (Decimal($0.purchasePriceCents) / 100).formatted(.number.precision(.fractionLength(2)))
        } ?? "0.00"
    }

    func formattedNumericInput(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    func trimmedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func optionalValue(_ value: String) -> String? {
        let trimmedValue = trimmedValue(value)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    func normalizedSerialNumber(_ value: String) -> String {
        let trimmed = trimmedValue(value)
        let allowedScalars = trimmed.unicodeScalars.filter(CharacterSet.alphanumerics.contains)
        return String(String.UnicodeScalarView(allowedScalars)).uppercased()
    }

    func optionalSerialNumber(_ value: String) -> String? {
        let normalizedValue = normalizedSerialNumber(value)
        return normalizedValue.isEmpty ? nil : normalizedValue
    }

    func purchasePriceCents(from text: String) -> Int? {
        priceInputParser.purchasePriceCents(from: text)
    }

    func magnificationValue(from text: String) -> Double? {
        let trimmedText = trimmedValue(text)
        guard !trimmedText.isEmpty else {
            return nil
        }

        guard let value = Double(trimmedText), value > 0 else {
            return nil
        }
        return value
    }

    func tubeSizeMillimeters(from text: String) -> Double? {
        let trimmedText = trimmedValue(text)
        guard !trimmedText.isEmpty else {
            return nil
        }

        guard let value = Double(trimmedText), value > 0 else {
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

    func resolvedFootprintDetail(selectedFootprint: OpticFootprint, customFootprint: String) -> String? {
        guard selectedFootprint == .other else {
            return nil
        }

        let footprintDetail = trimmedValue(customFootprint)
        return footprintDetail.isEmpty ? nil : footprintDetail
    }

    func resolvedFocalPlane(
        isFixedMagnification: Bool,
        focalPlane: OpticFocalPlane?
    ) -> OpticFocalPlane? {
        guard !isFixedMagnification else {
            return nil
        }
        return focalPlane
    }

    func updatedFootprintSelection(
        selectedType: OpticType,
        selectedFootprint: OpticFootprint,
        customFootprint: String
    ) -> (footprint: OpticFootprint, customFootprint: String) {
        guard let defaultFootprint = selectedType.defaultFootprint,
              selectedFootprint == .picatinny || selectedFootprint == .other else {
            return (selectedFootprint, customFootprint)
        }

        return (defaultFootprint, "")
    }

    func resolvedMagnification(
        isFixed: Bool,
        fixedText: String,
        minText: String,
        maxText: String
    ) -> (min: Double, max: Double)? {
        if isFixed {
            guard let value = magnificationValue(from: fixedText) else {
                return nil
            }
            return (value, value)
        }

        guard let minValue = magnificationValue(from: minText),
              let maxValue = magnificationValue(from: maxText),
              maxValue >= minValue else {
            return nil
        }
        return (minValue, maxValue)
    }

    func showsMagnificationFields(for selectedType: OpticType) -> Bool {
        switch selectedType {
        case .redDot, .holographic:
            return false
        default:
            return true
        }
    }

    func showsTubeSizeField(for selectedType: OpticType) -> Bool {
        showsMagnificationFields(for: selectedType)
    }

    func duplicateExists(serialNumber: String, excluding optic: Optic?, in existingOptics: [Optic]) -> Bool {
        guard let normalizedSerialNumber = optionalSerialNumber(serialNumber) else {
            return false
        }

        return existingOptics.contains {
            if let optic, $0.persistentModelID == optic.persistentModelID {
                return false
            }
            guard let existingSerialNumber = $0.serialNumber else {
                return false
            }
            return existingSerialNumber.compare(
                normalizedSerialNumber,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }
    }

    func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Optic>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highestSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1
        return highestSortOrder + 1
    }

    func canAdd(
        brand: String,
        modelName: String,
        purchasePriceText: String,
        tubeSizeText: String,
        selectedType: OpticType,
        selectedFootprint: OpticFootprint,
        footprintDetail: String?,
        isFixedMagnification: Bool,
        fixedMagnificationText: String,
        minMagnificationText: String,
        maxMagnificationText: String,
        focalPlane: OpticFocalPlane?,
        selectedColor: FirearmColor?,
        colorDetail: String?,
        duplicateExists: Bool
    ) -> Bool {
        guard !trimmedValue(brand).isEmpty else { return false }
        guard !trimmedValue(modelName).isEmpty else { return false }
        guard purchasePriceCents(from: purchasePriceText) != nil else { return false }
        guard !duplicateExists else { return false }
        if selectedFootprint == .other, footprintDetail == nil {
            return false
        }
        if showsMagnificationFields(for: selectedType) {
            guard resolvedMagnification(
                isFixed: isFixedMagnification,
                fixedText: fixedMagnificationText,
                minText: minMagnificationText,
                maxText: maxMagnificationText
            ) != nil else {
                return false
            }
        }
        if showsTubeSizeField(for: selectedType),
           !trimmedValue(tubeSizeText).isEmpty,
           tubeSizeMillimeters(from: tubeSizeText) == nil {
            return false
        }
        if showsMagnificationFields(for: selectedType), !isFixedMagnification, focalPlane == nil {
            return false
        }
        if selectedColor == .other, colorDetail == nil {
            return false
        }
        return true
    }

    func linkedFirearm(for optic: Optic?, unlinkFirearm: Bool) -> Firearm? {
        unlinkFirearm ? nil : optic?.firearm
    }

    func showsFocalPlane(isFixedMagnification: Bool) -> Bool {
        !isFixedMagnification
    }

    func purchasePriceWithTaxText(purchasePriceCents: Int?, taxRate: Double) -> String {
        guard let purchasePriceCents else {
            return "--"
        }

        let multiplier = 1 + (taxRate / 100)
        let total = (Decimal(purchasePriceCents) / 100) * Decimal(multiplier)
        return total.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    func isReadOnly(hasOptic: Bool, isEditing: Bool) -> Bool {
        hasOptic && !isEditing
    }

    func showsPurchaseSection(showValueInDetails: Bool, isReadOnly: Bool) -> Bool {
        showValueInDetails || !isReadOnly
    }

    func primaryButtonTitle(hasOptic: Bool, isEditing: Bool) -> String {
        if !hasOptic {
            return String(localized: "Add")
        }

        return isEditing ? String(localized: "Save") : String(localized: "Edit")
    }

    func addOptic(
        brand: String,
        modelName: String,
        type: OpticType,
        serialNumber: String,
        minMagnification: Double,
        maxMagnification: Double,
        footprint: OpticFootprint,
        footprintDetail: String?,
        tubeSizeMillimeters: Double?,
        reticle: String?,
        focalPlane: OpticFocalPlane?,
        isIlluminated: Bool,
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

        let optic = Optic(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            type: type,
            serialNumber: optionalSerialNumber(serialNumber),
            minMagnification: minMagnification,
            maxMagnification: maxMagnification,
            footprint: footprint,
            footprintDetail: footprintDetail,
            tubeSizeMillimeters: tubeSizeMillimeters,
            reticle: reticle,
            focalPlane: focalPlane,
            isIlluminated: isIlluminated,
            color: color,
            colorDetail: colorDetail,
            purchaseDate: purchaseDate,
            purchasePriceCents: purchasePriceCents,
            notes: notes,
            firearm: firearm,
            sortOrder: nextSortOrder(in: context)
        )
        context.insert(optic)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func updateOptic(
        _ optic: Optic,
        brand: String,
        modelName: String,
        type: OpticType,
        serialNumber: String,
        minMagnification: Double,
        maxMagnification: Double,
        footprint: OpticFootprint,
        footprintDetail: String?,
        tubeSizeMillimeters: Double?,
        reticle: String?,
        focalPlane: OpticFocalPlane?,
        isIlluminated: Bool,
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

        optic.brand = trimmedValue(brand)
        optic.modelName = trimmedValue(modelName)
        optic.type = type.rawValue
        optic.serialNumber = optionalSerialNumber(serialNumber)
        optic.minMagnification = minMagnification
        optic.maxMagnification = maxMagnification
        optic.footprint = footprint.rawValue
        optic.footprintDetail = footprintDetail
        optic.tubeSizeMillimeters = tubeSizeMillimeters
        optic.reticle = reticle
        optic.focalPlane = focalPlane?.rawValue
        optic.isIlluminated = isIlluminated
        optic.color = color?.rawValue
        optic.colorDetail = colorDetail
        optic.purchaseDate = purchaseDate
        optic.purchasePriceCents = purchasePriceCents
        optic.notes = notes
        optic.firearm = firearm

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

//
//  AddMagazineViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

enum MagazinePatternSelection: Equatable, Identifiable {
    case automatic
    case catalog(String)
    case existingCustom(MagazinePattern)
    case legacy
    case custom

    var id: String {
        switch self {
        case .automatic:
            return "automatic"
        case let .catalog(patternID):
            return "catalog:\(patternID)"
        case let .existingCustom(pattern):
            return "existing-custom:\(pattern.id)"
        case .legacy:
            return "legacy"
        case .custom:
            return "custom"
        }
    }

    var requiresManualName: Bool {
        switch self {
        case .legacy, .custom:
            return true
        case .automatic, .catalog, .existingCustom:
            return false
        }
    }

    var allowsManualCaliberSelection: Bool {
        switch self {
        case .legacy, .custom:
            return true
        case .automatic, .catalog, .existingCustom:
            return false
        }
    }
}

final class AddMagazineViewModel {
    private let priceInputParser: PriceInputParsing
    private let compatibilityValidator: MagazineCompatibilityValidator

    init(
        priceInputParser: PriceInputParsing = PriceInputParserService(),
        compatibilityValidator: MagazineCompatibilityValidator = MagazineCompatibilityValidator()
    ) {
        self.priceInputParser = priceInputParser
        self.compatibilityValidator = compatibilityValidator
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

    func initialPatternSelection(for magazine: Magazine?) -> MagazinePatternSelection {
        guard let magazine else {
            return .automatic
        }

        switch magazine.storedPatternKind {
        case .catalog:
            if let patternID = magazine.patternID,
               MagazinePatternCatalog.pattern(id: patternID) != nil {
                return .catalog(patternID)
            }
            return .automatic
        case .legacy:
            return .legacy
        case .custom:
            return .existingCustom(magazine.resolvedPattern)
        case .unknown, nil:
            return .automatic
        }
    }

    func availableCustomPatterns(in context: ModelContext) -> [MagazinePattern] {
        let descriptor = FetchDescriptor<Magazine>(
            sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.sortOrder)]
        )
        guard let magazines = try? context.fetch(descriptor) else {
            return []
        }

        var patternsByID: [String: MagazinePattern] = [:]
        for magazine in magazines where magazine.storedPatternKind == .custom {
            let pattern = magazine.resolvedPattern
            guard pattern.kind == .custom else {
                continue
            }

            patternsByID[pattern.id] = patternsByID[pattern.id] ?? pattern
        }

        return patternsByID.values.sorted {
            let nameComparison = $0.displayName.localizedCaseInsensitiveCompare($1.displayName)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }

            return $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending
        }
    }

    func initialManualPatternName(for magazine: Magazine?) -> String {
        guard let magazine,
              let patternKind = magazine.storedPatternKind,
              patternKind == .legacy || patternKind == .custom else {
            return ""
        }

        return magazine.patternDisplayName ?? magazine.resolvedPattern.displayName
    }

    func initialCompatibleCaliberNames(for magazine: Magazine?) -> Set<String> {
        Set(magazine?.supportedCaliberNames ?? [])
    }

    func toggledCompatibleCaliberSelection(
        currentSelection: Set<String>,
        caliberName: String,
        isEditing: Bool
    ) -> Set<String> {
        guard isEditing else {
            return currentSelection
        }

        let trimmedCaliberName = trimmedValue(caliberName)
        guard !trimmedCaliberName.isEmpty else {
            return currentSelection
        }

        var selection = currentSelection
        if selection.contains(trimmedCaliberName) {
            selection.remove(trimmedCaliberName)
        } else {
            selection.insert(trimmedCaliberName)
        }
        return selection
    }

    func suggestedCatalogPatterns(firearm: Firearm?) -> [MagazinePattern] {
        if let firearm {
            return MagazinePatternCatalog.suggestedPatterns(
                firearmType: firearm.firearmType,
                action: firearm.firearmAction,
                caliberName: firearm.caliber?.name
            )
        }

        return MagazinePatternCatalog.canonicalPatterns
    }

    func additionalCatalogPatterns(firearm: Firearm?) -> [MagazinePattern] {
        let suggestedIDs = Set(suggestedCatalogPatterns(firearm: firearm).map(\.id))
        return MagazinePatternCatalog.canonicalPatterns.filter { !suggestedIDs.contains($0.id) }
    }

    func selectedPatternTitle(
        selection: MagazinePatternSelection,
        manualPatternName: String,
        brand: String,
        modelName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        existingMagazine: Magazine? = nil
    ) -> String {
        resolvedPatternDefinition(
            selection: selection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: existingMagazine
        ).pattern.displayName
    }

    func selectedPatternDescription(
        selection: MagazinePatternSelection,
        manualPatternName: String,
        brand: String,
        modelName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        existingMagazine: Magazine? = nil
    ) -> String {
        let definition = resolvedPatternDefinition(
            selection: selection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: existingMagazine
        )

        switch selection {
        case .automatic:
            return "Automatically inferred from the magazine details and existing pattern catalog."
        case .catalog:
            let calibers = definition.pattern.compatibility.supportedCaliberNames.joined(separator: ", ")
            return calibers.isEmpty ? definition.pattern.familyLabel : calibers
        case .existingCustom:
            let calibers = definition.pattern.compatibility.supportedCaliberNames.joined(separator: ", ")
            return calibers.isEmpty ? "Saved custom pattern." : calibers
        case .legacy:
            return "Legacy pattern names stay visible and editable for existing data."
        case .custom:
            return "Custom pattern names are stored exactly as entered."
        }
    }

    func resolvedSupportedCaliberNames(
        selection: MagazinePatternSelection,
        manualPatternName: String,
        brand: String,
        modelName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        existingMagazine: Magazine? = nil
    ) -> [String] {
        resolvedPatternDefinition(
            selection: selection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: existingMagazine
        ).pattern.compatibility.supportedCaliberNames
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
        purchasePriceText: String,
        patternSelection: MagazinePatternSelection,
        manualPatternName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        existingMagazine: Magazine? = nil
    ) -> Bool {
        guard !trimmedValue(brand).isEmpty else { return false }
        guard !trimmedValue(modelName).isEmpty else { return false }
        guard count(from: countText) != nil else { return false }
        guard capacity(from: capacityText) != nil else { return false }
        guard purchasePriceCents(from: purchasePriceText) != nil else { return false }
        if selectedColor == .other, colorDetail == nil {
            return false
        }
        if patternSelection.requiresManualName && trimmedValue(manualPatternName).isEmpty {
            return false
        }

        return compatibilityValidationResult(
            patternSelection: patternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: existingMagazine
        ).isCompatible
    }

    func compatibilityValidationResult(
        patternSelection: MagazinePatternSelection,
        manualPatternName: String,
        brand: String,
        modelName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        existingMagazine: Magazine? = nil
    ) -> MagazineCompatibilityValidationResult {
        guard let firearm else {
            return .compatible
        }

        let definition = resolvedPatternDefinition(
            selection: patternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: existingMagazine
        )

        return compatibilityValidator.validate(
            pattern: definition.pattern,
            selectedMagazineCaliber: nil,
            firearmType: firearm.firearmType,
            action: firearm.firearmAction,
            caliber: firearm.caliber,
            firearmDescription: firearm.displayName
        )
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
        patternSelection: MagazinePatternSelection,
        manualPatternName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm? = nil,
        canAdd: Bool,
        to context: ModelContext
    ) -> Bool {
        guard canAdd else {
            return false
        }

        let definition = resolvedPatternDefinition(
            selection: patternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: nil
        )
        let magazine = Magazine(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            patternID: definition.patternID,
            patternKind: definition.patternKind,
            patternDisplayName: definition.patternDisplayName,
            patternSupportedCaliberNames: definition.pattern.compatibility.supportedCaliberNames,
            count: count,
            capacity: capacity,
            purchaseDate: purchaseDate,
            purchasePriceCents: purchasePriceCents,
            color: color,
            colorDetail: colorDetail,
            notes: notes,
            caliber: resolvedStoredCaliber(for: definition.pattern, existingMagazine: nil, in: context),
            firearm: firearm,
            sortOrder: nextSortOrder(in: context)
        )
        if let firearm {
            guard compatibilityValidator.validate(
                pattern: definition.pattern,
                selectedMagazineCaliber: nil,
                firearmType: firearm.firearmType,
                action: firearm.firearmAction,
                caliber: firearm.caliber,
                firearmDescription: firearm.displayName
            ).isCompatible else {
                return false
            }
        }
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
        patternSelection: MagazinePatternSelection,
        manualPatternName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        canSave: Bool,
        in context: ModelContext
    ) -> Bool {
        guard canSave else {
            return false
        }

        let definition = resolvedPatternDefinition(
            selection: patternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: compatibleCaliberNames,
            firearm: firearm,
            existingMagazine: magazine
        )
        if let firearm {
            guard compatibilityValidator.validate(
                pattern: definition.pattern,
                selectedMagazineCaliber: nil,
                firearmType: firearm.firearmType,
                action: firearm.firearmAction,
                caliber: firearm.caliber,
                firearmDescription: firearm.displayName
            ).isCompatible else {
                return false
            }
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
        magazine.caliber = resolvedStoredCaliber(for: definition.pattern, existingMagazine: magazine, in: context)
        magazine.firearm = firearm
        magazine.patternID = definition.patternID
        magazine.patternKind = definition.patternKind.rawValue
        magazine.patternDisplayName = definition.patternDisplayName
        magazine.storedPatternSupportedCaliberNames = definition.pattern.compatibility.supportedCaliberNames

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    private struct ResolvedPatternDefinition {
        let pattern: MagazinePattern
        let patternID: String
        let patternKind: MagazinePatternKind
        let patternDisplayName: String?
    }

    private func resolvedPatternDefinition(
        selection: MagazinePatternSelection,
        manualPatternName: String,
        brand: String,
        modelName: String,
        compatibleCaliberNames: Set<String>,
        firearm: Firearm?,
        existingMagazine: Magazine?
    ) -> ResolvedPatternDefinition {
        switch selection {
        case .automatic:
            return inferredPatternDefinition(
                brand: brand,
                modelName: modelName,
                firearm: firearm
            )
        case let .catalog(patternID):
            if let pattern = MagazinePatternCatalog.pattern(id: patternID) {
                return ResolvedPatternDefinition(
                    pattern: pattern,
                    patternID: pattern.id,
                    patternKind: .catalog,
                    patternDisplayName: nil
                )
            }

            return inferredPatternDefinition(
                brand: brand,
                modelName: modelName,
                firearm: firearm
            )
        case let .existingCustom(pattern):
            return ResolvedPatternDefinition(
                pattern: pattern,
                patternID: pattern.id,
                patternKind: .custom,
                patternDisplayName: pattern.displayName
            )
        case .legacy:
            let name = resolvedManualPatternName(
                manualPatternName,
                brand: brand,
                modelName: modelName,
                fallback: "Legacy Pattern"
            )
            let pattern = MagazinePattern.legacy(
                displayName: name,
                familyLabel: name,
                supportedCaliberNames: supportedCaliberNames(for: compatibleCaliberNames),
                compatibleFirearmTypes: compatibleFirearmTypes(for: firearm),
                compatibleFirearmActions: compatibleFirearmActions(for: firearm)
            )
            return ResolvedPatternDefinition(
                pattern: pattern,
                patternID: pattern.id,
                patternKind: .legacy,
                patternDisplayName: pattern.displayName
            )
        case .custom:
            let name = resolvedManualPatternName(
                manualPatternName,
                brand: brand,
                modelName: modelName,
                fallback: "Custom Pattern"
            )
            let pattern = MagazinePattern.custom(
                id: existingCustomPatternID(for: existingMagazine),
                displayName: name,
                familyLabel: name,
                supportedCaliberNames: supportedCaliberNames(for: compatibleCaliberNames),
                compatibleFirearmTypes: compatibleFirearmTypes(for: firearm),
                compatibleFirearmActions: compatibleFirearmActions(for: firearm)
            )
            return ResolvedPatternDefinition(
                pattern: pattern,
                patternID: pattern.id,
                patternKind: .custom,
                patternDisplayName: pattern.displayName
            )
        }
    }

    private func inferredPatternDefinition(
        brand: String,
        modelName: String,
        firearm: Firearm?
    ) -> ResolvedPatternDefinition {
        let workingMagazine = Magazine(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            capacity: 1,
            purchasePriceCents: 0,
            firearm: firearm
        )
        MagazinePatternMigration.applyResolvedPattern(to: workingMagazine)
        return ResolvedPatternDefinition(
            pattern: workingMagazine.resolvedPattern,
            patternID: workingMagazine.patternID ?? workingMagazine.resolvedPattern.id,
            patternKind: workingMagazine.storedPatternKind ?? workingMagazine.resolvedPattern.kind,
            patternDisplayName: workingMagazine.patternDisplayName
        )
    }

    private func resolvedManualPatternName(
        _ manualPatternName: String,
        brand: String,
        modelName: String,
        fallback: String
    ) -> String {
        let trimmedManualName = trimmedValue(manualPatternName)
        if !trimmedManualName.isEmpty {
            return trimmedManualName
        }

        let fallbackName = [trimmedValue(brand), trimmedValue(modelName)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return fallbackName.isEmpty ? fallback : fallbackName
    }

    private func supportedCaliberNames(for caliberNames: Set<String>) -> [String] {
        caliberNames
            .map(trimmedValue)
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func compatibleFirearmTypes(for firearm: Firearm?) -> [FirearmType] {
        firearm.map { [$0.firearmType] } ?? []
    }

    private func compatibleFirearmActions(for firearm: Firearm?) -> [FirearmAction] {
        firearm.map { [$0.firearmAction] } ?? []
    }

    private func existingCustomPatternID(for magazine: Magazine?) -> UUID {
        guard magazine?.storedPatternKind == .custom,
              let patternID = magazine?.patternID,
              patternID.hasPrefix("custom:"),
              let customID = UUID(uuidString: String(patternID.dropFirst("custom:".count))) else {
            return UUID()
        }

        return customID
    }

    private func resolvedStoredCaliber(
        for pattern: MagazinePattern,
        existingMagazine: Magazine?,
        in context: ModelContext
    ) -> Caliber? {
        let supportedCaliberNames = pattern.compatibility.supportedCaliberNames
            .map(trimmedValue)
            .filter { !$0.isEmpty }

        guard supportedCaliberNames.count == 1,
              let caliberName = supportedCaliberNames.first else {
            return nil
        }

        if let existingCaliber = existingMagazine?.caliber,
           trimmedValue(existingCaliber.name).caseInsensitiveCompare(caliberName) == .orderedSame {
            return existingCaliber
        }

        guard let calibers = try? context.fetch(FetchDescriptor<Caliber>()) else {
            return nil
        }

        return calibers.first {
            trimmedValue($0.name).caseInsensitiveCompare(caliberName) == .orderedSame
        }
    }
}

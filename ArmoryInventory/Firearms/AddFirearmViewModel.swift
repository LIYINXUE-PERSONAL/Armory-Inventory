//
//  AddFirearmViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

final class AddFirearmViewModel {
    private let priceInputParser: PriceInputParsing
    private let compatibilityValidator: MagazineCompatibilityValidator

    init(
        priceInputParser: PriceInputParsing = PriceInputParserService(),
        compatibilityValidator: MagazineCompatibilityValidator = MagazineCompatibilityValidator()
    ) {
        self.priceInputParser = priceInputParser
        self.compatibilityValidator = compatibilityValidator
    }

    func initialPurchasePriceText(for firearm: Firearm?) -> String {
        firearm.map {
            (Decimal($0.purchasePriceCents) / 100).formatted(.number.precision(.fractionLength(2)))
        } ?? "0.00"
    }

    func initialBarrelLengthText(for firearm: Firearm?) -> String {
        firearm?.barrelLengthInches.map {
            $0.formatted(.number.precision(.fractionLength(0...2)))
        } ?? ""
    }

    func inheritedValueNotice(source: FirearmConfigurationSource) -> String {
        String.localizedStringWithFormat(
            String(localized: "Currently inherited from the %@. Changes to the firearm's stored value may not be displayed while this part is attached."),
            source.displayName
        )
    }

    func selectedOpticIDs(for firearm: Firearm?) -> Set<PersistentIdentifier> {
        Set(firearm?.optics.map(\.persistentModelID) ?? [])
    }

    func selectedMagazinePatterns(for firearm: Firearm?) -> [FirearmMagazinePatternReference] {
        guard let firearm else {
            return []
        }

        if !firearm.supportedMagazinePatterns.isEmpty {
            return firearm.supportedMagazinePatterns
        }

        return inferredMagazinePatterns(from: firearm.magazines)
    }

    func selectedAttachmentIDs(for firearm: Firearm?) -> Set<PersistentIdentifier> {
        Set(firearm?.attachments.map(\.persistentModelID) ?? [])
    }

    func selectedPartIDs(for firearm: Firearm?) -> Set<PersistentIdentifier> {
        Set(firearm?.parts.map(\.persistentModelID) ?? [])
    }

    func selectedKitIDs(for firearm: Firearm?, kits: [Kit]) -> Set<PersistentIdentifier> {
        guard let firearm else {
            return []
        }
        return Set(kits.filter { $0.firearm?.persistentModelID == firearm.persistentModelID }.map(\.persistentModelID))
    }

    func trimmedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
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

    func resolvedActionDetail(selectedAction: FirearmAction, customAction: String) -> String? {
        guard selectedAction == .other else {
            return nil
        }

        let actionDetail = trimmedValue(customAction)
        return actionDetail.isEmpty ? nil : actionDetail
    }

    func resolvedColorDetail(selectedColor: FirearmColor?, customColor: String) -> String? {
        guard selectedColor == .other else {
            return nil
        }

        let colorDetail = trimmedValue(customColor)
        return colorDetail.isEmpty ? nil : colorDetail
    }

    func optionalValue(_ value: String) -> String? {
        let trimmedValue = trimmedValue(value)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    func barrelLength(from text: String) -> Double? {
        let trimmedText = trimmedValue(text)
        guard !trimmedText.isEmpty else {
            return nil
        }

        guard let barrelLength = Double(trimmedText), barrelLength > 0 else {
            return nil
        }
        return barrelLength
    }

    func purchasePriceCents(from text: String) -> Int? {
        priceInputParser.purchasePriceCents(from: text)
    }

    func resolvedOptics(from optics: [Optic], selectedIDs: Set<PersistentIdentifier>) -> [Optic] {
        optics.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func availableMagazinePatterns(
        from magazines: [Magazine],
        firearmType: FirearmType,
        action: FirearmAction,
        caliber: Caliber?,
        selectedPatterns: [FirearmMagazinePatternReference]
    ) -> [FirearmMagazinePatternReference] {
        let selectedPatternMap = Dictionary(uniqueKeysWithValues: selectedPatterns.map { ($0.id, $0) })
        var patternMap = selectedPatternMap

        for pattern in MagazinePatternCatalog.suggestedPatterns(
            firearmType: firearmType,
            action: action,
            caliberName: caliber?.name
        ) {
            patternMap[pattern.id] = patternMap[pattern.id] ?? FirearmMagazinePatternReference(pattern: pattern)
        }

        for magazine in magazines {
            let pattern = magazine.resolvedPattern
            let reference = FirearmMagazinePatternReference(pattern: pattern)
            let isSelected = selectedPatternMap[reference.id] != nil
            let isCompatible = compatibilityValidator.validate(
                pattern: pattern,
                selectedMagazineCaliber: magazine.caliber,
                firearmType: firearmType,
                action: action,
                caliber: caliber,
                firearmDescription: ""
            ).isCompatible

            if isSelected || isCompatible {
                patternMap[reference.id] = patternMap[reference.id] ?? reference
            }
        }

        return patternMap.values.sorted {
            let lhsSelected = selectedPatternMap[$0.id] != nil
            let rhsSelected = selectedPatternMap[$1.id] != nil
            if lhsSelected != rhsSelected {
                return lhsSelected && !rhsSelected
            }

            if $0.kind != $1.kind {
                return $0.kind.rawValue < $1.kind.rawValue
            }

            return $0.resolvedDisplayName.localizedCaseInsensitiveCompare($1.resolvedDisplayName) == .orderedAscending
        }
    }

    func resolvedAttachments(from attachments: [Attachment], selectedIDs: Set<PersistentIdentifier>) -> [Attachment] {
        attachments.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func resolvedParts(from parts: [Part], selectedIDs: Set<PersistentIdentifier>) -> [Part] {
        parts.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func availableOptics(
        from optics: [Optic],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?,
        kits: [Kit]
    ) -> [Optic] {
        let eligibilityService = KitEligibilityService()
        return optics.filter { optic in
            if selectedIDs.contains(optic.persistentModelID) {
                return true
            }

            guard !eligibilityService.isReserved(optic, by: kits, excluding: nil) else {
                return false
            }

            guard let linkedFirearm = optic.firearm else {
                return true
            }

            guard let firearm else {
                return false
            }

            return linkedFirearm.persistentModelID == firearm.persistentModelID
        }
    }

    func linkedMagazines(
        from magazines: [Magazine],
        selectedPatterns: [FirearmMagazinePatternReference],
        firearmType: FirearmType,
        action: FirearmAction,
        caliber: Caliber?
    ) -> [Magazine] {
        let effectivePatterns = effectiveSelectedMagazinePatterns(
            selectedPatterns: selectedPatterns,
            magazines: []
        )
        let selectedPatternIDs = Set(effectivePatterns.map(\.id))
        guard !selectedPatternIDs.isEmpty else {
            return []
        }

        return magazines.filter { magazine in
            if !selectedPatternIDs.contains(magazine.resolvedPattern.id) {
                return false
            }

            return compatibilityValidator.validate(
                pattern: magazine.resolvedPattern,
                selectedMagazineCaliber: magazine.caliber,
                firearmType: firearmType,
                action: action,
                caliber: caliber,
                firearmDescription: "\(firearmType.displayName) (\(action.displayName))"
            ).isCompatible
        }
    }

    func magazinePatternDetailText(
        for pattern: FirearmMagazinePatternReference,
        magazines: [Magazine],
        summaryFirearm: Firearm
    ) -> String {
        let matchingMagazines = magazines.filter { $0.resolvedPattern.id == pattern.id }
        guard !matchingMagazines.isEmpty else {
            return ""
        }

        return "\(summaryFirearm.linkedMagazineCountText(using: matchingMagazines)) • \(summaryFirearm.linkedMagazineCapacityText(using: matchingMagazines))"
    }

    func selectedMagazineValidationResult(
        magazines: [Magazine],
        selectedPatterns: [FirearmMagazinePatternReference],
        firearmType: FirearmType,
        action: FirearmAction,
        caliber: Caliber?,
        owningFirearm: Firearm?
    ) -> MagazineCompatibilityValidationResult {
        let selectedPatternIDs = Set(
            effectiveSelectedMagazinePatterns(
                selectedPatterns: selectedPatterns,
                magazines: magazines
            ).map(\.id)
        )
        if !selectedPatternIDs.isEmpty,
           let magazine = magazines.first(where: { !selectedPatternIDs.contains($0.resolvedPattern.id) }) {
            return .init(failure: .patternNotSelected(patternName: magazine.resolvedPattern.displayName))
        }

        return compatibilityValidator.firstFailure(
            magazines: magazines,
            firearmType: firearmType,
            action: action,
            caliber: caliber,
            owningFirearm: owningFirearm
        )
    }

    func availableAttachments(
        from attachments: [Attachment],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?,
        kits: [Kit]
    ) -> [Attachment] {
        let eligibilityService = KitEligibilityService()
        return attachments.filter { attachment in
            if selectedIDs.contains(attachment.persistentModelID) {
                return true
            }

            guard !eligibilityService.isReserved(attachment, by: kits, excluding: nil) else {
                return false
            }

            guard let linkedFirearm = attachment.firearm else {
                return true
            }

            guard let firearm else {
                return false
            }

            return linkedFirearm.persistentModelID == firearm.persistentModelID
        }
    }

    func availableParts(
        from parts: [Part],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?,
        kits: [Kit]
    ) -> [Part] {
        let eligibilityService = KitEligibilityService()
        return parts.filter { part in
            if selectedIDs.contains(part.persistentModelID) {
                return true
            }

            guard !eligibilityService.isReserved(part, by: kits, excluding: nil) else {
                return false
            }

            guard let linkedFirearm = part.firearm else {
                return true
            }

            guard let firearm else {
                return false
            }

            return linkedFirearm.persistentModelID == firearm.persistentModelID
        }
    }

    func toggledSelection(
        currentSelection: Set<PersistentIdentifier>,
        itemID: PersistentIdentifier,
        isEditing: Bool
    ) -> Set<PersistentIdentifier> {
        guard isEditing else {
            return currentSelection
        }

        var updatedSelection = currentSelection
        if updatedSelection.contains(itemID) {
            updatedSelection.remove(itemID)
        } else {
            updatedSelection.insert(itemID)
        }
        return updatedSelection
    }

    func toggledMagazinePatternSelection(
        currentSelection: [FirearmMagazinePatternReference],
        pattern: FirearmMagazinePatternReference,
        isEditing: Bool
    ) -> [FirearmMagazinePatternReference] {
        guard isEditing else {
            return currentSelection
        }

        var updatedSelection = currentSelection
        if let index = updatedSelection.firstIndex(where: { $0.id == pattern.id }) {
            updatedSelection.remove(at: index)
        } else {
            updatedSelection.append(pattern)
        }

        return updatedSelection.sorted {
            $0.resolvedDisplayName.localizedCaseInsensitiveCompare($1.resolvedDisplayName) == .orderedAscending
        }
    }

    func linkedKits(from kits: [Kit], selectedIDs: Set<PersistentIdentifier>) -> [Kit] {
        kits.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func availableKits(
        from kits: [Kit],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?
    ) -> [Kit] {
        kits.filter { kit in
            if selectedIDs.contains(kit.persistentModelID) {
                return true
            }
            guard let linkedFirearm = kit.firearm else {
                return kit.kitStatus == .built
            }
            guard let firearm else {
                return false
            }
            return linkedFirearm.persistentModelID == firearm.persistentModelID
        }
    }

    func managedOptics(from kits: [Kit]) -> [Optic] {
        kits.flatMap(\.components).compactMap(\.optic)
    }

    func managedAttachments(from kits: [Kit]) -> [Attachment] {
        kits.flatMap(\.components).compactMap(\.attachment)
    }

    func managedParts(from kits: [Kit]) -> [Part] {
        kits.flatMap(\.components).compactMap(\.part)
    }

    func effectiveOptics(resolvedOptics: [Optic], managedOptics: [Optic]) -> [Optic] {
        resolvedOptics + managedOptics.filter { managed in
            !resolvedOptics.contains { $0.persistentModelID == managed.persistentModelID }
        }
    }

    func effectiveAttachments(resolvedAttachments: [Attachment], managedAttachments: [Attachment]) -> [Attachment] {
        resolvedAttachments + managedAttachments.filter { managed in
            !resolvedAttachments.contains { $0.persistentModelID == managed.persistentModelID }
        }
    }

    func effectiveParts(resolvedParts: [Part], managedParts: [Part]) -> [Part] {
        resolvedParts + managedParts.filter { managed in
            !resolvedParts.contains { $0.persistentModelID == managed.persistentModelID }
        }
    }

    func accessoriesSubtotalCents(
        optics: [Optic],
        magazines: [Magazine],
        attachments: [Attachment],
        parts: [Part]
    ) -> Int {
        let opticsTotal = optics.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let magazinesTotal = magazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let attachmentsTotal = attachments.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let partsTotal = parts.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        return opticsTotal + magazinesTotal + attachmentsTotal + partsTotal
    }

    func isReadOnly(hasFirearm: Bool, isEditing: Bool) -> Bool {
        hasFirearm && !isEditing
    }

    func showsPurchaseSection(showValueInDetails: Bool, isReadOnly: Bool) -> Bool {
        showValueInDetails || !isReadOnly
    }

    func showsPostTaxTotalSection(hasFirearm: Bool, showValueInDetails: Bool) -> Bool {
        hasFirearm && showValueInDetails
    }

    func totalValueWithTaxText(
        firearmPriceCents: Int,
        accessoriesSubtotalCents: Int,
        firearmsTaxRate: Double,
        accessoriesTaxRate: Double
    ) -> String {
        let firearmTotalCents = taxedAmountCents(baseAmountCents: max(0, firearmPriceCents), taxRate: firearmsTaxRate)
        let accessoriesTotalCents = taxedAmountCents(baseAmountCents: accessoriesSubtotalCents, taxRate: accessoriesTaxRate)
        let amount = Decimal(firearmTotalCents + accessoriesTotalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    func taxedAmountCents(baseAmountCents: Int, taxRate: Double) -> Int {
        Int((Double(baseAmountCents) * (1 + max(0, taxRate) / 100)).rounded())
    }

    func currentFirearmForSummary(
        firearm: Firearm?,
        brand: String,
        modelName: String,
        purchasePriceCents: Int,
        type: FirearmType,
        action: FirearmAction
    ) -> Firearm {
        firearm ?? Firearm(
            brand: brand,
            modelName: modelName,
            purchasePriceCents: purchasePriceCents,
            type: type,
            action: action
        )
    }

    func primaryButtonTitle(hasFirearm: Bool, isEditing: Bool) -> String {
        if !hasFirearm {
            return String(localized: "Add")
        }

        return isEditing ? String(localized: "Save") : String(localized: "Edit")
    }

    func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Firearm>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highestSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1
        return highestSortOrder + 1
    }

    func duplicateExists(serialNumber: String, in existingFirearms: [Firearm]) -> Bool {
        duplicateExists(serialNumber: serialNumber, excluding: nil, in: existingFirearms)
    }

    func duplicateExists(serialNumber: String, excluding firearm: Firearm?, in existingFirearms: [Firearm]) -> Bool {
        guard let normalizedSerialNumber = optionalSerialNumber(serialNumber) else {
            return false
        }

        return existingFirearms.contains {
            if let firearm, $0.persistentModelID == firearm.persistentModelID {
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

    func canAdd(
        brand: String,
        modelName: String,
        serialNumber: String,
        selectedType: FirearmType,
        selectedAction: FirearmAction,
        actionDetail: String?,
        selectedColor: FirearmColor?,
        colorDetail: String?,
        purchasePriceText: String,
        barrelLengthText: String,
        duplicateExists: Bool,
        magazines: [Magazine],
        selectedMagazinePatterns: [FirearmMagazinePatternReference],
        caliber: Caliber?,
        owningFirearm: Firearm?
    ) -> Bool {
        guard !trimmedValue(brand).isEmpty else { return false }
        guard !trimmedValue(modelName).isEmpty else { return false }
        guard purchasePriceCents(from: purchasePriceText) != nil else { return false }
        guard !duplicateExists else { return false }
        if selectedAction == .other, actionDetail == nil {
            return false
        }
        if selectedColor == .other, colorDetail == nil {
            return false
        }

        if !trimmedValue(barrelLengthText).isEmpty && barrelLength(from: barrelLengthText) == nil {
            return false
        }

        return selectedMagazineValidationResult(
            magazines: magazines,
            selectedPatterns: selectedMagazinePatterns,
            firearmType: selectedType,
            action: selectedAction,
            caliber: caliber,
            owningFirearm: owningFirearm
        ).isCompatible
    }

    func addFirearm(
        brand: String,
        modelName: String,
        nickname: String?,
        serialNumber: String,
        purchaseDate: Date,
        lastCleanedDate: Date?,
        purchasePriceCents: Int,
        type: FirearmType,
        action: FirearmAction,
        actionDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        barrelLengthInches: Double?,
        notes: String?,
        supportedMagazinePatterns: [FirearmMagazinePatternReference],
        caliber: Caliber?,
        optics: [Optic],
        magazines: [Magazine],
        attachments: [Attachment],
        parts: [Part],
        canAdd: Bool,
        to context: ModelContext
    ) -> Bool {
        guard canAdd else {
            return false
        }
        guard selectedMagazineValidationResult(
            magazines: magazines,
            selectedPatterns: supportedMagazinePatterns,
            firearmType: type,
            action: action,
            caliber: caliber,
            owningFirearm: nil
        ).isCompatible else {
            return false
        }

        let persistedMagazinePatterns = effectiveSelectedMagazinePatterns(
            selectedPatterns: supportedMagazinePatterns,
            magazines: magazines
        )
        let firearm = Firearm(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            nickname: optionalValue(nickname ?? ""),
            serialNumber: optionalSerialNumber(serialNumber),
            purchaseDate: purchaseDate,
            lastCleanedDate: lastCleanedDate,
            purchasePriceCents: purchasePriceCents,
            type: type,
            action: action,
            actionDetail: actionDetail,
            color: color,
            colorDetail: colorDetail,
            barrelLengthInches: barrelLengthInches,
            notes: notes,
            supportedMagazinePatterns: persistedMagazinePatterns,
            caliber: caliber,
            optics: optics,
            magazines: [],
            attachments: attachments,
            parts: parts,
            sortOrder: nextSortOrder(in: context)
        )
        context.insert(firearm)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func updateFirearm(
        _ firearm: Firearm,
        brand: String,
        modelName: String,
        nickname: String?,
        serialNumber: String,
        purchaseDate: Date,
        lastCleanedDate: Date?,
        purchasePriceCents: Int,
        type: FirearmType,
        action: FirearmAction,
        actionDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        barrelLengthInches: Double?,
        notes: String?,
        supportedMagazinePatterns: [FirearmMagazinePatternReference],
        caliber: Caliber?,
        optics: [Optic],
        magazines: [Magazine],
        attachments: [Attachment],
        parts: [Part],
        canSave: Bool,
        in context: ModelContext
    ) -> Bool {
        guard canSave else {
            return false
        }
        guard selectedMagazineValidationResult(
            magazines: magazines,
            selectedPatterns: supportedMagazinePatterns,
            firearmType: type,
            action: action,
            caliber: caliber,
            owningFirearm: firearm
        ).isCompatible else {
            return false
        }

        let persistedMagazinePatterns = effectiveSelectedMagazinePatterns(
            selectedPatterns: supportedMagazinePatterns,
            magazines: magazines
        )
        firearm.brand = trimmedValue(brand)
        firearm.modelName = trimmedValue(modelName)
        firearm.nickname = optionalValue(nickname ?? "")
        firearm.serialNumber = optionalSerialNumber(serialNumber)
        firearm.purchaseDate = purchaseDate
        firearm.lastCleanedDate = lastCleanedDate
        firearm.purchasePriceCents = purchasePriceCents
        firearm.type = type.rawValue
        firearm.action = action.rawValue
        firearm.actionDetail = actionDetail
        firearm.color = color?.rawValue
        firearm.colorDetail = colorDetail
        firearm.barrelLengthInches = barrelLengthInches
        firearm.notes = notes
        firearm.supportedMagazinePatterns = persistedMagazinePatterns
        firearm.caliber = caliber
        firearm.optics = optics
        firearm.attachments = attachments
        firearm.parts = parts

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func deleteFirearm(_ firearm: Firearm, in context: ModelContext) -> KitValidationResult {
        do {
            let linkedKits = try context.fetch(FetchDescriptor<Kit>()).filter {
                $0.firearm?.persistentModelID == firearm.persistentModelID
            }

            for kit in linkedKits {
                kit.firearm = nil
                kit.status = KitStatus.built.rawValue
                kit.updatedAt = .now
            }

            context.delete(firearm)
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return .valid
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    func saveKitLinks(firearm: Firearm, selectedKitIDs: Set<PersistentIdentifier>, kits: [Kit], in context: ModelContext) -> KitValidationResult {
        for kit in kits {
            let isSelected = selectedKitIDs.contains(kit.persistentModelID)
            let isLinkedHere = kit.firearm?.persistentModelID == firearm.persistentModelID

            if isSelected {
                kit.firearm = firearm
                kit.status = KitStatus.linked.rawValue
                kit.updatedAt = .now
            } else if isLinkedHere {
                kit.firearm = nil
                kit.status = KitStatus.built.rawValue
                kit.updatedAt = .now
            }
        }

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return .valid
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    func managingKitName(for optic: Optic, kits: [Kit]) -> String {
        kits.first { kit in
            kit.components.contains { $0.optic?.persistentModelID == optic.persistentModelID }
        }?.displayName ?? String(localized: "Kit")
    }

    func managingKitName(for attachment: Attachment, kits: [Kit]) -> String {
        kits.first { kit in
            kit.components.contains { $0.attachment?.persistentModelID == attachment.persistentModelID }
        }?.displayName ?? String(localized: "Kit")
    }

    func managingKitName(for part: Part, kits: [Kit]) -> String {
        kits.first { kit in
            kit.components.contains { $0.part?.persistentModelID == part.persistentModelID }
        }?.displayName ?? String(localized: "Kit")
    }

    private func effectiveSelectedMagazinePatterns(
        selectedPatterns: [FirearmMagazinePatternReference],
        magazines: [Magazine]
    ) -> [FirearmMagazinePatternReference] {
        if !selectedPatterns.isEmpty {
            return selectedPatterns
        }

        return inferredMagazinePatterns(from: magazines)
    }

    private func inferredMagazinePatterns(from magazines: [Magazine]) -> [FirearmMagazinePatternReference] {
        var seenIDs: Set<String> = []
        var patterns: [FirearmMagazinePatternReference] = []

        for magazine in magazines {
            let reference = FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)
            if seenIDs.insert(reference.id).inserted {
                patterns.append(reference)
            }
        }

        return patterns.sorted {
            $0.resolvedDisplayName.localizedCaseInsensitiveCompare($1.resolvedDisplayName) == .orderedAscending
        }
    }
}

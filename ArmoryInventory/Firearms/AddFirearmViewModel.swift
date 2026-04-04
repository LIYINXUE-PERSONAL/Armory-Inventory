//
//  AddFirearmViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

final class AddFirearmViewModel {
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

    func selectedOpticIDs(for firearm: Firearm?) -> Set<PersistentIdentifier> {
        Set(firearm?.optics.map(\.persistentModelID) ?? [])
    }

    func selectedMagazineIDs(for firearm: Firearm?) -> Set<PersistentIdentifier> {
        Set(firearm?.magazines.map(\.persistentModelID) ?? [])
    }

    func selectedAttachmentIDs(for firearm: Firearm?) -> Set<PersistentIdentifier> {
        Set(firearm?.attachments.map(\.persistentModelID) ?? [])
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
        let trimmedText = trimmedValue(text)
        guard !trimmedText.isEmpty else {
            return nil
        }

        let normalizedText = trimmedText.replacingOccurrences(of: "$", with: "")
        guard let amount = Decimal(string: normalizedText), amount >= 0 else {
            return nil
        }

        let cents = (amount * 100 as NSDecimalNumber).rounding(accordingToBehavior: nil).intValue
        return cents
    }

    func resolvedOptics(from optics: [Optic], selectedIDs: Set<PersistentIdentifier>) -> [Optic] {
        optics.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func resolvedMagazines(from magazines: [Magazine], selectedIDs: Set<PersistentIdentifier>) -> [Magazine] {
        magazines.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func resolvedAttachments(from attachments: [Attachment], selectedIDs: Set<PersistentIdentifier>) -> [Attachment] {
        attachments.filter { selectedIDs.contains($0.persistentModelID) }
    }

    func availableOptics(
        from optics: [Optic],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?
    ) -> [Optic] {
        optics.filter { optic in
            if selectedIDs.contains(optic.persistentModelID) {
                return true
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

    func availableMagazines(
        from magazines: [Magazine],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?
    ) -> [Magazine] {
        magazines.filter { magazine in
            if selectedIDs.contains(magazine.persistentModelID) {
                return true
            }

            guard let linkedFirearm = magazine.firearm else {
                return true
            }

            guard let firearm else {
                return false
            }

            return linkedFirearm.persistentModelID == firearm.persistentModelID
        }
    }

    func availableAttachments(
        from attachments: [Attachment],
        selectedIDs: Set<PersistentIdentifier>,
        firearm: Firearm?
    ) -> [Attachment] {
        attachments.filter { attachment in
            if selectedIDs.contains(attachment.persistentModelID) {
                return true
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

    func isReadOnly(hasFirearm: Bool, isEditing: Bool) -> Bool {
        hasFirearm && !isEditing
    }

    func showsPurchaseSection(showValueInDetails: Bool, isReadOnly: Bool) -> Bool {
        showValueInDetails || !isReadOnly
    }

    func primaryButtonTitle(hasFirearm: Bool, isEditing: Bool) -> String {
        if !hasFirearm {
            return "Add"
        }

        return isEditing ? "Save" : "Edit"
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
        selectedAction: FirearmAction,
        actionDetail: String?,
        selectedColor: FirearmColor?,
        colorDetail: String?,
        purchasePriceText: String,
        barrelLengthText: String,
        duplicateExists: Bool
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

        return true
    }

    func addFirearm(
        brand: String,
        modelName: String,
        nickname: String?,
        serialNumber: String,
        purchaseDate: Date,
        purchasePriceCents: Int,
        type: FirearmType,
        action: FirearmAction,
        actionDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        barrelLengthInches: Double?,
        notes: String?,
        caliber: Caliber?,
        optics: [Optic],
        magazines: [Magazine],
        attachments: [Attachment],
        canAdd: Bool,
        to context: ModelContext
    ) -> Bool {
        guard canAdd else {
            return false
        }

        let firearm = Firearm(
            brand: trimmedValue(brand),
            modelName: trimmedValue(modelName),
            nickname: optionalValue(nickname ?? ""),
            serialNumber: optionalSerialNumber(serialNumber),
            purchaseDate: purchaseDate,
            purchasePriceCents: purchasePriceCents,
            type: type,
            action: action,
            actionDetail: actionDetail,
            color: color,
            colorDetail: colorDetail,
            barrelLengthInches: barrelLengthInches,
            notes: notes,
            caliber: caliber,
            optics: optics,
            magazines: magazines,
            attachments: attachments,
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
        purchasePriceCents: Int,
        type: FirearmType,
        action: FirearmAction,
        actionDetail: String?,
        color: FirearmColor?,
        colorDetail: String?,
        barrelLengthInches: Double?,
        notes: String?,
        caliber: Caliber?,
        optics: [Optic],
        magazines: [Magazine],
        attachments: [Attachment],
        canSave: Bool,
        in context: ModelContext
    ) -> Bool {
        guard canSave else {
            return false
        }

        firearm.brand = trimmedValue(brand)
        firearm.modelName = trimmedValue(modelName)
        firearm.nickname = optionalValue(nickname ?? "")
        firearm.serialNumber = optionalSerialNumber(serialNumber)
        firearm.purchaseDate = purchaseDate
        firearm.purchasePriceCents = purchasePriceCents
        firearm.type = type.rawValue
        firearm.action = action.rawValue
        firearm.actionDetail = actionDetail
        firearm.color = color?.rawValue
        firearm.colorDetail = colorDetail
        firearm.barrelLengthInches = barrelLengthInches
        firearm.notes = notes
        firearm.caliber = caliber
        firearm.optics = optics
        firearm.magazines = magazines
        firearm.attachments = attachments

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

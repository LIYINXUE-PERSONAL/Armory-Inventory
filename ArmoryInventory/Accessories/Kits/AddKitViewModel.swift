//
//  AddKitViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 5/14/26.
//

import Foundation
import SwiftData

struct KitComponentSelection: Identifiable, Hashable {
    let category: KitComponentCategory
    let itemID: PersistentIdentifier

    var id: String {
        "\(category.rawValue)-\(itemID)"
    }
}

struct AddKitComponentRow: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String

    init(selection: KitComponentSelection, title: String, subtitle: String) {
        self.id = selection.id
        self.title = title
        self.subtitle = subtitle
    }
}

struct AddKitComponentPickerItem: Identifiable, Hashable {
    let id: PersistentIdentifier
    let title: String
    let subtitle: String
    let isSelected: Bool
}

final class AddKitViewModel {
    private let eligibilityService: KitEligibilityServicing

    init(eligibilityService: KitEligibilityServicing = AppServices.shared.resolve(KitEligibilityServicing.self)) {
        self.eligibilityService = eligibilityService
    }

    func initialName(for kit: Kit?) -> String {
        kit?.name ?? ""
    }

    func initialNotes(for kit: Kit?) -> String {
        kit?.notes ?? ""
    }

    func initialKind(for kit: Kit?) -> KitKind {
        kit?.kitKind ?? .upperReceiver
    }

    func navigationTitle(for kit: Kit?) -> String {
        kit == nil ? String(localized: "New Kit") : String(localized: "Kit Details")
    }

    func primarySaveTitle(for kit: Kit?) -> String {
        kit == nil ? String(localized: "Build Kit") : String(localized: "Save")
    }

    func shouldShowDisassembleButton(for kit: Kit?) -> Bool {
        guard let kit else {
            return false
        }
        return kit.kitStatus == .built || kit.kitStatus == .linked
    }

    func initialSelections(for kit: Kit?) -> [KitComponentSelection] {
        kit?.sortedComponents.compactMap { component in
            guard let identity = component.stableIdentity else {
                return nil
            }

            switch identity {
            case let .part(id):
                return KitComponentSelection(category: .part, itemID: id)
            case let .optic(id):
                return KitComponentSelection(category: .optic, itemID: id)
            case let .attachment(id):
                return KitComponentSelection(category: .attachment, itemID: id)
            }
        } ?? []
    }

    func trimmedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func optionalValue(_ value: String) -> String? {
        let trimmed = trimmedValue(value)
        return trimmed.isEmpty ? nil : trimmed
    }

    func emptySelectionText(for category: KitComponentCategory) -> String {
        switch category {
        case .part:
            return String(localized: "No parts selected.")
        case .optic:
            return String(localized: "No optics selected.")
        case .attachment:
            return String(localized: "No attachments selected.")
        }
    }

    func pickerTitle(for category: KitComponentCategory) -> String {
        switch category {
        case .part:
            return String(localized: "Select Parts")
        case .optic:
            return String(localized: "Select Optics")
        case .attachment:
            return String(localized: "Select Attachments")
        }
    }

    func pickerEmptyTitle(for category: KitComponentCategory) -> String {
        switch category {
        case .part:
            return String(localized: "No Parts Available")
        case .optic:
            return String(localized: "No Optics Available")
        case .attachment:
            return String(localized: "No Attachments Available")
        }
    }

    func displayName(name: String, kind: KitKind) -> String {
        let trimmed = trimmedValue(name)
        return trimmed.isEmpty ? kind.displayName : trimmed
    }

    func selectedIDs(from selections: [KitComponentSelection], category: KitComponentCategory) -> Set<PersistentIdentifier> {
        Set(selections.filter { $0.category == category }.map(\.itemID))
    }

    func availableParts(from parts: [Part], selectedIDs: Set<PersistentIdentifier>, kits: [Kit], editing kit: Kit?) -> [Part] {
        parts.filter { part in
            selectedIDs.contains(part.persistentModelID) ||
            eligibilityService.canSelectForKit(part, kits: kits, excluding: kit)
        }
    }

    func availableOptics(from optics: [Optic], selectedIDs: Set<PersistentIdentifier>, kits: [Kit], editing kit: Kit?) -> [Optic] {
        optics.filter { optic in
            selectedIDs.contains(optic.persistentModelID) ||
            eligibilityService.canSelectForKit(optic, kits: kits, excluding: kit)
        }
    }

    func availableAttachments(
        from attachments: [Attachment],
        selectedIDs: Set<PersistentIdentifier>,
        kits: [Kit],
        editing kit: Kit?
    ) -> [Attachment] {
        attachments.filter { attachment in
            selectedIDs.contains(attachment.persistentModelID) ||
            eligibilityService.canSelectForKit(attachment, kits: kits, excluding: kit)
        }
    }

    func toggledSelection(
        _ selections: [KitComponentSelection],
        category: KitComponentCategory,
        itemID: PersistentIdentifier
    ) -> [KitComponentSelection] {
        var updated = selections
        if let index = updated.firstIndex(where: { $0.category == category && $0.itemID == itemID }) {
            updated.remove(at: index)
        } else {
            updated.append(KitComponentSelection(category: category, itemID: itemID))
        }
        return updated
    }

    func components(
        from selections: [KitComponentSelection],
        parts: [Part],
        optics: [Optic],
        attachments: [Attachment]
    ) -> [KitComponent] {
        selections.enumerated().compactMap { index, selection in
            switch selection.category {
            case .part:
                guard let part = parts.first(where: { $0.persistentModelID == selection.itemID }) else {
                    return nil
                }
                return KitComponent(category: .part, part: part, sortOrder: index)
            case .optic:
                guard let optic = optics.first(where: { $0.persistentModelID == selection.itemID }) else {
                    return nil
                }
                return KitComponent(category: .optic, optic: optic, sortOrder: index)
            case .attachment:
                guard let attachment = attachments.first(where: { $0.persistentModelID == selection.itemID }) else {
                    return nil
                }
                return KitComponent(category: .attachment, attachment: attachment, sortOrder: index)
            }
        }
    }

    func componentValueCents(
        from selections: [KitComponentSelection],
        parts: [Part],
        optics: [Optic],
        attachments: [Attachment]
    ) -> Int {
        KitValueService.totalValueCents(
            for: components(
                from: selections,
                parts: parts,
                optics: optics,
                attachments: attachments
            )
        )
    }

    func selectedComponentRows(
        for category: KitComponentCategory,
        selections: [KitComponentSelection],
        parts: [Part],
        optics: [Optic],
        attachments: [Attachment]
    ) -> [AddKitComponentRow] {
        selections
            .filter { $0.category == category }
            .map { selection in
                AddKitComponentRow(
                    selection: selection,
                    title: componentTitle(for: selection, parts: parts, optics: optics, attachments: attachments),
                    subtitle: componentSubtitle(for: selection, parts: parts, optics: optics, attachments: attachments)
                )
            }
    }

    func partPickerItems(
        parts: [Part],
        selections: [KitComponentSelection],
        kits: [Kit],
        editing kit: Kit?
    ) -> [AddKitComponentPickerItem] {
        let selectedIDs = selectedIDs(from: selections, category: .part)
        return availableParts(from: parts, selectedIDs: selectedIDs, kits: kits, editing: kit).map { part in
            AddKitComponentPickerItem(
                id: part.persistentModelID,
                title: part.displayName,
                subtitle: part.typeDisplayName,
                isSelected: selectedIDs.contains(part.persistentModelID)
            )
        }
    }

    func opticPickerItems(
        optics: [Optic],
        selections: [KitComponentSelection],
        kits: [Kit],
        editing kit: Kit?
    ) -> [AddKitComponentPickerItem] {
        let selectedIDs = selectedIDs(from: selections, category: .optic)
        return availableOptics(from: optics, selectedIDs: selectedIDs, kits: kits, editing: kit).map { optic in
            AddKitComponentPickerItem(
                id: optic.persistentModelID,
                title: optic.displayName,
                subtitle: opticSubtitle(for: optic),
                isSelected: selectedIDs.contains(optic.persistentModelID)
            )
        }
    }

    func attachmentPickerItems(
        attachments: [Attachment],
        selections: [KitComponentSelection],
        kits: [Kit],
        editing kit: Kit?
    ) -> [AddKitComponentPickerItem] {
        let selectedIDs = selectedIDs(from: selections, category: .attachment)
        return availableAttachments(from: attachments, selectedIDs: selectedIDs, kits: kits, editing: kit).map { attachment in
            AddKitComponentPickerItem(
                id: attachment.persistentModelID,
                title: attachment.displayName,
                subtitle: attachment.typeDisplayName,
                isSelected: selectedIDs.contains(attachment.persistentModelID)
            )
        }
    }

    func componentTitle(
        for selection: KitComponentSelection,
        parts: [Part],
        optics: [Optic],
        attachments: [Attachment]
    ) -> String {
        switch selection.category {
        case .part:
            return parts.first { $0.persistentModelID == selection.itemID }?.displayName ?? String(localized: "Missing Part")
        case .optic:
            return optics.first { $0.persistentModelID == selection.itemID }?.displayName ?? String(localized: "Missing Optic")
        case .attachment:
            return attachments.first { $0.persistentModelID == selection.itemID }?.displayName ?? String(localized: "Missing Attachment")
        }
    }

    func componentSubtitle(
        for selection: KitComponentSelection,
        parts: [Part],
        optics: [Optic],
        attachments: [Attachment]
    ) -> String {
        switch selection.category {
        case .part:
            return parts.first { $0.persistentModelID == selection.itemID }?.typeDisplayName ?? selection.category.displayName
        case .optic:
            guard let optic = optics.first(where: { $0.persistentModelID == selection.itemID }) else {
                return selection.category.displayName
            }
            return opticSubtitle(for: optic)
        case .attachment:
            return attachments.first { $0.persistentModelID == selection.itemID }?.typeDisplayName ?? selection.category.displayName
        }
    }

    func opticSubtitle(for optic: Optic) -> String {
        String.localizedStringWithFormat(
            String(localized: "%@ • %@"),
            optic.typeDisplayName,
            optic.magnificationText
        )
    }

    func validationResultForBuild(components: [KitComponent], kits: [Kit], editing kit: Kit?) -> KitValidationResult {
        guard !components.isEmpty else {
            return .invalid(String(localized: "Add at least one component before building this kit."))
        }
        return eligibilityService.validationResultForBuild(components: components, kits: kits, excluding: kit)
    }

    func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Kit>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highestSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1
        return highestSortOrder + 1
    }

    @discardableResult
    func saveKit(
        _ kit: Kit?,
        name: String,
        kind: KitKind,
        notes: String?,
        components: [KitComponent],
        targetStatus: KitStatus,
        kits: [Kit],
        in context: ModelContext
    ) -> KitValidationResult {
        if targetStatus.reservesComponents {
            let validation = validationResultForBuild(components: components, kits: kits, editing: kit)
            guard validation.isValid else {
                return validation
            }
        }

        let now = Date()
        let targetKit: Kit
        if let kit {
            targetKit = kit
            for component in kit.components {
                context.delete(component)
            }
            kit.components.removeAll()
        } else {
            targetKit = Kit(
                name: displayName(name: name, kind: kind),
                kind: kind,
                status: targetStatus,
                notes: notes,
                sortOrder: nextSortOrder(in: context),
                createdAt: now,
                updatedAt: now
            )
            context.insert(targetKit)
        }

        targetKit.name = displayName(name: name, kind: kind)
        targetKit.kind = kind.rawValue
        targetKit.status = targetStatus.rawValue
        targetKit.notes = notes
        targetKit.updatedAt = now
        if targetStatus != .linked {
            targetKit.firearm = nil
        }

        for component in components {
            component.kit = targetKit
            context.insert(component)
        }
        targetKit.components = components

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return .valid
        } catch {
            return .invalid(
                String.localizedStringWithFormat(
                    String(localized: "Failed to save kit: %@"),
                    error.localizedDescription
                )
            )
        }
    }

    func disassembleKit(_ kit: Kit, in context: ModelContext) -> KitValidationResult {
        kit.firearm = nil
        context.delete(kit)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return .valid
        } catch {
            return .invalid(error.localizedDescription)
        }
    }
}

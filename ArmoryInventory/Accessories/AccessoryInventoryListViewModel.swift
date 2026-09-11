//
//  AccessoryInventoryListViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 5/20/26.
//

import Foundation
import SwiftData

final class AccessoryInventoryListViewModel {
    private let eligibilityService: KitEligibilityServicing

    init(eligibilityService: KitEligibilityServicing = KitEligibilityService()) {
        self.eligibilityService = eligibilityService
    }

    func filteredParts(_ parts: [Part], selectedType: String? = nil, selectedStatusFilter: AccessoryLinkStatusFilter, kits: [Kit]) -> [Part] {
        filteredParts(
            parts,
            selectedTypes: Set(selectedType.map { [$0] } ?? []),
            selectedStatusFilters: selectedStatusFilter == .all ? [] : [selectedStatusFilter],
            kits: kits
        )
    }

    func filteredParts(
        _ parts: [Part],
        selectedTypes: Set<String>,
        selectedStatusFilters: Set<AccessoryLinkStatusFilter>,
        kits: [Kit]
    ) -> [Part] {
        parts.filter {
            matchesType($0.type, selectedTypes: selectedTypes) &&
                matchesStatus(linkedFirearm(for: $0, kits: kits) != nil, selectedStatusFilters: selectedStatusFilters)
        }
    }

    func sortedParts(_ parts: [Part], sortOrderRaw: String, sortDirectionRaw: String) -> [Part] {
        AccessoryItemSort.sorted(
            parts,
            by: selectedItemSortOrder(from: sortOrderRaw),
            direction: selectedItemSortDirection(sortOrderRaw: sortOrderRaw, sortDirectionRaw: sortDirectionRaw)
        )
    }

    func groupedParts(_ parts: [Part], sortOrderRaw: String, sortDirectionRaw: String) -> [String: [Part]] {
        Dictionary(grouping: parts, by: \.type).mapValues {
            AccessoryItemSort.sorted(
                $0,
                by: selectedItemSortOrder(from: sortOrderRaw),
                direction: selectedItemSortDirection(sortOrderRaw: sortOrderRaw, sortDirectionRaw: sortDirectionRaw)
            )
        }
    }

    func groupedPartTypes(from groupedParts: [String: [Part]]) -> [String] {
        PartTypeSort.displayOrder(for: Array(groupedParts.keys))
    }

    func partTypeDisplayName(for typeID: String) -> String {
        PartType(rawValue: typeID)?.displayName ?? typeID
    }

    func filteredOptics(_ optics: [Optic], selectedType: String? = nil, selectedStatusFilter: AccessoryLinkStatusFilter, kits: [Kit]) -> [Optic] {
        filteredOptics(
            optics,
            selectedTypes: Set(selectedType.map { [$0] } ?? []),
            selectedStatusFilters: selectedStatusFilter == .all ? [] : [selectedStatusFilter],
            kits: kits
        )
    }

    func filteredOptics(
        _ optics: [Optic],
        selectedTypes: Set<String>,
        selectedStatusFilters: Set<AccessoryLinkStatusFilter>,
        kits: [Kit]
    ) -> [Optic] {
        optics.filter {
            matchesType($0.type, selectedTypes: selectedTypes) &&
                matchesStatus(linkedFirearm(for: $0, kits: kits) != nil, selectedStatusFilters: selectedStatusFilters)
        }
    }

    func sortedOptics(_ optics: [Optic], sortOrderRaw: String, sortDirectionRaw: String) -> [Optic] {
        AccessoryItemSort.sorted(
            optics,
            by: selectedItemSortOrder(from: sortOrderRaw),
            direction: selectedItemSortDirection(sortOrderRaw: sortOrderRaw, sortDirectionRaw: sortDirectionRaw)
        )
    }

    func groupedOptics(_ optics: [Optic], sortOrderRaw: String, sortDirectionRaw: String) -> [String: [Optic]] {
        Dictionary(grouping: optics, by: \.type).mapValues {
            AccessoryItemSort.sorted(
                $0,
                by: selectedItemSortOrder(from: sortOrderRaw),
                direction: selectedItemSortDirection(sortOrderRaw: sortOrderRaw, sortDirectionRaw: sortDirectionRaw)
            )
        }
    }

    func groupedOpticTypes(from groupedOptics: [String: [Optic]]) -> [String] {
        OpticTypeSort.displayOrder(for: Array(groupedOptics.keys))
    }

    func opticTypeDisplayName(for typeID: String) -> String {
        OpticType(rawValue: typeID)?.displayName ?? typeID
    }

    func filteredAttachments(_ attachments: [Attachment], selectedType: String? = nil, selectedStatusFilter: AccessoryLinkStatusFilter, kits: [Kit]) -> [Attachment] {
        filteredAttachments(
            attachments,
            selectedTypes: Set(selectedType.map { [$0] } ?? []),
            selectedStatusFilters: selectedStatusFilter == .all ? [] : [selectedStatusFilter],
            kits: kits
        )
    }

    func filteredAttachments(
        _ attachments: [Attachment],
        selectedTypes: Set<String>,
        selectedStatusFilters: Set<AccessoryLinkStatusFilter>,
        kits: [Kit]
    ) -> [Attachment] {
        attachments.filter {
            matchesType($0.type, selectedTypes: selectedTypes) &&
                matchesStatus(linkedFirearm(for: $0, kits: kits) != nil, selectedStatusFilters: selectedStatusFilters)
        }
    }

    func sortedAttachments(_ attachments: [Attachment], sortOrderRaw: String, sortDirectionRaw: String) -> [Attachment] {
        AccessoryItemSort.sorted(
            attachments,
            by: selectedItemSortOrder(from: sortOrderRaw),
            direction: selectedItemSortDirection(sortOrderRaw: sortOrderRaw, sortDirectionRaw: sortDirectionRaw)
        )
    }

    func groupedAttachments(_ attachments: [Attachment], sortOrderRaw: String, sortDirectionRaw: String) -> [String: [Attachment]] {
        Dictionary(grouping: attachments, by: \.type).mapValues {
            AccessoryItemSort.sorted(
                $0,
                by: selectedItemSortOrder(from: sortOrderRaw),
                direction: selectedItemSortDirection(sortOrderRaw: sortOrderRaw, sortDirectionRaw: sortDirectionRaw)
            )
        }
    }

    func groupedAttachmentTypes(from groupedAttachments: [String: [Attachment]]) -> [String] {
        AttachmentTypeSort.displayOrder(for: Array(groupedAttachments.keys))
    }

    func attachmentTypeDisplayName(for typeID: String) -> String {
        AttachmentType(rawValue: typeID)?.displayName ?? typeID
    }

    func totalValueText<T: AccessoryInventoryValuable>(for items: [T]) -> String {
        let totalCents = items.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    func linkedKit(for part: Part, kits: [Kit]) -> Kit? {
        kits.first { kit in
            kit.isActiveReservation && kit.components.contains { $0.part?.persistentModelID == part.persistentModelID }
        }
    }

    func linkedKit(for optic: Optic, kits: [Kit]) -> Kit? {
        kits.first { kit in
            kit.isActiveReservation && kit.components.contains { $0.optic?.persistentModelID == optic.persistentModelID }
        }
    }

    func linkedKit(for attachment: Attachment, kits: [Kit]) -> Kit? {
        kits.first { kit in
            kit.isActiveReservation && kit.components.contains { $0.attachment?.persistentModelID == attachment.persistentModelID }
        }
    }

    func linkedFirearm(for part: Part, kits: [Kit]) -> Firearm? {
        part.firearm ?? linkedKit(for: part, kits: kits)?.firearm
    }

    func linkedFirearm(for optic: Optic, kits: [Kit]) -> Firearm? {
        optic.firearm ?? linkedKit(for: optic, kits: kits)?.firearm
    }

    func linkedFirearm(for attachment: Attachment, kits: [Kit]) -> Firearm? {
        attachment.firearm ?? linkedKit(for: attachment, kits: kits)?.firearm
    }

    func deleteParts(
        at offsets: IndexSet,
        in type: String,
        groupedParts: [String: [Part]],
        allParts: [Part],
        kits: [Kit],
        context: ModelContext
    ) -> KitValidationResult {
        guard let sectionParts = groupedParts[type] else {
            return .valid
        }

        var blockedMessage: String?
        for index in offsets {
            let part = sectionParts[index]
            if eligibilityService.isReserved(part, by: kits, excluding: nil) {
                blockedMessage = deletionBlockedMessage(itemName: part.displayName)
            } else {
                context.delete(part)
            }
        }
        resequence(allParts)
        return save(context: context, blockedMessage: blockedMessage)
    }

    func deletePart(_ part: Part, in context: ModelContext) -> KitValidationResult {
        do {
            let allParts = try context.fetch(FetchDescriptor<Part>(sortBy: [SortDescriptor(\.sortOrder)]))
            let groupedParts = Dictionary(grouping: allParts, by: \.type)
            let kits = try context.fetch(FetchDescriptor<Kit>())
            guard let index = groupedParts[part.type]?.firstIndex(where: {
                $0.persistentModelID == part.persistentModelID
            }) else {
                return .valid
            }
            return deleteParts(
                at: IndexSet(integer: index),
                in: part.type,
                groupedParts: groupedParts,
                allParts: allParts,
                kits: kits,
                context: context
            )
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    func deleteOptics(
        at offsets: IndexSet,
        in type: String,
        groupedOptics: [String: [Optic]],
        allOptics: [Optic],
        kits: [Kit],
        context: ModelContext
    ) -> KitValidationResult {
        guard let sectionOptics = groupedOptics[type] else {
            return .valid
        }

        var blockedMessage: String?
        for index in offsets {
            let optic = sectionOptics[index]
            if eligibilityService.isReserved(optic, by: kits, excluding: nil) {
                blockedMessage = deletionBlockedMessage(itemName: optic.displayName)
            } else {
                context.delete(optic)
            }
        }
        resequence(allOptics)
        return save(context: context, blockedMessage: blockedMessage)
    }

    func deleteOptic(_ optic: Optic, in context: ModelContext) -> KitValidationResult {
        do {
            let allOptics = try context.fetch(FetchDescriptor<Optic>(sortBy: [SortDescriptor(\.sortOrder)]))
            let groupedOptics = Dictionary(grouping: allOptics, by: \.type)
            let kits = try context.fetch(FetchDescriptor<Kit>())
            guard let index = groupedOptics[optic.type]?.firstIndex(where: {
                $0.persistentModelID == optic.persistentModelID
            }) else {
                return .valid
            }
            return deleteOptics(
                at: IndexSet(integer: index),
                in: optic.type,
                groupedOptics: groupedOptics,
                allOptics: allOptics,
                kits: kits,
                context: context
            )
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    func deleteAttachments(
        at offsets: IndexSet,
        in type: String,
        groupedAttachments: [String: [Attachment]],
        allAttachments: [Attachment],
        kits: [Kit],
        context: ModelContext
    ) -> KitValidationResult {
        guard let sectionAttachments = groupedAttachments[type] else {
            return .valid
        }

        var blockedMessage: String?
        for index in offsets {
            let attachment = sectionAttachments[index]
            if eligibilityService.isReserved(attachment, by: kits, excluding: nil) {
                blockedMessage = deletionBlockedMessage(itemName: attachment.displayName)
            } else {
                context.delete(attachment)
            }
        }
        resequence(allAttachments)
        return save(context: context, blockedMessage: blockedMessage)
    }

    func deleteAttachment(_ attachment: Attachment, in context: ModelContext) -> KitValidationResult {
        do {
            let allAttachments = try context.fetch(FetchDescriptor<Attachment>(sortBy: [SortDescriptor(\.sortOrder)]))
            let groupedAttachments = Dictionary(grouping: allAttachments, by: \.type)
            let kits = try context.fetch(FetchDescriptor<Kit>())
            guard let index = groupedAttachments[attachment.type]?.firstIndex(where: {
                $0.persistentModelID == attachment.persistentModelID
            }) else {
                return .valid
            }
            return deleteAttachments(
                at: IndexSet(integer: index),
                in: attachment.type,
                groupedAttachments: groupedAttachments,
                allAttachments: allAttachments,
                kits: kits,
                context: context
            )
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    private func selectedItemSortOrder(from rawValue: String) -> AccessoryItemSortOrder {
        AccessoryItemSortOrder(rawValue: rawValue) ?? .manual
    }

    private func selectedItemSortDirection(sortOrderRaw: String, sortDirectionRaw: String) -> AccessoryItemSortDirection {
        let sortOrder = selectedItemSortOrder(from: sortOrderRaw)
        return AccessoryItemSortDirection(rawValue: sortDirectionRaw) ?? AccessoryItemSort.preferredDirection(for: sortOrder)
    }

    private func matchesStatus(_ isLinked: Bool, selectedStatusFilters: Set<AccessoryLinkStatusFilter>) -> Bool {
        guard !selectedStatusFilters.isEmpty else {
            return true
        }
        return (isLinked && selectedStatusFilters.contains(.linked)) ||
            (!isLinked && selectedStatusFilters.contains(.unlinked))
    }

    private func matchesType(_ type: String, selectedTypes: Set<String>) -> Bool {
        selectedTypes.isEmpty || selectedTypes.contains(type)
    }

    private func resequence<T: AccessoryInventorySortable>(_ items: [T]) {
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
    }

    private func save(context: ModelContext, blockedMessage: String?) -> KitValidationResult {
        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            if let blockedMessage {
                return .invalid(blockedMessage)
            }
            return .valid
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    private func deletionBlockedMessage(itemName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "Disassemble or edit the built/linked kit using %@ before deleting it."),
            itemName
        )
    }
}

protocol AccessoryInventoryValuable {
    var purchasePriceCents: Int { get }
}

protocol AccessoryInventorySortable: AnyObject {
    var sortOrder: Int { get set }
}

extension Part: AccessoryInventoryValuable, AccessoryInventorySortable {}
extension Optic: AccessoryInventoryValuable, AccessoryInventorySortable {}
extension Attachment: AccessoryInventoryValuable, AccessoryInventorySortable {}

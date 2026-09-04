//
//  KitsViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 5/20/26.
//

import Foundation
import SwiftData

struct KitComponentSummary: Identifiable, Hashable {
    let title: String
    let itemNames: String

    var id: String { title }
}

final class KitsViewModel {
    func filteredKits(
        _ kits: [Kit],
        selectedKind: KitKind?,
        selectedStatusFilter: AccessoryLinkStatusFilter,
        searchText: String
    ) -> [Kit] {
        kits.filter {
            matchesFilters(
                $0,
                selectedKind: selectedKind,
                selectedStatusFilter: selectedStatusFilter,
                searchText: searchText
            )
        }
    }

    func matchesFilters(
        _ kit: Kit,
        selectedKind: KitKind?,
        selectedStatusFilter: AccessoryLinkStatusFilter,
        searchText: String
    ) -> Bool {
        let matchesKind = selectedKind == nil || kit.kitKind == selectedKind
        let matchesStatus = matchesStatus(kit.firearm != nil, selectedStatusFilter: selectedStatusFilter)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchesSearch = query.isEmpty ||
            kit.displayName.localizedCaseInsensitiveContains(query) ||
            kit.kitKind.displayName.localizedCaseInsensitiveContains(query) ||
            (kit.firearm?.displayName.localizedCaseInsensitiveContains(query) ?? false) ||
            kit.components.contains { $0.displayName.localizedCaseInsensitiveContains(query) }
        return matchesKind && matchesStatus && matchesSearch
    }

    func totalValueText(for kits: [Kit]) -> String {
        KitValueService.currencyText(for: kits.reduce(0) { $0 + $1.totalValueCents })
    }

    func countForKind(_ kind: KitKind, in kits: [Kit]) -> Int {
        kits.count { $0.kitKind == kind }
    }

    func allKindsCountText(for kits: [Kit]) -> String {
        String.localizedStringWithFormat(
            String(localized: "All Kinds (%@)"),
            kits.count.localizedCountString
        )
    }

    func filterCountText(title: String, count: Int) -> String {
        String.localizedStringWithFormat(
            String(localized: "%@ (%@)"),
            title,
            count.localizedCountString
        )
    }

    func componentSummaries(for kit: Kit) -> [KitComponentSummary] {
        [
            KitComponentSummary(title: String(localized: "Parts"), itemNames: itemNames(for: .part, in: kit)),
            KitComponentSummary(title: String(localized: "Optics"), itemNames: itemNames(for: .optic, in: kit)),
            KitComponentSummary(title: String(localized: "Attachments"), itemNames: itemNames(for: .attachment, in: kit))
        ]
        .filter { !$0.itemNames.isEmpty }
    }

    func reorderedKits(
        allKits kits: [Kit],
        filteredKits: [Kit],
        selectedKind: KitKind?,
        selectedStatusFilter: AccessoryLinkStatusFilter,
        searchText: String,
        source: IndexSet,
        destination: Int
    ) -> [Kit] {
        let reorderedFilteredKits = movingItems(in: filteredKits, from: source, to: destination)

        var reorderedFilteredIterator = reorderedFilteredKits.makeIterator()
        return kits.map { kit in
            guard matchesFilters(
                kit,
                selectedKind: selectedKind,
                selectedStatusFilter: selectedStatusFilter,
                searchText: searchText
            ) else {
                return kit
            }

            return reorderedFilteredIterator.next() ?? kit
        }
    }

    func applySortOrder(to kits: [Kit]) {
        for (index, kit) in kits.enumerated() {
            kit.sortOrder = index
        }
    }

    func moveKits(
        allKits kits: [Kit],
        filteredKits: [Kit],
        selectedKind: KitKind?,
        selectedStatusFilter: AccessoryLinkStatusFilter,
        searchText: String,
        source: IndexSet,
        destination: Int,
        in context: ModelContext
    ) -> KitValidationResult {
        let reorderedKits = reorderedKits(
            allKits: kits,
            filteredKits: filteredKits,
            selectedKind: selectedKind,
            selectedStatusFilter: selectedStatusFilter,
            searchText: searchText,
            source: source,
            destination: destination
        )
        applySortOrder(to: reorderedKits)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return .valid
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    private func itemNames(for category: KitComponentCategory, in kit: Kit) -> String {
        kit.sortedComponents
            .filter { $0.componentCategory == category }
            .map(\.displayName)
            .joined(separator: ", ")
    }

    private func matchesStatus(_ isLinked: Bool, selectedStatusFilter: AccessoryLinkStatusFilter) -> Bool {
        switch selectedStatusFilter {
        case .all:
            return true
        case .linked:
            return isLinked
        case .unlinked:
            return !isLinked
        }
    }

    private func movingItems(in kits: [Kit], from source: IndexSet, to destination: Int) -> [Kit] {
        guard !source.isEmpty else {
            return kits
        }

        var reorderedKits = kits
        let sourceIndexes = source.sorted()
        let movingKits = sourceIndexes.map { reorderedKits[$0] }

        for index in sourceIndexes.reversed() {
            reorderedKits.remove(at: index)
        }

        let insertionIndex = destination - sourceIndexes.count { $0 < destination }
        reorderedKits.insert(contentsOf: movingKits, at: max(0, min(insertionIndex, reorderedKits.count)))
        return reorderedKits
    }
}

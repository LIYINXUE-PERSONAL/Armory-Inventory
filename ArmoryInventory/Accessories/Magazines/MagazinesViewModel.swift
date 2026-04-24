//
//  MagazinesViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/24/26.
//

import Foundation

struct MagazinePatternGroupSummary: Identifiable, Equatable {
    let id: String
    let displayName: String
    let caliberText: String
    let linkedFirearmNames: [String]
    let magazines: [Magazine]

    var summaryText: String {
        let totalCount = magazines.reduce(0) { $0 + max(0, $1.count) }
        let countText = String.localizedStringWithFormat(
            String(localized: "magazineCount"),
            Int64(totalCount)
        )
        guard !caliberText.isEmpty else {
            return countText
        }

        return "\(caliberText) • \(countText)"
    }

    var primaryCaliberName: String? {
        let caliberNames = caliberText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return caliberNames.first
    }

    var linkedFirearmsText: String {
        let baseText = String.localizedStringWithFormat(
            String(localized: "usedByFirearm"),
            Int64(linkedFirearmNames.count)
        )
        guard !linkedFirearmNames.isEmpty else {
            return baseText
        }

        return "\(baseText)\(linkedFirearmNames.joined(separator: ", "))"
    }
}

final class MagazinesViewModel {
    func groupedMagazines(_ magazines: [Magazine], firearms: [Firearm]) -> [MagazinePatternGroupSummary] {
        let grouped = Dictionary(grouping: magazines) { magazine in
            magazine.resolvedPattern.id
        }

        return grouped
            .compactMap { _, magazines in
                guard let firstMagazine = magazines.first else {
                    return nil
                }

                let pattern = firstMagazine.resolvedPattern
                return MagazinePatternGroupSummary(
                    id: pattern.id,
                    displayName: pattern.displayName,
                    caliberText: pattern.compatibility.supportedCaliberNames.joined(separator: ", "),
                    linkedFirearmNames: linkedFirearmNames(for: magazines, firearms: firearms),
                    magazines: magazines
                )
            }
            .sorted(by: areInDisplayOrder)
    }

    func linkedFirearmNames(for magazines: [Magazine], firearms: [Firearm]) -> [String] {
        var uniqueNames: Set<String> = []

        for magazine in magazines {
            for firearm in magazine.linkedFirearms(from: firearms) {
                uniqueNames.insert(firearm.displayName)
            }
        }

        return uniqueNames.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    func areInDisplayOrder(_ lhs: MagazinePatternGroupSummary, _ rhs: MagazinePatternGroupSummary) -> Bool {
        switch (lhs.primaryCaliberName, rhs.primaryCaliberName) {
        case let (lhs?, rhs?):
            if lhs.caseInsensitiveCompare(rhs) != .orderedSame {
                return CaliberSort.areInAscendingOrder(lhs, rhs)
            }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }

        let nameComparison = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
        if nameComparison != .orderedSame {
            return nameComparison == .orderedAscending
        }

        return lhs.id.localizedCaseInsensitiveCompare(rhs.id) == .orderedAscending
    }
}

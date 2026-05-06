//
//  PartTypeOrderingViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 4/6/26.
//

import Foundation

final class PartTypeOrderingViewModel {
    func rankingSource() -> [String] {
        PartTypeSort.persistedOrder(including: PartType.allCases.map(\.id))
    }

    func displayName(for normalizedName: String) -> String {
        if let match = PartType.allCases.first(where: {
            $0.id.lowercased() == normalizedName
        }) {
            return match.displayName
        }

        return normalizedName
    }

    func saveRanking(_ typeNames: [String]) {
        PartTypeSort.saveOrder(typeNames)
    }

    func refreshedRankingNames() -> [String] {
        rankingSource()
    }

    func moveRanking(_ rankingNames: [String], from source: IndexSet, to destination: Int) -> [String] {
        var updatedRankingNames = rankingNames
        let movedItems = source.map { updatedRankingNames[$0] }
        for offset in source.sorted(by: >) {
            updatedRankingNames.remove(at: offset)
        }

        var insertionIndex = destination
        for offset in source where offset < destination {
            insertionIndex -= 1
        }
        updatedRankingNames.insert(contentsOf: movedItems, at: insertionIndex)
        saveRanking(updatedRankingNames)
        return updatedRankingNames
    }

    func resetOrder(rankingNames: inout [String]) {
        PartTypeSort.resetOrder()
        rankingNames = rankingSource()
    }
}

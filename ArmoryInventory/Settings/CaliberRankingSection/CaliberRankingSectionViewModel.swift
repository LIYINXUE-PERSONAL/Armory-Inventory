//
//  CaliberRankingSectionViewModel.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation

final class CaliberRankingSectionViewModel {
    func rankingSource(calibers: [Caliber]) -> [String] {
        let allNames = CommonAmmoCatalog.defaultCaliberNames + calibers.map(\.name)
        return CaliberSort.persistedOrder(including: allNames)
    }

    func displayName(for normalizedName: String, calibers: [Caliber]) -> String {
        if let existingMatch = calibers.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
        }) {
            return existingMatch.name
        }

        if let defaultMatch = CommonAmmoCatalog.defaultCaliberNames.first(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
        }) {
            return defaultMatch
        }

        return normalizedName
    }

    func saveRanking(_ rankingNames: [String]) {
        CaliberSort.saveOrder(rankingNames)
    }

    func refreshedRankingNames(calibers: [Caliber]) -> [String] {
        rankingSource(calibers: calibers)
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

    func resetOrder(rankingNames: inout [String], calibers: [Caliber]) {
        CaliberSort.resetOrder()
        rankingNames = rankingSource(calibers: calibers)
    }
}

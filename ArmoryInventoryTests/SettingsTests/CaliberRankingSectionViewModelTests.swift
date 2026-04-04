//
//  CaliberRankingSectionViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
@testable import ArmoryInventory

final class CaliberRankingSectionViewModelTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "CaliberSortOrder")
        UserDefaults.standard.removeObject(forKey: CaliberSort.settingsVersionKey)
        super.tearDown()
    }

    func testRankingSourceIncludesSavedKnownAndCustomNames() {
        let viewModel = CaliberRankingSectionViewModel()
        CaliberSort.saveOrder(["Custom Carry", "9mm"])
        let calibers = [Caliber(name: "Range Toy")]

        let ranking = viewModel.rankingSource(calibers: calibers)

        XCTAssertEqual(Array(ranking.prefix(2)), ["custom carry", "9mm"])
        XCTAssertTrue(ranking.contains(".22 lr"))
        XCTAssertTrue(ranking.contains("range toy"))
    }

    func testDisplayNamePrefersExistingCaliberThenDefaultThenFallback() {
        let viewModel = CaliberRankingSectionViewModel()
        let calibers = [Caliber(name: "  Custom Carry  ")]

        XCTAssertEqual(viewModel.displayName(for: "custom carry", calibers: calibers), "  Custom Carry  ")
        XCTAssertEqual(viewModel.displayName(for: "9mm", calibers: calibers), "9mm")
        XCTAssertEqual(viewModel.displayName(for: "wildcat", calibers: calibers), "wildcat")
    }

    func testSaveRankingPersistsOrder() {
        let viewModel = CaliberRankingSectionViewModel()

        viewModel.saveRanking(["  Match Load  ", "9MM"])

        XCTAssertEqual(
            UserDefaults.standard.stringArray(forKey: "CaliberSortOrder"),
            ["match load", "9mm"]
        )
        XCTAssertEqual(UserDefaults.standard.integer(forKey: CaliberSort.settingsVersionKey), 1)
    }

    func testRefreshedRankingNamesReturnsLatestPersistedOrdering() {
        let viewModel = CaliberRankingSectionViewModel()
        let calibers = [Caliber(name: "Range Load")]
        viewModel.saveRanking(["Range Load", "9mm"])

        let ranking = viewModel.refreshedRankingNames(calibers: calibers)

        XCTAssertEqual(Array(ranking.prefix(2)), ["range load", "9mm"])
    }

    func testMoveRankingReordersItemsAndPersistsUpdatedOrder() {
        let viewModel = CaliberRankingSectionViewModel()
        let rankingNames = [".22 lr", "9mm", ".223 rem", ".45 acp"]

        let updated = viewModel.moveRanking(rankingNames, from: IndexSet([1, 2]), to: 4)

        XCTAssertEqual(updated, [".22 lr", ".45 acp", "9mm", ".223 rem"])
        XCTAssertEqual(
            UserDefaults.standard.stringArray(forKey: "CaliberSortOrder"),
            [".22 lr", ".45 acp", "9mm", ".223 rem"]
        )
        XCTAssertEqual(UserDefaults.standard.integer(forKey: CaliberSort.settingsVersionKey), 1)
    }

    func testResetOrderClearsSavedOrderAndRefreshesRankingNames() {
        let viewModel = CaliberRankingSectionViewModel()
        CaliberSort.saveOrder(["Custom Carry"])
        var rankingNames = ["custom carry"]
        let calibers = [Caliber(name: "Backup Gun")]

        viewModel.resetOrder(rankingNames: &rankingNames, calibers: calibers)

        XCTAssertNil(UserDefaults.standard.stringArray(forKey: "CaliberSortOrder"))
        XCTAssertEqual(UserDefaults.standard.integer(forKey: CaliberSort.settingsVersionKey), 2)
        XCTAssertTrue(rankingNames.contains(".22 lr"))
        XCTAssertTrue(rankingNames.contains("backup gun"))
        XCTAssertFalse(rankingNames.contains("custom carry"))
    }
}

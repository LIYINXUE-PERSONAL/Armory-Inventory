//
//  OpticTypeOrderingViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/6/26.
//

import XCTest
@testable import ArmoryInventory

final class OpticTypeOrderingViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpticTypeSort.resetOrder()
    }

    override func tearDown() {
        OpticTypeSort.resetOrder()
        super.tearDown()
    }

    func testRankingSourceReturnsDefaultOpticOrder() {
        let viewModel = OpticTypeOrderingViewModel()

        XCTAssertEqual(
            viewModel.rankingSource(),
            OpticType.allCases.map(\.id).map { $0.lowercased() }
        )
    }

    func testDisplayNameMatchesKnownTypesAndFallsBackForUnknownNames() {
        let viewModel = OpticTypeOrderingViewModel()

        XCTAssertEqual(viewModel.displayName(for: "reddot"), "Red Dot")
        XCTAssertEqual(viewModel.displayName(for: "red dot"), "red dot")
        XCTAssertEqual(viewModel.displayName(for: "lpvo"), "LPVO")
        XCTAssertEqual(viewModel.displayName(for: "custom thermal"), "custom thermal")
    }

    func testSaveRankingAndRefreshedRankingNamesPersistCustomOrder() {
        let viewModel = OpticTypeOrderingViewModel()
        let savedRanking = ["other", "scope", "reddot"]

        viewModel.saveRanking(savedRanking)

        XCTAssertEqual(viewModel.refreshedRankingNames().prefix(3).map { $0 }, savedRanking)
    }

    func testMoveRankingReordersValuesAndPersistsResult() {
        let viewModel = OpticTypeOrderingViewModel()
        let rankingNames = ["scope", "reddot", "holographic", "lpvo"]

        let updated = viewModel.moveRanking(rankingNames, from: IndexSet(integer: 1), to: 4)

        XCTAssertEqual(updated, ["scope", "holographic", "lpvo", "reddot"])
        XCTAssertEqual(Array(viewModel.refreshedRankingNames().prefix(4)), updated)
    }

    func testResetOrderRestoresDefaultOrdering() {
        let viewModel = OpticTypeOrderingViewModel()
        var rankingNames = ["other", "scope", "reddot"]
        viewModel.saveRanking(rankingNames)

        viewModel.resetOrder(rankingNames: &rankingNames)

        XCTAssertEqual(
            rankingNames,
            OpticType.allCases.map(\.id).map { $0.lowercased() }
        )
    }
}

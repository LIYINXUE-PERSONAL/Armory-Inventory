//
//  PartTypeOrderingViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/6/26.
//

import XCTest
@testable import ArmoryInventory

final class PartTypeOrderingViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PartTypeSort.resetOrder()
    }

    override func tearDown() {
        PartTypeSort.resetOrder()
        super.tearDown()
    }

    func testRankingSourceReturnsDefaultPartOrder() {
        let viewModel = PartTypeOrderingViewModel()

        XCTAssertEqual(
            viewModel.rankingSource(),
            PartType.allCases.map(\.id).map { $0.lowercased() }
        )
    }

    func testDisplayNameMatchesKnownTypesAndFallsBackForUnknownNames() {
        let viewModel = PartTypeOrderingViewModel()

        XCTAssertEqual(viewModel.displayName(for: "trigger"), "Trigger")
        XCTAssertEqual(viewModel.displayName(for: "boltcarriergroup"), "Bolt Carrier Group")
        XCTAssertEqual(viewModel.displayName(for: "bolt carrier group"), "bolt carrier group")
        XCTAssertEqual(viewModel.displayName(for: "custom internals"), "custom internals")
    }

    func testSaveRankingAndRefreshedRankingNamesPersistCustomOrder() {
        let viewModel = PartTypeOrderingViewModel()
        let savedRanking = ["other", "trigger", "barrel"]

        viewModel.saveRanking(savedRanking)

        XCTAssertEqual(viewModel.refreshedRankingNames().prefix(3).map { $0 }, savedRanking)
    }

    func testMoveRankingReordersValuesAndPersistsResult() {
        let viewModel = PartTypeOrderingViewModel()
        let rankingNames = ["trigger", "barrel", "slide", "charging handle"]

        let updated = viewModel.moveRanking(rankingNames, from: IndexSet(integer: 1), to: 4)

        XCTAssertEqual(updated, ["trigger", "slide", "charging handle", "barrel"])
        XCTAssertEqual(Array(viewModel.refreshedRankingNames().prefix(4)), updated)
    }

    func testResetOrderRestoresDefaultOrdering() {
        let viewModel = PartTypeOrderingViewModel()
        var rankingNames = ["other", "trigger", "barrel"]
        viewModel.saveRanking(rankingNames)

        viewModel.resetOrder(rankingNames: &rankingNames)

        XCTAssertEqual(
            rankingNames,
            PartType.allCases.map(\.id).map { $0.lowercased() }
        )
    }
}

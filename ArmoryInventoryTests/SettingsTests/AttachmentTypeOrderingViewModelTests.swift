//
//  AttachmentTypeOrderingViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class AttachmentTypeOrderingViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AttachmentTypeSort.resetOrder()
    }

    override func tearDown() {
        AttachmentTypeSort.resetOrder()
        super.tearDown()
    }

    func testRankingSourceReturnsDefaultAttachmentOrder() {
        let viewModel = AttachmentTypeOrderingViewModel()

        XCTAssertEqual(
            viewModel.rankingSource(),
            AttachmentType.allCases.map(\.id).map { $0.lowercased() }
        )
    }

    func testDisplayNameMatchesKnownTypesAndFallsBackForUnknownNames() {
        let viewModel = AttachmentTypeOrderingViewModel()

        XCTAssertEqual(viewModel.displayName(for: "stock"), "Stock")
        XCTAssertEqual(viewModel.displayName(for: "muzzledevice"), "Muzzle Device")
        XCTAssertEqual(viewModel.displayName(for: "muzzle device"), "muzzle device")
        XCTAssertEqual(viewModel.displayName(for: "custom wrap"), "custom wrap")
    }

    func testSaveRankingAndRefreshedRankingNamesPersistCustomOrder() {
        let viewModel = AttachmentTypeOrderingViewModel()
        let savedRanking = ["other", "stock", "grip"]

        viewModel.saveRanking(savedRanking)

        XCTAssertEqual(viewModel.refreshedRankingNames().prefix(3).map { $0 }, savedRanking)
    }

    func testMoveRankingReordersValuesAndPersistsResult() {
        let viewModel = AttachmentTypeOrderingViewModel()
        let rankingNames = ["stock", "grip", "laser", "light"]

        let updated = viewModel.moveRanking(rankingNames, from: IndexSet(integer: 1), to: 4)

        XCTAssertEqual(updated, ["stock", "laser", "light", "grip"])
        XCTAssertEqual(Array(viewModel.refreshedRankingNames().prefix(4)), updated)
    }

    func testResetOrderRestoresDefaultOrdering() {
        let viewModel = AttachmentTypeOrderingViewModel()
        var rankingNames = ["other", "stock", "grip"]
        viewModel.saveRanking(rankingNames)

        viewModel.resetOrder(rankingNames: &rankingNames)

        XCTAssertEqual(
            rankingNames,
            AttachmentType.allCases.map(\.id).map { $0.lowercased() }
        )
    }
}

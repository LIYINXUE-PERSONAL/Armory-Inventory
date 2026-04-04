//
//  AdjustAmmoQuantityViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
@testable import ArmoryInventory

final class AdjustAmmoQuantityViewModelTests: XCTestCase {
    func testValidationPreventsNegativeInventory() {
        let viewModel = AdjustAmmoQuantityViewModel()

        XCTAssertTrue(viewModel.canApply(quantityDeltaText: "25", currentQuantity: 50, multiplier: -1))
        XCTAssertFalse(viewModel.canApply(quantityDeltaText: "60", currentQuantity: 50, multiplier: -1))
        XCTAssertEqual(viewModel.deltaToApply(quantityDeltaText: "20", currentQuantity: 50, multiplier: -1), -20)
    }

    func testValidationRejectsInvalidOrZeroInput() {
        let viewModel = AdjustAmmoQuantityViewModel()

        XCTAssertFalse(viewModel.canApply(quantityDeltaText: "abc", currentQuantity: 50, multiplier: 1))
        XCTAssertFalse(viewModel.canApply(quantityDeltaText: "0", currentQuantity: 50, multiplier: 1))
        XCTAssertNil(viewModel.deltaToApply(quantityDeltaText: "abc", currentQuantity: 50, multiplier: 1))
    }
}

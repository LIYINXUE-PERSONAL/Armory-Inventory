//
//  AccessoriesViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/20/26.
//

import XCTest
@testable import ArmoryInventory

final class AccessoriesViewModelTests: XCTestCase {
    func testTopLevelCategoriesIncludeKitsAndTotalValueExcludesKitMembership() {
        let viewModel = AccessoriesViewModel()
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let magazine = Magazine(brand: "Magpul", modelName: "PMAG", count: 2, capacity: 30, purchasePriceCents: 1_500)
        let attachment = Attachment(brand: "BCM", modelName: "KAG", type: .handStop, purchasePriceCents: 2_000)
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 20_000)

        XCTAssertEqual(viewModel.topLevelCategories.map(\.id), ["optics", "magazines", "attachments", "parts", "kits"])
        XCTAssertEqual(
            viewModel.totalValueText(
                optics: [optic],
                magazines: [magazine],
                attachments: [attachment],
                parts: [part]
            ),
            "$935.00"
        )
    }
}

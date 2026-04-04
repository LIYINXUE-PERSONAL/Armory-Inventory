//
//  AddCaliberViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddCaliberViewModelTests: XCTestCase {
    func testSelectedNameTrimsCustomInputAndRejectsDuplicates() {
        let viewModel = AddCaliberViewModel()
        let existing = [Caliber(name: "9mm")]

        let selectedName = viewModel.selectedName(
            selectedCaliberName: "__custom__",
            customName: "  9MM  ",
            customOption: "__custom__"
        )

        XCTAssertEqual(selectedName, "9MM")
        XCTAssertTrue(viewModel.duplicateExists(named: selectedName, in: existing))
        XCTAssertFalse(viewModel.canAdd(selectedName: selectedName, duplicateExists: true))
    }

    func testSelectedNameUsesPresetSelectionAndCanAddRejectsEmptyNames() {
        let viewModel = AddCaliberViewModel()

        let selectedName = viewModel.selectedName(
            selectedCaliberName: " .308 Win ",
            customName: "Ignored",
            customOption: "__custom__"
        )

        XCTAssertEqual(selectedName, ".308 Win")
        XCTAssertFalse(viewModel.duplicateExists(named: selectedName, in: [Caliber(name: "6.5 Creedmoor")]))
        XCTAssertTrue(viewModel.canAdd(selectedName: selectedName, duplicateExists: false))
        XCTAssertFalse(viewModel.canAdd(selectedName: "", duplicateExists: false))
    }

    func testCommonCaliberNamesExcludeExistingEntries() {
        let viewModel = AddCaliberViewModel()
        let existing = [
            Caliber(name: "9mm"),
            Caliber(name: " .223 Rem ")
        ]

        let names = viewModel.commonCaliberNames(excluding: existing)

        XCTAssertFalse(names.contains("9mm"))
        XCTAssertFalse(names.contains(".223 Rem"))
        XCTAssertTrue(names.contains(".22 LR"))
    }

    func testUpdatedSelectedCaliberNameKeepsValidSelectionOrFallsBackAppropriately() {
        let viewModel = AddCaliberViewModel()
        let names = [".22 LR", ".308 Win", "9mm"]

        XCTAssertEqual(
            viewModel.updatedSelectedCaliberName(
                currentSelection: "__custom__",
                customOption: "__custom__",
                commonCaliberNames: names
            ),
            ".22 LR"
        )
        XCTAssertEqual(
            viewModel.updatedSelectedCaliberName(
                currentSelection: ".308 Win",
                customOption: "__custom__",
                commonCaliberNames: names
            ),
            ".308 Win"
        )
        XCTAssertEqual(
            viewModel.updatedSelectedCaliberName(
                currentSelection: ".45 ACP",
                customOption: "__custom__",
                commonCaliberNames: names
            ),
            ".22 LR"
        )
        XCTAssertEqual(
            viewModel.updatedSelectedCaliberName(
                currentSelection: "__custom__",
                customOption: "__custom__",
                commonCaliberNames: []
            ),
            "__custom__"
        )
    }

    @MainActor
    func testAddCaliberPersistsModel() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddCaliberViewModel()

        let didAdd = viewModel.addCaliber(named: ".308 Win", canAdd: true, to: context)
        let calibers = try context.fetch(FetchDescriptor<Caliber>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(calibers.count, 1)
        XCTAssertEqual(calibers.first?.name, ".308 Win")
    }

    @MainActor
    func testAddCaliberReturnsFalseWhenBlocked() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddCaliberViewModel()

        let didAdd = viewModel.addCaliber(named: ".308 Win", canAdd: false, to: context)
        let calibers = try context.fetch(FetchDescriptor<Caliber>())

        XCTAssertFalse(didAdd)
        XCTAssertTrue(calibers.isEmpty)
    }
}

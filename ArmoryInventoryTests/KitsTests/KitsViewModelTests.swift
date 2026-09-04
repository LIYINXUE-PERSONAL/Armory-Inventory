//
//  KitsViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/20/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class KitsViewModelTests: XCTestCase {
    @MainActor
    func testFilteringCountsTotalsAndComponentSummaries() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = KitsViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 100_000,
            type: .rifle,
            action: .semiAuto
        )
        let part = Part(brand: "BCM", modelName: "MK2", type: .upperReceiver, purchasePriceCents: 20_000)
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let upperKit = Kit(name: "Range Upper", kind: .upperReceiver, status: .linked, firearm: firearm)
        let opticKit = Kit(name: "Dot Package", kind: .optics)
        let partComponent = KitComponent(category: .part, part: part)
        let opticComponent = KitComponent(category: .optic, optic: optic)
        partComponent.kit = upperKit
        opticComponent.kit = opticKit
        upperKit.components = [partComponent]
        opticKit.components = [opticComponent]

        context.insert(firearm)
        context.insert(part)
        context.insert(optic)
        context.insert(upperKit)
        context.insert(opticKit)
        context.insert(partComponent)
        context.insert(opticComponent)
        try context.save()

        XCTAssertEqual(
            viewModel.filteredKits(
                [upperKit, opticKit],
                selectedKind: .upperReceiver,
                selectedStatusFilter: .all,
                searchText: ""
            ).map(\.name),
            ["Range Upper"]
        )
        XCTAssertEqual(
            viewModel.filteredKits(
                [upperKit, opticKit],
                selectedKind: nil,
                selectedStatusFilter: .all,
                searchText: "aimpoint"
            ).map(\.name),
            ["Dot Package"]
        )
        XCTAssertEqual(
            viewModel.filteredKits(
                [upperKit, opticKit],
                selectedKind: nil,
                selectedStatusFilter: .all,
                searchText: "ddm4"
            ).map(\.name),
            ["Range Upper"]
        )
        XCTAssertEqual(
            viewModel.filteredKits(
                [upperKit, opticKit],
                selectedKind: nil,
                selectedStatusFilter: .linked,
                searchText: ""
            ).map(\.name),
            ["Range Upper"]
        )
        XCTAssertEqual(
            viewModel.filteredKits(
                [upperKit, opticKit],
                selectedKind: nil,
                selectedStatusFilter: .unlinked,
                searchText: ""
            ).map(\.name),
            ["Dot Package"]
        )
        XCTAssertEqual(viewModel.countForKind(.upperReceiver, in: [upperKit, opticKit]), 1)
        XCTAssertEqual(viewModel.allKindsCountText(for: [upperKit, opticKit]), "All Kinds (2)")
        XCTAssertEqual(viewModel.filterCountText(title: "Optics Kit", count: 1), "Optics Kit (1)")
        XCTAssertEqual(viewModel.totalValueText(for: [upperKit, opticKit]), "$900.00")
        XCTAssertEqual(
            viewModel.componentSummaries(for: upperKit),
            [KitComponentSummary(title: "Parts", itemNames: "BCM MK2")]
        )
    }

    func testMultiSelectKindAndStatusFiltering() {
        let viewModel = KitsViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 100_000,
            type: .rifle,
            action: .semiAuto
        )
        let linkedUpper = Kit(name: "Range Upper", kind: .upperReceiver, firearm: firearm)
        let unlinkedOptic = Kit(name: "Dot Package", kind: .optics)
        let unlinkedLower = Kit(name: "Lower Build", kind: .lowerReceiver)

        XCTAssertEqual(
            viewModel.filteredKits(
                [linkedUpper, unlinkedOptic, unlinkedLower],
                selectedKinds: [.upperReceiver, .optics],
                selectedStatusFilters: [.linked, .unlinked],
                searchText: ""
            ).map(\.name),
            ["Range Upper", "Dot Package"]
        )
        XCTAssertEqual(
            viewModel.filteredKits(
                [linkedUpper, unlinkedOptic, unlinkedLower],
                selectedKinds: [.upperReceiver, .optics],
                selectedStatusFilters: [.unlinked],
                searchText: ""
            ).map(\.name),
            ["Dot Package"]
        )
    }

    @MainActor
    func testReorderOnlyAppliesWithinFilteredKits() {
        let viewModel = KitsViewModel()
        let first = Kit(name: "First Upper", kind: .upperReceiver, sortOrder: 0)
        let middle = Kit(name: "Middle Optic", kind: .optics, sortOrder: 1)
        let last = Kit(name: "Last Upper", kind: .upperReceiver, sortOrder: 2)
        let allKits = [first, middle, last]
        let filteredKits = viewModel.filteredKits(
            allKits,
            selectedKind: .upperReceiver,
            selectedStatusFilter: .all,
            searchText: ""
        )

        let reordered = viewModel.reorderedKits(
            allKits: allKits,
            filteredKits: filteredKits,
            selectedKind: .upperReceiver,
            selectedStatusFilter: .all,
            searchText: "",
            source: IndexSet(integer: 1),
            destination: 0
        )
        viewModel.applySortOrder(to: reordered)

        XCTAssertEqual(reordered.map(\.name), ["Last Upper", "Middle Optic", "First Upper"])
        XCTAssertEqual(last.sortOrder, 0)
        XCTAssertEqual(middle.sortOrder, 1)
        XCTAssertEqual(first.sortOrder, 2)
    }
}

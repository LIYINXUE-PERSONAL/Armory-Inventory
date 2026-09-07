//
//  FirearmsViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/20/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class FirearmsViewModelTests: XCTestCase {
    @MainActor
    func testFilteringCountsSortingAndEffectiveTotals() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = FirearmsViewModel()
        let rifleCaliber = Caliber(name: "5.56 NATO")
        let pistolCaliber = Caliber(name: "9mm")
        let rifle = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 100_000,
            type: .rifle,
            action: .semiAuto,
            caliber: rifleCaliber
        )
        let pistol = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto,
            caliber: pistolCaliber
        )
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000,
            firearm: rifle
        )
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 20_000)
        let kit = Kit(name: "Upper Kit", kind: .upperReceiver, status: .linked, firearm: rifle)
        let partComponent = KitComponent(category: .part, part: part)
        partComponent.kit = kit
        kit.components = [partComponent]
        rifle.optics = [optic]

        context.insert(rifleCaliber)
        context.insert(pistolCaliber)
        context.insert(rifle)
        context.insert(pistol)
        context.insert(optic)
        context.insert(part)
        context.insert(kit)
        context.insert(partComponent)
        try context.save()

        XCTAssertEqual(viewModel.countForType(.rifle, in: [rifle, pistol]), 1)
        XCTAssertEqual(viewModel.countForAction(.semiAuto, in: [rifle, pistol]), 2)
        XCTAssertEqual(viewModel.countForCaliber(rifleCaliber, in: [rifle, pistol]), 1)
        XCTAssertEqual(viewModel.availableCalibers(from: [rifle, pistol]).map(\.name), ["5.56 NATO", "9mm"])
        XCTAssertEqual(
            viewModel.filteredFirearms(
                [rifle, pistol],
                kits: [kit],
                magazines: [],
                selectedTypeFilter: .rifle,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .brand,
                sortDirection: .ascending
            ).map(\.displayName),
            ["Daniel Defense DDM4"]
        )
        XCTAssertEqual(
            viewModel.filteredFirearms(
                [rifle, pistol],
                kits: [kit],
                magazines: [],
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .value,
                sortDirection: .descending
            ).map(\.displayName),
            ["Daniel Defense DDM4", "Glock 19"]
        )
        XCTAssertEqual(viewModel.linkedKits(for: rifle, kits: [kit]).map(\.displayName), ["Upper Kit"])
        XCTAssertEqual(viewModel.effectiveValueCents(for: rifle, kits: [kit], magazines: []), 190_000)
        XCTAssertEqual(viewModel.totalValueText(for: [rifle, pistol], kits: [kit], magazines: []), "$2,400.00")
        XCTAssertEqual(viewModel.allTypesCountText(for: [rifle, pistol]), "All Types (2)")
        XCTAssertEqual(viewModel.allActionsCountText(for: [rifle, pistol]), "All Actions (2)")
        XCTAssertEqual(viewModel.allCalibersCountText(for: [rifle, pistol]), "All Calibers (2)")
        XCTAssertEqual(viewModel.filterCountText(title: "Rifle", count: 1), "Rifle (1)")
    }

    @MainActor
    func testSortOrdersAndDefaults() {
        let viewModel = FirearmsViewModel()
        let rifleCaliber = Caliber(name: "5.56 NATO")
        let pistolCaliber = Caliber(name: "9mm")
        let first = Firearm(
            brand: "Aero",
            modelName: "M4E1",
            purchaseDate: Date(timeIntervalSince1970: 2),
            purchasePriceCents: 90_000,
            type: .rifle,
            action: .semiAuto,
            barrelLengthInches: 16,
            caliber: rifleCaliber
        )
        let second = Firearm(
            brand: "Aero",
            modelName: "X15",
            purchaseDate: Date(timeIntervalSince1970: 1),
            purchasePriceCents: 95_000,
            type: .rifle,
            action: .bolt,
            barrelLengthInches: 20,
            caliber: rifleCaliber
        )
        let third = Firearm(
            brand: "Glock",
            modelName: "19",
            purchaseDate: Date(timeIntervalSince1970: 3),
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto,
            caliber: pistolCaliber
        )
        let firearms = [first, second, third]

        XCTAssertEqual(viewModel.selectedSortOrder(from: "bad"), .manual)
        XCTAssertEqual(viewModel.selectedSortOrder(from: FirearmSortOrder.brand.rawValue), .brand)
        XCTAssertEqual(viewModel.selectedSortDirection(from: "bad", sortOrder: .purchaseDate), .descending)
        XCTAssertEqual(viewModel.selectedSortDirection(from: FirearmSortDirection.ascending.rawValue, sortOrder: .value), .ascending)
        XCTAssertEqual(viewModel.preferredDirection(for: .manual), .ascending)
        XCTAssertEqual(viewModel.preferredDirection(for: .value), .descending)
        XCTAssertEqual(viewModel.preferredDirection(for: .type), .ascending)
        XCTAssertFalse(
            viewModel.matchesFilters(
                first,
                selectedTypeFilter: .pistol,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil
            )
        )
        XCTAssertFalse(
            viewModel.matchesFilters(
                first,
                selectedTypeFilter: nil,
                selectedActionFilter: .pump,
                selectedCaliberFilter: nil
            )
        )
        XCTAssertFalse(
            viewModel.matchesFilters(
                first,
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: pistolCaliber
            )
        )
        XCTAssertEqual(
            viewModel.filteredFirearms(
                firearms,
                kits: [],
                magazines: [],
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .purchaseDate,
                sortDirection: .ascending
            ).map(\.displayName),
            ["Aero X15", "Aero M4E1", "Glock 19"]
        )
        XCTAssertEqual(
            viewModel.filteredFirearms(
                firearms,
                kits: [],
                magazines: [],
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .barrelLength,
                sortDirection: .descending
            ).map(\.displayName),
            ["Aero X15", "Aero M4E1", "Glock 19"]
        )
        XCTAssertEqual(
            viewModel.filteredFirearms(
                firearms,
                kits: [],
                magazines: [],
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .caliber,
                sortDirection: .ascending
            ).map(\.displayName),
            ["Aero M4E1", "Aero X15", "Glock 19"]
        )
        XCTAssertEqual(
            viewModel.filteredFirearms(
                firearms,
                kits: [],
                magazines: [],
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .type,
                sortDirection: .descending
            ).map(\.displayName),
            ["Aero X15", "Aero M4E1", "Glock 19"]
        )
        XCTAssertEqual(
            viewModel.filteredFirearms(
                firearms,
                kits: [],
                magazines: [],
                selectedTypeFilter: nil,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .brand,
                sortDirection: .ascending
            ).map(\.displayName),
            ["Aero M4E1", "Aero X15", "Glock 19"]
        )
    }

    func testMultiSelectTypeActionAndCaliberFiltering() {
        let viewModel = FirearmsViewModel()
        let rifleCaliber = Caliber(name: "5.56 NATO")
        let pistolCaliber = Caliber(name: "9mm")
        let shotgunCaliber = Caliber(name: "12 Gauge")
        let rifle = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 100_000,
            type: .rifle,
            action: .semiAuto,
            caliber: rifleCaliber
        )
        let pistol = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto,
            caliber: pistolCaliber
        )
        let shotgun = Firearm(
            brand: "Mossberg",
            modelName: "590",
            purchasePriceCents: 40_000,
            type: .shotgun,
            action: .pump,
            caliber: shotgunCaliber
        )

        XCTAssertEqual(
            viewModel.filteredFirearms(
                [rifle, pistol, shotgun],
                kits: [],
                magazines: [],
                selectedTypeFilters: [.rifle, .pistol],
                selectedActionFilters: [.semiAuto],
                selectedCaliberFilters: [
                    rifleCaliber.persistentModelID,
                    pistolCaliber.persistentModelID
                ],
                sortOrder: .manual,
                sortDirection: .ascending
            ).map(\.displayName),
            ["Daniel Defense DDM4", "Glock 19"]
        )
    }

    @MainActor
    func testReorderOnlyAppliesWithinFilteredManualList() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = FirearmsViewModel()
        let first = Firearm(brand: "A", modelName: "Rifle", purchasePriceCents: 0, type: .rifle, action: .semiAuto, sortOrder: 0)
        let middle = Firearm(brand: "B", modelName: "Pistol", purchasePriceCents: 0, type: .pistol, action: .semiAuto, sortOrder: 1)
        let last = Firearm(brand: "C", modelName: "Rifle", purchasePriceCents: 0, type: .rifle, action: .bolt, sortOrder: 2)
        let firearms = [first, middle, last]
        for firearm in firearms {
            context.insert(firearm)
        }
        try context.save()
        let filtered = viewModel.filteredFirearms(
            firearms,
            kits: [],
            magazines: [],
            selectedTypeFilter: .rifle,
            selectedActionFilter: nil,
            selectedCaliberFilter: nil,
            sortOrder: .manual,
            sortDirection: .ascending
        )

        let reordered = viewModel.reorderedFirearms(
            allFirearms: firearms,
            filteredFirearms: filtered,
            selectedTypeFilter: .rifle,
            selectedActionFilter: nil,
            selectedCaliberFilter: nil,
            source: IndexSet(integer: 1),
            destination: 0
        )
        viewModel.applySortOrder(to: reordered)

        XCTAssertEqual(reordered.map(\.displayName), ["C Rifle", "B Pistol", "A Rifle"])
        XCTAssertEqual(last.sortOrder, 0)
        XCTAssertEqual(middle.sortOrder, 1)
        XCTAssertEqual(first.sortOrder, 2)
        XCTAssertEqual(
            viewModel.reorderedFirearms(
                allFirearms: firearms,
                filteredFirearms: filtered,
                selectedTypeFilter: .rifle,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                source: [],
                destination: 0
            ).map(\.displayName),
            ["A Rifle", "B Pistol", "C Rifle"]
        )
        XCTAssertTrue(
            viewModel.moveFirearms(
                allFirearms: firearms,
                filteredFirearms: filtered,
                selectedTypeFilter: .rifle,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .brand,
                source: IndexSet(integer: 1),
                destination: 0,
                in: context
            ).isValid
        )
        XCTAssertTrue(
            viewModel.moveFirearms(
                allFirearms: firearms,
                filteredFirearms: filtered,
                selectedTypeFilter: .rifle,
                selectedActionFilter: nil,
                selectedCaliberFilter: nil,
                sortOrder: .manual,
                source: IndexSet(integer: 1),
                destination: 0,
                in: context
            ).isValid
        )
    }
}

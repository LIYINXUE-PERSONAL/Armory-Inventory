//
//  AddAmmoTypeViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddAmmoTypeViewModelTests: XCTestCase {
    @MainActor
    func testValidationHandlesRifleAndShotgunInputs() {
        let viewModel = AddAmmoTypeViewModel(ammoChangeService: AmmoChangeService())

        XCTAssertTrue(
            viewModel.canAdd(
                quantityText: "100",
                centsPerRoundText: "40",
                resolvedBrand: "Federal",
                resolvedBulletType: "FMJ",
                resolvedGrain: 115,
                resolvedLoadDetail: nil,
                isShotgun: false
            )
        )

        XCTAssertFalse(
            viewModel.canAdd(
                quantityText: "25",
                centsPerRoundText: "60",
                resolvedBrand: "Federal",
                resolvedBulletType: "Buckshot",
                resolvedGrain: nil,
                resolvedLoadDetail: nil,
                isShotgun: true
            )
        )

        XCTAssertFalse(
            viewModel.canAdd(
                quantityText: "-1",
                centsPerRoundText: "60",
                resolvedBrand: "Federal",
                resolvedBulletType: "FMJ",
                resolvedGrain: 115,
                resolvedLoadDetail: nil,
                isShotgun: false
            )
        )
    }

    func testResolutionHelpersCoverCustomAndTrimmedValues() {
        let viewModel = AddAmmoTypeViewModel(ammoChangeService: AmmoChangeServiceMock())
        let shotgun = Caliber(name: "12 Gauge")
        let rifle = Caliber(name: "9mm")

        XCTAssertEqual(AddAmmoTypeViewModel.initialGrain(for: rifle), 115)
        XCTAssertTrue(viewModel.isShotgunCaliber(shotgun))
        XCTAssertEqual(viewModel.bulletTypes(for: shotgun), CommonAmmoCatalog.commonShotgunTypes)
        XCTAssertEqual(viewModel.loadDetailTitle(for: shotgun, bulletType: "Buckshot"), "Size")
        XCTAssertEqual(viewModel.loadDetailTitle(for: shotgun, bulletType: "Slug"), "Grain")
        XCTAssertEqual(viewModel.loadDetailPlaceholder(for: shotgun, bulletType: "Buckshot"), "00, 000, #1")
        XCTAssertEqual(viewModel.loadDetailPlaceholder(for: shotgun, bulletType: "Birdshot"), "#4, #6, #7.5")
        XCTAssertEqual(viewModel.loadDetailPlaceholder(for: shotgun, bulletType: "Custom"), "Detail")
        XCTAssertEqual(viewModel.resolvedBrand(selectedBrand: "PMC", customBrand: "  AAC  ", isCustomBrand: true), "AAC")
        XCTAssertEqual(viewModel.resolvedProductName("  HST  "), "HST")
        XCTAssertNil(viewModel.resolvedProductName("   "))
        XCTAssertEqual(
            viewModel.resolvedBulletType(
                selectedBulletType: "FMJ",
                customBulletType: "  Soft Point  ",
                isCustomBulletType: true
            ),
            "Soft Point"
        )
        XCTAssertEqual(viewModel.resolvedLoadDetail(for: shotgun, bulletType: "Buckshot", loadDetailText: " 00 "), "00")
        XCTAssertNil(viewModel.resolvedLoadDetail(for: rifle, bulletType: "FMJ", loadDetailText: "115"))
        XCTAssertEqual(viewModel.resolvedGrain(grainRange: 100...120, selectedGrainValue: 115, customGrainText: "90"), 115)
        XCTAssertEqual(viewModel.resolvedGrain(grainRange: nil, selectedGrainValue: 0, customGrainText: "90"), 90)
    }

    @MainActor
    func testAddAmmoPersistsModelAndRecordsInitialPurchase() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        context.insert(caliber)

        let service = AmmoChangeServiceMock()
        let viewModel = AddAmmoTypeViewModel(ammoChangeService: service)

        let didAdd = viewModel.addAmmo(
            caliber: caliber,
            resolvedBrand: "Federal",
            resolvedProductName: "HST",
            resolvedBulletType: "JHP",
            resolvedGrain: 124,
            resolvedLoadDetail: nil,
            quantityText: "50",
            centsPerRoundText: "80",
            to: context
        )

        let ammo = try context.fetch(FetchDescriptor<AmmoType>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(ammo.count, 1)
        XCTAssertEqual(ammo.first?.brand, "Federal")
        XCTAssertEqual(ammo.first?.quantity, 50)
        XCTAssertEqual(service.recordedInitialPurchase?.quantity, 50)
        XCTAssertEqual(service.recordedInitialPurchase?.ammo.brand, "Federal")
    }

    @MainActor
    func testAddAmmoReturnsFalseForInvalidRifleGrain() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        context.insert(caliber)

        let viewModel = AddAmmoTypeViewModel(ammoChangeService: AmmoChangeServiceMock())
        let didAdd = viewModel.addAmmo(
            caliber: caliber,
            resolvedBrand: "Federal",
            resolvedProductName: nil,
            resolvedBulletType: "FMJ",
            resolvedGrain: nil,
            resolvedLoadDetail: nil,
            quantityText: "50",
            centsPerRoundText: "30",
            to: context
        )

        XCTAssertFalse(didAdd)
    }

    @MainActor
    func testUpdateAmmoPersistsDetailsWithoutChangingQuantityOrRecordingPurchase() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            productName: "Old Product",
            bulletType: "FMJ",
            grain: 115,
            quantity: 50,
            centsPerRound: 30,
            caliber: caliber
        )
        context.insert(caliber)
        context.insert(ammo)

        let service = AmmoChangeServiceMock()
        let viewModel = AddAmmoTypeViewModel(ammoChangeService: service)
        let didUpdate = viewModel.updateAmmo(
            ammo,
            caliber: caliber,
            resolvedBrand: "Federal",
            resolvedProductName: "HST",
            resolvedBulletType: "JHP",
            resolvedGrain: 124,
            resolvedLoadDetail: nil,
            centsPerRoundText: "85",
            in: context
        )

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(ammo.productName, "HST")
        XCTAssertEqual(ammo.bulletType, "JHP")
        XCTAssertEqual(ammo.grain, 124)
        XCTAssertEqual(ammo.centsPerRound, 85)
        XCTAssertEqual(ammo.quantity, 50)
        XCTAssertNil(service.recordedInitialPurchase)
    }
}

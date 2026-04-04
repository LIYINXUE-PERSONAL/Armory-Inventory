//
//  AddOpticViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddOpticViewModelTests: XCTestCase {
    func testResolutionAndValidationHandleTrimmedAndInvalidValues() {
        let viewModel = AddOpticViewModel()
        let existing = [
            Optic(
                brand: "Aimpoint",
                modelName: "T-2",
                type: .redDot,
                serialNumber: "AB123",
                minMagnification: 1,
                maxMagnification: 1,
                footprint: .picatinny,
                purchasePriceCents: 80000
            )
        ]

        XCTAssertEqual(viewModel.initialPurchasePriceText(for: nil), "0.00")
        XCTAssertEqual(viewModel.formattedNumericInput(3), "3")
        XCTAssertEqual(viewModel.formattedNumericInput(3.5), "3.5")
        XCTAssertEqual(viewModel.trimmedValue("  LPVO "), "LPVO")
        XCTAssertEqual(viewModel.optionalValue("  ACSS  "), "ACSS")
        XCTAssertNil(viewModel.optionalValue("   "))
        XCTAssertEqual(viewModel.normalizedSerialNumber(" ab-12 cd_34 "), "AB12CD34")
        XCTAssertNil(viewModel.optionalSerialNumber(" - _ "))
        XCTAssertEqual(viewModel.purchasePriceCents(from: " 1299.95 "), 129995)
        XCTAssertNil(viewModel.purchasePriceCents(from: "bad"))
        XCTAssertEqual(viewModel.magnificationValue(from: " 1.5 "), 1.5)
        XCTAssertNil(viewModel.magnificationValue(from: "0"))
        XCTAssertEqual(viewModel.tubeSizeMillimeters(from: " 30 "), 30)
        XCTAssertNil(viewModel.tubeSizeMillimeters(from: "-1"))
        XCTAssertNil(viewModel.resolvedColorDetail(selectedColor: .black, customColor: "Ignored"))
        XCTAssertEqual(viewModel.resolvedColorDetail(selectedColor: .other, customColor: "  FDE  "), "FDE")
        XCTAssertNil(viewModel.resolvedFootprintDetail(selectedFootprint: .rmr, customFootprint: "Ignored"))
        XCTAssertEqual(
            viewModel.resolvedFootprintDetail(selectedFootprint: .other, customFootprint: "  MOS Plate  "),
            "MOS Plate"
        )
        XCTAssertNil(viewModel.resolvedFocalPlane(isFixedMagnification: true, focalPlane: .first))
        XCTAssertEqual(viewModel.resolvedFocalPlane(isFixedMagnification: false, focalPlane: .second), .second)
        XCTAssertEqual(
            viewModel.updatedFootprintSelection(
                selectedType: .scope,
                selectedFootprint: .other,
                customFootprint: "Custom"
            ).footprint,
            .picatinny
        )
        XCTAssertEqual(
            viewModel.updatedFootprintSelection(
                selectedType: .scope,
                selectedFootprint: .other,
                customFootprint: "Custom"
            ).customFootprint,
            ""
        )
        XCTAssertEqual(viewModel.resolvedMagnification(isFixed: true, fixedText: "3", minText: "", maxText: "")?.min, 3)
        XCTAssertEqual(viewModel.resolvedMagnification(isFixed: false, fixedText: "", minText: "1", maxText: "6")?.max, 6)
        XCTAssertNil(viewModel.resolvedMagnification(isFixed: false, fixedText: "", minText: "6", maxText: "1"))
        XCTAssertTrue(viewModel.duplicateExists(serialNumber: " ab123 ", excluding: nil, in: existing))
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Vortex",
                modelName: "Razor",
                purchasePriceText: "bad",
                tubeSizeText: "",
                selectedType: .lpvo,
                selectedFootprint: .picatinny,
                footprintDetail: nil,
                isFixedMagnification: false,
                fixedMagnificationText: "",
                minMagnificationText: "1",
                maxMagnificationText: "6",
                focalPlane: .first,
                selectedColor: nil,
                colorDetail: nil,
                duplicateExists: false
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Vortex",
                modelName: "Razor",
                purchasePriceText: "1000",
                tubeSizeText: "",
                selectedType: .lpvo,
                selectedFootprint: .other,
                footprintDetail: nil,
                isFixedMagnification: false,
                fixedMagnificationText: "",
                minMagnificationText: "1",
                maxMagnificationText: "6",
                focalPlane: .first,
                selectedColor: nil,
                colorDetail: nil,
                duplicateExists: false
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Vortex",
                modelName: "Razor",
                purchasePriceText: "1000",
                tubeSizeText: "",
                selectedType: .lpvo,
                selectedFootprint: .picatinny,
                footprintDetail: nil,
                isFixedMagnification: false,
                fixedMagnificationText: "",
                minMagnificationText: "1",
                maxMagnificationText: "6",
                focalPlane: nil,
                selectedColor: nil,
                colorDetail: nil,
                duplicateExists: false
            )
        )
        XCTAssertTrue(
            viewModel.canAdd(
                brand: "Vortex",
                modelName: "Razor",
                purchasePriceText: "1000",
                tubeSizeText: "30",
                selectedType: .lpvo,
                selectedFootprint: .picatinny,
                footprintDetail: nil,
                isFixedMagnification: false,
                fixedMagnificationText: "",
                minMagnificationText: "1",
                maxMagnificationText: "6",
                focalPlane: .first,
                selectedColor: .black,
                colorDetail: nil,
                duplicateExists: false
            )
        )
        XCTAssertNil(viewModel.linkedFirearm(for: nil, unlinkFirearm: false))
        XCTAssertTrue(viewModel.showsFocalPlane(isFixedMagnification: false))
        XCTAssertFalse(viewModel.showsFocalPlane(isFixedMagnification: true))
        XCTAssertEqual(viewModel.purchasePriceWithTaxText(purchasePriceCents: nil, taxRate: 8.25), "--")
        XCTAssertTrue(viewModel.isReadOnly(hasOptic: true, isEditing: false))
        XCTAssertFalse(viewModel.showsPurchaseSection(showValueInDetails: false, isReadOnly: true))
        XCTAssertEqual(viewModel.primaryButtonTitle(hasOptic: true, isEditing: true), "Save")
    }

    @MainActor
    func testAddOpticPersistsModel() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddOpticViewModel()
        let purchaseDate = Date(timeIntervalSince1970: 1_234_567)
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto
        )
        context.insert(firearm)

        let didAdd = viewModel.addOptic(
            brand: "  EOTech ",
            modelName: " EXPS3 ",
            type: .holographic,
            serialNumber: " eo-123 ",
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            footprintDetail: nil,
            tubeSizeMillimeters: nil,
            reticle: "Ring",
            focalPlane: nil,
            isIlluminated: true,
            color: .black,
            colorDetail: nil,
            purchaseDate: purchaseDate,
            purchasePriceCents: 69999,
            notes: "Night vision compatible",
            firearm: firearm,
            canAdd: true,
            to: context
        )

        let optics = try context.fetch(FetchDescriptor<Optic>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(optics.count, 1)
        XCTAssertEqual(optics.first?.brand, "EOTech")
        XCTAssertEqual(optics.first?.modelName, "EXPS3")
        XCTAssertEqual(optics.first?.serialNumber, "EO123")
        XCTAssertEqual(optics.first?.opticType, .holographic)
        XCTAssertEqual(optics.first?.firearm?.displayName, "Daniel Defense DDM4")
        XCTAssertEqual(optics.first?.purchaseDate, purchaseDate)
        XCTAssertEqual(optics.first?.sortOrder, 0)
    }

    @MainActor
    func testAddOpticReturnsFalseWhenBlocked() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddOpticViewModel()

        let didAdd = viewModel.addOptic(
            brand: "Aimpoint",
            modelName: "Acro",
            type: .redDot,
            serialNumber: "",
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .acro,
            footprintDetail: nil,
            tubeSizeMillimeters: nil,
            reticle: nil,
            focalPlane: nil,
            isIlluminated: true,
            color: nil,
            colorDetail: nil,
            purchaseDate: .now,
            purchasePriceCents: 50000,
            notes: nil,
            firearm: nil,
            canAdd: false,
            to: context
        )

        XCTAssertFalse(didAdd)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Optic>()).isEmpty)
    }

    @MainActor
    func testUpdateOpticPersistsEditedValues() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let originalFirearm = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto
        )
        let updatedFirearm = Firearm(
            brand: "Staccato",
            modelName: "P",
            purchasePriceCents: 220000,
            type: .pistol,
            action: .semiAuto
        )
        let optic = Optic(
            brand: "Holosun",
            modelName: "507C",
            type: .redDot,
            serialNumber: "HS123",
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .rmr,
            purchasePriceCents: 31000,
            firearm: originalFirearm
        )
        context.insert(originalFirearm)
        context.insert(updatedFirearm)
        context.insert(optic)

        let viewModel = AddOpticViewModel()
        let didSave = viewModel.updateOptic(
            optic,
            brand: "  Vortex ",
            modelName: " Razor HD ",
            type: .lpvo,
            serialNumber: " vr-456 ",
            minMagnification: 1,
            maxMagnification: 6,
            footprint: .picatinny,
            footprintDetail: nil,
            tubeSizeMillimeters: 30,
            reticle: "JM-1",
            focalPlane: .first,
            isIlluminated: true,
            color: .other,
            colorDetail: "OD Green",
            purchaseDate: Date(timeIntervalSince1970: 9_999),
            purchasePriceCents: 129999,
            notes: "Updated",
            firearm: updatedFirearm,
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(optic.brand, "Vortex")
        XCTAssertEqual(optic.modelName, "Razor HD")
        XCTAssertEqual(optic.serialNumber, "VR456")
        XCTAssertEqual(optic.opticType, .lpvo)
        XCTAssertEqual(optic.maxMagnification, 6)
        XCTAssertEqual(optic.opticFocalPlane, .first)
        XCTAssertEqual(optic.opticColor, .other)
        XCTAssertEqual(optic.colorDetail, "OD Green")
        XCTAssertEqual(optic.firearm?.displayName, "Staccato P")
        XCTAssertEqual(optic.notes, "Updated")
    }
}

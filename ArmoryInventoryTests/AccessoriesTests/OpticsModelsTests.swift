//
//  OpticsModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class OpticsModelsTests: XCTestCase {
    func testOpticTypeDisplayNamesAndDefaultFootprints() {
        XCTAssertEqual(OpticType.redDot.displayName, "Red Dot")
        XCTAssertEqual(OpticType.holographic.displayName, "Holographic")
        XCTAssertEqual(OpticType.prism.displayName, "Prism")
        XCTAssertEqual(OpticType.lpvo.displayName, "LPVO")
        XCTAssertEqual(OpticType.scope.displayName, "Scope")
        XCTAssertEqual(OpticType.magnifier.displayName, "Magnifier")
        XCTAssertEqual(OpticType.other.displayName, "Other")

        XCTAssertNil(OpticType.redDot.defaultFootprint)
        XCTAssertEqual(OpticType.lpvo.defaultFootprint, .picatinny)
        XCTAssertEqual(OpticType.scope.defaultFootprint, .picatinny)
    }

    func testOpticFootprintAndFocalPlaneDisplayNames() {
        XCTAssertEqual(OpticFootprint.picatinny.displayName, "Picatinny")
        XCTAssertEqual(OpticFootprint.weaver.displayName, "Weaver")
        XCTAssertEqual(OpticFootprint.rmr.displayName, "RMR")
        XCTAssertEqual(OpticFootprint.rmsc.displayName, "RMSc")
        XCTAssertEqual(OpticFootprint.doctor.displayName, "Docter/Noblex")
        XCTAssertEqual(OpticFootprint.deltaPointPro.displayName, "DeltaPoint Pro")
        XCTAssertEqual(OpticFootprint.aimpointMicro.displayName, "Aimpoint Micro")
        XCTAssertEqual(OpticFootprint.acro.displayName, "ACRO")
        XCTAssertEqual(OpticFootprint.cMore.displayName, "C-More RTS/STS")
        XCTAssertEqual(OpticFootprint.other.displayName, "Other")

        XCTAssertEqual(OpticFocalPlane.first.displayName, "FFP")
        XCTAssertEqual(OpticFocalPlane.second.displayName, "SFP")
    }

    func testOpticComputedPropertiesPreferStoredDetails() {
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto
        )
        let optic = Optic(
            brand: "Vortex",
            modelName: "Razor HD",
            type: .lpvo,
            serialNumber: "VR123",
            minMagnification: 1,
            maxMagnification: 6,
            footprint: .other,
            footprintDetail: "Spuhr Mount",
            tubeSizeMillimeters: 30,
            reticle: "JM-1",
            focalPlane: .first,
            isIlluminated: true,
            color: .other,
            colorDetail: "OD Green",
            purchasePriceCents: 129999,
            firearm: firearm
        )

        XCTAssertEqual(optic.opticType, .lpvo)
        XCTAssertEqual(optic.opticFocalPlane, .first)
        XCTAssertEqual(optic.opticFootprint, .other)
        XCTAssertEqual(optic.footprintDisplayName, "Spuhr Mount")
        XCTAssertEqual(optic.opticColor, .other)
        XCTAssertEqual(optic.colorDisplayName, "OD Green")
        XCTAssertEqual(optic.displayName, "Vortex Razor HD")
        XCTAssertEqual(optic.typeDisplayName, "LPVO")
        XCTAssertEqual(optic.magnificationText, "1-6x")
        XCTAssertEqual(optic.tubeSizeText, "30 mm")
        XCTAssertTrue(optic.purchasePriceText.contains("1,299"))
        XCTAssertTrue(optic.firearm === firearm)
    }

    func testOpticComputedPropertiesFallbackForInvalidStoredValues() {
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            serialNumber: "T2001",
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 80000
        )
        optic.type = "invalid-type"
        optic.focalPlane = "invalid-focal-plane"
        optic.footprint = "invalid-footprint"
        optic.color = "invalid-color"
        optic.footprintDetail = nil
        optic.colorDetail = nil

        XCTAssertEqual(optic.opticType, .other)
        XCTAssertNil(optic.opticFocalPlane)
        XCTAssertEqual(optic.opticFootprint, .other)
        XCTAssertEqual(optic.footprintDisplayName, "Other")
        XCTAssertEqual(optic.opticColor, .other)
        XCTAssertEqual(optic.colorDisplayName, "Other")
        XCTAssertEqual(optic.typeDisplayName, "Other")
        XCTAssertEqual(optic.magnificationText, "1x")
        XCTAssertNil(optic.tubeSizeText)

        optic.color = nil

        XCTAssertNil(optic.opticColor)
        XCTAssertNil(optic.colorDisplayName)
    }
}

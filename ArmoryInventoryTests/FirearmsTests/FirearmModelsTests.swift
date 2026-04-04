//
//  FirearmModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class FirearmModelsTests: XCTestCase {
    func testFirearmTypeActionAndColorDisplayNames() {
        XCTAssertEqual(FirearmType.rifle.displayName, "Rifle")
        XCTAssertEqual(FirearmType.pistol.displayName, "Pistol")
        XCTAssertEqual(FirearmType.shotgun.displayName, "Shotgun")
        XCTAssertEqual(FirearmType.other.displayName, "Other")

        XCTAssertEqual(FirearmAction.semiAuto.displayName, "Semi-Auto")
        XCTAssertEqual(FirearmAction.selectFire.displayName, "Select-Fire")
        XCTAssertEqual(FirearmAction.bolt.displayName, "Bolt Action")
        XCTAssertEqual(FirearmAction.pump.displayName, "Pump Action")
        XCTAssertEqual(FirearmAction.lever.displayName, "Lever Action")
        XCTAssertEqual(FirearmAction.breakAction.displayName, "Break Action")
        XCTAssertEqual(FirearmAction.singleShot.displayName, "Single Shot")
        XCTAssertEqual(FirearmAction.revolver.displayName, "Revolver")
        XCTAssertEqual(FirearmAction.other.displayName, "Other")

        XCTAssertEqual(FirearmColor.black.displayName, "Black")
        XCTAssertEqual(FirearmColor.flatDarkEarth.displayName, "Flat Dark Earth")
        XCTAssertEqual(FirearmColor.odGreen.displayName, "OD Green")
        XCTAssertEqual(FirearmColor.gray.displayName, "Gray")
        XCTAssertEqual(FirearmColor.silver.displayName, "Silver")
        XCTAssertEqual(FirearmColor.stainless.displayName, "Stainless")
        XCTAssertEqual(FirearmColor.fdeCamo.displayName, "Camo")
        XCTAssertEqual(FirearmColor.bronze.displayName, "Bronze")
        XCTAssertEqual(FirearmColor.tan.displayName, "Tan")
        XCTAssertEqual(FirearmColor.white.displayName, "White")
        XCTAssertEqual(FirearmColor.other.displayName, "Other")
    }

    func testFirearmComputedPropertiesPreferStoredDetails() {
        let caliber = Caliber(name: "9mm")
        let ammoOne = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 150,
            centsPerRound: 30,
            caliber: caliber
        )
        let ammoTwo = AmmoType(
            brand: "Speer",
            bulletType: "JHP",
            grain: 124,
            quantity: 50,
            centsPerRound: 60,
            caliber: caliber
        )
        caliber.ammoTypes = [ammoOne, ammoTwo]

        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 80000
        )
        let magazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            count: 3,
            capacity: 17,
            purchasePriceCents: 7500
        )
        let attachment = Attachment(
            brand: "SureFire",
            modelName: "X300",
            type: .light,
            purchasePriceCents: 28000
        )
        let firearm = Firearm(
            brand: "Staccato",
            modelName: "P",
            nickname: "Duty",
            serialNumber: "ABC123",
            purchasePriceCents: 250000,
            type: .other,
            action: .other,
            actionDetail: "DA/SA",
            color: .other,
            colorDetail: "Two Tone",
            barrelLengthInches: 4.4,
            caliber: caliber,
            optics: [optic],
            magazines: [magazine],
            attachments: [attachment]
        )

        XCTAssertEqual(firearm.firearmType, .other)
        XCTAssertEqual(firearm.displayName, "Staccato P")
        XCTAssertEqual(firearm.firearmAction, .other)
        XCTAssertEqual(firearm.actionDisplayName, "DA/SA")
        XCTAssertEqual(firearm.firearmColor, .other)
        XCTAssertEqual(firearm.colorDisplayName, "Two Tone")
        XCTAssertEqual(firearm.subtitle, "\"Duty\"")
        XCTAssertEqual(firearm.roundsText, "200 Rounds")
        XCTAssertEqual(firearm.barrelLengthText, "4.4 in")
        XCTAssertTrue(firearm.purchasePriceText.contains("2,500"))
        XCTAssertEqual(firearm.totalCardValueCents, 365500)
        XCTAssertTrue(firearm.totalCardValueText.contains("3,655"))
    }

    func testFirearmComputedPropertiesFallbackForInvalidStoredValues() {
        let caliber = Caliber(name: ".223")
        let ammo = AmmoType(
            brand: "PMC",
            bulletType: "FMJ",
            grain: 55,
            quantity: -10,
            centsPerRound: 40,
            caliber: caliber
        )
        caliber.ammoTypes = [ammo]

        let optic = Optic(
            brand: "Holosun",
            modelName: "503",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: -100
        )
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            count: 1,
            capacity: 30,
            purchasePriceCents: -200
        )
        let attachment = Attachment(
            brand: "BCM",
            modelName: "KAG",
            type: .handStop,
            purchasePriceCents: -300
        )
        let firearm = Firearm(
            brand: "Colt",
            modelName: "6920",
            purchasePriceCents: -400,
            type: .rifle,
            action: .semiAuto,
            caliber: caliber,
            optics: [optic],
            magazines: [magazine],
            attachments: [attachment]
        )
        firearm.type = "invalid-type"
        firearm.action = "invalid-action"
        firearm.color = "invalid-color"
        firearm.actionDetail = nil
        firearm.colorDetail = nil
        firearm.nickname = nil
        firearm.barrelLengthInches = nil

        XCTAssertEqual(firearm.firearmType, .other)
        XCTAssertEqual(firearm.firearmAction, .other)
        XCTAssertEqual(firearm.actionDisplayName, "Other")
        XCTAssertEqual(firearm.firearmColor, .other)
        XCTAssertEqual(firearm.colorDisplayName, "Other")
        XCTAssertEqual(firearm.subtitle, "Other")
        XCTAssertEqual(firearm.roundsText, "0 Rounds")
        XCTAssertNil(firearm.barrelLengthText)
        XCTAssertEqual(firearm.totalCardValueCents, 0)
        XCTAssertTrue(firearm.totalCardValueText.contains("0.00"))

        firearm.color = nil
        firearm.caliber = nil

        XCTAssertNil(firearm.firearmColor)
        XCTAssertNil(firearm.colorDisplayName)
        XCTAssertNil(firearm.roundsText)
    }
}

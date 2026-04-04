//
//  AttachmentModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class AttachmentModelsTests: XCTestCase {
    func testAttachmentTypeDisplayNamesCoverKnownAndOtherCases() {
        XCTAssertEqual(AttachmentType.stock.displayName, "Stock")
        XCTAssertEqual(AttachmentType.handStop.displayName, "Hand Stop")
        XCTAssertEqual(AttachmentType.muzzleDevice.displayName, "Muzzle Device")
        XCTAssertEqual(AttachmentType.other.displayName, "Other")
    }

    func testAttachmentComputedPropertiesPreferCustomDetailsAndFallbacks() {
        let firearm = Firearm(
            brand: "BCM",
            modelName: "Recce",
            purchasePriceCents: 160000,
            type: .rifle,
            action: .semiAuto
        )
        let attachment = Attachment(
            brand: "SureFire",
            modelName: "M640DF",
            type: .other,
            typeDetail: "Light",
            color: .other,
            colorDetail: "Burnt Bronze",
            purchasePriceCents: 32999,
            firearm: firearm
        )

        XCTAssertEqual(attachment.attachmentType, .other)
        XCTAssertEqual(attachment.typeDisplayName, "Light")
        XCTAssertEqual(attachment.displayName, "SureFire M640DF")
        XCTAssertEqual(attachment.attachmentColor, .other)
        XCTAssertEqual(attachment.colorDisplayName, "Burnt Bronze")
        XCTAssertTrue(attachment.purchasePriceText.contains("329"))
        XCTAssertTrue(attachment.firearm === firearm)
    }

    func testAttachmentComputedPropertiesFallbackWhenStoredValuesAreInvalidOrMissing() {
        let attachment = Attachment(
            brand: "BCM",
            modelName: "KAG",
            type: .grip,
            purchasePriceCents: 2000
        )
        attachment.type = "not-a-real-type"
        attachment.color = "not-a-real-color"
        attachment.colorDetail = nil

        XCTAssertEqual(attachment.attachmentType, .other)
        XCTAssertEqual(attachment.typeDisplayName, "Other")
        XCTAssertEqual(attachment.attachmentColor, .other)
        XCTAssertEqual(attachment.colorDisplayName, "Other")

        attachment.color = nil

        XCTAssertNil(attachment.attachmentColor)
        XCTAssertNil(attachment.colorDisplayName)
    }
}

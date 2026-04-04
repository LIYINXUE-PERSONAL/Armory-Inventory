//
//  AddAttachmentViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddAttachmentViewModelTests: XCTestCase {
    func testResolutionAndValidationHandleTrimmedAndInvalidValues() {
        let viewModel = AddAttachmentViewModel()

        XCTAssertEqual(viewModel.initialPurchasePriceText(for: nil), "0.00")
        XCTAssertEqual(viewModel.trimmedValue("  SureFire "), "SureFire")
        XCTAssertEqual(viewModel.optionalValue("  Scout  "), "Scout")
        XCTAssertNil(viewModel.optionalValue(" "))
        XCTAssertEqual(viewModel.purchasePriceCents(from: " 279.99 "), 27999)
        XCTAssertNil(viewModel.purchasePriceCents(from: "bad"))
        XCTAssertNil(viewModel.resolvedTypeDetail(selectedType: .light, customType: "Ignored"))
        XCTAssertEqual(viewModel.resolvedTypeDetail(selectedType: .other, customType: "  Handguard Wrap  "), "Handguard Wrap")
        XCTAssertNil(viewModel.resolvedColorDetail(selectedColor: .black, customColor: "Ignored"))
        XCTAssertEqual(viewModel.resolvedColorDetail(selectedColor: .other, customColor: "  Burnt Bronze  "), "Burnt Bronze")
        XCTAssertNil(viewModel.linkedFirearm(for: nil, unlinkFirearm: false))
        XCTAssertEqual(viewModel.purchasePriceWithTaxText(purchasePriceCents: nil, taxRate: 6), "--")
        XCTAssertTrue(viewModel.isReadOnly(hasAttachment: true, isEditing: false))
        XCTAssertFalse(viewModel.showsPurchaseSection(showValueInDetails: false, isReadOnly: true))
        XCTAssertEqual(viewModel.primaryButtonTitle(hasAttachment: true, isEditing: false), "Edit")
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "SureFire",
                modelName: "Scout",
                selectedType: .other,
                typeDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "100"
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "SureFire",
                modelName: "Scout",
                selectedType: .light,
                typeDetail: nil,
                selectedColor: .other,
                colorDetail: nil,
                purchasePriceText: "100"
            )
        )
        XCTAssertTrue(
            viewModel.canAdd(
                brand: "SureFire",
                modelName: "Scout",
                selectedType: .light,
                typeDetail: nil,
                selectedColor: .black,
                colorDetail: nil,
                purchasePriceText: "100"
            )
        )
    }

    @MainActor
    func testAddAttachmentPersistsModel() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddAttachmentViewModel()
        let purchaseDate = Date(timeIntervalSince1970: 1_234_567)
        let firearm = Firearm(
            brand: "BCM",
            modelName: "Recce",
            purchasePriceCents: 160000,
            type: .rifle,
            action: .semiAuto
        )
        context.insert(firearm)

        let didAdd = viewModel.addAttachment(
            brand: "  SureFire ",
            modelName: " M640DF ",
            type: .light,
            typeDetail: nil,
            color: .black,
            colorDetail: nil,
            purchaseDate: purchaseDate,
            purchasePriceCents: 32999,
            notes: "Weapon light",
            firearm: firearm,
            canAdd: true,
            to: context
        )

        let attachments = try context.fetch(FetchDescriptor<Attachment>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(attachments.count, 1)
        XCTAssertEqual(attachments.first?.brand, "SureFire")
        XCTAssertEqual(attachments.first?.modelName, "M640DF")
        XCTAssertEqual(attachments.first?.attachmentType, .light)
        XCTAssertEqual(attachments.first?.firearm?.displayName, "BCM Recce")
        XCTAssertEqual(attachments.first?.purchaseDate, purchaseDate)
        XCTAssertEqual(attachments.first?.sortOrder, 0)
    }

    @MainActor
    func testAddAttachmentReturnsFalseWhenBlocked() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddAttachmentViewModel()

        let didAdd = viewModel.addAttachment(
            brand: "BCM",
            modelName: "KAG",
            type: .handStop,
            typeDetail: nil,
            color: nil,
            colorDetail: nil,
            purchaseDate: .now,
            purchasePriceCents: 2000,
            notes: nil,
            firearm: nil,
            canAdd: false,
            to: context
        )

        XCTAssertFalse(didAdd)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Attachment>()).isEmpty)
    }

    @MainActor
    func testUpdateAttachmentPersistsEditedValues() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let originalFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "MK18",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto
        )
        let updatedFirearm = Firearm(
            brand: "LMT",
            modelName: "MARS-L",
            purchasePriceCents: 250000,
            type: .rifle,
            action: .semiAuto
        )
        let attachment = Attachment(
            brand: "BCM",
            modelName: "KAG",
            type: .handStop,
            purchasePriceCents: 2000,
            firearm: originalFirearm
        )
        context.insert(originalFirearm)
        context.insert(updatedFirearm)
        context.insert(attachment)

        let viewModel = AddAttachmentViewModel()
        let didSave = viewModel.updateAttachment(
            attachment,
            brand: "  Magpul ",
            modelName: " CTR ",
            type: .other,
            typeDetail: "Stock",
            color: .other,
            colorDetail: "Foliage Green",
            purchaseDate: Date(timeIntervalSince1970: 9_999),
            purchasePriceCents: 6499,
            notes: "Updated",
            firearm: updatedFirearm,
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(attachment.brand, "Magpul")
        XCTAssertEqual(attachment.modelName, "CTR")
        XCTAssertEqual(attachment.attachmentType, .other)
        XCTAssertEqual(attachment.typeDetail, "Stock")
        XCTAssertEqual(attachment.attachmentColor, .other)
        XCTAssertEqual(attachment.colorDetail, "Foliage Green")
        XCTAssertEqual(attachment.firearm?.displayName, "LMT MARS-L")
        XCTAssertEqual(attachment.notes, "Updated")
    }
}

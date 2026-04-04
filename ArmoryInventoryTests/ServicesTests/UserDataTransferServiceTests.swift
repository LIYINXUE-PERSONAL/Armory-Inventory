//
//  UserDataTransferServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class UserDataTransferServiceTests: XCTestCase {
    @MainActor
    func testExportAndImportRoundTripsInventoryAndManagedSettings() throws {
        let sourceContainer = try makeInMemoryContainer()
        let sourceContext = sourceContainer.mainContext
        let defaults = makeUserDefaults()
        seedManagedSettings(in: defaults)

        let caliber = Caliber(name: "9mm")
        let firearmID = UUID()
        let firearm = Firearm(
            id: firearmID,
            brand: "Glock",
            modelName: "19",
            nickname: "Carry",
            serialNumber: "ABC123",
            purchaseDate: Date(timeIntervalSince1970: 1_000),
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto,
            color: .black,
            notes: "Primary",
            caliber: caliber,
            sortOrder: 3,
            createdAt: Date(timeIntervalSince1970: 2_000)
        )
        let ammo = AmmoType(
            brand: "Federal",
            productName: "HST",
            bulletType: "JHP",
            grain: 124,
            loadDetail: "P",
            quantity: 250,
            centsPerRound: 65,
            caliber: caliber
        )
        let optic = Optic(
            id: UUID(),
            brand: "Holosun",
            modelName: "507C",
            type: .redDot,
            serialNumber: "OPT123",
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .rmr,
            reticle: "Circle Dot",
            isIlluminated: true,
            color: .black,
            purchaseDate: Date(timeIntervalSince1970: 3_000),
            purchasePriceCents: 31_000,
            firearm: firearm,
            sortOrder: 1,
            createdAt: Date(timeIntervalSince1970: 4_000)
        )
        let magazine = Magazine(
            id: UUID(),
            brand: "Magpul",
            modelName: "PMAG",
            count: 5,
            capacity: 17,
            purchaseDate: Date(timeIntervalSince1970: 5_000),
            purchasePriceCents: 7_500,
            notes: "Range set",
            caliber: caliber,
            firearm: firearm,
            sortOrder: 2,
            createdAt: Date(timeIntervalSince1970: 6_000)
        )
        let attachment = Attachment(
            id: UUID(),
            brand: "SureFire",
            modelName: "X300",
            type: .light,
            purchaseDate: Date(timeIntervalSince1970: 7_000),
            purchasePriceCents: 29_000,
            firearm: firearm,
            sortOrder: 4,
            createdAt: Date(timeIntervalSince1970: 8_000)
        )
        let record = AmmoAdjustmentRecord(
            quantity: 50,
            occurredAt: Date(timeIntervalSince1970: 9_000),
            kind: .purchase,
            caliber: caliber,
            ammoType: ammo
        )

        sourceContext.insert(caliber)
        sourceContext.insert(firearm)
        sourceContext.insert(ammo)
        sourceContext.insert(optic)
        sourceContext.insert(magazine)
        sourceContext.insert(attachment)
        sourceContext.insert(record)
        try sourceContext.save()

        let service = UserDataTransferService(userDefaults: defaults)
        let data = try service.exportData(from: sourceContext)

        let destinationContainer = try makeInMemoryContainer()
        let destinationContext = destinationContainer.mainContext
        let destinationDefaults = makeUserDefaults()
        destinationDefaults.set(false, forKey: InventorySettingsKeys.showValueInCard)

        let importService = UserDataTransferService(userDefaults: destinationDefaults)
        try importService.importData(data, into: destinationContext)

        let importedFirearms = try destinationContext.fetch(FetchDescriptor<Firearm>())
        let importedAmmoTypes = try destinationContext.fetch(FetchDescriptor<AmmoType>())
        let importedOptics = try destinationContext.fetch(FetchDescriptor<Optic>())
        let importedMagazines = try destinationContext.fetch(FetchDescriptor<Magazine>())
        let importedAttachments = try destinationContext.fetch(FetchDescriptor<Attachment>())
        let importedRecords = try destinationContext.fetch(FetchDescriptor<AmmoAdjustmentRecord>())

        XCTAssertEqual(importedFirearms.count, 1)
        XCTAssertEqual(importedAmmoTypes.count, 1)
        XCTAssertEqual(importedOptics.count, 1)
        XCTAssertEqual(importedMagazines.count, 1)
        XCTAssertEqual(importedAttachments.count, 1)
        XCTAssertEqual(importedRecords.count, 1)
        XCTAssertEqual(importedFirearms.first?.id, firearmID)
        XCTAssertEqual(importedFirearms.first?.caliber?.name, "9mm")
        XCTAssertEqual(importedOptics.first?.firearm?.id, firearmID)
        XCTAssertEqual(importedMagazines.first?.caliber?.name, "9mm")
        XCTAssertEqual(importedAttachments.first?.firearm?.id, firearmID)
        XCTAssertEqual(importedRecords.first?.ammoType?.brand, "Federal")
        XCTAssertEqual(importedRecords.first?.adjustmentKind, .purchase)

        XCTAssertEqual(destinationDefaults.double(forKey: InventorySettingsKeys.firearmsSalesTaxRate), 7.5)
        XCTAssertEqual(destinationDefaults.stringArray(forKey: InventorySettingsKeys.caliberSortOrder), ["9mm", ".45 acp"])
        XCTAssertEqual(destinationDefaults.bool(forKey: InventorySettingsKeys.showValueInCard), true)
        XCTAssertEqual(destinationDefaults.integer(forKey: InventorySettingsKeys.attachmentTypeSortOrderVersion), 2)
        XCTAssertNotNil(destinationDefaults.object(forKey: InventorySettingsKeys.lastModelSaveDate) as? Date)
    }

    @MainActor
    func testImportClearsExistingInventoryBeforeRestoringBackup() throws {
        let defaults = makeUserDefaults()
        let service = UserDataTransferService(userDefaults: defaults)
        let sourceContainer = try makeInMemoryContainer()
        let sourceContext = sourceContainer.mainContext

        let caliber = Caliber(name: ".223 Rem")
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "M4A1",
            purchasePriceCents: 180_000,
            type: .rifle,
            action: .semiAuto,
            caliber: caliber
        )
        sourceContext.insert(caliber)
        sourceContext.insert(firearm)
        try sourceContext.save()

        let data = try service.exportData(from: sourceContext)

        let destinationContainer = try makeInMemoryContainer()
        let destinationContext = destinationContainer.mainContext
        let staleCaliber = Caliber(name: "9mm")
        destinationContext.insert(staleCaliber)
        destinationContext.insert(
            Firearm(
                brand: "Old",
                modelName: "Data",
                purchasePriceCents: 1,
                type: .other,
                action: .other,
                caliber: staleCaliber
            )
        )
        try destinationContext.save()

        try service.importData(data, into: destinationContext)

        let importedCalibers = try destinationContext.fetch(FetchDescriptor<Caliber>())
        let importedFirearms = try destinationContext.fetch(FetchDescriptor<Firearm>())

        XCTAssertEqual(importedCalibers.map(\.name), [".223 Rem"])
        XCTAssertEqual(importedFirearms.map(\.brand), ["Daniel Defense"])
    }

    @MainActor
    func testClearAllDataRemovesInventoryAndManagedSettings() throws {
        let defaults = makeUserDefaults()
        seedManagedSettings(in: defaults)
        let service = UserDataTransferService(userDefaults: defaults)
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let caliber = Caliber(name: "9mm")
        context.insert(caliber)
        context.insert(
            Firearm(
                brand: "Glock",
                modelName: "17",
                purchasePriceCents: 45_000,
                type: .pistol,
                action: .semiAuto,
                caliber: caliber
            )
        )
        try context.save()

        try service.clearAllData(in: context)

        XCTAssertTrue(try context.fetch(FetchDescriptor<Caliber>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Firearm>()).isEmpty)
        XCTAssertNil(defaults.object(forKey: InventorySettingsKeys.firearmsSalesTaxRate))
        XCTAssertNil(defaults.object(forKey: InventorySettingsKeys.showValueInCard))
        XCTAssertNil(defaults.object(forKey: InventorySettingsKeys.caliberSortOrder))
        XCTAssertNil(defaults.object(forKey: InventorySettingsKeys.lastModelSaveDate))
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "UserDataTransferServiceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    private func seedManagedSettings(in defaults: UserDefaults) {
        defaults.set(7.5, forKey: InventorySettingsKeys.firearmsSalesTaxRate)
        defaults.set(true, forKey: InventorySettingsKeys.showValueInCard)
        defaults.set(["9mm", ".45 acp"], forKey: InventorySettingsKeys.caliberSortOrder)
        defaults.set(2, forKey: InventorySettingsKeys.attachmentTypeSortOrderVersion)
        defaults.set(Date(timeIntervalSince1970: 10_000), forKey: InventorySettingsKeys.lastModelSaveDate)
    }
}

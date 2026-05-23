//
//  KitUserDataTransferTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/14/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class KitUserDataTransferTests: XCTestCase {
    @MainActor
    func testVersionOneBackupImportsWithEmptyKits() throws {
        let json = """
        {
          "version" : 1,
          "exportedAt" : "2026-05-14T00:00:00Z",
          "settings" : {},
          "calibers" : [],
          "ammoTypes" : [],
          "ammoAdjustmentRecords" : [],
          "firearms" : [],
          "optics" : [],
          "magazines" : [],
          "attachments" : [],
          "parts" : []
        }
        """
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        try UserDataTransferService().importData(Data(json.utf8), into: context)

        let importedKits = try context.fetch(FetchDescriptor<Kit>())
        XCTAssertTrue(importedKits.isEmpty)
    }

    @MainActor
    func testKitExportImportRoundTripsComponentReferences() throws {
        let sourceContainer = try makeInMemoryContainer()
        let sourceContext = sourceContainer.mainContext
        let firearmID = UUID()
        let partID = UUID()
        let firearm = Firearm(
            id: firearmID,
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 100_000,
            type: .rifle,
            action: .semiAuto
        )
        let part = Part(
            id: partID,
            brand: "BCM",
            modelName: "BCG",
            type: .boltCarrierGroup,
            purchasePriceCents: 18_000
        )
        let kit = Kit(name: "Upper", kind: .upperReceiver, status: .linked, firearm: firearm)
        let component = KitComponent(category: .part, slot: .boltCarrierGroup, part: part)
        component.kit = kit
        kit.components = [component]

        sourceContext.insert(firearm)
        sourceContext.insert(part)
        sourceContext.insert(kit)
        sourceContext.insert(component)
        try sourceContext.save()

        let data = try UserDataTransferService().exportData(from: sourceContext)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(jsonObject?["version"] as? Int, 2)

        let destinationContainer = try makeInMemoryContainer()
        let destinationContext = destinationContainer.mainContext
        try UserDataTransferService().importData(data, into: destinationContext)

        let importedKits = try destinationContext.fetch(FetchDescriptor<Kit>())
        XCTAssertEqual(importedKits.count, 1)
        XCTAssertEqual(importedKits.first?.name, "Upper")
        XCTAssertEqual(importedKits.first?.kitStatus, .linked)
        XCTAssertEqual(importedKits.first?.firearm?.id, firearmID)
        XCTAssertEqual(importedKits.first?.components.first?.part?.id, partID)
        XCTAssertEqual(importedKits.first?.components.first?.componentSlot, .boltCarrierGroup)
    }
}

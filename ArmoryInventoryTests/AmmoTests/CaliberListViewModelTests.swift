//
//  CaliberListViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class CaliberListViewModelTests: XCTestCase {
    func testAmmoHistoryPresetTitlesAndSummaryTitles() {
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.day.title, "Day")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.week.title, "Week")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.month.title, "Month")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.custom.title, "Custom")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.day.summaryTitle, "Today")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.week.summaryTitle, "This Week")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.month.summaryTitle, "This Month")
        XCTAssertEqual(CaliberListViewModel.AmmoHistoryPreset.custom.summaryTitle, "Custom Range")
    }

    @MainActor
    func testSortedAmmoTotalRoundsAndInjectedTaxRate() {
        let caliber = Caliber(name: "9mm")
        let lowerStock = AmmoType(
            brand: "PMC",
            bulletType: "FMJ",
            grain: 115,
            quantity: 20,
            centsPerRound: 30,
            caliber: caliber
        )
        let higherStock = AmmoType(
            brand: "Federal",
            bulletType: "JHP",
            grain: 124,
            quantity: 40,
            centsPerRound: 50,
            caliber: caliber
        )
        caliber.ammoTypes = [lowerStock, higherStock]

        let service = AmmoChangeServiceMock()
        service.summaryResult = AmmoChangeSummary(
            purchased: 2,
            consumed: 1,
            purchasedAmountCents: 125,
            consumedAmountCents: 60
        )
        let viewModel = CaliberListViewModel(
            ammoChangeService: service,
            taxRateProvider: FixedInventoryTaxRateProvider(ammoTaxRate: 25)
        )

        let sortedAmmo = viewModel.sortedAmmo(for: caliber)
        let summary = viewModel.ammoHistory(
            for: caliber,
            within: AmmoChangeRange(start: .distantPast, end: .distantFuture)
        )

        XCTAssertEqual(sortedAmmo.map(\.quantity), [40, 20])
        XCTAssertEqual(viewModel.totalRounds(for: caliber), 60)
        XCTAssertEqual(summary.purchasedAmountCents, 125)
    }

    @MainActor
    func testSortedCalibersSortedAmmoTieBreakersAndValueFormatting() {
        let firstCaliber = Caliber(name: "5.56 NATO")
        let secondCaliber = Caliber(name: "9mm")
        let thirdCaliber = Caliber(name: ".45 ACP")
        let caliber = Caliber(name: "Test")
        let firstAmmo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 124,
            loadDetail: "Target",
            quantity: 20,
            centsPerRound: 30,
            caliber: caliber
        )
        let secondAmmo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            loadDetail: "Target",
            quantity: 20,
            centsPerRound: 40,
            caliber: caliber
        )
        let thirdAmmo = AmmoType(
            brand: "Blazer",
            bulletType: "JHP",
            grain: 124,
            loadDetail: nil,
            quantity: 20,
            centsPerRound: 20,
            caliber: caliber
        )
        let fourthAmmo = AmmoType(
            brand: "PMC",
            bulletType: "FMJ",
            grain: 55,
            quantity: -10,
            centsPerRound: 100,
            caliber: secondCaliber
        )
        let fifthAmmo = AmmoType(
            brand: "AAC",
            bulletType: "OTM",
            grain: 77,
            quantity: 10,
            centsPerRound: 150,
            caliber: firstCaliber
        )
        secondCaliber.ammoTypes = [fourthAmmo]
        firstCaliber.ammoTypes = [fifthAmmo]
        caliber.ammoTypes = [firstAmmo, secondAmmo, thirdAmmo]

        let viewModel = CaliberListViewModel(
            ammoChangeService: AmmoChangeServiceMock(),
            taxRateProvider: FixedInventoryTaxRateProvider()
        )

        XCTAssertEqual(
            viewModel.sortedCalibers(from: [secondCaliber, thirdCaliber, firstCaliber]).map(\.name),
            ["5.56 NATO", "9mm", ".45 ACP"]
        )
        XCTAssertEqual(
            viewModel.sortedAmmo(for: caliber).map(\.brand),
            ["Blazer", "Federal", "Federal"]
        )
        XCTAssertEqual(
            viewModel.sortedAmmo(for: caliber).map(\.grain),
            [124, 115, 124]
        )

        let expectedValue = (Decimal(1500) / 100).formatted(.currency(code: "USD"))
        XCTAssertEqual(
            viewModel.totalValueText(for: [firstCaliber, secondCaliber], currencyCode: "USD"),
            expectedValue
        )
    }

    @MainActor
    func testUpdateAndDeletionHelpersMutateContext() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 50,
            centsPerRound: 30,
            caliber: caliber
        )
        context.insert(caliber)
        context.insert(ammo)

        let viewModel = CaliberListViewModel(
            ammoChangeService: AmmoChangeServiceMock(),
            taxRateProvider: FixedInventoryTaxRateProvider()
        )

        viewModel.updateQuantity(for: ammo, to: -10, in: context)
        XCTAssertEqual(ammo.quantity, 0)
        XCTAssertTrue(viewModel.shouldClearSelectedCaliber(caliber.persistentModelID, deleting: caliber))

        viewModel.deleteAmmo(ammo, in: context)
        XCTAssertTrue(try context.fetch(FetchDescriptor<AmmoType>()).isEmpty)

        viewModel.deleteCaliber(caliber, in: context)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Caliber>()).isEmpty)
        XCTAssertFalse(viewModel.shouldClearSelectedCaliber(nil, deleting: caliber))
    }

    @MainActor
    func testAdjustmentAndHistorySummaryHelpers() {
        let service = AmmoChangeServiceMock()
        let viewModel = CaliberListViewModel(
            ammoChangeService: service,
            taxRateProvider: FixedInventoryTaxRateProvider()
        )
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 4, day: 6))!

        let customRange = viewModel.consumptionRange(
            for: .custom,
            customStartDate: start,
            customEndDate: end,
            calendar: calendar
        )

        XCTAssertEqual(customRange.start, calendar.startOfDay(for: end))
        XCTAssertEqual(
            customRange.end,
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start))
        )
        XCTAssertEqual(viewModel.consumptionSummary(for: .day, range: customRange, calendar: calendar), "Today")
        XCTAssertEqual(viewModel.consumptionSummary(for: .week, range: customRange, calendar: calendar), "This Week")
        XCTAssertEqual(viewModel.consumptionSummary(for: .month, range: customRange, calendar: calendar), "This Month")
        XCTAssertTrue(viewModel.consumptionSummary(for: .custom, range: customRange, calendar: calendar).contains("2026"))
    }

    func testCurrencyStringUsesCurrencyFormatting() {
        let viewModel = CaliberListViewModel(
            ammoChangeService: AmmoChangeServiceMock(),
            taxRateProvider: FixedInventoryTaxRateProvider()
        )
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let expected = formatter.string(from: NSDecimalNumber(value: 1234).dividing(by: 100))

        XCTAssertEqual(viewModel.currencyString(for: 1234), expected)
    }

    @MainActor
    func testAdjustQuantityDelegatesToService() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 50,
            centsPerRound: 30,
            caliber: caliber
        )
        context.insert(caliber)
        context.insert(ammo)

        let service = AmmoChangeServiceMock()
        let viewModel = CaliberListViewModel(
            ammoChangeService: service,
            taxRateProvider: FixedInventoryTaxRateProvider()
        )
        let occurredAt = Date(timeIntervalSince1970: 100)

        viewModel.adjustQuantity(for: ammo, by: -10, occurredAt: occurredAt, in: context)

        XCTAssertTrue(service.appliedChange?.ammo === ammo)
        XCTAssertEqual(service.appliedChange?.delta, -10)
        XCTAssertEqual(service.appliedChange?.occurredAt, occurredAt)
    }
}

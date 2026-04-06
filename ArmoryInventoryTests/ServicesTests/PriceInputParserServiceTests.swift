//
//  PriceInputParserServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/5/26.
//

import XCTest
@testable import ArmoryInventory

final class PriceInputParserServiceTests: XCTestCase {
    private let service = PriceInputParserService()

    func testParserAcceptsPlainAndFormattedCurrencyInput() {
        XCTAssertEqual(service.purchasePriceCents(from: "999.99"), 99999)
        XCTAssertEqual(service.purchasePriceCents(from: "1,000.00"), 100000)
        XCTAssertEqual(service.purchasePriceCents(from: "$2,499.99"), 249999)
        XCTAssertEqual(service.purchasePriceCents(from: "2499,99"), 249999)
        XCTAssertEqual(service.purchasePriceCents(from: "2500"), 250000)
    }

    func testParserRejectsInvalidOrOverPreciseInput() {
        XCTAssertNil(service.purchasePriceCents(from: ""))
        XCTAssertNil(service.purchasePriceCents(from: "bad"))
        XCTAssertNil(service.purchasePriceCents(from: "2499.999"))
        XCTAssertNil(service.purchasePriceCents(from: "1,000."))
    }
}

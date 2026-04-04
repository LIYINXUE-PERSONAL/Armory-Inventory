//
//  FeedbackServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class FeedbackServiceTests: XCTestCase {
    func testFeedbackEmailURLBuildsMailtoLinkWithExpectedRecipientAndSubject() throws {
        let service = FeedbackService()

        let url = try XCTUnwrap(service.feedbackEmailURL(appVersion: "1.2.3"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, "armory.inventory@liyinxue.com")
        XCTAssertEqual(
            components.queryItems?.first(where: { $0.name == "subject" })?.value,
            "Armory Inventory Feedback"
        )
    }

    func testFeedbackEmailURLIncludesTemplateBodyAndVersion() throws {
        let service = FeedbackService()

        let url = try XCTUnwrap(service.feedbackEmailURL(appVersion: "2026.04"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let body = try XCTUnwrap(components.queryItems?.first(where: { $0.name == "body" })?.value)

        XCTAssertTrue(body.contains("Please describe the issue you ran into:"))
        XCTAssertTrue(body.contains("Steps to reproduce:"))
        XCTAssertTrue(body.contains("Expected result:"))
        XCTAssertTrue(body.contains("Actual result:"))
        XCTAssertTrue(body.contains("Please attach screenshots if available."))
        XCTAssertTrue(body.contains("App version: 2026.04"))
    }
}

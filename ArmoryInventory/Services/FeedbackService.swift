//
//  FeedbackService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation

protocol FeedbackServicing {
    func feedbackEmailURL(appVersion: String) -> URL?
}

final class FeedbackService: FeedbackServicing {
    private let recipient = "armory.inventory@liyinxue.com"
    private let subject = "Armory Inventory Feedback"

    func feedbackEmailURL(appVersion: String) -> URL? {
        let body = """
        Please describe the issue you ran into:


        Steps to reproduce:


        Expected result:


        Actual result:


        Please attach screenshots if available.

        App version: \(appVersion)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}

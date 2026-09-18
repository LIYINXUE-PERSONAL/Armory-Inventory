//
//  DebugDataInjector.swift
//  Armory Inventory
//

#if DEBUG
import Foundation
import SwiftData

enum DebugDataInjectorError: LocalizedError {
    case missingResource

    var errorDescription: String? {
        String(localized: "DebugData.json is missing from the debug app bundle.")
    }
}

enum DebugDataInjector {
    @MainActor
    static func inject(
        into context: ModelContext,
        using service: UserDataTransferServicing
    ) throws {
        guard let url = Bundle.main.url(forResource: "DebugData", withExtension: "json") else {
            throw DebugDataInjectorError.missingResource
        }

        let data = try Data(contentsOf: url)
        try service.importData(data, into: context)
    }
}
#endif

//
//  OpticLookupService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

protocol OpticLookupServicing {
    func fetchExistingOptics(in context: ModelContext) throws -> [Optic]
}

struct OpticLookupService: OpticLookupServicing {
    func fetchExistingOptics(in context: ModelContext) throws -> [Optic] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Optic.brand), SortDescriptor(\Optic.modelName)]
            )
        )
    }
}

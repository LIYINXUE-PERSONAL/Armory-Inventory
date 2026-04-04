//
//  CaliberQueryService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

protocol CaliberQueryServicing {
    func fetchCalibers(in context: ModelContext) throws -> [Caliber]
}

struct CaliberQueryService: CaliberQueryServicing {
    func fetchCalibers(in context: ModelContext) throws -> [Caliber] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Caliber.name, comparator: .localizedStandard)]
            )
        )
    }
}

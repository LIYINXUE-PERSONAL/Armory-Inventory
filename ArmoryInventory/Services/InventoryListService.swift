//
//  InventoryListService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

protocol InventoryListServicing {
    func fetchAttachments(in context: ModelContext) throws -> [Attachment]
    func fetchMagazines(in context: ModelContext) throws -> [Magazine]
    func fetchOptics(in context: ModelContext) throws -> [Optic]
    func fetchFirearms(in context: ModelContext) throws -> [Firearm]
}

struct InventoryListService: InventoryListServicing {
    func fetchAttachments(in context: ModelContext) throws -> [Attachment] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Attachment.sortOrder), SortDescriptor(\Attachment.createdAt)]
            )
        )
    }

    func fetchMagazines(in context: ModelContext) throws -> [Magazine] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Magazine.sortOrder), SortDescriptor(\Magazine.createdAt)]
            )
        )
    }

    func fetchOptics(in context: ModelContext) throws -> [Optic] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Optic.sortOrder), SortDescriptor(\Optic.createdAt)]
            )
        )
    }

    func fetchFirearms(in context: ModelContext) throws -> [Firearm] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Firearm.sortOrder), SortDescriptor(\Firearm.createdAt)]
            )
        )
    }
}

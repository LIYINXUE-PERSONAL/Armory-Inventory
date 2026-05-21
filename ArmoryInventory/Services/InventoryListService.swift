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
    func fetchParts(in context: ModelContext) throws -> [Part]
    func fetchFirearms(in context: ModelContext) throws -> [Firearm]
    func fetchKits(in context: ModelContext) throws -> [Kit]
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

    func fetchParts(in context: ModelContext) throws -> [Part] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Part.sortOrder), SortDescriptor(\Part.createdAt)]
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

    func fetchKits(in context: ModelContext) throws -> [Kit] {
        try context.fetch(
            FetchDescriptor(
                sortBy: [SortDescriptor(\Kit.sortOrder), SortDescriptor(\Kit.createdAt)]
            )
        )
    }
}

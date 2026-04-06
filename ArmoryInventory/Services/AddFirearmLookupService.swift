//
//  AddFirearmLookupService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

struct AddFirearmLookupData {
    var calibers: [Caliber] = []
    var existingFirearms: [Firearm] = []
    var optics: [Optic] = []
    var magazines: [Magazine] = []
    var attachments: [Attachment] = []
    var parts: [Part] = []
}

protocol AddFirearmLookupServicing {
    func fetchLookupData(in context: ModelContext) throws -> AddFirearmLookupData
}

struct AddFirearmLookupService: AddFirearmLookupServicing {
    func fetchLookupData(in context: ModelContext) throws -> AddFirearmLookupData {
        let calibersDescriptor = FetchDescriptor<Caliber>(
            sortBy: [SortDescriptor(\.name, comparator: .localizedStandard)]
        )
        let firearmsDescriptor = FetchDescriptor<Firearm>(
            sortBy: [SortDescriptor(\.brand), SortDescriptor(\.modelName)]
        )
        let opticsDescriptor = FetchDescriptor<Optic>(
            sortBy: [SortDescriptor(\.brand), SortDescriptor(\.modelName)]
        )
        let magazinesDescriptor = FetchDescriptor<Magazine>(
            sortBy: [SortDescriptor(\.brand), SortDescriptor(\.modelName)]
        )
        let attachmentsDescriptor = FetchDescriptor<Attachment>(
            sortBy: [SortDescriptor(\.brand), SortDescriptor(\.modelName)]
        )
        let partsDescriptor = FetchDescriptor<Part>(
            sortBy: [SortDescriptor(\.brand), SortDescriptor(\.modelName)]
        )

        return AddFirearmLookupData(
            calibers: try context.fetch(calibersDescriptor),
            existingFirearms: try context.fetch(firearmsDescriptor),
            optics: try context.fetch(opticsDescriptor),
            magazines: try context.fetch(magazinesDescriptor),
            attachments: try context.fetch(attachmentsDescriptor),
            parts: try context.fetch(partsDescriptor)
        )
    }
}

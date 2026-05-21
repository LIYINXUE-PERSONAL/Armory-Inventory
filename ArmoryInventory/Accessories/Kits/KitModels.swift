//
//  KitModels.swift
//  Armory Inventory
//
//  Created by Codex on 5/14/26.
//

import Foundation
import SwiftData

enum KitKind: String, Codable, CaseIterable, Hashable, Identifiable {
    case upperReceiver
    case lowerReceiver
    case optics
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .upperReceiver:
            return String(localized: "Upper Receiver Kit")
        case .lowerReceiver:
            return String(localized: "Lower Receiver Kit")
        case .optics:
            return String(localized: "Optics Kit")
        case .custom:
            return String(localized: "Custom Kit")
        }
    }
}

enum KitStatus: String, Codable, CaseIterable, Hashable, Identifiable {
    case built
    case linked

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .built:
            return String(localized: "Built")
        case .linked:
            return String(localized: "Linked")
        }
    }

    var reservesComponents: Bool {
        self == .built || self == .linked
    }
}

enum KitComponentCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case part
    case optic
    case attachment

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .part:
            return String(localized: "Part")
        case .optic:
            return String(localized: "Optic")
        case .attachment:
            return String(localized: "Attachment")
        }
    }
}

enum KitComponentSlot: String, Codable, CaseIterable, Hashable, Identifiable {
    case receiver
    case boltCarrierGroup
    case handguard
    case muzzleDevice
    case foregrip
    case optic
    case lowerReceiver
    case trigger
    case recoilSystem
    case internals
    case stock
    case grip
    case mount
    case magnifier
    case support
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .receiver:
            return String(localized: "Receiver")
        case .boltCarrierGroup:
            return String(localized: "Bolt Carrier Group")
        case .handguard:
            return String(localized: "Handguard")
        case .muzzleDevice:
            return String(localized: "Muzzle Device")
        case .foregrip:
            return String(localized: "Foregrip")
        case .optic:
            return String(localized: "Optic")
        case .lowerReceiver:
            return String(localized: "Lower Receiver")
        case .trigger:
            return String(localized: "Trigger")
        case .recoilSystem:
            return String(localized: "Recoil System")
        case .internals:
            return String(localized: "Internals")
        case .stock:
            return String(localized: "Stock")
        case .grip:
            return String(localized: "Grip")
        case .mount:
            return String(localized: "Mount")
        case .magnifier:
            return String(localized: "Magnifier")
        case .support:
            return String(localized: "Support")
        case .other:
            return String(localized: "Other")
        }
    }
}

enum KitHistoryEvent: String, Codable, CaseIterable, Hashable, Identifiable {
    case created
    case updated
    case built
    case linked
    case unlinked

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .created:
            return String(localized: "Created")
        case .updated:
            return String(localized: "Updated")
        case .built:
            return String(localized: "Built")
        case .linked:
            return String(localized: "Linked")
        case .unlinked:
            return String(localized: "Unlinked")
        }
    }
}

@Model
final class Kit {
    var id: UUID?
    var name: String
    var kind: KitKind.RawValue
    var status: KitStatus.RawValue
    var notes: String?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship var firearm: Firearm?
    @Relationship(deleteRule: .cascade, inverse: \KitComponent.kit) var components: [KitComponent]
    @Relationship(deleteRule: .cascade, inverse: \KitHistoryRecord.kit) var historyRecords: [KitHistoryRecord]

    init(
        id: UUID? = UUID(),
        name: String,
        kind: KitKind,
        status: KitStatus = .built,
        notes: String? = nil,
        firearm: Firearm? = nil,
        components: [KitComponent] = [],
        historyRecords: [KitHistoryRecord] = [],
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind.rawValue
        self.status = status.rawValue
        self.notes = notes
        self.firearm = firearm
        self.components = components
        self.historyRecords = historyRecords
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var kitKind: KitKind {
        KitKind(rawValue: kind) ?? .custom
    }

    var kitStatus: KitStatus {
        KitStatus(rawValue: status) ?? .built
    }

    var isActiveReservation: Bool {
        kitStatus.reservesComponents
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? kitKind.displayName : name
    }

    var sortedComponents: [KitComponent] {
        components.sorted {
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    var sortedHistoryRecords: [KitHistoryRecord] {
        historyRecords.sorted { $0.occurredAt > $1.occurredAt }
    }

    var componentCountText: String {
        String.localizedStringWithFormat(
            String(localized: "componentCount"),
            components.count,
            components.count.localizedCountString
        )
    }

    var totalValueCents: Int {
        KitValueService.totalValueCents(for: components)
    }

    var totalValueText: String {
        KitValueService.currencyText(for: totalValueCents)
    }
}

@Model
final class KitComponent {
    var id: UUID?
    var category: KitComponentCategory.RawValue
    var slot: KitComponentSlot.RawValue?
    var sortOrder: Int

    @Relationship var kit: Kit?
    @Relationship var part: Part?
    @Relationship var optic: Optic?
    @Relationship var attachment: Attachment?

    init(
        id: UUID? = UUID(),
        category: KitComponentCategory,
        slot: KitComponentSlot? = nil,
        part: Part? = nil,
        optic: Optic? = nil,
        attachment: Attachment? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.category = category.rawValue
        self.slot = slot?.rawValue
        self.part = part
        self.optic = optic
        self.attachment = attachment
        self.sortOrder = sortOrder
    }

    var componentCategory: KitComponentCategory {
        KitComponentCategory(rawValue: category) ?? .part
    }

    var componentSlot: KitComponentSlot? {
        guard let slot else {
            return nil
        }
        return KitComponentSlot(rawValue: slot)
    }

    var displayName: String {
        switch componentCategory {
        case .part:
            return part?.displayName ?? String(localized: "Missing Part")
        case .optic:
            return optic?.displayName ?? String(localized: "Missing Optic")
        case .attachment:
            return attachment?.displayName ?? String(localized: "Missing Attachment")
        }
    }

    var detailText: String {
        let slotText = componentSlot?.displayName
        let typeText: String?
        switch componentCategory {
        case .part:
            typeText = part?.typeDisplayName
        case .optic:
            typeText = optic.map {
                String.localizedStringWithFormat(
                    String(localized: "%@ • %@"),
                    $0.typeDisplayName,
                    $0.magnificationText
                )
            }
        case .attachment:
            typeText = attachment?.typeDisplayName
        }

        return [slotText, typeText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    var purchasePriceCents: Int {
        switch componentCategory {
        case .part:
            return max(0, part?.purchasePriceCents ?? 0)
        case .optic:
            return max(0, optic?.purchasePriceCents ?? 0)
        case .attachment:
            return max(0, attachment?.purchasePriceCents ?? 0)
        }
    }

    var stableIdentity: KitComponentIdentity? {
        if let part {
            return .part(part.persistentModelID)
        }
        if let optic {
            return .optic(optic.persistentModelID)
        }
        if let attachment {
            return .attachment(attachment.persistentModelID)
        }
        return nil
    }
}

@Model
final class KitHistoryRecord {
    var occurredAt: Date
    var event: KitHistoryEvent.RawValue
    var note: String?

    @Relationship var kit: Kit?

    init(
        occurredAt: Date = .now,
        event: KitHistoryEvent,
        note: String? = nil
    ) {
        self.occurredAt = occurredAt
        self.event = event.rawValue
        self.note = note
    }

    var historyEvent: KitHistoryEvent {
        KitHistoryEvent(rawValue: event) ?? .updated
    }
}

enum KitComponentIdentity: Hashable {
    case part(PersistentIdentifier)
    case optic(PersistentIdentifier)
    case attachment(PersistentIdentifier)
}

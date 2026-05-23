//
//  KitServices.swift
//  Armory Inventory
//
//  Created by Codex on 5/14/26.
//

import Foundation
import SwiftData

struct KitValidationResult {
    let isValid: Bool
    let message: String?

    static let valid = KitValidationResult(isValid: true, message: nil)

    static func invalid(_ message: String) -> KitValidationResult {
        KitValidationResult(isValid: false, message: message)
    }
}

protocol KitEligibilityServicing {
    func isReserved(_ part: Part, by kits: [Kit], excluding kit: Kit?) -> Bool
    func isReserved(_ optic: Optic, by kits: [Kit], excluding kit: Kit?) -> Bool
    func isReserved(_ attachment: Attachment, by kits: [Kit], excluding kit: Kit?) -> Bool
    func canSelectForKit(_ part: Part, kits: [Kit], excluding kit: Kit?) -> Bool
    func canSelectForKit(_ optic: Optic, kits: [Kit], excluding kit: Kit?) -> Bool
    func canSelectForKit(_ attachment: Attachment, kits: [Kit], excluding kit: Kit?) -> Bool
    func canSelectForDirectFirearm(_ part: Part, kits: [Kit]) -> Bool
    func canSelectForDirectFirearm(_ optic: Optic, kits: [Kit]) -> Bool
    func canSelectForDirectFirearm(_ attachment: Attachment, kits: [Kit]) -> Bool
    func validationResultForBuild(components: [KitComponent], kits: [Kit], excluding kit: Kit?) -> KitValidationResult
}

struct KitEligibilityService: KitEligibilityServicing {
    func isReserved(_ part: Part, by kits: [Kit], excluding kit: Kit? = nil) -> Bool {
        reservedComponents(in: kits, excluding: kit).contains { $0.part?.persistentModelID == part.persistentModelID }
    }

    func isReserved(_ optic: Optic, by kits: [Kit], excluding kit: Kit? = nil) -> Bool {
        reservedComponents(in: kits, excluding: kit).contains { $0.optic?.persistentModelID == optic.persistentModelID }
    }

    func isReserved(_ attachment: Attachment, by kits: [Kit], excluding kit: Kit? = nil) -> Bool {
        reservedComponents(in: kits, excluding: kit).contains { $0.attachment?.persistentModelID == attachment.persistentModelID }
    }

    func canSelectForKit(_ part: Part, kits: [Kit], excluding kit: Kit? = nil) -> Bool {
        part.firearm == nil && !isReserved(part, by: kits, excluding: kit)
    }

    func canSelectForKit(_ optic: Optic, kits: [Kit], excluding kit: Kit? = nil) -> Bool {
        optic.firearm == nil && !isReserved(optic, by: kits, excluding: kit)
    }

    func canSelectForKit(_ attachment: Attachment, kits: [Kit], excluding kit: Kit? = nil) -> Bool {
        attachment.firearm == nil && !isReserved(attachment, by: kits, excluding: kit)
    }

    func canSelectForDirectFirearm(_ part: Part, kits: [Kit]) -> Bool {
        part.firearm == nil && !isReserved(part, by: kits, excluding: nil)
    }

    func canSelectForDirectFirearm(_ optic: Optic, kits: [Kit]) -> Bool {
        optic.firearm == nil && !isReserved(optic, by: kits, excluding: nil)
    }

    func canSelectForDirectFirearm(_ attachment: Attachment, kits: [Kit]) -> Bool {
        attachment.firearm == nil && !isReserved(attachment, by: kits, excluding: nil)
    }

    func validationResultForBuild(components: [KitComponent], kits: [Kit], excluding kit: Kit? = nil) -> KitValidationResult {
        for component in components {
            switch component.componentCategory {
            case .part:
                guard let part = component.part else {
                    return .invalid(String(localized: "A selected part is missing."))
                }
                if part.firearm != nil {
                    return .invalid(alreadyLinkedToFirearmMessage(itemName: part.displayName))
                }
                if isReserved(part, by: kits, excluding: kit) {
                    return .invalid(alreadyReservedByKitMessage(itemName: part.displayName))
                }
            case .optic:
                guard let optic = component.optic else {
                    return .invalid(String(localized: "A selected optic is missing."))
                }
                if optic.firearm != nil {
                    return .invalid(alreadyLinkedToFirearmMessage(itemName: optic.displayName))
                }
                if isReserved(optic, by: kits, excluding: kit) {
                    return .invalid(alreadyReservedByKitMessage(itemName: optic.displayName))
                }
            case .attachment:
                guard let attachment = component.attachment else {
                    return .invalid(String(localized: "A selected attachment is missing."))
                }
                if attachment.firearm != nil {
                    return .invalid(alreadyLinkedToFirearmMessage(itemName: attachment.displayName))
                }
                if isReserved(attachment, by: kits, excluding: kit) {
                    return .invalid(alreadyReservedByKitMessage(itemName: attachment.displayName))
                }
            }
        }

        return .valid
    }

    private func reservedComponents(in kits: [Kit], excluding kit: Kit?) -> [KitComponent] {
        kits.filter { candidate in
            candidate.isActiveReservation && candidate.persistentModelID != kit?.persistentModelID
        }
        .flatMap(\.components)
    }

    private func alreadyLinkedToFirearmMessage(itemName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "%@ is already linked to a firearm."),
            itemName
        )
    }

    private func alreadyReservedByKitMessage(itemName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "%@ is already reserved by another built or linked kit."),
            itemName
        )
    }
}

struct KitValueService {
    static func totalValueCents(for components: [KitComponent]) -> Int {
        var seen: Set<KitComponentIdentity> = []
        return components.reduce(0) { total, component in
            guard let identity = component.stableIdentity else {
                return total
            }
            guard seen.insert(identity).inserted else {
                return total
            }
            return total + component.purchasePriceCents
        }
    }

    static func effectiveTotalValueCents(
        for firearm: Firearm,
        linkedKits: [Kit],
        compatibleMagazines: [Magazine]
    ) -> Int {
        var seen: Set<KitComponentIdentity> = []
        var total = max(0, firearm.purchasePriceCents)

        for optic in firearm.optics where seen.insert(.optic(optic.persistentModelID)).inserted {
            total += max(0, optic.purchasePriceCents)
        }

        for attachment in firearm.attachments where seen.insert(.attachment(attachment.persistentModelID)).inserted {
            total += max(0, attachment.purchasePriceCents)
        }

        for part in firearm.parts where seen.insert(.part(part.persistentModelID)).inserted {
            total += max(0, part.purchasePriceCents)
        }

        total += compatibleMagazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) }

        for component in linkedKits.flatMap(\.components) {
            guard let identity = component.stableIdentity else {
                continue
            }
            guard seen.insert(identity).inserted else {
                continue
            }
            total += component.purchasePriceCents
        }

        return total
    }

    static func currencyText(for amountCents: Int) -> String {
        let amount = Decimal(amountCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

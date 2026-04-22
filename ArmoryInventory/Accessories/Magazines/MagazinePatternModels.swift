//
//  MagazinePatternModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/21/26.
//

import Foundation

enum MagazinePatternKind: String, Codable, CaseIterable, Identifiable {
    case catalog
    case legacy
    case unknown

    var id: String { rawValue }
}

enum MagazinePatternFamily: String, Codable, CaseIterable, Identifiable {
    case ar15Stanag
    case glockDoubleStack9mm
    case sigP320DoubleStack9mm
    case doubleStack1911_2011_9mm
    case legacy
    case unknown

    var id: String { rawValue }
}

enum MagazinePatternFitProfile: String, Codable, CaseIterable, Identifiable {
    case rifleStandard
    case fullSizeAndCompact
    case compactOnly
    case servicePistol
    case doubleStack1911
    case legacy
    case unknown

    var id: String { rawValue }
}

struct MagazinePattern: Identifiable, Codable, Hashable {
    let id: String
    let kind: MagazinePatternKind
    let family: MagazinePatternFamily
    let displayName: String
    let supportedCaliberNames: [String]
    let compatibleFirearmTypes: [FirearmType]
    let compatibleFirearmActions: [FirearmAction]
    let compatiblePlatformNames: [String]
    let fitProfile: MagazinePatternFitProfile
    let aliases: [String]
    let notes: String?

    var isFallback: Bool {
        kind != .catalog
    }

    func supports(caliberName: String?) -> Bool {
        guard let caliberName else {
            return false
        }

        let normalizedQuery = Self.normalize(caliberName)
        guard !normalizedQuery.isEmpty else {
            return false
        }

        return supportedCaliberNames.contains { Self.normalize($0) == normalizedQuery }
    }

    func isCompatible(
        with firearmType: FirearmType,
        action: FirearmAction,
        caliberName: String?
    ) -> Bool {
        let typeMatches = compatibleFirearmTypes.isEmpty || compatibleFirearmTypes.contains(firearmType)
        let actionMatches = compatibleFirearmActions.isEmpty || compatibleFirearmActions.contains(action)
        let caliberMatches = caliberName == nil || supports(caliberName: caliberName)
        return typeMatches && actionMatches && caliberMatches
    }

    static let unknown = MagazinePattern(
        id: "unknown",
        kind: .unknown,
        family: .unknown,
        displayName: "Unknown Pattern",
        supportedCaliberNames: [],
        compatibleFirearmTypes: [],
        compatibleFirearmActions: [],
        compatiblePlatformNames: [],
        fitProfile: .unknown,
        aliases: [],
        notes: "Fallback used when no catalog pattern can be resolved."
    )

    static func legacy(
        displayName: String,
        supportedCaliberNames: [String] = [],
        compatibleFirearmTypes: [FirearmType] = [],
        compatibleFirearmActions: [FirearmAction] = [],
        compatiblePlatformNames: [String] = [],
        notes: String? = nil
    ) -> MagazinePattern {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedDisplayName.isEmpty ? "Legacy Pattern" : trimmedDisplayName
        let normalizedID = normalize(resolvedName)
        let legacyID = normalizedID.isEmpty ? "legacy-pattern" : normalizedID

        return MagazinePattern(
            id: "legacy:\(legacyID)",
            kind: .legacy,
            family: .legacy,
            displayName: resolvedName,
            supportedCaliberNames: supportedCaliberNames,
            compatibleFirearmTypes: compatibleFirearmTypes,
            compatibleFirearmActions: compatibleFirearmActions,
            compatiblePlatformNames: compatiblePlatformNames,
            fitProfile: .legacy,
            aliases: [],
            notes: notes
        )
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

enum MagazinePatternCatalog {
    static let canonicalPatterns: [MagazinePattern] = [
        MagazinePattern(
            id: "ar15-stanag-223-556-300blk",
            kind: .catalog,
            family: .ar15Stanag,
            displayName: "AR-15 STANAG",
            supportedCaliberNames: [".223 Rem", "5.56 NATO", ".300 Blackout"],
            compatibleFirearmTypes: [.rifle],
            compatibleFirearmActions: [.semiAuto, .selectFire],
            compatiblePlatformNames: ["AR-15", "STANAG", "AR-15 pattern lower"],
            fitProfile: .rifleStandard,
            aliases: ["STANAG AR-15", "AR-15 PMAG", "GI AR-15"],
            notes: "Standard AR-15 magazine family shared across .223 Rem, 5.56 NATO, and .300 Blackout platforms."
        ),
        MagazinePattern(
            id: "glock-double-stack-9mm-full-size-compact",
            kind: .catalog,
            family: .glockDoubleStack9mm,
            displayName: "Glock Double-Stack 9mm Full-Size",
            supportedCaliberNames: ["9mm"],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            compatiblePlatformNames: ["Glock 17", "Glock 19", "Glock 34", "Glock 45"],
            fitProfile: .fullSizeAndCompact,
            aliases: ["G17/G19 9mm", "Glock OEM 17-round", "Glock full-size 9mm"],
            notes: "Longer Glock-pattern 9mm magazines that work in both full-size and compact frames."
        ),
        MagazinePattern(
            id: "glock-double-stack-9mm-compact",
            kind: .catalog,
            family: .glockDoubleStack9mm,
            displayName: "Glock Double-Stack 9mm Compact",
            supportedCaliberNames: ["9mm"],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            compatiblePlatformNames: ["Glock 19", "Glock 26", "Glock 49"],
            fitProfile: .compactOnly,
            aliases: ["G19-only 9mm", "Glock OEM 15-round", "Glock compact 9mm"],
            notes: "Shorter Glock-pattern 9mm magazines that do not fit the same set of firearms as full-size bodies."
        ),
        MagazinePattern(
            id: "sig-p320-double-stack-9mm",
            kind: .catalog,
            family: .sigP320DoubleStack9mm,
            displayName: "SIG P320 9mm",
            supportedCaliberNames: ["9mm"],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            compatiblePlatformNames: ["SIG P320", "SIG M17", "SIG M18", "AXG Pro"],
            fitProfile: .servicePistol,
            aliases: ["P320 9mm", "M17/M18 9mm", "SIG 320 full-size 9mm"],
            notes: "Double-stack SIG P320 family magazines."
        ),
        MagazinePattern(
            id: "2011-double-stack-9mm",
            kind: .catalog,
            family: .doubleStack1911_2011_9mm,
            displayName: "2011 / Double-Stack 1911 9mm",
            supportedCaliberNames: ["9mm"],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            compatiblePlatformNames: ["2011", "Staccato", "Atlas", "double-stack 1911"],
            fitProfile: .doubleStack1911,
            aliases: ["2011 9mm", "DS 1911 9mm", "Staccato 9mm"],
            notes: "Double-stack 1911 / 2011 magazine family."
        )
    ]

    static func pattern(id: String) -> MagazinePattern? {
        canonicalPatterns.first { $0.id == id }
    }

    static func suggestedPatterns(
        firearmType: FirearmType,
        action: FirearmAction,
        caliberName: String?
    ) -> [MagazinePattern] {
        canonicalPatterns.filter {
            $0.isCompatible(with: firearmType, action: action, caliberName: caliberName)
        }
    }
}

//
//  MagazinePatternModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/21/26.
//

import Foundation

enum MagazinePatternKind: String, Codable, CaseIterable, Identifiable {
    case catalog
    case custom
    case legacy
    case unknown

    var id: String { rawValue }
}

struct MagazinePatternCompatibility: Codable, Hashable {
    let supportedCaliberNames: [String]
    let compatibleFirearmTypes: [FirearmType]
    let compatibleFirearmActions: [FirearmAction]
    let platformTags: [String]
    let fitDescriptors: [String]

    static let empty = MagazinePatternCompatibility(
        supportedCaliberNames: [],
        compatibleFirearmTypes: [],
        compatibleFirearmActions: [],
        platformTags: [],
        fitDescriptors: []
    )
}

struct MagazinePattern: Identifiable, Codable, Hashable {
    private static let normalizationLocale = Locale(identifier: "en_US_POSIX")
    private static let catalogPrefix = "catalog:"
    private static let customPrefix = "custom:"
    private static let legacyPrefix = "legacy:"

    let id: String
    let kind: MagazinePatternKind
    let displayName: String
    let familyLabel: String
    let compatibility: MagazinePatternCompatibility
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

        return compatibility.supportedCaliberNames.contains { Self.normalize($0) == normalizedQuery }
    }

    func isCompatible(
        with firearmType: FirearmType,
        action: FirearmAction,
        caliberName: String?
    ) -> Bool {
        let typeMatches = compatibility.compatibleFirearmTypes.isEmpty || compatibility.compatibleFirearmTypes.contains(firearmType)
        let actionMatches = compatibility.compatibleFirearmActions.isEmpty || compatibility.compatibleFirearmActions.contains(action)
        let caliberMatches = compatibility.supportedCaliberNames.isEmpty || caliberName == nil || supports(caliberName: caliberName)
        return typeMatches && actionMatches && caliberMatches
    }

    static let unknown = MagazinePattern(
        id: "\(legacyPrefix)unknown",
        kind: .unknown,
        displayName: "Unknown Pattern",
        familyLabel: "Unknown",
        compatibility: .empty,
        aliases: [],
        notes: "Fallback used when no catalog pattern can be resolved."
    )

    static func custom(
        id: UUID = UUID(),
        displayName: String,
        familyLabel: String,
        supportedCaliberNames: [String] = [],
        compatibleFirearmTypes: [FirearmType] = [],
        compatibleFirearmActions: [FirearmAction] = [],
        platformTags: [String] = [],
        fitDescriptors: [String] = [],
        aliases: [String] = [],
        notes: String? = nil
    ) -> MagazinePattern {
        let resolvedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedFamilyLabel = familyLabel.trimmingCharacters(in: .whitespacesAndNewlines)

        return MagazinePattern(
            id: "\(customPrefix)\(id.uuidString.lowercased())",
            kind: .custom,
            displayName: resolvedDisplayName.isEmpty ? "Custom Pattern" : resolvedDisplayName,
            familyLabel: resolvedFamilyLabel.isEmpty ? (resolvedDisplayName.isEmpty ? "Custom Pattern" : resolvedDisplayName) : resolvedFamilyLabel,
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: supportedCaliberNames,
                compatibleFirearmTypes: compatibleFirearmTypes,
                compatibleFirearmActions: compatibleFirearmActions,
                platformTags: platformTags,
                fitDescriptors: fitDescriptors
            ),
            aliases: aliases,
            notes: notes
        )
    }

    static func legacy(
        displayName: String,
        familyLabel: String? = nil,
        supportedCaliberNames: [String] = [],
        compatibleFirearmTypes: [FirearmType] = [],
        compatibleFirearmActions: [FirearmAction] = [],
        platformTags: [String] = [],
        fitDescriptors: [String] = [],
        notes: String? = nil
    ) -> MagazinePattern {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedDisplayName.isEmpty ? "Legacy Pattern" : trimmedDisplayName
        let normalizedID = normalize(resolvedName)
        let legacyID = normalizedID.isEmpty ? fallbackLegacyID(for: resolvedName) : normalizedID

        return MagazinePattern(
            id: "\(legacyPrefix)\(legacyID)",
            kind: .legacy,
            displayName: resolvedName,
            familyLabel: familyLabel ?? resolvedName,
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: supportedCaliberNames,
                compatibleFirearmTypes: compatibleFirearmTypes,
                compatibleFirearmActions: compatibleFirearmActions,
                platformTags: platformTags,
                fitDescriptors: fitDescriptors
            ),
            aliases: [],
            notes: notes
        )
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: normalizationLocale)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func fallbackLegacyID(for value: String) -> String {
        let scalarFingerprint = value.unicodeScalars
            .map { String(format: "%04x", $0.value) }
            .joined(separator: "")

        if scalarFingerprint.isEmpty {
            return "legacy-empty"
        }

        return "legacy-\(scalarFingerprint)"
    }
}

enum MagazinePatternCatalog {
    static let canonicalPatterns: [MagazinePattern] = [
        MagazinePattern(
            id: "catalog:ar15-stanag-223-556-300blk",
            kind: .catalog,
            displayName: "AR-15 STANAG",
            familyLabel: "AR-15 STANAG",
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: [".223 Rem", "5.56 NATO", ".300 Blackout"],
                compatibleFirearmTypes: [.rifle],
                compatibleFirearmActions: [.semiAuto, .selectFire],
                platformTags: ["AR-15", "STANAG", "AR-15 pattern lower"],
                fitDescriptors: ["standard rifle magazine", "straight-in STANAG magwell"]
            ),
            aliases: ["STANAG AR-15", "AR-15 PMAG", "GI AR-15"],
            notes: "Standard AR-15 magazine family shared across .223 Rem, 5.56 NATO, and .300 Blackout platforms."
        ),
        MagazinePattern(
            id: "catalog:glock-double-stack-9mm-full-size-compact",
            kind: .catalog,
            displayName: "Glock Double-Stack 9mm Full-Size",
            familyLabel: "Glock Double-Stack 9mm",
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: ["9mm"],
                compatibleFirearmTypes: [.pistol],
                compatibleFirearmActions: [.semiAuto],
                platformTags: ["Glock 17", "Glock 19", "Glock 34", "Glock 45"],
                fitDescriptors: ["full-size body", "fits full-size and compact Glock-pattern frames"]
            ),
            aliases: ["G17/G19 9mm", "Glock OEM 17-round", "Glock full-size 9mm"],
            notes: "Longer Glock-pattern 9mm magazines that work in both full-size and compact frames."
        ),
        MagazinePattern(
            id: "catalog:glock-double-stack-9mm-compact",
            kind: .catalog,
            displayName: "Glock Double-Stack 9mm Compact",
            familyLabel: "Glock Double-Stack 9mm",
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: ["9mm"],
                compatibleFirearmTypes: [.pistol],
                compatibleFirearmActions: [.semiAuto],
                platformTags: ["Glock 19", "Glock 26", "Glock 49"],
                fitDescriptors: ["compact body", "compact-only Glock-pattern frames"]
            ),
            aliases: ["G19-only 9mm", "Glock OEM 15-round", "Glock compact 9mm"],
            notes: "Shorter Glock-pattern 9mm magazines that do not fit the same set of firearms as full-size bodies."
        ),
        MagazinePattern(
            id: "catalog:sig-p320-double-stack-9mm",
            kind: .catalog,
            displayName: "SIG P320 9mm",
            familyLabel: "SIG P320 9mm",
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: ["9mm"],
                compatibleFirearmTypes: [.pistol],
                compatibleFirearmActions: [.semiAuto],
                platformTags: ["SIG P320", "SIG M17", "SIG M18", "AXG Pro"],
                fitDescriptors: ["double-stack service pistol body"]
            ),
            aliases: ["P320 9mm", "M17/M18 9mm", "SIG 320 full-size 9mm"],
            notes: "Double-stack SIG P320 family magazines."
        ),
        MagazinePattern(
            id: "catalog:2011-double-stack-9mm",
            kind: .catalog,
            displayName: "2011 / Double-Stack 1911 9mm",
            familyLabel: "2011 / Double-Stack 1911 9mm",
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: ["9mm"],
                compatibleFirearmTypes: [.pistol],
                compatibleFirearmActions: [.semiAuto],
                platformTags: ["2011", "Staccato", "Atlas", "double-stack 1911"],
                fitDescriptors: ["double-stack 1911 grip module", "2011 pattern"]
            ),
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

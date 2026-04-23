//
//  MagazinePatternMigration.swift
//  Armory Inventory
//
//  Created by Codex on 4/22/26.
//

import Foundation
import SwiftData

struct MagazinePatternMigration {
    nonisolated private static let ignoredMatchTokens: Set<String> = [
        "12",
        "22",
        "223",
        "300",
        "308",
        "40",
        "45",
        "556",
        "65",
        "762x39",
        "9mm",
        "acp",
        "body",
        "blackout",
        "compact",
        "creedmoor",
        "double",
        "fits",
        "frame",
        "frames",
        "full",
        "gauge",
        "magazine",
        "magazines",
        "nato",
        "oem",
        "only",
        "pattern",
        "pistol",
        "rem",
        "round",
        "service",
        "size",
        "stack",
        "sw",
        "win"
    ]

    private struct StoredPatternData {
        let id: String
        let kind: MagazinePatternKind
        let displayName: String?
    }

    @discardableResult
    static func backfillMissingPatterns(in context: ModelContext) -> Bool {
        guard let magazines = try? context.fetch(FetchDescriptor<Magazine>()) else {
            return false
        }

        var didChange = false

        for magazine in magazines where needsBackfill(magazine) {
            applyResolvedPattern(to: magazine)
            didChange = true
        }

        return didChange
    }

    static func applyResolvedPattern(to magazine: Magazine) {
        let storedPattern = resolvedStoredPatternData(for: magazine)
        magazine.patternID = storedPattern.id
        magazine.patternKind = storedPattern.kind.rawValue
        magazine.patternDisplayName = storedPattern.displayName
    }

    static func resolvedPattern(for magazine: Magazine) -> MagazinePattern {
        let caliberNames = supportedCaliberNames(for: magazine)
        let firearmTypes = compatibleFirearmTypes(for: magazine)
        let firearmActions = compatibleFirearmActions(for: magazine)

        switch magazine.storedPatternKind {
        case .catalog:
            if let patternID = magazine.patternID,
               let pattern = MagazinePatternCatalog.pattern(id: patternID) {
                return pattern
            }
        case .legacy:
            return MagazinePattern.legacy(
                displayName: magazine.patternDisplayName ?? legacyDisplayName(for: magazine),
                familyLabel: magazine.patternDisplayName ?? legacyDisplayName(for: magazine),
                supportedCaliberNames: caliberNames,
                compatibleFirearmTypes: firearmTypes,
                compatibleFirearmActions: firearmActions,
                platformTags: legacyPlatformTags(for: magazine)
            )
        case .unknown:
            return .unknown
        case .custom:
            return MagazinePattern.custom(
                id: customPatternUUID(from: magazine.patternID),
                displayName: magazine.patternDisplayName ?? legacyDisplayName(for: magazine),
                familyLabel: magazine.patternDisplayName ?? legacyDisplayName(for: magazine),
                supportedCaliberNames: caliberNames,
                compatibleFirearmTypes: firearmTypes,
                compatibleFirearmActions: firearmActions,
                platformTags: legacyPlatformTags(for: magazine)
            )
        case nil:
            break
        }

        return inferredPattern(for: magazine)
    }

    private static func needsBackfill(_ magazine: Magazine) -> Bool {
        guard let patternID = magazine.patternID, !patternID.isEmpty,
              let kind = magazine.storedPatternKind else {
            return true
        }

        switch kind {
        case .catalog:
            return MagazinePatternCatalog.pattern(id: patternID) == nil
        case .legacy, .custom:
            return (magazine.patternDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case .unknown:
            return false
        }
    }

    private static func resolvedStoredPatternData(for magazine: Magazine) -> StoredPatternData {
        let pattern = inferredPattern(for: magazine)

        switch pattern.kind {
        case .catalog, .unknown:
            return StoredPatternData(
                id: pattern.id,
                kind: pattern.kind,
                displayName: nil
            )
        case .legacy, .custom:
            return StoredPatternData(
                id: pattern.id,
                kind: pattern.kind,
                displayName: pattern.displayName
            )
        }
    }

    private static func inferredPattern(for magazine: Magazine) -> MagazinePattern {
        if let catalogPattern = inferredCatalogPattern(for: magazine) {
            return catalogPattern
        }

        if legacyDisplayName(for: magazine).isEmpty {
            return .unknown
        }

        return MagazinePattern.legacy(
            displayName: legacyDisplayName(for: magazine),
            familyLabel: legacyDisplayName(for: magazine),
            supportedCaliberNames: supportedCaliberNames(for: magazine),
            compatibleFirearmTypes: compatibleFirearmTypes(for: magazine),
            compatibleFirearmActions: compatibleFirearmActions(for: magazine),
            platformTags: legacyPlatformTags(for: magazine)
        )
    }

    private static func inferredCatalogPattern(for magazine: Magazine) -> MagazinePattern? {
        let caliberName = primaryCaliberName(for: magazine)
        if caliberName == nil, magazine.firearm == nil {
            return nil
        }

        let candidates: [MagazinePattern]
        if let firearm = magazine.firearm {
            candidates = MagazinePatternCatalog.suggestedPatterns(
                firearmType: firearm.firearmType,
                action: firearm.firearmAction,
                caliberName: caliberName
            )
        } else {
            candidates = MagazinePatternCatalog.canonicalPatterns.filter { pattern in
                guard let caliberName else {
                    return true
                }

                return pattern.supports(caliberName: caliberName)
            }
        }

        guard !candidates.isEmpty else {
            return nil
        }

        if candidates.count == 1 {
            return candidates.first
        }

        let scoredCandidates = candidates
            .map { (pattern: $0, score: matchScore(for: $0, magazine: magazine)) }
            .sorted {
                if $0.score == $1.score {
                    return $0.pattern.id < $1.pattern.id
                }

                return $0.score > $1.score
            }

        guard let best = scoredCandidates.first,
              best.score > 0 else {
            return nil
        }

        if scoredCandidates.count > 1, scoredCandidates[1].score == best.score {
            return nil
        }

        return best.pattern
    }

    private static func matchScore(for pattern: MagazinePattern, magazine: Magazine) -> Int {
        let haystack = Set(searchTokens(for: magazine))
        var matchedTokens = Set<String>()

        for value in pattern.aliases + pattern.compatibility.platformTags {
            let tokens = normalizedTokens(from: value)
            guard !tokens.isEmpty else {
                continue
            }

            matchedTokens.formUnion(haystack.intersection(tokens))
        }

        var score = matchedTokens.count

        if let firearm = magazine.firearm,
           magazine.brand.localizedCaseInsensitiveContains("glock") {
            switch pattern.id {
            case "catalog:glock-double-stack-9mm-full-size-compact" where firearm.brand.localizedCaseInsensitiveContains("glock") && magazine.capacity >= 17:
                score += 3
            case "catalog:glock-double-stack-9mm-compact" where firearm.brand.localizedCaseInsensitiveContains("glock") && magazine.capacity <= 15:
                score += 3
            default:
                break
            }
        }

        return score
    }

    private static func searchTokens(for magazine: Magazine) -> [String] {
        var values = [
            magazine.brand,
            magazine.modelName,
            magazine.notes ?? "",
            magazine.caliber?.name ?? "",
            String(magazine.capacity),
            "\(magazine.capacity)-round"
        ]

        if let firearm = magazine.firearm {
            values.append(contentsOf: [
                firearm.brand,
                firearm.modelName,
                firearm.nickname ?? "",
                firearm.caliber?.name ?? ""
            ])
        }

        return values.flatMap(normalizedTokens(from:))
    }

    nonisolated private static func normalizedTokens(from value: String) -> [String] {
        let normalizedValue = normalizedString(value)
        guard !normalizedValue.isEmpty else {
            return []
        }

        return normalizedValue
            .split(separator: "-")
            .map(String.init)
            .filter { token in
                token.count >= 2 &&
                !ignoredMatchTokens.contains(token) &&
                token.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
            }
    }

    nonisolated private static func normalizedString(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func primaryCaliberName(for magazine: Magazine) -> String? {
        let names = supportedCaliberNames(for: magazine)
        return names.first
    }

    private static func supportedCaliberNames(for magazine: Magazine) -> [String] {
        if let caliberName = magazine.caliber?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           !caliberName.isEmpty {
            return [caliberName]
        }

        if let caliberName = magazine.firearm?.caliber?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           !caliberName.isEmpty {
            return [caliberName]
        }

        return []
    }

    private static func compatibleFirearmTypes(for magazine: Magazine) -> [FirearmType] {
        guard let firearm = magazine.firearm else {
            return []
        }

        return [firearm.firearmType]
    }

    private static func compatibleFirearmActions(for magazine: Magazine) -> [FirearmAction] {
        guard let firearm = magazine.firearm else {
            return []
        }

        return [firearm.firearmAction]
    }

    private static func legacyDisplayName(for magazine: Magazine) -> String {
        magazine.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func legacyPlatformTags(for magazine: Magazine) -> [String] {
        guard let firearm = magazine.firearm else {
            return []
        }

        return [firearm.displayName]
    }

    private static func customPatternUUID(from patternID: String?) -> UUID {
        guard let patternID,
              patternID.hasPrefix("custom:") else {
            return UUID()
        }

        let rawValue = String(patternID.dropFirst("custom:".count))
        return UUID(uuidString: rawValue) ?? UUID()
    }
}

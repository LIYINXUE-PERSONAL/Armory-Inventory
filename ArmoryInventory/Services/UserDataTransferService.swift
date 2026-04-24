//
//  UserDataTransferService.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

protocol UserDataTransferServicing {
    @MainActor
    func exportData(from context: ModelContext) throws -> Data

    @MainActor
    func importData(_ data: Data, into context: ModelContext) throws

    @MainActor
    func clearAllData(in context: ModelContext) throws
}

enum UserDataTransferError: LocalizedError {
    case invalidBackupFile
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBackupFile:
            return "The selected file is not a valid Armory Inventory backup."
        case let .unsupportedVersion(version):
            return "This backup format version (\(version)) is not supported."
        }
    }
}

final class UserDataTransferService: UserDataTransferServicing {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    @MainActor
    func exportData(from context: ModelContext) throws -> Data {
        try encoder.encode(makeSnapshot(from: context))
    }

    @MainActor
    func importData(_ data: Data, into context: ModelContext) throws {
        let snapshot: UserDataSnapshot
        do {
            snapshot = try decoder.decode(UserDataSnapshot.self, from: data)
        } catch {
            throw UserDataTransferError.invalidBackupFile
        }

        guard snapshot.version == UserDataSnapshot.currentVersion else {
            throw UserDataTransferError.unsupportedVersion(snapshot.version)
        }

        try replaceData(with: snapshot, in: context)
    }

    @MainActor
    func clearAllData(in context: ModelContext) throws {
        try deleteExistingData(in: context)
        apply(settings: [:])
    }

    @MainActor
    private func makeSnapshot(from context: ModelContext) throws -> UserDataSnapshot {
        let calibers = try context.fetch(FetchDescriptor<Caliber>(sortBy: [SortDescriptor(\.name)]))
        let ammoTypes = try context.fetch(FetchDescriptor<AmmoType>())
        let records = try context.fetch(FetchDescriptor<AmmoAdjustmentRecord>(sortBy: [SortDescriptor(\.occurredAt)]))
        let firearms = try context.fetch(FetchDescriptor<Firearm>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
        let optics = try context.fetch(FetchDescriptor<Optic>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
        let magazines = try context.fetch(FetchDescriptor<Magazine>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
        let attachments = try context.fetch(FetchDescriptor<Attachment>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
        let parts = try context.fetch(FetchDescriptor<Part>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))

        var ammoIdentifiers: [ObjectIdentifier: UUID] = [:]
        let ammoSnapshots = ammoTypes.map { ammo -> AmmoTypeSnapshot in
            let backupID = UUID()
            ammoIdentifiers[ObjectIdentifier(ammo)] = backupID
            return AmmoTypeSnapshot(
                backupID: backupID,
                brand: ammo.brand,
                productName: ammo.productName,
                bulletType: ammo.bulletType,
                grain: ammo.grain,
                loadDetail: ammo.loadDetail,
                quantity: ammo.quantity,
                centsPerRound: ammo.centsPerRound,
                caliberName: ammo.caliber?.name
            )
        }

        let recordSnapshots = records.map { record in
            AmmoAdjustmentRecordSnapshot(
                quantity: record.quantity,
                occurredAt: record.occurredAt,
                kind: record.kind,
                caliberName: record.caliber?.name,
                ammoBackupID: record.ammoType.flatMap { ammoIdentifiers[ObjectIdentifier($0)] }
            )
        }

        return UserDataSnapshot(
            exportedAt: .now,
            settings: managedSettingsSnapshot(),
            calibers: calibers.map { CaliberSnapshot(name: $0.name) },
            ammoTypes: ammoSnapshots,
            ammoAdjustmentRecords: recordSnapshots,
            firearms: firearms.map {
                FirearmSnapshot(
                    id: $0.id ?? UUID(),
                    brand: $0.brand,
                    modelName: $0.modelName,
                    nickname: $0.nickname,
                    serialNumber: $0.serialNumber,
                    purchaseDate: $0.purchaseDate,
                    purchasePriceCents: $0.purchasePriceCents,
                    type: $0.type,
                    action: $0.action,
                    actionDetail: $0.actionDetail,
                    color: $0.color,
                    colorDetail: $0.colorDetail,
                    barrelLengthInches: $0.barrelLengthInches,
                    notes: $0.notes,
                    supportedMagazinePatterns: $0.supportedMagazinePatterns,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    caliberName: $0.caliber?.name
                )
            },
            optics: optics.map {
                OpticSnapshot(
                    id: $0.id ?? UUID(),
                    brand: $0.brand,
                    modelName: $0.modelName,
                    type: $0.type,
                    serialNumber: $0.serialNumber,
                    minMagnification: $0.minMagnification,
                    maxMagnification: $0.maxMagnification,
                    footprint: $0.footprint,
                    footprintDetail: $0.footprintDetail,
                    tubeSizeMillimeters: $0.tubeSizeMillimeters,
                    reticle: $0.reticle,
                    focalPlane: $0.focalPlane,
                    isIlluminated: $0.isIlluminated,
                    color: $0.color,
                    colorDetail: $0.colorDetail,
                    purchaseDate: $0.purchaseDate,
                    purchasePriceCents: $0.purchasePriceCents,
                    notes: $0.notes,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    firearmID: $0.firearm?.id
                )
            },
            magazines: magazines.map {
                MagazineSnapshot(
                    id: $0.id ?? UUID(),
                    brand: $0.brand,
                    modelName: $0.modelName,
                    patternID: $0.patternID,
                    patternKind: $0.patternKind,
                    patternDisplayName: $0.patternDisplayName,
                    patternSupportedCaliberNames: $0.storedPatternSupportedCaliberNames,
                    count: $0.count,
                    capacity: $0.capacity,
                    purchaseDate: $0.purchaseDate,
                    purchasePriceCents: $0.purchasePriceCents,
                    color: $0.color,
                    colorDetail: $0.colorDetail,
                    notes: $0.notes,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    caliberName: $0.caliber?.name,
                    firearmID: $0.firearm?.id
                )
            },
            attachments: attachments.map {
                AttachmentSnapshot(
                    id: $0.id ?? UUID(),
                    brand: $0.brand,
                    modelName: $0.modelName,
                    type: $0.type,
                    typeDetail: $0.typeDetail,
                    color: $0.color,
                    colorDetail: $0.colorDetail,
                    purchaseDate: $0.purchaseDate,
                    purchasePriceCents: $0.purchasePriceCents,
                    notes: $0.notes,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    firearmID: $0.firearm?.id
                )
            },
            parts: parts.map {
                PartSnapshot(
                    id: $0.id ?? UUID(),
                    brand: $0.brand,
                    modelName: $0.modelName,
                    type: $0.type,
                    typeDetail: $0.typeDetail,
                    color: $0.color,
                    colorDetail: $0.colorDetail,
                    purchaseDate: $0.purchaseDate,
                    purchasePriceCents: $0.purchasePriceCents,
                    notes: $0.notes,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    firearmID: $0.firearm?.id
                )
            }
        )
    }

    @MainActor
    private func replaceData(with snapshot: UserDataSnapshot, in context: ModelContext) throws {
        try deleteExistingData(in: context)

        let calibers = snapshot.calibers.reduce(into: [String: Caliber]()) { result, snapshot in
            let caliber = Caliber(name: snapshot.name)
            context.insert(caliber)
            result[snapshot.name] = caliber
        }

        let firearms = snapshot.firearms.reduce(into: [UUID: Firearm]()) { result, snapshot in
            let firearm = Firearm(
                id: snapshot.id,
                brand: snapshot.brand,
                modelName: snapshot.modelName,
                nickname: snapshot.nickname,
                serialNumber: snapshot.serialNumber,
                purchaseDate: snapshot.purchaseDate,
                purchasePriceCents: snapshot.purchasePriceCents,
                type: FirearmType(rawValue: snapshot.type) ?? .other,
                action: FirearmAction(rawValue: snapshot.action) ?? .other,
                actionDetail: snapshot.actionDetail,
                color: snapshot.color.flatMap(FirearmColor.init(rawValue:)),
                colorDetail: snapshot.colorDetail,
                barrelLengthInches: snapshot.barrelLengthInches,
                notes: snapshot.notes,
                supportedMagazinePatterns: snapshot.supportedMagazinePatterns,
                caliber: snapshot.caliberName.flatMap { calibers[$0] },
                sortOrder: snapshot.sortOrder,
                createdAt: snapshot.createdAt
            )
            context.insert(firearm)
            result[snapshot.id] = firearm
        }

        let ammoTypes = snapshot.ammoTypes.reduce(into: [UUID: AmmoType]()) { result, snapshot in
            let ammoType = AmmoType(
                brand: snapshot.brand,
                productName: snapshot.productName,
                bulletType: snapshot.bulletType,
                grain: snapshot.grain,
                loadDetail: snapshot.loadDetail,
                quantity: snapshot.quantity,
                centsPerRound: snapshot.centsPerRound,
                caliber: snapshot.caliberName.flatMap { calibers[$0] }
            )
            context.insert(ammoType)
            result[snapshot.backupID] = ammoType
        }

        for snapshot in snapshot.optics {
            let optic = Optic(
                id: snapshot.id,
                brand: snapshot.brand,
                modelName: snapshot.modelName,
                type: OpticType(rawValue: snapshot.type) ?? .other,
                serialNumber: snapshot.serialNumber,
                minMagnification: snapshot.minMagnification,
                maxMagnification: snapshot.maxMagnification,
                footprint: OpticFootprint(rawValue: snapshot.footprint) ?? .other,
                footprintDetail: snapshot.footprintDetail,
                tubeSizeMillimeters: snapshot.tubeSizeMillimeters,
                reticle: snapshot.reticle,
                focalPlane: snapshot.focalPlane.flatMap(OpticFocalPlane.init(rawValue:)),
                isIlluminated: snapshot.isIlluminated,
                color: snapshot.color.flatMap(FirearmColor.init(rawValue:)),
                colorDetail: snapshot.colorDetail,
                purchaseDate: snapshot.purchaseDate,
                purchasePriceCents: snapshot.purchasePriceCents,
                notes: snapshot.notes,
                firearm: snapshot.firearmID.flatMap { firearms[$0] },
                sortOrder: snapshot.sortOrder,
                createdAt: snapshot.createdAt
            )
            context.insert(optic)
        }

        for snapshot in snapshot.magazines {
            let magazine = Magazine(
                id: snapshot.id,
                brand: snapshot.brand,
                modelName: snapshot.modelName,
                patternID: snapshot.patternID,
                patternKind: snapshot.patternKind.flatMap(MagazinePatternKind.init(rawValue:)),
                patternDisplayName: snapshot.patternDisplayName,
                patternSupportedCaliberNames: snapshot.patternSupportedCaliberNames ?? [],
                count: snapshot.count,
                capacity: snapshot.capacity,
                purchaseDate: snapshot.purchaseDate,
                purchasePriceCents: snapshot.purchasePriceCents,
                color: snapshot.color.flatMap(FirearmColor.init(rawValue:)),
                colorDetail: snapshot.colorDetail,
                notes: snapshot.notes,
                caliber: snapshot.caliberName.flatMap { calibers[$0] },
                firearm: snapshot.firearmID.flatMap { firearms[$0] },
                sortOrder: snapshot.sortOrder,
                createdAt: snapshot.createdAt
            )
            context.insert(magazine)
        }

        _ = MagazinePatternMigration.backfillMissingPatterns(in: context)

        for snapshot in snapshot.attachments {
            let attachment = Attachment(
                id: snapshot.id,
                brand: snapshot.brand,
                modelName: snapshot.modelName,
                type: AttachmentType(rawValue: snapshot.type) ?? .other,
                typeDetail: snapshot.typeDetail,
                color: snapshot.color.flatMap(FirearmColor.init(rawValue:)),
                colorDetail: snapshot.colorDetail,
                purchaseDate: snapshot.purchaseDate,
                purchasePriceCents: snapshot.purchasePriceCents,
                notes: snapshot.notes,
                firearm: snapshot.firearmID.flatMap { firearms[$0] },
                sortOrder: snapshot.sortOrder,
                createdAt: snapshot.createdAt
            )
            context.insert(attachment)
        }

        for snapshot in snapshot.parts {
            let part = Part(
                id: snapshot.id,
                brand: snapshot.brand,
                modelName: snapshot.modelName,
                type: PartType(rawValue: snapshot.type) ?? .other,
                typeDetail: snapshot.typeDetail,
                color: snapshot.color.flatMap(FirearmColor.init(rawValue:)),
                colorDetail: snapshot.colorDetail,
                purchaseDate: snapshot.purchaseDate,
                purchasePriceCents: snapshot.purchasePriceCents,
                notes: snapshot.notes,
                firearm: snapshot.firearmID.flatMap { firearms[$0] },
                sortOrder: snapshot.sortOrder,
                createdAt: snapshot.createdAt
            )
            context.insert(part)
        }

        for snapshot in snapshot.ammoAdjustmentRecords {
            let record = AmmoAdjustmentRecord(
                quantity: snapshot.quantity,
                occurredAt: snapshot.occurredAt,
                kind: AmmoAdjustmentKind(rawValue: snapshot.kind) ?? .consumption,
                caliber: snapshot.caliberName.flatMap { calibers[$0] },
                ammoType: snapshot.ammoBackupID.flatMap { ammoTypes[$0] }
            )
            context.insert(record)
        }

        try context.save()
        apply(settings: snapshot.settings)
    }

    @MainActor
    private func deleteExistingData(in context: ModelContext) throws {
        try deleteAll(FetchDescriptor<AmmoAdjustmentRecord>(), in: context)
        try deleteAll(FetchDescriptor<Attachment>(), in: context)
        try deleteAll(FetchDescriptor<Part>(), in: context)
        try deleteAll(FetchDescriptor<Magazine>(), in: context)
        try deleteAll(FetchDescriptor<Optic>(), in: context)
        try deleteAll(FetchDescriptor<Firearm>(), in: context)
        try deleteAll(FetchDescriptor<AmmoType>(), in: context)
        try deleteAll(FetchDescriptor<Caliber>(), in: context)
        try context.save()
    }

    @MainActor
    private func deleteAll<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>, in context: ModelContext) throws {
        for model in try context.fetch(descriptor) {
            context.delete(model)
        }
    }

    private func managedSettingsSnapshot() -> [String: SettingValue] {
        InventorySettingsKeys.managedUserDataKeys.reduce(into: [:]) { result, key in
            if let value = settingValue(for: key) {
                result[key] = value
            }
        }
    }

    private func apply(settings: [String: SettingValue]) {
        for key in InventorySettingsKeys.managedUserDataKeys {
            userDefaults.removeObject(forKey: key)
        }

        for (key, value) in settings {
            switch value {
            case let .bool(value):
                userDefaults.set(value, forKey: key)
            case let .double(value):
                userDefaults.set(value, forKey: key)
            case let .int(value):
                userDefaults.set(value, forKey: key)
            case let .string(value):
                userDefaults.set(value, forKey: key)
            case let .stringArray(value):
                userDefaults.set(value, forKey: key)
            case let .date(value):
                userDefaults.set(value, forKey: key)
            }
        }
    }

    private func settingValue(for key: String) -> SettingValue? {
        let object = userDefaults.object(forKey: key)

        switch object {
        case let value as Bool:
            return .bool(value)
        case let value as Double:
            return .double(value)
        case let value as Int:
            return .int(value)
        case let value as String:
            return .string(value)
        case let value as [String]:
            return .stringArray(value)
        case let value as Date:
            return .date(value)
        default:
            return nil
        }
    }
}

private struct UserDataSnapshot: Codable {
    static let currentVersion = 1

    private enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case settings
        case calibers
        case ammoTypes
        case ammoAdjustmentRecords
        case firearms
        case optics
        case magazines
        case attachments
        case parts
    }

    let version: Int
    let exportedAt: Date
    let settings: [String: SettingValue]
    let calibers: [CaliberSnapshot]
    let ammoTypes: [AmmoTypeSnapshot]
    let ammoAdjustmentRecords: [AmmoAdjustmentRecordSnapshot]
    let firearms: [FirearmSnapshot]
    let optics: [OpticSnapshot]
    let magazines: [MagazineSnapshot]
    let attachments: [AttachmentSnapshot]
    let parts: [PartSnapshot]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        settings = try container.decode([String: SettingValue].self, forKey: .settings)
        calibers = try container.decode([CaliberSnapshot].self, forKey: .calibers)
        ammoTypes = try container.decode([AmmoTypeSnapshot].self, forKey: .ammoTypes)
        ammoAdjustmentRecords = try container.decode([AmmoAdjustmentRecordSnapshot].self, forKey: .ammoAdjustmentRecords)
        firearms = try container.decode([FirearmSnapshot].self, forKey: .firearms)
        optics = try container.decode([OpticSnapshot].self, forKey: .optics)
        magazines = try container.decode([MagazineSnapshot].self, forKey: .magazines)
        attachments = try container.decode([AttachmentSnapshot].self, forKey: .attachments)
        parts = try container.decodeIfPresent([PartSnapshot].self, forKey: .parts) ?? []
    }

    init(
        version: Int = currentVersion,
        exportedAt: Date,
        settings: [String: SettingValue],
        calibers: [CaliberSnapshot],
        ammoTypes: [AmmoTypeSnapshot],
        ammoAdjustmentRecords: [AmmoAdjustmentRecordSnapshot],
        firearms: [FirearmSnapshot],
        optics: [OpticSnapshot],
        magazines: [MagazineSnapshot],
        attachments: [AttachmentSnapshot],
        parts: [PartSnapshot]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.settings = settings
        self.calibers = calibers
        self.ammoTypes = ammoTypes
        self.ammoAdjustmentRecords = ammoAdjustmentRecords
        self.firearms = firearms
        self.optics = optics
        self.magazines = magazines
        self.attachments = attachments
        self.parts = parts
    }
}

private struct CaliberSnapshot: Codable {
    let name: String
}

private struct AmmoTypeSnapshot: Codable {
    let backupID: UUID
    let brand: String
    let productName: String?
    let bulletType: String
    let grain: Int
    let loadDetail: String?
    let quantity: Int
    let centsPerRound: Int
    let caliberName: String?
}

private struct AmmoAdjustmentRecordSnapshot: Codable {
    let quantity: Int
    let occurredAt: Date
    let kind: String
    let caliberName: String?
    let ammoBackupID: UUID?
}

private struct FirearmSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case brand
        case modelName
        case nickname
        case serialNumber
        case purchaseDate
        case purchasePriceCents
        case type
        case action
        case actionDetail
        case color
        case colorDetail
        case barrelLengthInches
        case notes
        case supportedMagazinePatterns
        case sortOrder
        case createdAt
        case caliberName
    }

    let id: UUID
    let brand: String
    let modelName: String
    let nickname: String?
    let serialNumber: String?
    let purchaseDate: Date
    let purchasePriceCents: Int
    let type: String
    let action: String
    let actionDetail: String?
    let color: String?
    let colorDetail: String?
    let barrelLengthInches: Double?
    let notes: String?
    let supportedMagazinePatterns: [FirearmMagazinePatternReference]
    let sortOrder: Int
    let createdAt: Date
    let caliberName: String?

    init(
        id: UUID,
        brand: String,
        modelName: String,
        nickname: String?,
        serialNumber: String?,
        purchaseDate: Date,
        purchasePriceCents: Int,
        type: String,
        action: String,
        actionDetail: String?,
        color: String?,
        colorDetail: String?,
        barrelLengthInches: Double?,
        notes: String?,
        supportedMagazinePatterns: [FirearmMagazinePatternReference],
        sortOrder: Int,
        createdAt: Date,
        caliberName: String?
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.nickname = nickname
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.purchasePriceCents = purchasePriceCents
        self.type = type
        self.action = action
        self.actionDetail = actionDetail
        self.color = color
        self.colorDetail = colorDetail
        self.barrelLengthInches = barrelLengthInches
        self.notes = notes
        self.supportedMagazinePatterns = supportedMagazinePatterns
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.caliberName = caliberName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        brand = try container.decode(String.self, forKey: .brand)
        modelName = try container.decode(String.self, forKey: .modelName)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        serialNumber = try container.decodeIfPresent(String.self, forKey: .serialNumber)
        purchaseDate = try container.decode(Date.self, forKey: .purchaseDate)
        purchasePriceCents = try container.decode(Int.self, forKey: .purchasePriceCents)
        type = try container.decode(String.self, forKey: .type)
        action = try container.decode(String.self, forKey: .action)
        actionDetail = try container.decodeIfPresent(String.self, forKey: .actionDetail)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        colorDetail = try container.decodeIfPresent(String.self, forKey: .colorDetail)
        barrelLengthInches = try container.decodeIfPresent(Double.self, forKey: .barrelLengthInches)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        supportedMagazinePatterns = try container.decodeIfPresent([FirearmMagazinePatternReference].self, forKey: .supportedMagazinePatterns) ?? []
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        caliberName = try container.decodeIfPresent(String.self, forKey: .caliberName)
    }
}

private struct OpticSnapshot: Codable {
    let id: UUID
    let brand: String
    let modelName: String
    let type: String
    let serialNumber: String?
    let minMagnification: Double
    let maxMagnification: Double
    let footprint: String
    let footprintDetail: String?
    let tubeSizeMillimeters: Double?
    let reticle: String?
    let focalPlane: String?
    let isIlluminated: Bool
    let color: String?
    let colorDetail: String?
    let purchaseDate: Date
    let purchasePriceCents: Int
    let notes: String?
    let sortOrder: Int
    let createdAt: Date
    let firearmID: UUID?
}

private struct MagazineSnapshot: Codable {
    let id: UUID
    let brand: String
    let modelName: String
    let patternID: String?
    let patternKind: String?
    let patternDisplayName: String?
    let patternSupportedCaliberNames: [String]?
    let count: Int
    let capacity: Int
    let purchaseDate: Date
    let purchasePriceCents: Int
    let color: String?
    let colorDetail: String?
    let notes: String?
    let sortOrder: Int
    let createdAt: Date
    let caliberName: String?
    let firearmID: UUID?
}

private struct AttachmentSnapshot: Codable {
    let id: UUID
    let brand: String
    let modelName: String
    let type: String
    let typeDetail: String?
    let color: String?
    let colorDetail: String?
    let purchaseDate: Date
    let purchasePriceCents: Int
    let notes: String?
    let sortOrder: Int
    let createdAt: Date
    let firearmID: UUID?
}

private struct PartSnapshot: Codable {
    let id: UUID
    let brand: String
    let modelName: String
    let type: String
    let typeDetail: String?
    let color: String?
    let colorDetail: String?
    let purchaseDate: Date
    let purchasePriceCents: Int
    let notes: String?
    let sortOrder: Int
    let createdAt: Date
    let firearmID: UUID?
}

private enum SettingValue: Codable {
    case bool(Bool)
    case double(Double)
    case int(Int)
    case string(String)
    case stringArray([String])
    case date(Date)

    private enum CodingKeys: String, CodingKey {
        case type
        case bool
        case double
        case int
        case string
        case stringArray
        case date
    }

    private enum ValueType: String, Codable {
        case bool
        case double
        case int
        case string
        case stringArray
        case date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ValueType.self, forKey: .type) {
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .bool))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .double))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .int))
        case .string:
            self = .string(try container.decode(String.self, forKey: .string))
        case .stringArray:
            self = .stringArray(try container.decode([String].self, forKey: .stringArray))
        case .date:
            self = .date(try container.decode(Date.self, forKey: .date))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .bool(value):
            try container.encode(ValueType.bool, forKey: .type)
            try container.encode(value, forKey: .bool)
        case let .double(value):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(value, forKey: .double)
        case let .int(value):
            try container.encode(ValueType.int, forKey: .type)
            try container.encode(value, forKey: .int)
        case let .string(value):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(value, forKey: .string)
        case let .stringArray(value):
            try container.encode(ValueType.stringArray, forKey: .type)
            try container.encode(value, forKey: .stringArray)
        case let .date(value):
            try container.encode(ValueType.date, forKey: .type)
            try container.encode(value, forKey: .date)
        }
    }
}

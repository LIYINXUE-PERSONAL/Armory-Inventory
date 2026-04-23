//
//  AddFirearmView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData
import UIKit

struct AddFirearmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true

    let firearm: Firearm?
    @State private var brand = ""
    @State private var modelName = ""
    @State private var nickname = ""
    @State private var serialNumber = ""
    @State private var purchaseDate = Date.now
    @State private var hasLastCleanedDate = false
    @State private var lastCleanedDate = Date.now
    @State private var purchasePriceText = "0.00"
    @State private var selectedType: FirearmType = .rifle
    @State private var selectedAction: FirearmAction = .semiAuto
    @State private var customAction = ""
    @State private var selectedColor: FirearmColor?
    @State private var customColor = ""
    @State private var barrelLengthText = ""
    @State private var notes = ""
    @State private var selectedCaliber: Caliber?
    @State private var selectedOpticIDs: Set<PersistentIdentifier> = []
    @State private var selectedMagazinePatterns: [FirearmMagazinePatternReference] = []
    @State private var selectedAttachmentIDs: Set<PersistentIdentifier> = []
    @State private var selectedPartIDs: Set<PersistentIdentifier> = []
    @State private var showingOpticsPicker = false
    @State private var showingMagazinePatternsPicker = false
    @State private var showingAttachmentsPicker = false
    @State private var showingPartsPicker = false
    @State private var showingAddCaliber = false
    @State private var isEditing = false
    @State private var lookupData = AddFirearmLookupData()
    @State private var snapshotErrorMessage: String?

    let viewModel: AddFirearmViewModel
    private let lookupService: AddFirearmLookupServicing
    private let taxRateProvider: InventoryTaxRateProviding

    init(
        firearm: Firearm? = nil,
        viewModel: AddFirearmViewModel,
        lookupService: AddFirearmLookupServicing = AppServices.shared.resolve(AddFirearmLookupServicing.self),
        taxRateProvider: InventoryTaxRateProviding = AppServices.shared.resolve(InventoryTaxRateProviding.self)
    ) {
        self.firearm = firearm
        self.viewModel = viewModel
        self.lookupService = lookupService
        self.taxRateProvider = taxRateProvider
        _brand = State(initialValue: firearm?.brand ?? "")
        _modelName = State(initialValue: firearm?.modelName ?? "")
        _nickname = State(initialValue: firearm?.nickname ?? "")
        _serialNumber = State(initialValue: firearm?.serialNumber ?? "")
        _purchaseDate = State(initialValue: firearm?.purchaseDate ?? .now)
        _hasLastCleanedDate = State(initialValue: firearm?.lastCleanedDate != nil)
        _lastCleanedDate = State(initialValue: firearm?.lastCleanedDate ?? .now)
        _purchasePriceText = State(initialValue: viewModel.initialPurchasePriceText(for: firearm))
        _selectedType = State(initialValue: firearm?.firearmType ?? .rifle)
        _selectedAction = State(initialValue: firearm?.firearmAction ?? .semiAuto)
        _customAction = State(initialValue: firearm?.firearmAction == .other ? firearm?.actionDetail ?? "" : "")
        _selectedColor = State(initialValue: firearm?.firearmColor)
        _customColor = State(initialValue: firearm?.firearmColor == .other ? firearm?.colorDetail ?? "" : "")
        _selectedCaliber = State(initialValue: firearm?.caliber)
        _selectedOpticIDs = State(initialValue: viewModel.selectedOpticIDs(for: firearm))
        _selectedMagazinePatterns = State(initialValue: viewModel.selectedMagazinePatterns(for: firearm))
        _selectedAttachmentIDs = State(initialValue: viewModel.selectedAttachmentIDs(for: firearm))
        _selectedPartIDs = State(initialValue: viewModel.selectedPartIDs(for: firearm))
        _barrelLengthText = State(initialValue: viewModel.initialBarrelLengthText(for: firearm))
        _notes = State(initialValue: firearm?.notes ?? "")
        _isEditing = State(initialValue: firearm == nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    LabeledContent("Brand") {
                        TextField("", text: $brand)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Model Name") {
                        TextField("", text: $modelName)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Nickname") {
                        TextField("Optional", text: $nickname)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Serial Number") {
                        TextField("Optional", text: $serialNumber)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                    }
                    if duplicateExists {
                        Text("That serial number already exists in your inventory.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .disabled(isReadOnly)

                Section("Configuration") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(FirearmType.allCases) { firearmType in
                            Text(firearmType.displayName).tag(firearmType)
                        }
                    }

                    LabeledContent("Caliber") {
                        Menu {
                            Button {
                                selectedCaliber = nil
                            } label: {
                                if selectedCaliber == nil {
                                    Label("None", systemImage: "checkmark")
                                } else {
                                    Text("None")
                                }
                            }

                            ForEach(lookupData.calibers) { caliber in
                                Button {
                                    selectedCaliber = caliber
                                } label: {
                                    if selectedCaliber?.persistentModelID == caliber.persistentModelID {
                                        Label(caliber.name, systemImage: "checkmark")
                                    } else {
                                        Text(caliber.name)
                                    }
                                }
                            }

                            if isEditing {
                                Divider()
                                Button {
                                    showingAddCaliber = true
                                } label: {
                                    Label("Add Caliber", systemImage: "plus.circle")
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedCaliber?.name ?? "None")
                                    .foregroundStyle(selectedCaliber == nil ? .secondary : .primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Picker("Action", selection: $selectedAction) {
                        ForEach(FirearmAction.allCases) { action in
                            Text(action.displayName).tag(action)
                        }
                    }

                    if selectedAction == .other {
                        TextField("Action details", text: $customAction)
                    }

                    LabeledContent("Barrel Length") {
                        HStack(spacing: 6) {
                            TextField("", text: $barrelLengthText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)

                            Text("in.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Color", selection: $selectedColor) {
                        Text("None").tag(nil as FirearmColor?)
                        ForEach(FirearmColor.allCases) { color in
                            Text(color.displayName).tag(Optional(color))
                        }
                    }

                    if selectedColor == .other {
                        TextField("Color details", text: $customColor)
                    }
                }
                .disabled(isReadOnly)

                Section("Maintenance") {
                    if isReadOnly {
                        LabeledContent("Last cleaned", value: firearm?.lastCleanedDateText ?? "Not set")
                    } else {
                        Toggle("Track last cleaned date", isOn: $hasLastCleanedDate)

                        if hasLastCleanedDate {
                            DatePicker("Last cleaned", selection: $lastCleanedDate, displayedComponents: .date)
                        }
                    }
                }
                .disabled(isReadOnly)

                if showsPurchaseSection {
                    Section("Purchase") {
                        DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
                        LabeledContent("Purchase Price") {
                            SelectAllTextField(
                                placeholder: "",
                                text: $purchasePriceText,
                                keyboardType: .decimalPad,
                                textAlignment: .right
                            )
                        }
                        Text("Enter dollars and cents, for example 1299.99.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isReadOnly)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                .disabled(isReadOnly)

                Section("Linked Optics") {
                    if isEditing {
                        Button {
                            showingOpticsPicker = true
                        } label: {
                            Label(selectedOpticIDs.isEmpty ? "Add Optics" : "Manage Optics", systemImage: "plus.circle")
                        }
                    }

                    if lookupData.optics.isEmpty {
                        Text("Add optics first to link them to this firearm.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if availableOptics.isEmpty {
                        Text("No unlinked optics available.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if resolvedOptics.isEmpty {
                        Text("No optics linked.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(resolvedOptics) { optic in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(optic.displayName)
                                Text("\(optic.opticType.displayName) • \(optic.magnificationText)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Magazine Patterns") {
                    if isEditing {
                        Button {
                            showingMagazinePatternsPicker = true
                        } label: {
                            Label(
                                selectedMagazinePatterns.isEmpty ? "Select Magazine Patterns" : "Manage Magazine Patterns",
                                systemImage: "square.stack.3d.down.right.fill"
                            )
                        }
                    }

                    if selectedMagazinePatterns.isEmpty {
                        Text("No magazine patterns selected.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedMagazinePatterns, id: \.id) { pattern in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.resolvedDisplayName)
                                Text(pattern.kind == .catalog ? "Catalog pattern" : pattern.kind.id.capitalized)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Linked Magazines") {
                    if let compatibilityMessage = selectedMagazineCompatibilityMessage {
                        Text(compatibilityMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if lookupData.magazines.isEmpty {
                        Text("Add magazines first to link them to this firearm.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if selectedMagazinePatterns.isEmpty {
                        Text("Select one or more magazine patterns to see linked magazines.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if resolvedMagazines.isEmpty {
                        Text("No magazines currently match the selected patterns.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(resolvedMagazines) { magazine in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(magazine.displayName)
                                Text("\(magazine.caliber?.name ?? "No Caliber") • \(magazine.capacityText)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Linked Attachments") {
                    if isEditing {
                        Button {
                            showingAttachmentsPicker = true
                        } label: {
                            Label(selectedAttachmentIDs.isEmpty ? "Add Attachments" : "Manage Attachments", systemImage: "plus.circle")
                        }
                    }

                    if lookupData.attachments.isEmpty {
                        Text("Add attachments first to link them to this firearm.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if availableAttachments.isEmpty {
                        Text("No unlinked attachments available.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if resolvedAttachments.isEmpty {
                        Text("No attachments linked.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(resolvedAttachments) { attachment in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.displayName)
                                Text(attachment.typeDisplayName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Linked Parts") {
                    if isEditing {
                        Button {
                            showingPartsPicker = true
                        } label: {
                            Label(selectedPartIDs.isEmpty ? "Add Parts" : "Manage Parts", systemImage: "plus.circle")
                        }
                    }

                    if lookupData.parts.isEmpty {
                        Text("Add parts first to link them to this firearm.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if availableParts.isEmpty {
                        Text("No unlinked parts available.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if resolvedParts.isEmpty {
                        Text("No parts linked.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(resolvedParts) { part in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(part.displayName)
                                Text(part.typeDisplayName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if showsPostTaxTotalSection {
                    Section("Total Value") {
                        LabeledContent("Post-Tax Total", value: totalValueWithTaxText)
                        Text("Includes the firearm plus linked optics, magazines, attachments, and parts.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if firearm != nil {
                    Section {
                        Button("Delete Firearm", role: .destructive) {
                            deleteFirearm()
                        }
                    }
                }
            }
            .navigationTitle(firearm == nil ? "New Firearm" : "Firearm Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                reloadLookupData()
            }
            .onChange(of: serialNumber) {
                guard isEditing else {
                    return
                }
                let normalizedValue = viewModel.normalizedSerialNumber(serialNumber)
                if normalizedValue != serialNumber {
                    serialNumber = normalizedValue
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if firearm != nil && !isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            shareSnapshot()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryButtonTitle) { handlePrimaryAction() }
                        .disabled(isEditing && !canAdd)
                }
            }
            .sheet(isPresented: $showingAddCaliber, onDismiss: reloadLookupData) {
                AddCaliberView(viewModel: AddCaliberViewModel())
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingOpticsPicker) {
                NavigationStack {
                    Group {
                        if availableOptics.isEmpty {
                            ContentUnavailableView(
                                "No Optics Available",
                                systemImage: "scope",
                                description: Text("All saved optics are linked to other firearms or none have been added yet.")
                            )
                        } else {
                            List {
                                ForEach(availableOptics) { optic in
                                    Button {
                                        toggleOpticSelection(for: optic)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(optic.displayName)
                                                    .foregroundStyle(.primary)
                                                Text("\(optic.opticType.displayName) • \(optic.magnificationText)")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if selectedOpticIDs.contains(optic.persistentModelID) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.tint)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .navigationTitle("Link Optics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingOpticsPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingMagazinePatternsPicker) {
                NavigationStack {
                    Group {
                        if availableMagazinePatterns.isEmpty {
                            ContentUnavailableView(
                                "No Magazine Patterns Available",
                                systemImage: "square.stack.3d.down.right.fill",
                                description: Text("Add magazines or select a caliber to surface compatible patterns.")
                            )
                        } else {
                            List {
                                ForEach(availableMagazinePatterns, id: \.id) { pattern in
                                    Button {
                                        toggleMagazinePatternSelection(for: pattern)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(pattern.resolvedDisplayName)
                                                    .foregroundStyle(.primary)
                                                Text(pattern.kind == .catalog ? "Catalog pattern" : pattern.kind.id.capitalized)
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if selectedMagazinePatterns.contains(where: { $0.id == pattern.id }) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.tint)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .navigationTitle("Magazine Patterns")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingMagazinePatternsPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingAttachmentsPicker) {
                NavigationStack {
                    Group {
                        if availableAttachments.isEmpty {
                            ContentUnavailableView(
                                "No Attachments Available",
                                systemImage: "hand.raised.fill",
                                description: Text("All saved attachments are linked to other firearms or none have been added yet.")
                            )
                        } else {
                            List {
                                ForEach(availableAttachments) { attachment in
                                    Button {
                                        toggleAttachmentSelection(for: attachment)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(attachment.displayName)
                                                    .foregroundStyle(.primary)
                                                Text(attachment.typeDisplayName)
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if selectedAttachmentIDs.contains(attachment.persistentModelID) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.tint)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .navigationTitle("Link Attachments")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingAttachmentsPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingPartsPicker) {
                NavigationStack {
                    Group {
                        if availableParts.isEmpty {
                            ContentUnavailableView(
                                "No Parts Available",
                                systemImage: "gearshape.2.fill",
                                description: Text("All saved parts are linked to other firearms or none have been added yet.")
                            )
                        } else {
                            List {
                                ForEach(availableParts) { part in
                                    Button {
                                        togglePartSelection(for: part)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(part.displayName)
                                                    .foregroundStyle(.primary)
                                                Text(part.typeDisplayName)
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if selectedPartIDs.contains(part.persistentModelID) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.tint)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .navigationTitle("Link Parts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingPartsPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .alert("Snapshot Error", isPresented: snapshotErrorBinding) {
                Button("OK", role: .cancel) {
                    snapshotErrorMessage = nil
                }
            } message: {
                Text(snapshotErrorMessage ?? "")
            }
        }
    }

    private var resolvedActionDetail: String? {
        viewModel.resolvedActionDetail(selectedAction: selectedAction, customAction: customAction)
    }

    private var resolvedNickname: String? {
        viewModel.optionalValue(nickname)
    }

    private var resolvedColorDetail: String? {
        viewModel.resolvedColorDetail(selectedColor: selectedColor, customColor: customColor)
    }

    private var resolvedNotes: String? {
        viewModel.optionalValue(notes)
    }

    private var resolvedBarrelLength: Double? {
        viewModel.barrelLength(from: barrelLengthText)
    }

    private var resolvedPurchasePriceCents: Int? {
        viewModel.purchasePriceCents(from: purchasePriceText)
    }

    private var resolvedLastCleanedDate: Date? {
        hasLastCleanedDate ? lastCleanedDate : nil
    }

    private var resolvedOptics: [Optic] {
        viewModel.resolvedOptics(from: lookupData.optics, selectedIDs: selectedOpticIDs)
    }

    private var resolvedMagazines: [Magazine] {
        viewModel.linkedMagazines(
            from: lookupData.magazines,
            selectedPatterns: selectedMagazinePatterns,
            firearmType: selectedType,
            action: selectedAction,
            caliber: selectedCaliber
        )
    }

    private var resolvedAttachments: [Attachment] {
        viewModel.resolvedAttachments(from: lookupData.attachments, selectedIDs: selectedAttachmentIDs)
    }

    private var resolvedParts: [Part] {
        viewModel.resolvedParts(from: lookupData.parts, selectedIDs: selectedPartIDs)
    }

    private var availableOptics: [Optic] {
        viewModel.availableOptics(from: lookupData.optics, selectedIDs: selectedOpticIDs, firearm: firearm)
    }

    private var selectedMagazineCompatibilityMessage: String? {
        viewModel.selectedMagazineValidationResult(
            magazines: resolvedMagazines,
            selectedPatterns: selectedMagazinePatterns,
            firearmType: selectedType,
            action: selectedAction,
            caliber: selectedCaliber,
            owningFirearm: firearm
        ).message
    }

    private var availableMagazinePatterns: [FirearmMagazinePatternReference] {
        viewModel.availableMagazinePatterns(
            from: lookupData.magazines,
            firearmType: selectedType,
            action: selectedAction,
            caliber: selectedCaliber,
            selectedPatterns: selectedMagazinePatterns
        )
    }

    private var availableAttachments: [Attachment] {
        viewModel.availableAttachments(from: lookupData.attachments, selectedIDs: selectedAttachmentIDs, firearm: firearm)
    }

    private var availableParts: [Part] {
        viewModel.availableParts(from: lookupData.parts, selectedIDs: selectedPartIDs, firearm: firearm)
    }

    private var duplicateExists: Bool {
        viewModel.duplicateExists(serialNumber: serialNumber, excluding: firearm, in: lookupData.existingFirearms)
    }

    private var isReadOnly: Bool {
        viewModel.isReadOnly(hasFirearm: firearm != nil, isEditing: isEditing)
    }

    private var showsPurchaseSection: Bool {
        viewModel.showsPurchaseSection(showValueInDetails: showValueInDetails, isReadOnly: isReadOnly)
    }

    private var showsPostTaxTotalSection: Bool {
        firearm != nil && showValueInDetails
    }

    private var totalValueWithTaxText: String {
        let firearmTotalCents = taxedAmountCents(
            baseAmountCents: max(0, resolvedPurchasePriceCents ?? 0),
            taxRate: taxRateProvider.firearmsTaxRate
        )
        let accessoriesTotalCents = taxedAmountCents(
            baseAmountCents: accessoriesSubtotalCents,
            taxRate: taxRateProvider.accessoriesTaxRate
        )
        let amount = Decimal(firearmTotalCents + accessoriesTotalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private var accessoriesSubtotalCents: Int {
        let opticsTotal = resolvedOptics.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let magazinesTotal = resolvedMagazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let attachmentsTotal = resolvedAttachments.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let partsTotal = resolvedParts.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        return opticsTotal + magazinesTotal + attachmentsTotal + partsTotal
    }

    private var primaryButtonTitle: String {
        viewModel.primaryButtonTitle(hasFirearm: firearm != nil, isEditing: isEditing)
    }

    private var canAdd: Bool {
        viewModel.canAdd(
            brand: brand,
            modelName: modelName,
            serialNumber: serialNumber,
            selectedType: selectedType,
            selectedAction: selectedAction,
            actionDetail: resolvedActionDetail,
            selectedColor: selectedColor,
            colorDetail: resolvedColorDetail,
            purchasePriceText: purchasePriceText,
            barrelLengthText: barrelLengthText,
            duplicateExists: duplicateExists,
            magazines: resolvedMagazines,
            selectedMagazinePatterns: selectedMagazinePatterns,
            caliber: selectedCaliber,
            owningFirearm: firearm
        )
    }

    private func reloadLookupData() {
        do {
            lookupData = try lookupService.fetchLookupData(in: context)
        } catch {
            print("Lookup fetch error: \(error)")
        }
    }

    private func taxedAmountCents(baseAmountCents: Int, taxRate: Double) -> Int {
        Int((Double(baseAmountCents) * (1 + max(0, taxRate) / 100)).rounded())
    }

    private func saveFirearm() {
        let didSave: Bool
        if let firearm {
            didSave = viewModel.updateFirearm(
                firearm,
                brand: brand,
                modelName: modelName,
                nickname: resolvedNickname,
                serialNumber: serialNumber,
                purchaseDate: purchaseDate,
                lastCleanedDate: resolvedLastCleanedDate,
                purchasePriceCents: resolvedPurchasePriceCents ?? 0,
                type: selectedType,
                action: selectedAction,
                actionDetail: resolvedActionDetail,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                barrelLengthInches: resolvedBarrelLength,
                notes: resolvedNotes,
                supportedMagazinePatterns: selectedMagazinePatterns,
                caliber: selectedCaliber,
                optics: resolvedOptics,
                magazines: resolvedMagazines,
                attachments: resolvedAttachments,
                parts: resolvedParts,
                canSave: canAdd,
                in: context
            )
        } else {
            didSave = viewModel.addFirearm(
                brand: brand,
                modelName: modelName,
                nickname: resolvedNickname,
                serialNumber: serialNumber,
                purchaseDate: purchaseDate,
                lastCleanedDate: resolvedLastCleanedDate,
                purchasePriceCents: resolvedPurchasePriceCents ?? 0,
                type: selectedType,
                action: selectedAction,
                actionDetail: resolvedActionDetail,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                barrelLengthInches: resolvedBarrelLength,
                notes: resolvedNotes,
                supportedMagazinePatterns: selectedMagazinePatterns,
                caliber: selectedCaliber,
                optics: resolvedOptics,
                magazines: resolvedMagazines,
                attachments: resolvedAttachments,
                parts: resolvedParts,
                canAdd: canAdd,
                to: context
            )
        }

        guard didSave else {
            return
        }
        if firearm == nil {
            dismiss()
        } else {
            isEditing = false
        }
    }

    private func deleteFirearm() {
        guard let firearm else {
            return
        }

        context.delete(firearm)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            dismiss()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private func handlePrimaryAction() {
        if firearm != nil && !isEditing {
            isEditing = true
            return
        }
        saveFirearm()
    }

    private func toggleOpticSelection(for optic: Optic) {
        selectedOpticIDs = viewModel.toggledSelection(
            currentSelection: selectedOpticIDs,
            itemID: optic.persistentModelID,
            isEditing: isEditing
        )
    }

    private func toggleMagazinePatternSelection(for pattern: FirearmMagazinePatternReference) {
        selectedMagazinePatterns = viewModel.toggledMagazinePatternSelection(
            currentSelection: selectedMagazinePatterns,
            pattern: pattern,
            isEditing: isEditing
        )
    }

    private func toggleAttachmentSelection(for attachment: Attachment) {
        selectedAttachmentIDs = viewModel.toggledSelection(
            currentSelection: selectedAttachmentIDs,
            itemID: attachment.persistentModelID,
            isEditing: isEditing
        )
    }

    private func togglePartSelection(for part: Part) {
        selectedPartIDs = viewModel.toggledSelection(
            currentSelection: selectedPartIDs,
            itemID: part.persistentModelID,
            isEditing: isEditing
        )
    }

    private var snapshotErrorBinding: Binding<Bool> {
        Binding(
            get: { snapshotErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    snapshotErrorMessage = nil
                }
            }
        )
    }

    private func shareSnapshot() {
        guard let firearm else {
            return
        }

        guard let image = renderSnapshotImage(for: firearm) else {
            snapshotErrorMessage = FirearmSnapshotError.renderFailed.localizedDescription
            return
        }

        presentShareSheet(with: image)
    }

    private func renderSnapshotImage(for firearm: Firearm) -> UIImage? {
        let content = FirearmSnapshotCard(
            firearm: firearm,
            hidesSerialNumber: true,
            showsValue: showValueInDetails,
            totalValueText: totalValueWithTaxText,
            optics: resolvedOptics,
            magazines: resolvedMagazines,
            attachments: resolvedAttachments,
            parts: resolvedParts
        )
        .frame(width: 1080)
        .background(Color.white)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: 1080, height: nil)
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.uiImage
    }

    private func presentShareSheet(with image: UIImage) {
        guard let presentingViewController = UIApplication.topViewController() else {
            snapshotErrorMessage = FirearmSnapshotError.presentationFailed.localizedDescription
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = presentingViewController.view
            popover.sourceRect = CGRect(
                x: presentingViewController.view.bounds.midX,
                y: presentingViewController.view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }

        presentingViewController.present(activityViewController, animated: true)
    }
}

private enum FirearmSnapshotError: LocalizedError {
    case renderFailed
    case presentationFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "The snapshot image could not be generated."
        case .presentationFailed:
            return "The share sheet could not be presented."
        }
    }
}

private extension UIApplication {
    static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let navigationController = base as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }

        if let tabBarController = base as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(base: selectedViewController)
        }

        if let presentedViewController = base?.presentedViewController {
            return topViewController(base: presentedViewController)
        }

        return base
    }
}

private struct FirearmSnapshotCard: View {
    let firearm: Firearm
    let hidesSerialNumber: Bool
    let showsValue: Bool
    let totalValueText: String
    let optics: [Optic]
    let magazines: [Magazine]
    let attachments: [Attachment]
    let parts: [Part]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            detailGrid

            if !firearm.notesTextForSnapshot.isEmpty {
                snapshotSection("Notes") {
                    Text(firearm.notesTextForSnapshot)
                        .font(.system(size: 34))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            linkedSection("Linked Optics", items: optics.map { "\($0.displayName) • \($0.magnificationText)" })
            linkedSection("Linked Magazines", items: magazines.map { "\($0.displayName) • \($0.capacityText)" })
            linkedSection("Linked Attachments", items: attachments.map { "\($0.displayName) • \($0.typeDisplayName)" })
            linkedSection("Linked Parts", items: parts.map { "\($0.displayName) • \($0.typeDisplayName)" })

            Text("Generated by Armory Inventory")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.92),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(firearm.displayName)
                .font(.system(size: 66, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                snapshotBadge(firearm.firearmType.displayName)

                if let caliberName = firearm.caliber?.name, !caliberName.isEmpty {
                    snapshotBadge(caliberName)
                }

                if let serialText = serialNumberText {
                    snapshotBadge(serialText)
                }
            }

            if let nickname = firearm.nicknameTextForSnapshot {
                Text("“\(nickname)”")
                    .font(.system(size: 38, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 18),
                GridItem(.flexible(), spacing: 18)
            ],
            alignment: .leading,
            spacing: 18
        ) {
            snapshotMetric("Action", firearm.actionDisplayName)

            if let barrel = firearm.barrelLengthText {
                snapshotMetric("Barrel", barrel)
            }

            if let color = firearm.colorDisplayName {
                snapshotMetric("Color", color)
            }

            snapshotMetric("Purchase Date", firearm.purchaseDate.formatted(date: .abbreviated, time: .omitted))

            if let lastCleaned = firearm.lastCleanedDateText {
                snapshotMetric("Last Cleaned", lastCleaned)
            }

            if showsValue {
                snapshotMetric("Post-Tax Total", totalValueText)
            }
        }
    }

    private var serialNumberText: String? {
        guard let serialNumber = firearm.serialNumberTextForSnapshot else {
            return nil
        }

        if hidesSerialNumber {
            return "Serial Hidden"
        }

        return "SN \(serialNumber)"
    }

    private func snapshotMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func linkedSection(_ title: String, items: [String]) -> some View {
        snapshotSection(title) {
            if items.isEmpty {
                Text("None linked")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color.primary.opacity(0.75))
                                .frame(width: 8, height: 8)
                                .padding(.top, 14)

                            Text(item)
                                .font(.system(size: 30))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func snapshotSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.primary)

            content()
        }
    }

    private func snapshotBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(Color(red: 0.26, green: 0.21, blue: 0.13))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color(red: 0.89, green: 0.83, blue: 0.7))
            )
    }
}

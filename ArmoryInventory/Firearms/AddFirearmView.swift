//
//  AddFirearmView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

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
    @State private var selectedMagazineIDs: Set<PersistentIdentifier> = []
    @State private var selectedAttachmentIDs: Set<PersistentIdentifier> = []
    @State private var showingOpticsPicker = false
    @State private var showingMagazinesPicker = false
    @State private var showingAttachmentsPicker = false
    @State private var isEditing = false
    @State private var lookupData = AddFirearmLookupData()

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
        _purchasePriceText = State(initialValue: viewModel.initialPurchasePriceText(for: firearm))
        _selectedType = State(initialValue: firearm?.firearmType ?? .rifle)
        _selectedAction = State(initialValue: firearm?.firearmAction ?? .semiAuto)
        _customAction = State(initialValue: firearm?.firearmAction == .other ? firearm?.actionDetail ?? "" : "")
        _selectedColor = State(initialValue: firearm?.firearmColor)
        _customColor = State(initialValue: firearm?.firearmColor == .other ? firearm?.colorDetail ?? "" : "")
        _selectedCaliber = State(initialValue: firearm?.caliber)
        _selectedOpticIDs = State(initialValue: viewModel.selectedOpticIDs(for: firearm))
        _selectedMagazineIDs = State(initialValue: viewModel.selectedMagazineIDs(for: firearm))
        _selectedAttachmentIDs = State(initialValue: viewModel.selectedAttachmentIDs(for: firearm))
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

                    Picker("Caliber", selection: $selectedCaliber) {
                        Text("None").tag(nil as Caliber?)
                        ForEach(lookupData.calibers) { caliber in
                            Text(caliber.name).tag(Optional(caliber))
                        }
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

                Section("Linked Magazines") {
                    if isEditing {
                        Button {
                            showingMagazinesPicker = true
                        } label: {
                            Label(selectedMagazineIDs.isEmpty ? "Add Magazines" : "Manage Magazines", systemImage: "plus.circle")
                        }
                    }

                    if lookupData.magazines.isEmpty {
                        Text("Add magazines first to link them to this firearm.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if availableMagazines.isEmpty {
                        Text("No unlinked magazines available.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if resolvedMagazines.isEmpty {
                        Text("No magazines linked.")
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

                if showsPostTaxTotalSection {
                    Section("Total Value") {
                        LabeledContent("Post-Tax Total", value: totalValueWithTaxText)
                        Text("Includes the firearm plus linked optics, magazines, and attachments.")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryButtonTitle) { handlePrimaryAction() }
                        .disabled(isEditing && !canAdd)
                }
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
            .sheet(isPresented: $showingMagazinesPicker) {
                NavigationStack {
                    Group {
                        if availableMagazines.isEmpty {
                            ContentUnavailableView(
                                "No Magazines Available",
                                systemImage: "rectangle.stack.fill.badge.plus",
                                description: Text("All saved magazines are linked to other firearms or none have been added yet.")
                            )
                        } else {
                            List {
                                ForEach(availableMagazines) { magazine in
                                    Button {
                                        toggleMagazineSelection(for: magazine)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(magazine.displayName)
                                                    .foregroundStyle(.primary)
                                                Text("\(magazine.caliber?.name ?? "No Caliber") • \(magazine.capacityText)")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if selectedMagazineIDs.contains(magazine.persistentModelID) {
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
                    .navigationTitle("Link Magazines")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingMagazinesPicker = false
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

    private var resolvedOptics: [Optic] {
        viewModel.resolvedOptics(from: lookupData.optics, selectedIDs: selectedOpticIDs)
    }

    private var resolvedMagazines: [Magazine] {
        viewModel.resolvedMagazines(from: lookupData.magazines, selectedIDs: selectedMagazineIDs)
    }

    private var resolvedAttachments: [Attachment] {
        viewModel.resolvedAttachments(from: lookupData.attachments, selectedIDs: selectedAttachmentIDs)
    }

    private var availableOptics: [Optic] {
        viewModel.availableOptics(from: lookupData.optics, selectedIDs: selectedOpticIDs, firearm: firearm)
    }

    private var availableMagazines: [Magazine] {
        viewModel.availableMagazines(from: lookupData.magazines, selectedIDs: selectedMagazineIDs, firearm: firearm)
    }

    private var availableAttachments: [Attachment] {
        viewModel.availableAttachments(from: lookupData.attachments, selectedIDs: selectedAttachmentIDs, firearm: firearm)
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
        return opticsTotal + magazinesTotal + attachmentsTotal
    }

    private var primaryButtonTitle: String {
        viewModel.primaryButtonTitle(hasFirearm: firearm != nil, isEditing: isEditing)
    }

    private var canAdd: Bool {
        viewModel.canAdd(
            brand: brand,
            modelName: modelName,
            serialNumber: serialNumber,
            selectedAction: selectedAction,
            actionDetail: resolvedActionDetail,
            selectedColor: selectedColor,
            colorDetail: resolvedColorDetail,
            purchasePriceText: purchasePriceText,
            barrelLengthText: barrelLengthText,
            duplicateExists: duplicateExists
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
                purchasePriceCents: resolvedPurchasePriceCents ?? 0,
                type: selectedType,
                action: selectedAction,
                actionDetail: resolvedActionDetail,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                barrelLengthInches: resolvedBarrelLength,
                notes: resolvedNotes,
                caliber: selectedCaliber,
                optics: resolvedOptics,
                magazines: resolvedMagazines,
                attachments: resolvedAttachments,
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
                purchasePriceCents: resolvedPurchasePriceCents ?? 0,
                type: selectedType,
                action: selectedAction,
                actionDetail: resolvedActionDetail,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                barrelLengthInches: resolvedBarrelLength,
                notes: resolvedNotes,
                caliber: selectedCaliber,
                optics: resolvedOptics,
                magazines: resolvedMagazines,
                attachments: resolvedAttachments,
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

    private func toggleMagazineSelection(for magazine: Magazine) {
        selectedMagazineIDs = viewModel.toggledSelection(
            currentSelection: selectedMagazineIDs,
            itemID: magazine.persistentModelID,
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
}

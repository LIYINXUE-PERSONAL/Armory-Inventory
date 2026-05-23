//
//  AddKitView.swift
//  Armory Inventory
//
//  Created by Codex on 5/14/26.
//

import SwiftUI
import SwiftData

struct AddKitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true

    let kit: Kit?
    let viewModel: AddKitViewModel
    private let inventoryListService: InventoryListServicing

    @State private var name = ""
    @State private var kind: KitKind = .upperReceiver
    @State private var notes = ""
    @State private var componentSelections: [KitComponentSelection] = []
    @State private var parts: [Part] = []
    @State private var optics: [Optic] = []
    @State private var attachments: [Attachment] = []
    @State private var kits: [Kit] = []
    @State private var showingPartsPicker = false
    @State private var showingOpticsPicker = false
    @State private var showingAttachmentsPicker = false
    @State private var alertMessage: String?

    init(
        kit: Kit? = nil,
        viewModel: AddKitViewModel,
        inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)
    ) {
        self.kit = kit
        self.viewModel = viewModel
        self.inventoryListService = inventoryListService
        _name = State(initialValue: viewModel.initialName(for: kit))
        _kind = State(initialValue: viewModel.initialKind(for: kit))
        _notes = State(initialValue: viewModel.initialNotes(for: kit))
        _componentSelections = State(initialValue: viewModel.initialSelections(for: kit))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kit") {
                    LabeledContent("Name") {
                        TextField(kind.displayName, text: $name)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Kind", selection: $kind) {
                        ForEach(KitKind.allCases) { kitKind in
                            Text(kitKind.displayName).tag(kitKind)
                        }
                    }

                    if let kit {
                        if let firearm = kit.firearm {
                            LabeledContent("Linked Firearm", value: firearm.displayName)
                        }
                    }
                }

                Section("Parts") {
                    Button {
                        showingPartsPicker = true
                    } label: {
                        Label("Manage Parts", systemImage: "gearshape.2.fill")
                    }

                    selectedComponentRows(for: .part)
                }

                Section("Optics") {
                    Button {
                        showingOpticsPicker = true
                    } label: {
                        Label("Manage Optics", systemImage: "scope")
                    }

                    selectedComponentRows(for: .optic)
                }

                Section("Attachments") {
                    Button {
                        showingAttachmentsPicker = true
                    } label: {
                        Label("Manage Attachments", systemImage: "paperclip")
                    }

                    selectedComponentRows(for: .attachment)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if showValueInDetails {
                    Section("Total Value") {
                        LabeledContent(
                            "Components",
                            value: KitValueService.currencyText(
                                for: viewModel.componentValueCents(
                                    from: componentSelections,
                                    parts: parts,
                                    optics: optics,
                                    attachments: attachments
                                )
                            )
                        )
                    }
                }

                if viewModel.shouldShowDisassembleButton(for: kit) {
                    Section {
                        Button("Disassemble Kit", role: .destructive) {
                            disassembleKit()
                        }
                        Button("Discard Kit", role: .destructive) {
                            discardKit()
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle(for: kit))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                reloadData()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.primarySaveTitle(for: kit)) {
                        saveCurrentStatus()
                    }
                }
            }
            .sheet(isPresented: $showingPartsPicker) {
                componentPicker(
                    title: viewModel.pickerTitle(for: .part),
                    emptyTitle: viewModel.pickerEmptyTitle(for: .part),
                    systemImage: "gearshape.2.fill",
                    items: viewModel.partPickerItems(
                        parts: parts,
                        selections: componentSelections,
                        kits: kits,
                        editing: kit
                    ),
                    onToggle: togglePart
                )
            }
            .sheet(isPresented: $showingOpticsPicker) {
                componentPicker(
                    title: viewModel.pickerTitle(for: .optic),
                    emptyTitle: viewModel.pickerEmptyTitle(for: .optic),
                    systemImage: "scope",
                    items: viewModel.opticPickerItems(
                        optics: optics,
                        selections: componentSelections,
                        kits: kits,
                        editing: kit
                    ),
                    onToggle: toggleOptic
                )
            }
            .sheet(isPresented: $showingAttachmentsPicker) {
                componentPicker(
                    title: viewModel.pickerTitle(for: .attachment),
                    emptyTitle: viewModel.pickerEmptyTitle(for: .attachment),
                    systemImage: "paperclip",
                    items: viewModel.attachmentPickerItems(
                        attachments: attachments,
                        selections: componentSelections,
                        kits: kits,
                        editing: kit
                    ),
                    onToggle: toggleAttachment
                )
            }
            .alert("Kit Save Failed", isPresented: alertBinding) {
                Button("OK", role: .cancel) {
                    alertMessage = nil
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var selectedComponents: [KitComponent] {
        viewModel.components(
            from: componentSelections,
            parts: parts,
            optics: optics,
            attachments: attachments
        )
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    private func reloadData() {
        do {
            parts = try inventoryListService.fetchParts(in: context)
            optics = try inventoryListService.fetchOptics(in: context)
            attachments = try inventoryListService.fetchAttachments(in: context)
            kits = try inventoryListService.fetchKits(in: context)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func saveCurrentStatus() {
        let status = kit?.kitStatus ?? .built
        let result = viewModel.saveKit(
            kit,
            name: name,
            kind: kind,
            notes: viewModel.optionalValue(notes),
            components: selectedComponents,
            targetStatus: status,
            kits: kits,
            in: context
        )
        handle(result)
    }

    private func disassembleKit() {
        guard let kit else {
            return
        }
        handle(viewModel.disassembleKit(kit, in: context))
    }

    private func discardKit() {
        guard let kit else {
            return
        }
        handle(viewModel.discardKit(kit, in: context))
    }

    private func handle(_ result: KitValidationResult) {
        if result.isValid {
            dismiss()
        } else {
            alertMessage = result.message
        }
    }

    private func togglePart(_ id: PersistentIdentifier) {
        componentSelections = viewModel.toggledSelection(
            componentSelections,
            category: .part,
            itemID: id
        )
    }

    private func toggleOptic(_ id: PersistentIdentifier) {
        componentSelections = viewModel.toggledSelection(
            componentSelections,
            category: .optic,
            itemID: id
        )
    }

    private func toggleAttachment(_ id: PersistentIdentifier) {
        componentSelections = viewModel.toggledSelection(
            componentSelections,
            category: .attachment,
            itemID: id
        )
    }

    @ViewBuilder
    private func selectedComponentRows(for category: KitComponentCategory) -> some View {
        let rows = viewModel.selectedComponentRows(
            for: category,
            selections: componentSelections,
            parts: parts,
            optics: optics,
            attachments: attachments
        )
        if rows.isEmpty {
            Text(viewModel.emptySelectionText(for: category))
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.headline)
                    Text(row.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func componentPicker(
        title: String,
        emptyTitle: String,
        systemImage: String,
        items: [AddKitComponentPickerItem],
        onToggle: @escaping (PersistentIdentifier) -> Void
    ) -> some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: systemImage,
                        description: Text("Only unlinked items outside built or linked kits can be selected.")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            Button {
                                onToggle(item.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .foregroundStyle(.primary)
                                        Text(item.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isSelected ? Color.accentColor : Color.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showingPartsPicker = false
                        showingOpticsPicker = false
                        showingAttachmentsPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

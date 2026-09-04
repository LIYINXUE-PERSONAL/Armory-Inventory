//
//  AttachmentsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AttachmentsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(AttachmentTypeSort.settingsVersionKey) private var typeSortVersion = 0
    @AppStorage(InventorySettingsKeys.attachmentItemSortOrder) private var itemSortOrder = AccessoryItemSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.attachmentItemSortDirection) private var itemSortDirectionRaw = ""
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddAttachment = false
    @State private var selectedAttachment: Attachment?
    @State private var attachments: [Attachment] = []
    @State private var kits: [Kit] = []
    @State private var alertMessage: String?
    @State private var showingFilters = false
    @State private var selectedStatusFilter: AccessoryLinkStatusFilter = .all

    private let viewModel = AccessoryInventoryListViewModel()
    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)

    var body: some View {
        Group {
            if attachments.isEmpty {
                ContentUnavailableView(
                    "No Attachments Yet",
                    systemImage: "paperclip",
                    description: Text("Add your first attachment to track stocks, grips, lasers, lights, and other hardware.")
                )
            } else {
                List {
                    Section {
                        AccessoryLinkStatusFiltersCard(
                            isExpanded: $showingFilters,
                            selectedStatusFilter: $selectedStatusFilter
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    if filteredAttachments.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "No Matching Attachments",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No attachments match the selected filters.")
                            )
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(groupedAttachmentTypes, id: \.self) { typeID in
                            Section(attachmentTypeDisplayName(for: typeID)) {
                                ForEach(groupedAttachments[typeID] ?? []) { attachment in
                                    Button {
                                        selectedAttachment = attachment
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(attachment.displayName)
                                                .font(.headline)

                                            if showValueInCard, attachment.purchasePriceCents > 0 {
                                                LabeledContent("Value", value: attachment.purchasePriceText)
                                            }

                                            if let firearm = viewModel.linkedFirearm(for: attachment, kits: kits) {
                                                LabeledContent("Linked Firearm", value: firearm.displayName)
                                            }

                                            if let kit = viewModel.linkedKit(for: attachment, kits: kits) {
                                                LabeledContent("Linked Kit", value: kit.displayName)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    deleteAttachments(at: offsets, in: typeID)
                                }
                            }
                        }

                        if showTotalValue {
                            Section {
                                LabeledContent("Total Value", value: totalValueText)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Attachments")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadAttachments()
        }
        .onAppear {
            reloadAttachments()
        }
        .onChange(of: showingAddAttachment) {
            if !showingAddAttachment {
                reloadAttachments()
            }
        }
        .onChange(of: selectedAttachment) {
            if selectedAttachment == nil {
                reloadAttachments()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()

                Button {
                    showingAddAttachment = true
                } label: {
                    Label("Add Attachment", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAttachment) {
            AddAttachmentView(viewModel: AddAttachmentViewModel())
                .presentationDetents([.large])
        }
        .sheet(item: $selectedAttachment) { attachment in
            AddAttachmentView(attachment: attachment, viewModel: AddAttachmentViewModel())
                .presentationDetents([.large])
        }
        .alert("Attachment Cannot Be Deleted", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var filteredAttachments: [Attachment] {
        viewModel.filteredAttachments(attachments, selectedStatusFilter: selectedStatusFilter, kits: kits)
    }

    private var groupedAttachments: [String: [Attachment]] {
        viewModel.groupedAttachments(filteredAttachments, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw)
    }

    private var groupedAttachmentTypes: [String] {
        viewModel.groupedAttachmentTypes(from: groupedAttachments)
    }

    private func deleteAttachments(at offsets: IndexSet, in type: String) {
        let result = viewModel.deleteAttachments(
            at: offsets,
            in: type,
            groupedAttachments: groupedAttachments,
            allAttachments: attachments,
            kits: kits,
            context: context
        )
        if result.isValid {
            reloadAttachments()
        } else {
            alertMessage = result.message
            reloadAttachments()
        }
    }

    private func reloadAttachments() {
        do {
            attachments = try inventoryListService.fetchAttachments(in: context)
            kits = try inventoryListService.fetchKits(in: context)
        } catch {
            print("Attachments fetch error: \(error)")
        }
    }

    private var totalValueText: String {
        viewModel.totalValueText(for: filteredAttachments)
    }

    private func attachmentTypeDisplayName(for typeID: String) -> String {
        viewModel.attachmentTypeDisplayName(for: typeID)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }
}

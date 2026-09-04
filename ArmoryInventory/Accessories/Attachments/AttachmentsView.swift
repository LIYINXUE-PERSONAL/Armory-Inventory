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
    @State private var selectedType: String?
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        AccessoryLinkStatusFiltersCard(
                            isExpanded: $showingFilters,
                            typeOptions: typeFilterOptions,
                            selectedType: $selectedType,
                            selectedStatusFilter: $selectedStatusFilter
                        )

                        if filteredAttachments.isEmpty {
                            ContentUnavailableView(
                                "No Matching Attachments",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No attachments match the selected filters.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            ForEach(filteredAttachments) { attachment in
                                attachmentRow(attachment)
                            }

                            if showTotalValue {
                                LabeledContent("Total Value", value: totalValueText)
                                    .padding(16)
                                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                    .padding()
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

    private func attachmentRow(_ attachment: Attachment) -> some View {
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
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteAttachment(attachment)
            }
        }
    }

    private var filteredAttachments: [Attachment] {
        viewModel.sortedAttachments(
            viewModel.filteredAttachments(attachments, selectedType: selectedType, selectedStatusFilter: selectedStatusFilter, kits: kits),
            sortOrderRaw: itemSortOrder,
            sortDirectionRaw: itemSortDirectionRaw
        )
    }

    private var typeFilterOptions: [InventoryTypeFilterOption] {
        viewModel.groupedAttachmentTypes(from: viewModel.groupedAttachments(attachments, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw))
            .map { InventoryTypeFilterOption(id: $0, displayName: attachmentTypeDisplayName(for: $0)) }
    }

    private var groupedAttachments: [String: [Attachment]] {
        viewModel.groupedAttachments(filteredAttachments, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw)
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

    private func deleteAttachment(_ attachment: Attachment) {
        guard let index = groupedAttachments[attachment.type]?.firstIndex(where: { $0.persistentModelID == attachment.persistentModelID }) else {
            return
        }
        deleteAttachments(at: IndexSet(integer: index), in: attachment.type)
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

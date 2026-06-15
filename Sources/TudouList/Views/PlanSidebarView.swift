import SwiftUI

struct PlanSidebarView: View {
    let planLists: [PlanList]
    @Binding var selectedPlanId: UUID?
    let onAdd: () -> Void
    let onRename: (PlanList) -> Void
    let onDelete: (PlanList) -> Void

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedPlanId) {
                Section("计划表") {
                    ForEach(planLists) { plan in
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(plan.name)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                if !plan.descriptionText.isEmpty {
                                    Text(plan.descriptionText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        } icon: {
                            Image(systemName: "rectangle.stack")
                                .foregroundStyle(.secondary)
                        }
                        .tag(plan.id)
                        .contextMenu {
                            Button("重命名") {
                                onRename(plan)
                            }
                            Button("删除", role: .destructive) {
                                onDelete(plan)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            Button {
                onAdd()
            } label: {
                Label("新建计划表", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    onAdd()
                } label: {
                    Label("新建计划表", systemImage: "plus")
                }
            }
        }
    }
}

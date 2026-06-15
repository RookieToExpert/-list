import SwiftUI

struct GoalDetailView: View {
    let goal: Goal?
    @ObservedObject var store: PlanningStore

    var body: some View {
        Group {
            if let goal {
                GoalEditor(goal: goal, store: store)
                    .id(goal.id)
            } else {
                EmptyStateView(
                    systemImage: "square.and.pencil",
                    title: "选择目标查看详情",
                    message: "在右侧编辑标题、备注、完成状态和加急标记。"
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct GoalEditor: View {
    let goal: Goal
    @ObservedObject var store: PlanningStore
    @State private var draftTitle = ""
    @State private var draftNote = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case note
    }

    var body: some View {
        Form {
            Section {
                TextField("标题", text: $draftTitle, axis: .vertical)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .title)
                    .onSubmit {
                        saveDraft()
                    }

                TextEditor(text: $draftNote)
                    .font(.body)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .note)
            } header: {
                Text(goal.level.displayName)
            }

            Section("状态") {
                Toggle("已完成", isOn: Binding(
                    get: { store.goal(id: goal.id)?.isCompleted ?? goal.isCompleted },
                    set: { value in
                        saveDraft()
                        if let current = store.goal(id: goal.id) {
                            store.setCompleted(current, isCompleted: value)
                        }
                    }
                ))

                Toggle("加急", isOn: Binding(
                    get: { store.goal(id: goal.id)?.isUrgent ?? goal.isUrgent },
                    set: { _ in
                        saveDraft()
                        if let current = store.goal(id: goal.id) {
                            store.toggleUrgent(current)
                        }
                    }
                ))

                if let completedAt = store.goal(id: goal.id)?.completedAt ?? goal.completedAt {
                    LabeledContent("完成时间") {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("元信息") {
                LabeledContent("创建时间") {
                    Text(goal.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("更新时间") {
                    Text((store.goal(id: goal.id)?.updatedAt ?? goal.updatedAt).formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
        .onAppear {
            syncDraft(from: goal)
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                saveDraft()
            }
        }
    }

    private func syncDraft(from goal: Goal) {
        let current = store.goal(id: goal.id) ?? goal
        draftTitle = current.title
        draftNote = current.note
    }

    private func saveDraft() {
        guard let current = store.goal(id: goal.id) else { return }
        if current.title != draftTitle || current.note != draftNote {
            store.updateGoal(current, title: draftTitle, note: draftNote)
        }
    }
}

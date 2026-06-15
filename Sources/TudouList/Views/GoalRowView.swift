import SwiftUI

struct GoalRowView: View {
    let goal: Goal
    let planListId: UUID
    let levelDepth: Int
    @Binding var selectedGoalId: UUID?
    @Binding var expandedGoalIds: Set<UUID>
    @ObservedObject var store: PlanningStore
    let onDelete: (Goal) -> Void

    private var isSelected: Bool { selectedGoalId == goal.id }
    private var hasChildren: Bool { store.hasChildren(goal) }
    private var isExpanded: Bool { expandedGoalIds.contains(goal.id) }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    if hasChildren {
                        if isExpanded {
                            expandedGoalIds.remove(goal.id)
                        } else {
                            expandedGoalIds.insert(goal.id)
                        }
                    }
                } label: {
                    Image(systemName: hasChildren ? "chevron.right" : "circle.fill")
                        .font(hasChildren ? .caption.weight(.semibold) : .system(size: 4))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 22)
                }
                .buttonStyle(.plain)

                Button {
                    store.setCompleted(goal, isCompleted: !goal.isCompleted)
                } label: {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(goal.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Label(goal.level.displayName, systemImage: goal.level.accentSymbol)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        if goal.isUrgent {
                            Label("加急", systemImage: "flag.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.orange.opacity(0.9))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.12), in: Capsule())
                        }
                    }

                    Text(goal.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                        .strikethrough(goal.isCompleted, color: .secondary)
                        .lineLimit(2)

                    if !goal.note.isEmpty {
                        Text(goal.note)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if let completedAt = goal.completedAt {
                        Text("完成于 \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                Button {
                    store.toggleUrgent(goal)
                } label: {
                    Label("加急", systemImage: goal.isUrgent ? "flag.fill" : "flag")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(goal.isUrgent ? Color.orange.opacity(0.9) : .secondary)

                Button {
                    addChildGoal()
                } label: {
                    Label("新增下一级", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .disabled(goal.level.childLevel == nil)
            }
            .padding(14)
            .background(rowBackground)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(goal.isUrgent ? Color.orange.opacity(0.55) : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(goal.isCompleted ? 0.62 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onTapGesture {
                selectedGoalId = goal.id
            }
            .contextMenu {
                Button(goal.isCompleted ? "取消完成" : "完成") {
                    store.setCompleted(goal, isCompleted: !goal.isCompleted)
                }
                Button(goal.isUrgent ? "取消加急" : "设为加急") {
                    store.toggleUrgent(goal)
                }
                Button("新增下一级") {
                    addChildGoal()
                }
                .disabled(goal.level.childLevel == nil)
                Divider()
                Button("删除", role: .destructive) {
                    onDelete(goal)
                }
            }

            if isExpanded {
                ForEach(store.orderedGoals(planListId: planListId, parentId: goal.id)) { child in
                    GoalRowView(
                        goal: child,
                        planListId: planListId,
                        levelDepth: levelDepth + 1,
                        selectedGoalId: $selectedGoalId,
                        expandedGoalIds: $expandedGoalIds,
                        store: store,
                        onDelete: onDelete
                    )
                }
            }
        }
        .padding(.leading, CGFloat(levelDepth) * 24)
    }

    private var rowBackground: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.12))
        }
        if goal.isUrgent {
            return AnyShapeStyle(Color.orange.opacity(0.06))
        }
        return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
    }

    private func addChildGoal() {
        guard goal.level.childLevel != nil else { return }
        if let child = store.createGoal(planListId: planListId, parent: goal) {
            expandedGoalIds.insert(goal.id)
            selectedGoalId = child.id
        }
    }
}

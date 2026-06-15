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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    toggleExpansion()
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

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(goal.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                            .strikethrough(goal.isCompleted, color: .secondary)
                            .lineLimit(2)

                        if goal.isUrgent {
                            Label("加急", systemImage: "flag.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.orange.opacity(0.9))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.12), in: Capsule())
                        }
                    }

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

                childGoalMenu
            }
            .padding(12)
            .background(rowBackground)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(goal.isUrgent ? Color.orange.opacity(0.55) : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 9)
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
                ForEach(store.allowedChildLevels(for: goal)) { childLevel in
                    Button("新增\(childLevel.displayName)") {
                        addChildGoal(level: childLevel)
                    }
                }
                Divider()
                Button("删除", role: .destructive) {
                    onDelete(goal)
                }
            }

            if isExpanded {
                GoalSiblingRows(
                    goals: store.orderedGoals(planListId: planListId, parentId: goal.id),
                    planListId: planListId,
                    levelDepth: levelDepth + 1,
                    selectedGoalId: $selectedGoalId,
                    expandedGoalIds: $expandedGoalIds,
                    store: store,
                    onDelete: onDelete
                )
            }
        }
        .padding(.leading, CGFloat(levelDepth) * 24)
    }

    @ViewBuilder
    private var childGoalMenu: some View {
        let childLevels = store.allowedChildLevels(for: goal)
        if childLevels.isEmpty {
            Button {} label: {
                Label("无可新增子目标", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(true)
        } else {
            Menu {
                ForEach(childLevels) { childLevel in
                    Button {
                        addChildGoal(level: childLevel)
                    } label: {
                        Label("新增\(childLevel.displayName)", systemImage: childLevel.accentSymbol)
                    }
                }
            } label: {
                Label("新增子目标", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
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

    private func toggleExpansion() {
        guard hasChildren else { return }
        if isExpanded {
            expandedGoalIds.remove(goal.id)
        } else {
            expandedGoalIds.insert(goal.id)
        }
    }

    private func addChildGoal(level: GoalLevel? = nil) {
        if let child = store.createGoal(planListId: planListId, parent: goal, level: level) {
            expandedGoalIds.insert(goal.id)
            selectedGoalId = child.id
        }
    }
}

struct GoalSiblingRows: View {
    let goals: [Goal]
    let planListId: UUID
    let levelDepth: Int
    @Binding var selectedGoalId: UUID?
    @Binding var expandedGoalIds: Set<UUID>
    @ObservedObject var store: PlanningStore
    let onDelete: (Goal) -> Void

    private var sections: [GoalPeriodSection] {
        GoalPeriodSection.makeSections(from: goals)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 4) {
                    periodHeader(for: section)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(section.goals) { goal in
                            GoalRowView(
                                goal: goal,
                                planListId: planListId,
                                levelDepth: levelDepth,
                                selectedGoalId: $selectedGoalId,
                                expandedGoalIds: $expandedGoalIds,
                                store: store,
                                onDelete: onDelete
                            )
                        }
                    }
                }
            }
        }
    }

    private func periodHeader(for section: GoalPeriodSection) -> some View {
        Label(section.displayName, systemImage: section.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, CGFloat(levelDepth) * 24 + 42)
            .padding(.top, levelDepth == 0 ? 2 : 4)
    }
}

private struct GoalPeriodSection: Identifiable {
    let id: String
    let displayName: String
    let systemImage: String
    var goals: [Goal]

    static func makeSections(from goals: [Goal]) -> [GoalPeriodSection] {
        goals.reduce(into: []) { sections, goal in
            if let lastIndex = sections.indices.last,
               sections[lastIndex].id == goal.periodDisplayKey {
                sections[lastIndex].goals.append(goal)
            } else {
                sections.append(
                    GoalPeriodSection(
                        id: goal.periodDisplayKey,
                        displayName: goal.periodDisplayName,
                        systemImage: goal.level.accentSymbol,
                        goals: [goal]
                    )
                )
            }
        }
    }
}

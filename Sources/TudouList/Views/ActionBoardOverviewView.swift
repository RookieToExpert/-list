import SwiftUI
import UniformTypeIdentifiers

struct ActionBoardOverviewView: View {
    @Binding var selectedGoalId: UUID?
    @ObservedObject var store: PlanningStore

    private var todayGoals: [Goal] {
        store.sortedGoals(
            store.goals.filter {
                $0.effectiveKind == .action &&
                !$0.isCompleted &&
                !$0.isLegacyWeekContainer &&
                $0.effectiveActionScope == .today
            }
        )
    }

    private var allocationGoals: [Goal] {
        store.sortedGoals(
            store.goals.filter {
                $0.effectiveKind == .action &&
                !$0.isCompleted &&
                !$0.isLegacyWeekContainer &&
                ($0.effectiveActionScope == .thisWeek || $0.effectiveActionScope == .later)
            }
        )
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: 16) {
                ActionBoardColumn(
                    title: "今日必须",
                    emptyMessage: "暂无今日必须",
                    goals: todayGoals,
                    targetScope: .today,
                    selectedGoalId: $selectedGoalId,
                    store: store
                )

                ActionBoardColumn(
                    title: "待分配",
                    emptyMessage: "暂无待分配",
                    goals: allocationGoals,
                    targetScope: .later,
                    selectedGoalId: $selectedGoalId,
                    store: store
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct ActionBoardColumn: View {
    let title: String
    let emptyMessage: String
    let goals: [Goal]
    let targetScope: ActionScope
    @Binding var selectedGoalId: UUID?
    @ObservedObject var store: PlanningStore
    @State private var isDropTargeted = false
    @State private var pendingMove: PendingActionScopeMove?
    @AppStorage("urgentMoveWarningSuppressedDate") private var suppressedUrgentMoveWarningDate = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if goals.isEmpty {
                        Text(emptyMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(goals) { goal in
                                draggableRow(for: goal)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(columnBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onDrop(of: [UTType.text.identifier], isTargeted: $isDropTargeted, perform: handleDrop(providers:))
        .urgentMoveConfirmation(pendingMove: $pendingMove, store: store)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("\(goals.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.10), in: Capsule())

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.55)
        }
    }

    @ViewBuilder
    private func draggableRow(for goal: Goal) -> some View {
        OverviewGoalRowView(
            goal: goal,
            isSelected: selectedGoalId == goal.id,
            store: store
        ) {
            selectedGoalId = goal.id
        }
        .onDrag {
            NSItemProvider(object: goal.id.uuidString as NSString)
        }
    }

    private var columnBackground: Color {
        isDropTargeted ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.04)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let string = item as? String,
                  let goalId = UUID(uuidString: string) else {
                return
            }

            Task { @MainActor in
                guard let goal = store.goal(id: goalId),
                      goal.effectiveKind == .action,
                      !goal.isCompleted,
                      !goal.isLegacyWeekContainer,
                      goal.effectiveActionScope != targetScope else {
                    return
                }

                requestMove(for: goal, to: targetScope)
            }
        }

        return true
    }

    private func requestMove(for goal: Goal, to targetScope: ActionScope) {
        if shouldWarnBeforeActionScopeMove(goal, to: targetScope, suppressedDate: suppressedUrgentMoveWarningDate) {
            pendingMove = PendingActionScopeMove(goalID: goal.id, targetScope: targetScope)
        } else {
            store.updateActionScope(id: goal.id, actionScope: targetScope)
        }
    }
}

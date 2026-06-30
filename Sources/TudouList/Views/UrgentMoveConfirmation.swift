import SwiftUI

struct PendingActionScopeMove: Identifiable, Equatable {
    let goalID: UUID
    let targetScope: ActionScope

    var id: String {
        "\(goalID.uuidString)-\(targetScope.rawValue)"
    }
}

func shouldWarnBeforeActionScopeMove(_ goal: Goal, to targetScope: ActionScope, suppressedDate: String, now: Date = .now) -> Bool {
    guard targetScope != .today else { return false }
    guard goal.isUrgent else { return false }
    return suppressedDate != urgentMoveWarningDateString(for: now)
}

func urgentMoveWarningDateString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private struct UrgentMoveConfirmationModifier: ViewModifier {
    @Binding var pendingMove: PendingActionScopeMove?
    @ObservedObject var store: PlanningStore
    @AppStorage("urgentMoveWarningSuppressedDate") private var suppressedDate = ""

    func body(content: Content) -> some View {
        content
            .alert(
                "移回待分配？",
                isPresented: isPresentedBinding,
                presenting: pendingMove
            ) { move in
                Button("取消", role: .cancel) {
                    pendingMove = nil
                }
                Button("移回待分配") {
                    execute(move, suppressForToday: false)
                }
                Button("今日不再提示并移回") {
                    execute(move, suppressForToday: true)
                }
            } message: { _ in
                Text("这个任务当前标记为加急。移回待分配后，加急标记会被清除，之后再移回今日必须也不会自动恢复。")
            }
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { pendingMove != nil },
            set: { isPresented in
                if !isPresented {
                    pendingMove = nil
                }
            }
        )
    }

    private func execute(_ move: PendingActionScopeMove, suppressForToday: Bool) {
        if suppressForToday {
            suppressedDate = urgentMoveWarningDateString(for: .now)
        }
        store.updateActionScope(id: move.goalID, actionScope: move.targetScope)
        pendingMove = nil
    }
}

extension View {
    func urgentMoveConfirmation(pendingMove: Binding<PendingActionScopeMove?>, store: PlanningStore) -> some View {
        modifier(UrgentMoveConfirmationModifier(pendingMove: pendingMove, store: store))
    }
}

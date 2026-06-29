import Foundation

enum GoalLevelFilter: String, CaseIterable, Identifiable {
    case all
    case objectives
    case actions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .objectives:
            return "目标"
        case .actions:
            return "行动"
        }
    }

    func includes(_ goal: Goal) -> Bool {
        switch self {
        case .all:
            return true
        case .objectives:
            return goal.effectiveKind == .objective
        case .actions:
            return goal.effectiveKind == .action
        }
    }
}

import Foundation

enum OverviewKind: String, CaseIterable, Identifiable, Hashable {
    case todayFocus
    case thisWeek
    case actionBoard
    case urgent
    case all
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todayFocus: "今日重点"
        case .thisWeek: "待分配"
        case .actionBoard: "行动看板"
        case .urgent: "加急"
        case .all: "目标地图"
        case .completed: "已完成"
        }
    }

    var subtitle: String {
        switch self {
        case .todayFocus: "只查看今天必须完成的行动"
        case .thisWeek: "集中查看还未安排到今日必须的行动"
        case .actionBoard: "在今日必须和待分配之间安排行动"
        case .urgent: "今日必须中标记加急的行动"
        case .all: "按长期目标查看阶段和行动进展"
        case .completed: "查看最近完成的目标"
        }
    }

    var systemImage: String {
        switch self {
        case .todayFocus: "sun.max"
        case .thisWeek: "calendar.day.timeline.left"
        case .actionBoard: "rectangle.split.2x1"
        case .urgent: "flag"
        case .all: "rectangle.3.group"
        case .completed: "checkmark.circle"
        }
    }

    var emptyTitle: String {
        switch self {
        case .todayFocus: "暂无今日重点"
        case .thisWeek: "暂无待分配"
        case .actionBoard: "暂无行动"
        case .urgent: "暂无加急目标"
        case .all: "暂无长期目标"
        case .completed: "暂无已完成目标"
        }
    }

    var emptyMessage: String {
        switch self {
        case .todayFocus: "在阶段目标中添加今日必须后，它们会出现在这里。"
        case .thisWeek: "创建本周行动或待安排任务后，它们会显示在这里。"
        case .actionBoard: "在阶段目标中添加今日必须或待分配后，它们会显示在这里。"
        case .urgent: "在今日必须任务上标记加急后，它们会显示在这里。"
        case .all: "进入某个计划表，创建长期目标后，它们会出现在这里。"
        case .completed: "完成目标后，它们会按时间出现在这里。"
        }
    }
}

import SwiftUI

struct GoalMapOverviewView: View {
    @Binding var selectedGoalId: UUID?
    @ObservedObject var store: PlanningStore

    private var sections: [GoalMapSection] {
        store.goalMapSections()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.planList.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(section.summaries) { summary in
                                GoalMapSummaryRow(
                                    summary: summary,
                                    isSelected: selectedGoalId == summary.rootGoal.id
                                ) {
                                    selectedGoalId = summary.rootGoal.id
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct GoalMapSummaryRow: View {
    let summary: GoalMapSummary
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.rootGoal.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            Text(summary.planListName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(summaryLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture(perform: onSelect)
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.04)
    }

    private var summaryLine: String {
        "\(summary.stageGoalCount) 个阶段目标 · \(summary.todayActionCount) 个今日必须 · \(summary.allocationActionCount) 个待分配 · \(summary.completedActionCount) 个已完成"
    }
}

import Combine
import Foundation

@MainActor
final class PlanningStore: ObservableObject {
    @Published private(set) var planLists: [PlanList] = []
    @Published private(set) var goals: [Goal] = []

    private let storeURL: URL

    init(storeURL: URL? = nil) {
        self.storeURL = storeURL ?? Self.defaultStoreURL()
        load()
    }

    func createPlanList(name: String, description: String = "") -> PlanList {
        let plan = PlanList(name: cleaned(name, fallback: "新的计划表"), descriptionText: description)
        planLists.append(plan)
        save()
        return plan
    }

    func updatePlanList(_ plan: PlanList, name: String? = nil, description: String? = nil) {
        guard let index = planLists.firstIndex(where: { $0.id == plan.id }) else { return }
        if let name {
            planLists[index].name = cleaned(name, fallback: planLists[index].name)
        }
        if let description {
            planLists[index].descriptionText = description
        }
        planLists[index].updatedAt = .now
        save()
    }

    func deletePlanList(_ plan: PlanList) {
        goals.removeAll { $0.planListId == plan.id }
        planLists.removeAll { $0.id == plan.id }
        save()
    }

    func createGoal(
        planListId: UUID,
        parent: Goal?,
        title: String? = nil
    ) -> Goal? {
        let level: GoalLevel
        if let parent {
            guard let childLevel = parent.level.childLevel else { return nil }
            level = childLevel
        } else {
            level = .year
        }

        let siblings = goals.filter {
            $0.planListId == planListId && $0.parentId == parent?.id && $0.level == level
        }
        let nextOrder = (siblings.map(\.sortOrder).max() ?? 0) + 1
        let goal = Goal(
            planListId: planListId,
            parentId: parent?.id,
            title: cleaned(title ?? defaultTitle(for: level), fallback: defaultTitle(for: level)),
            level: level,
            sortOrder: nextOrder
        )
        goals.append(goal)
        if let parent, let parentIndex = goals.firstIndex(where: { $0.id == parent.id }) {
            goals[parentIndex].updatedAt = .now
        }
        save()
        return goal
    }

    func updateGoal(_ goal: Goal, title: String? = nil, note: String? = nil) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        if let title {
            goals[index].title = cleaned(title, fallback: goals[index].title)
        }
        if let note {
            goals[index].note = note
        }
        goals[index].updatedAt = .now
        save()
    }

    func setCompleted(_ goal: Goal, isCompleted: Bool) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index].isCompleted = isCompleted
        goals[index].completedAt = isCompleted ? .now : nil
        goals[index].updatedAt = .now
        save()
    }

    func toggleUrgent(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index].isUrgent.toggle()
        goals[index].updatedAt = .now
        save()
    }

    func deleteGoal(_ goal: Goal) {
        let deleteIds = Set(([goal] + descendantGoals(of: goal.id, in: goals)).map(\.id))
        goals.removeAll { deleteIds.contains($0.id) }
        save()
    }

    func goal(id: UUID?) -> Goal? {
        guard let id else { return nil }
        return goals.first { $0.id == id }
    }

    // TODO: Add same-level drag reordering by updating sortOrder values from a drop delegate.
    func orderedGoals(planListId: UUID, parentId: UUID?) -> [Goal] {
        goals
            .filter { $0.planListId == planListId && $0.parentId == parentId }
            .sorted { lhs, rhs in
                if lhs.isUrgent != rhs.isUrgent { return lhs.isUrgent && !rhs.isUrgent }
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted && rhs.isCompleted }
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }
    }

    func hasChildren(_ goal: Goal) -> Bool {
        goals.contains { $0.parentId == goal.id }
    }

    private func descendantGoals(of parentId: UUID, in goals: [Goal]) -> [Goal] {
        let children = goals.filter { $0.parentId == parentId }
        return children + children.flatMap { descendantGoals(of: $0.id, in: goals) }
    }

    private func cleaned(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func defaultTitle(for level: GoalLevel) -> String {
        switch level {
        case .year: "新的年目标"
        case .month: "新的月目标"
        case .week: "新的周目标"
        case .day: "新的日目标"
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storeURL)
            let snapshot = try JSONDecoder.tudou.decode(StoreSnapshot.self, from: data)
            planLists = snapshot.planLists
            goals = snapshot.goals
        } catch CocoaError.fileReadNoSuchFile {
            planLists = []
            goals = []
        } catch {
            assertionFailure("JSON store load failed: \(error)")
            planLists = []
            goals = []
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let snapshot = StoreSnapshot(planLists: planLists, goals: goals)
            let data = try JSONEncoder.tudou.encode(snapshot)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            assertionFailure("JSON store save failed: \(error)")
        }
    }

    private static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appending(path: "TudouList", directoryHint: .isDirectory)
            .appending(path: "store.json")
    }
}

private struct StoreSnapshot: Codable {
    var planLists: [PlanList]
    var goals: [Goal]
}

private extension JSONEncoder {
    static var tudou: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var tudou: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

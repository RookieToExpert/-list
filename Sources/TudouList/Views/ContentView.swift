import SwiftUI

struct ContentView: View {
    @StateObject private var store = PlanningStore()
    @State private var selectedPlanId: UUID?
    @State private var selectedGoalId: UUID?
    @State private var newPlanName = ""
    @State private var showingNewPlan = false
    @State private var renamingPlan: PlanList?
    @State private var renamePlanName = ""
    @State private var deletingPlan: PlanList?

    private var selectedPlan: PlanList? {
        guard let selectedPlanId else { return nil }
        return store.planLists.first { $0.id == selectedPlanId }
    }

    private var selectedGoal: Goal? {
        store.goal(id: selectedGoalId)
    }

    var body: some View {
        NavigationSplitView {
            PlanSidebarView(
                planLists: store.planLists,
                selectedPlanId: $selectedPlanId,
                onAdd: {
                    newPlanName = ""
                    showingNewPlan = true
                },
                onRename: { plan in
                    renamingPlan = plan
                    renamePlanName = plan.name
                },
                onDelete: { plan in
                    deletingPlan = plan
                }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            GoalBoardView(
                plan: selectedPlan,
                selectedGoalId: $selectedGoalId,
                store: store
            )
            .navigationSplitViewColumnWidth(min: 460, ideal: 620)
        } detail: {
            GoalDetailView(goal: selectedGoal, store: store)
                .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 460)
        }
        .frame(minWidth: 980, minHeight: 620)
        .onAppear {
            selectedPlanId = selectedPlanId ?? store.planLists.first?.id
        }
        .onChange(of: store.planLists.map(\.id)) { _, ids in
            if selectedPlanId == nil {
                selectedPlanId = ids.first
            } else if let selectedPlanId, !ids.contains(selectedPlanId) {
                self.selectedPlanId = ids.first
                selectedGoalId = nil
            }
        }
        .onChange(of: selectedPlanId) {
            selectedGoalId = nil
        }
        .alert("新建计划表", isPresented: $showingNewPlan) {
            TextField("计划表名称", text: $newPlanName)
            Button("创建") {
                let plan = store.createPlanList(name: newPlanName)
                selectedPlanId = plan.id
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("例如：学习计划、工作冲刺、长期目标。")
        }
        .alert("重命名计划表", isPresented: Binding(
            get: { renamingPlan != nil },
            set: { if !$0 { renamingPlan = nil } }
        )) {
            TextField("计划表名称", text: $renamePlanName)
            Button("保存") {
                if let renamingPlan {
                    store.updatePlanList(renamingPlan, name: renamePlanName)
                }
                renamingPlan = nil
            }
            Button("取消", role: .cancel) {
                renamingPlan = nil
            }
        }
        .confirmationDialog(
            "删除计划表？",
            isPresented: Binding(
                get: { deletingPlan != nil },
                set: { if !$0 { deletingPlan = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let deletingPlan {
                    store.deletePlanList(deletingPlan)
                    if selectedPlanId == deletingPlan.id {
                        selectedPlanId = store.planLists.first?.id
                    }
                    selectedGoalId = nil
                }
                deletingPlan = nil
            }
            Button("取消", role: .cancel) {
                deletingPlan = nil
            }
        } message: {
            Text("该计划表中的所有目标都会被删除。")
        }
    }
}

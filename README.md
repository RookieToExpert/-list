# TudouList

TudouList 是一个 macOS 原生 SwiftUI 计划表 / Todo / Goal Planning 应用。它现在以“目标 + 行动”的方式组织任务：在普通计划表里，你可以围绕「长期目标」「阶段目标」「今日必须」「待分配」来拆解与推进工作，同时保留跨计划表的总览视图。

![alt text](image.png)

![alt text](image-1.png)

## 已实现功能

- 多计划表管理：新增、重命名、删除计划表。
- 三栏 macOS 原生布局：左侧 Sidebar，中间目标列表 / 总览，右侧目标详情编辑。
- 总览 Smart List：支持「今日重点」「待分配」「加急」「全部目标」「已完成」。
- 跨计划表展示：总览可以集中显示所有计划表里的相关目标，并展示所属计划表和父级路径。
- 总览显示筛选：在「全部目标」「已完成」中支持「全部」「仅行动」两种显示范围。
- 目标模型：底层仍兼容 `year / month / week / day` 四级结构，但 UI 语义已切换为「长期目标 / 阶段目标 / 今日必须 / 待分配」。
- 目标编辑：支持标题、备注、完成状态、加急状态编辑。
- 自动保存：标题和备注输入后实时写回数据源，并通过 JSON 本地持久化。
- 完成时间：完成目标时自动写入 `completedAt`，取消完成时清空；中间列表显示完成日期。
- 普通计划表展示：
  - 长期目标下添加阶段目标。
  - 阶段目标展开后固定显示「今日必须」「待分配」「已完成」三个 section。
  - 已完成行动会从 active 区域分流到「已完成」section。
  - 旧版 legacy week container（如“第 3 周”）会被隐藏，子任务视觉打平到「待分配」。
- 任务移动：支持通过右键菜单在「今日必须」和「待分配」之间移动 action，不修改 `parentId`。
- 排序规则：同级目标中未完成优先；active section 内加急优先，其次按 `sortOrder` 和创建时间排序。
- 展开状态：普通计划表的展开 / 收起状态在 App 运行期间保持稳定，不会因刷新轻易丢失。
- 删除确认：删除计划表或目标前确认；删除目标会同时删除子目标。
- 级联完成：完成上层目标时会递归完成其所有后代目标；取消完成时只影响当前目标。
- 本地持久化：使用 Codable + JSON 保存数据，关闭 App 后重新打开仍然存在。
- 浅色 / 深色模式：使用系统颜色与材质，跟随 macOS 外观。

## 总览规则

- 今日重点：只显示未完成的 `today action`，也就是“今日必须”。
- 待分配：显示未完成的 `thisWeek + later action`，也就是当前尚未进入“今日必须”的行动池。
- 加急：只显示未完成、且属于“今日必须”的加急 action。
- 全部目标：显示全部长期目标、阶段目标和行动；默认过滤 legacy week container 本体。
- 已完成：显示全部已完成目标，按完成时间倒序；默认过滤 legacy week container 本体。

## 如何运行

```bash
swift build
swift run TudouList
```

如果你希望像普通 macOS App 一样打开，可以使用项目里的打包脚本生成 `.app`，再自行打包为 DMG / Release。

## 主要文件结构

```text
Package.swift
Sources/TudouList/
  TudouListApp.swift
  Models/
    Goal.swift
    GoalLevel.swift
    GoalLevelFilter.swift
    OverviewKind.swift
    OverviewStats.swift
    PlanList.swift
    SidebarSelection.swift
  Stores/
    PlanningStore.swift
  Views/
    ContentView.swift
    EmptyOverviewView.swift
    EmptyStateView.swift
    GoalBoardView.swift
    GoalDetailView.swift
    GoalRowView.swift
    OverviewContentView.swift
    OverviewGoalRowView.swift
    OverviewStatsView.swift
    PlanSidebarView.swift
```

## 后续可扩展方向

- 拖拽调整同级目标顺序，并写回 `sortOrder`。
- 为计划表增加描述编辑入口和统计信息。
- 为目标增加更明确的 `dueDate` / 调度语义，让今日重点和待分配可以更精准。
- 增加“移动到今日必须 / 移回待分配”之外的批量调整能力，例如右键批量移动或拖拽。
- 增加目标搜索、更多筛选和按日期聚合视图。
- 增加快捷键，例如快速新增长期目标 / 阶段目标 / 行动。
- 增加单元测试，覆盖 Store 的层级删除、排序、总览查询和完成状态逻辑。

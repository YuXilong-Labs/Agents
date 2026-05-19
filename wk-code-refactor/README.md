# wk-code-refactor

`wk-code-refactor` 是一个面向单组件、子模块和单个功能点的重构 Agent。它的目标不是“把代码换一种写法”，而是在完整理解旧实现的前提下，用 TDD、功能点矩阵和分阶段计划保证重构前后功能一致，同时允许在执行过程中对现有架构与代码进行必要优化，避免实现弯路、过度设计和不符合既有规范的新增结构。

本仓库是唯一基仓。Codex 与 Claude Code 的运行目录都只作为安装目标，后续迭代应先修改本仓库，再执行校验与安装同步。

## 适用范围

- 重构整个组件。
- 重构组件内的子模块。
- 重构已有组件中的单个 `feature_point`，例如直播间中的某一个挂件。
- 从旧 Objective-C 实现迁移到新的 Swift 实现。
- 对输入框统一架构这类跨文件、跨场景的重构进行计划、执行和复核。

## 核心原则

- 旧实现先读：必须先确认 `legacy_reference`，仔细阅读旧代码并拆出完整功能点。
- 新范围先定：必须确认 `new_implementation_scope`，包括目标路径、边界和不做什么。
- 功能一致：使用功能点矩阵逐项记录、复核和验收每个 `feature_point`。
- TDD 优先：按照 `RED -> GREEN -> REFACTOR` 锁住行为，再进行实现替换或结构优化。
- 计划确认：`plan_confirmed_required` 是硬门禁，未确认计划不得进入代码修改。
- 渐进式披露：默认先输出必要信息；只有在复杂度、风险或用户要求增加时展开完整细节。
- 服从现有规范：重构生成的代码必须符合项目已有 rules、命名、分层、依赖和验证方式。

## 文件结构

```text
wk-code-refactor/
├── README.md
├── core/
│   └── wk-code-refactor-core.md
├── codex/
│   └── wk-code-refactor.toml
├── claude/
│   └── wk-code-refactor.md
├── docs/
│   ├── workflow.md
│   ├── function-matrix-template.md
│   ├── tdd-checklist.md
│   └── technical-selection-checklist.md
└── scripts/
    ├── install.sh
    └── verify.sh
```

## 安装

```bash
cd /Users/yuxilong/Desktop/code/Agents/wk-code-refactor
scripts/verify.sh
scripts/install.sh
```

安装目标：

- Codex: `/Users/yuxilong/.codex/agents/wk-code-refactor.toml`
- Codex shared core: `/Users/yuxilong/.codex/agents/shared/wk-code-refactor-core.md`
- Claude Code: `/Users/yuxilong/.claude/agents/wk-code-refactor.md`

## Codex 使用

在 Codex 中调用 `wk-code-refactor` 时，先提供：

- `legacy_reference`: 旧实现代码路径或可判定的旧实现入口。
- `new_implementation_scope`: 新实现范围、目标路径、迁移边界。
- 重构粒度：全组件、子模块，或指定单个 `feature_point`。
- 可用验证方式：单测、集成测试、编译命令、SwiftLint、手工验证路径等。

Codex 侧推荐角色分工：

- `planner`: 使用当前最高可用模型与最高推理强度，只读分析，产出功能点矩阵和计划。
- `executor`: 使用高能力执行模型，按已确认计划分阶段落地。
- `verifier`: 与 executor 同级模型，独立复核功能点一致性、测试和编译证据。

执行阶段应充分利用 `/goal`：把已确认的阶段目标写成明确 objective，每阶段完成后用验证证据关闭，避免长重构中途漂移。

## Claude Code 使用

Claude Code 入口位于：

```text
/Users/yuxilong/.claude/agents/wk-code-refactor.md
```

Claude Code 侧推荐模型权重：

- planner: Opus 4.6/4.7 或当前最高可用 Opus，最高推理配置。
- executor: Sonnet 4.6 或当前高能力 Sonnet。
- verifier: 与 executor 同级模型，独立复核。

如果当前运行环境无法精确选择这些模型，应使用可用的最高规划模型和高能力执行模型，并在计划中明确记录实际模型选择。

## 技术选型确认

计划阶段必须确认技术选型，尤其是 iOS 组件重构常见项：

- 布局框架：Masonry、SnapKit 或项目既有布局方式。
- RTL 适配：镜像方向、物理方向、文字方向、资源方向。
- 国际化：KString 或项目既有多语言方案。
- 资源加载、路由、桥接、依赖边界、编译验证方式。

## 常见示例

重构整个组件：

```text
使用 wk-code-refactor 重构 BTUserCardPanelNew/Classes/V2。
legacy_reference 是 .old/BTUserCardPanel，对齐全部 Room V2 功能点。
new_implementation_scope 是 BTUserCardPanelNew/Classes/Views/V2。
先输出功能点矩阵和计划，确认后再执行。
```

重构组件内单个挂件：

```text
使用 wk-code-refactor 只重构直播间中的某个挂件 feature_point。
legacy_reference 是旧挂件实现路径。
new_implementation_scope 是新挂件视图与 ViewModel 的目标路径。
不要改动其它挂件行为。
```

旧 OC 到新 Swift：

```text
使用 wk-code-refactor 将旧 Objective-C 输入区域迁移到 Swift。
先拆旧 OC 的交互、布局、事件、状态、埋点、降级逻辑，再列计划。
```

输入框统一架构：

```text
使用 wk-code-refactor 评估并执行私聊/群聊输入框统一重构。
要求先列完整功能点和差异矩阵，计划确认后分阶段迁移。
```

## 验证与失败处理

校验 Agent 产物：

```bash
scripts/verify.sh
```

同步到运行目录：

```bash
scripts/install.sh
```

安装后检查：

```bash
test -e /Users/yuxilong/.codex/agents/wk-code-refactor.toml
test -e /Users/yuxilong/.claude/agents/wk-code-refactor.md
```

如果校验失败，先修复基仓文件，再重新执行 `scripts/verify.sh` 和 `scripts/install.sh`。不要直接修改 Codex 或 Claude Code 运行目录中的安装产物。

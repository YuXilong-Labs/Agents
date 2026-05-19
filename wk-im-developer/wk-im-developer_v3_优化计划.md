# wk-im-developer v3 优化计划

> 制定时间：2026-05-19
> 基于：v2 实际使用痛点分析 + Claude Code 原生能力调研

---

## 一、背景与痛点

当前 v2 方案存在三个核心问题：

1. **`@` 引用不可用**：在空的 `BTIM-Workspace` 目录用 `claude --agent wk-im-developer` 启动，组件代码不在工作目录下，`@BTIMService/xxx.swift` 无法引用。

2. **未利用 Claude Code 原生能力**：自建了 5 个 subagent 手动编排（planner/executor/verifier/explorer）、手动模型路由（高/中/低）、自建记忆系统（.wkim/），而 Claude Code 原生已支持这些能力。

3. **跨组件编译验证缺失**：BTIMService 和 BTIMModule 是独立仓库，service 新增函数未发布时 module 编译失败，无法在本地验证跨组件改动。

---

## 二、解决方案

### 2.1 解决 `@` 引用问题

**方案**：改为直接在包含组件源码的 workspace 目录启动 claude，通过 `CLAUDE.md` + `.claude/` 让 agent 自动生效。

```
BTIM-Workspace/
├── BTIMService -> ~/Code/BTIMService   (symlink，独立仓库原地不动)
├── BTIMModule  -> ~/Code/BTIMModule    (symlink)
├── HostApp/                            (壳工程，用于联合编译)
│   ├── Podfile
│   └── HostApp.xcworkspace
├── CLAUDE.md                           (精简规则 <80行)
├── .claude/
│   ├── settings.json
│   ├── agents/
│   │   └── wk-im-explorer.md
│   └── skills/
│       ├── wk-im-feature/
│       ├── wk-im-bugfix/
│       └── wk-im-knowledge/
├── scripts/
│   ├── setup.sh
│   ├── verify.sh
│   └── guard.sh
└── .wk-im-workspace.json               (路径配置持久化)
```

启动方式变为：
```bash
cd BTIM-Workspace && claude
```

### 2.2 解决跨组件编译验证

**方案**：HostApp 的 Podfile 用 `:path =>` 同时引用两个本地组件源码：

```ruby
platform :ios, '15.0'

target 'HostApp' do
  use_frameworks!
  pod 'BTIMService', :path => '../BTIMService'
  pod 'BTIMModule',  :path => '../BTIMModule'
end
```

`pod install` 后两个组件在同一 xcworkspace 中编译。BTIMService 新增函数后，BTIMModule 可以直接引用，无需发布。

### 2.3 利用 Claude Code 原生能力

| 当前 v2（自建） | 优化后 v3（原生） |
|---------------|----------------|
| 5 个 subagent 手动编排 | 1 个 explorer subagent（自动委派） |
| 手动 3 级模型路由 | 删除，信任 Claude Code |
| 自建 .wkim/ 记忆系统 | 原生 `memory: project` |
| 自建 skill 触发匹配 | 原生 description 自动匹配 |
| 多 agent 流水线 | CLAUDE.md 工作流规则 + Claude 自行执行 |

---

## 三、setup.sh 设计

支持两种模式：

```bash
# 模式 1：交互式引导
bash scripts/setup.sh

# 模式 2：直接指定路径
bash scripts/setup.sh \
  --service ~/Code/BTIMService \
  --module  ~/Code/BTIMModule \
  --host-app ~/Code/HostApp    # 可选，不传则自动创建
```

**逻辑**：
1. 解析参数或交互式询问路径
2. 创建 symlink：`BTIMService -> <service_path>`、`BTIMModule -> <module_path>`
3. 处理 HostApp：已有则复用并修改 Podfile，没有则创建最小壳工程
4. 持久化配置到 `.wk-im-workspace.json`
5. 运行 `pod install` + `xcodebuild build` 验证

**配置文件**（`.wk-im-workspace.json`）：
```json
{
  "service": "~/Code/BTIMService",
  "module": "~/Code/BTIMModule",
  "hostApp": "~/Code/HostApp"
}
```

---

## 四、完整 Task 列表

### Task 1：创建 workspace 目录结构和 setup.sh

**目标**：产出一键初始化脚本，新人执行后得到可工作的 workspace。

**交付物**：
- `scripts/setup.sh`（支持参数模式和交互模式）
- `.wk-im-workspace.json` 配置持久化
- `.gitignore`（忽略 `HostApp/Pods/`、`.claude/agent-memory*/`、`.wk-im-workspace.json`）

**验收标准**：
- `setup.sh --service <path> --module <path>` 执行成功，看到 "✅ Workspace ready"
- 重复执行检测到配置文件，提示复用

---

### Task 2：创建 HostApp 壳工程和 Podfile

**目标**：实现跨组件联合编译，BTIMModule 可以引用 BTIMService 未发布的新 API。

**交付物**：
- `HostApp/` 最小壳工程（AppDelegate + Info.plist + xcodeproj）
- `HostApp/Podfile`（`:path =>` 引用本地组件）

**验收标准**：
- BTIMService 新增 public 函数 → BTIMModule 引用 → `pod install` + `xcodebuild build` 通过
- 无需发布 BTIMService

---

### Task 3：编写精简 CLAUDE.md（<80行）

**目标**：只包含 Claude 无法从代码推断的信息，让 agent 在 workspace 中自动生效。

**内容**：
- 身份声明（中文回答身份问题）
- Build & Test 命令
- 架构硬约束（依赖方向、SDK 隔离、scope 限制）
- 可编辑范围 / 禁止修改范围
- 隐私规则
- 工作流指示：探索时用并行 subagent 分别探索两个组件

**验收标准**：
- 启动后问"你是谁"，正确回答
- 问"BTIMService 能 import BTIMModule 吗"，正确回答"不能"

---

### Task 4：创建 wk-im-explorer subagent

**目标**：定义只读探索 subagent，支持并行探索两个组件，利用原生 memory 积累代码知识。

**交付物**：`.claude/agents/wk-im-explorer.md`

```yaml
---
name: wk-im-explorer
description: Read-only code exploration for BTIMService and BTIMModule.
  Use proactively when needing to find files, trace call chains,
  understand module structure, or locate implementations.
  Can run in parallel for independent explorations of each component.
tools: Read, Grep, Glob, Bash(grep*), Bash(find*), Bash(git log*), Bash(git blame*)
disallowedTools: Write, Edit
model: haiku
memory: project
color: cyan
---
```

**验收标准**：
- 问跨组件问题，Claude 自动并行派出两个 explorer 分别探索
- 探索结果返回结构化摘要（<1500 token），主上下文不被文件内容污染

---

### Task 5：实现 hooks 守护机制

**目标**：确定性阻止越界操作，不依赖 agent 记住规则。

**交付物**：
- `.claude/settings.json`（permissions + PostToolUse + Stop hooks）
- `scripts/scope-check.py`（阻止写入 Pods/ 等只读目录）
- `scripts/guard.sh`（检查 git diff 中的违规）

**验收标准**：
- 尝试修改 `HostApp/Pods/` 被阻止
- BTIMService 中 `import BTIMModule` 被 guard 检测到
- 任务结束自动运行 guard

---

### Task 6：创建 skills 体系（3 个核心 skill）

**目标**：按需加载的工作流，不污染每次对话上下文。

**交付物**：
- `.claude/skills/wk-im-feature/SKILL.md`：新功能开发（explore→plan→code→verify）
- `.claude/skills/wk-im-bugfix/SKILL.md`：Bug 修复（locate→reproduce→fix→verify）
- `.claude/skills/wk-im-knowledge/SKILL.md`：架构知识查询 + 附加文件

**验收标准**：
- 描述新功能需求，Claude 自动加载 feature skill
- 问架构问题，Claude 自动加载 knowledge skill

---

### Task 7：编写 verify.sh 和 guard.sh

**目标**：可靠的编译验证和规则检查。

**verify.sh 核心逻辑**：
```bash
cd HostApp && pod install --silent
xcodebuild -workspace HostApp.xcworkspace -scheme HostApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**guard.sh 检查项**：
- scope：修改了 HostApp/Pods/ 或 ThirdPartySDK/
- contract：BTIMService import BTIMModule / BTIMModule import ThirdPartyIMSDK
- privacy：日志中暴露 messageBody/token/cookie

**验收标准**：
- 正常代码 verify 通过
- 引入违规后 guard 报错

---

### Task 8：端到端集成验证和 README

**目标**：验证完整工作流，团队成员 5 分钟上手。

**验证场景**：
1. `@BTIMService/Sources/xxx.swift` 引用文件成功
2. 跨组件新增 API → 编译通过（无需发布）
3. 并行 subagent 探索两个组件
4. hook 拦截越界写操作
5. skill 自动触发

---

## 五、架构对比

```
v2（当前）                          v3（优化后）
─────────────────────────────────   ─────────────────────────────────
启动方式                            启动方式
claude --agent wk-im-developer      cd BTIM-Workspace && claude
（空目录）                          （代码目录）

@ 引用                              @ 引用
❌ 不可用                           ✅ 自然可用

subagent                            subagent
5 个（手动编排）                    1 个 explorer（自动委派 + 并行）

模型路由                            模型路由
自建 3 级路由                       删除，信任 Claude Code

记忆系统                            记忆系统
自建 .wkim/                         原生 memory: project

跨组件编译                          跨组件编译
❌ 无法验证                         ✅ HostApp + :path 联合编译

文件总数                            文件总数
69 个                               ~15 个
```

---

## 六、落地时间线

| Task | 预计时间 | 里程碑 |
|------|---------|--------|
| Task 1-2 | 1 天 | workspace 结构 + 跨组件编译可用 |
| Task 3-4 | 1 天 | CLAUDE.md + explorer subagent |
| Task 5-7 | 1 天 | hooks + skills + verify/guard |
| Task 8 | 半天 | 端到端验证 + README |

**总计**：约 3.5 天可完成可用版本。

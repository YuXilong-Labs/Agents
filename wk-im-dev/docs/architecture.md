# wk-im-dev 架构与运行原理

> 本文档面向「想理解或重画 wk-im-dev 架构图」的读者。所有 Mermaid 代码块可直接渲染。

> ⚠️ **2026-06-15 起的变更（部分图待刷新）**：Codex 路径已转为 plugin-native——
> 行为契约的**唯一事实源**是 `agents/wk-im-dev.md`（不再有 `core/wk-im-dev-core.md`）；
> Codex 激活走 plugin `agents/` + `SessionStart` hook（`hooks/session-init.sh`）+ `/wk-im-dev` 命令，
> 不再安装 `~/.codex/agents/wk-im-dev.toml` 与 `~/.codex/wk-im-dev.config.toml`（profile）。
> launcher 离线 fallback 现注入 `~/.wk-im-dev/wk-im-dev-agent.md`。
> 下方提到 `core spec 复制`、`wk-im-dev.toml → ~/.codex/agents/`、`profile.toml 合并 config.toml` 的图块属旧流程，待整体重绘。

---

## 0. 一句话定位

`wk-im-dev` = **一个跨 Codex / Claude Code 双运行时的 iOS IM 组件开发 Agent**。它把"开发者人格 + 项目知识库 + 跨 Pod 边界约束 + 多 subagent 分工 + 工程化校验"打包成一个可一键安装、可在任意 BTIMService / BTIMModule / HostApp 仓库激活的实体。

---

## 1. 总体架构（分层视图）

```mermaid
graph TB
  subgraph User["用户"]
    U[Developer]
  end

  subgraph Launcher["统一入口层"]
    L["wk-im-dev launcher\n(bin/wk-im-dev)"]
    D["wk-im-dev doctor"]
  end

  subgraph Runtime["运行时层 (二选一)"]
    direction LR
    CC["Claude Code\nplugin 模式"]
    CX["Codex CLI\nprofile + developer_instructions"]
  end

  subgraph Persona["人格 / 路由层"]
    MA["主 Agent: wk-im-dev"]
    CORE["core/wk-im-dev-core.md\n(共享事实源)"]
    AGENTS["codex/AGENTS.md\n(项目入口)"]
  end

  subgraph Subagents["Subagent 分工层"]
    EXP[wk-im-explorer]
    PLN[wk-im-planner]
    DBG[wk-im-debugger]
    EXE[wk-im-executor]
    VER[wk-im-verifier]
    KMA[wk-im-knowledge-maintainer]
  end

  subgraph Skills["技能层 (slash command)"]
    S1[setup]
    S2[feature]
    S3[bugfix]
    S4[im-review]
    S5[im-knowledge]
    S6[guard]
  end

  subgraph Tools["工具与外部依赖"]
    KB["docs/agent-knowledge/\n(Markdown LLM Wiki)"]
    WS["~/.wk-im-dev/workspace.json\n(组件路径配置)"]
    CG["CodeGraph\n(AST 索引, 可选)"]
    MCP["codegraph_* MCP tools"]
    SHELL["bin/*.sh\n(detect/init/kb-scan/guard/verify/...)"]
    HOOKS["hooks.json\nPostToolUse + Stop"]
  end

  subgraph Repos["目标仓库"]
    SVC[(BTIMService/)]
    MOD[(BTIMModule/)]
    APP[(HostApp/)]
  end

  U --> L
  U -.调用.-> D
  L -->|claude plugin 已装| CC
  L -->|否则| CX
  CC --> MA
  CX --> MA
  MA --- CORE
  CX --- AGENTS
  AGENTS --- CORE

  MA --> EXP
  MA --> PLN
  MA --> DBG
  MA --> EXE
  MA --> VER
  MA --> KMA
  MA --> S1
  MA --> S2
  MA --> S3
  MA --> S4
  MA --> S5
  MA --> S6

  EXP -.读.-> KB
  EXP -.可选.-> MCP
  KMA -.写.-> KB
  EXE -.改.-> SVC
  EXE -.改.-> MOD
  VER -.调.-> SHELL
  S1 -.调.-> SHELL

  MA -.读.-> WS
  WS -.指向.-> SVC
  WS -.指向.-> MOD
  WS -.指向.-> APP
  KB -.驻在.-> SVC
  KB -.驻在.-> MOD
  MCP -.读.-> CG
  CG -.驻在.-> SVC
  CG -.驻在.-> MOD

  HOOKS -.拦截.-> EXE
  HOOKS -.拦截.-> MA

  style L fill:#ffd54f,stroke:#f57f17,stroke-width:2px
  style MA fill:#90caf9,stroke:#1565c0,stroke-width:2px
  style CORE fill:#ce93d8,stroke:#6a1b9a
  style KB fill:#a5d6a7,stroke:#2e7d32
  style WS fill:#a5d6a7,stroke:#2e7d32
  style CG fill:#ffab91,stroke:#bf360c
  style HOOKS fill:#ef9a9a,stroke:#b71c1c
```

**关键含义**：

- 用户只看到一个命令 `wk-im-dev`，launcher 在背后选 runtime。
- 主 agent + subagent + skill 三层路由共同实现"一个 IM 任务怎么拆解"。
- 知识库 (`docs/agent-knowledge/`)、组件路径配置 (`~/.wk-im-dev/workspace.json`)、AST 索引 (`.codegraph/`) 是三类长期持久化的「外部记忆」。
- Hooks 在每次文件写入和会话结束时静默执行检查，是非 LLM 路径的强约束。

---

## 2. 一键安装 + 初始化流程

```mermaid
flowchart TD
  A["用户执行\ncurl ... bootstrap.sh | bash -s -- --target <repo>"] --> B{--target?}
  B -- 未填 --> B1[默认 pwd]
  B -- 已填 --> B2[使用指定路径]
  B1 --> C[sparse clone Agents 仓库]
  B2 --> C
  C --> D["调用 scripts/install.sh\n--runtime codex --target <repo>"]

  D --> E[validate_source_layout]
  E --> F[merge AGENTS.md marker 块]
  F --> G["复制 wk-im-dev.toml → ~/.codex/agents/"]
  G --> H["复制 core spec → ~/.wk-im-dev/wk-im-dev-core.md"]
  H --> I["复制 bin/*.sh + launcher → ~/.wk-im-dev/bin/"]
  I --> J[追加 shell rc PATH]
  J --> K["写 [profiles.wk-im-dev] 到 ~/.codex/config.toml"]

  K --> L{looks_like_im_repo?}
  L -- 是 --> M["自动调用 wk-im-init.sh --root <target> --quiet"]
  L -- 否 --> N[只装不 init,打印提示]

  M --> M1[wk-im-detect-env.sh 解析仓库类型]
  M1 --> M2["写 ~/.wk-im-dev/workspace.json\n(service/module/hostApps)"]
  M2 --> M3["wk-im-kb-bootstrap.sh\n创建 docs/agent-knowledge/ 骨架"]
  M3 --> M4["wk-im-kb-scan.sh\n刷新 generated block"]
  M4 --> M5["wk-im-kb-check.sh\n校验链接/完整性"]
  M5 --> M6{CodeGraph 已装?}
  M6 -- 是 --> M7["wk-im-codegraph.sh init\n每个 scan_root 建 .codegraph/"]
  M6 -- 否 + --with-codegraph --> M8["自动 install CodeGraph"]
  M6 -- 否 + 默认 --> M9[只打印提示性输出]
  M7 --> Z[打印 doctor / 启动命令]
  M8 --> M7
  M9 --> Z
  N --> Z

  Z --> Z1["用户执行 wk-im-dev"]

  style A fill:#fff59d
  style L fill:#ffcc80,stroke:#e65100
  style M fill:#c5e1a5,stroke:#33691e
  style Z fill:#80deea,stroke:#006064
```

**判断 `looks_like_im_repo` 的规则**：

- `<target>/BTIMService.podspec` **或** `<target>/BTIMModule.podspec` 存在 → 是
- `<target>/Podfile` 同时引用 `BTIMService` 和 `BTIMModule` → 是
- 否则 → 否（install 完成但跳过 init，避免污染临时目录）

---

## 3. Launcher 多 runtime 派发

```mermaid
flowchart LR
  IN[wk-im-dev] --> SUB{第一个参数}
  SUB -->|doctor / --doctor| D[run_doctor 打印安装状态]
  SUB -->|-h / --help| H[show_help 截取脚本头]
  SUB -->|其他/无| DET[detect_runtime]

  DET --> E1{WK_IM_DEV_RUNTIME?}
  E1 -- claude --> RC[claude 分支]
  E1 -- codex --> RX[codex 分支]
  E1 -- 未设 --> E2{claude_plugin_installed?}
  E2 -- 是 --> RC
  E2 -- 否 --> E3{codex 可用?}
  E3 -- 是 --> RX
  E3 -- 否 --> ERR["报错: no supported runtime"]

  RC -->|exec| CC["claude --agent wk-im-dev $@"]
  RX -->|exec| CX["codex -c developer_instructions=<core> \\\n  --profile wk-im-dev (或 -c model/effort fallback) $@"]

  style DET fill:#fff176
  style RC fill:#a5d6a7
  style RX fill:#ffab91
```

**`claude_plugin_installed` 判断条件**：

- `~/.claude/settings.json` 含 `"wk-im-dev"` 字符串
- 或当前目录是 plugin 源码（`./.claude-plugin/plugin.json` 含 `"wk-im-dev"`，用于 `--plugin-dir` 调试模式）

---

## 4. 主 Agent 意图路由

```mermaid
flowchart TD
  U["用户自然语言请求"] --> CHK["首次会话自检\n读 ~/.wk-im-dev/workspace.json"]
  CHK --> CHK2{workspace.json 存在?}
  CHK2 -- 是 --> CHK3[预读各组件 index.md]
  CHK2 -- 否 --> CHK4[提示用户跑 setup,继续处理本次请求]
  CHK3 --> RT[意图路由]
  CHK4 --> RT

  RT --> I1{意图分类}
  I1 -- 新功能/implement/add --> F1[feature skill → planner → executor → kb-maintainer → verifier]
  I1 -- bug/crash/修复 --> F2[bugfix skill → debugger → executor → verifier]
  I1 -- review/PR --> F3[im-review skill 只读]
  I1 -- 架构/设计/API/消息流程 --> F4[im-knowledge skill]
  I1 -- 探索/找文件/调用链 --> F5[wk-im-explorer subagent]
  I1 -- plan/重构 --> F6[wk-im-planner subagent]
  I1 -- 实现/补测试 --> F7[wk-im-executor subagent]
  I1 -- 验证/build/test --> F8[wk-im-verifier subagent]
  I1 -- 知识库/agent-knowledge --> F9[wk-im-knowledge-maintainer]
  I1 -- setup/init --> F10[setup skill]

  style CHK fill:#fff9c4
  style RT fill:#b3e5fc
```

---

## 5. 新功能工作流（subagent 协作时序）

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant MA as 主Agent (wk-im-dev)
  participant E as wk-im-explorer
  participant P as wk-im-planner
  participant X as wk-im-executor
  participant K as wk-im-knowledge-maintainer
  participant V as wk-im-verifier
  participant KB as docs/agent-knowledge/
  participant CG as CodeGraph MCP
  participant SRC as 源码 (BTIMService/Module)
  participant HK as Hooks

  U->>MA: 帮我加一个消息撤回确认弹窗
  MA->>KB: 读 index.md / common-flows.md
  MA->>E: 派发探索(并行 BTIMService+BTIMModule)
  E->>CG: codegraph_search "RecallMessage"
  E->>SRC: 读相关文件片段
  E-->>MA: 返回入口/调用链/相关 contracts
  MA->>P: 输出 plan(影响范围、API 契约变更、风险)
  P-->>MA: 阶段化计划
  MA->>U: 展示计划并请求确认 (非平凡需求)
  U-->>MA: 确认

  MA->>X: 按计划实现
  X->>SRC: Edit/Write 文件
  SRC-->>HK: PostToolUse 触发
  HK->>HK: scope-check.sh (检查依赖方向/路径白名单)
  HK->>HK: kb-refresh.sh (生命周期内 5min 去重)
  HK-->>X: 通过/阻断
  X-->>MA: 实现完成

  MA->>K: 更新 contracts / topics / source-map
  K->>KB: 修改 Curated Notes + generated block
  K-->>MA: 知识库已同步

  MA->>V: 运行 verifier
  V->>V: wk-im-verify.sh (build/test/guard)
  V->>V: wk-im-kb-check.sh
  V->>V: diff 范围核对
  V-->>MA: 全部通过

  MA-->>HK: 会话即将结束 → Stop hook
  HK->>HK: wk-im-guard.sh --quiet
  HK-->>MA: 通过

  MA-->>U: 报告: 变更文件 + 验证证据 + 剩余风险
```

---

## 6. Hook 静默校验通路

```mermaid
graph LR
  subgraph PostToolUse["PostToolUse(每次 Write/Edit/MultiEdit)"]
    direction TB
    H1[scope-check.sh]
    H2[kb-refresh.sh]
  end

  subgraph Stop["Stop(会话结束)"]
    H3[wk-im-guard.sh --quiet]
  end

  E["Edit/Write 工具"] --> H1
  H1 -->|路径含 Pods/ThirdPartySDK| BLOCK[阻断 + 报错]
  H1 -->|通过| H2
  H2 -->|向上查 *.podspec| FOUND{IM 仓库?}
  FOUND -- 否 --> NOP1[5ms 内退出 0]
  FOUND -- 是 --> RUN[触发 kb-scan 更新 generated block]

  SESS[会话结束] --> H3
  H3 -->|detect-env 返回 unknown| NOP2[快速退出 0]
  H3 -->|IM 仓库| CHECK[检查隐私关键词/契约一致性]

  style BLOCK fill:#ef9a9a,stroke:#b71c1c
  style NOP1 fill:#c8e6c9
  style NOP2 fill:#c8e6c9
```

**对非 IM 项目的安全性**：三个 hook 都内置"快速 no-op"路径（找不到 podspec、env=unknown 等），平均开销 < 5ms，不污染其他项目。

---

## 7. 知识库 (Knowledge Base) 结构

```mermaid
graph TB
  subgraph Repo["组件仓库 (BTIMService 或 BTIMModule)"]
    subgraph KB["docs/agent-knowledge/"]
      IDX[index.md]
      LOG[log.md]
      SM[source-map.md]
      WF[workflows.md]
      CT[contracts.md]
      subgraph Topics["topics/"]
        T1[entrypoints.md]
        T2[unread-count.md]
        T3[message-status.md]
        T4[chat-input.md]
      end
    end
    PODSPEC[BTIMService.podspec / BTIMModule.podspec]
    SRC[Classes/, Sources/]
  end

  IDX --> SM
  IDX --> WF
  IDX --> CT
  IDX --> Topics

  SM -.源码扫描.-> SRC
  CT -.public header 解析.-> SRC

  subgraph Block["每个 .md 内部结构"]
    FM["--- YAML frontmatter ---"]
    GB["<!-- WK-IM-GENERATED:START -->\n脚本维护(自动刷新)\n<!-- WK-IM-GENERATED:END -->"]
    CN[Curated Notes\n人工/agent 写入]
    SR[Source Refs\n相对路径]
  end

  IDX -.遵循.-> Block

  style GB fill:#ffe082
  style CN fill:#a5d6a7
```

**关键约定**：

- `<!-- WK-IM-GENERATED:START/END -->` 之间是脚本所有，agent 不写
- `Curated Notes` 由人 / agent 维护，是长期稳定知识的归宿
- 源码变化时，**同一提交**里同步更新知识库（强制约束）

---

## 8. 跨 Pod 边界约束（硬规则）

```mermaid
graph LR
  APP[HostApp] --> MOD[BTIMModule]
  MOD --> SVC[BTIMService]
  SVC --> SDK[ThirdPartyIMSDK]

  MOD -. ❌ 禁止 .-> SDK
  SVC -. ❌ 禁止反向 .-> MOD

  subgraph 隐私["隐私保护"]
    P1[禁止日志: privacy 声明字段]
    P2[禁止日志: token/accessToken]
    P3[禁止日志: cookie]
    P4[禁止日志: 用户内容/媒体]
    P5[禁止日志: 用户 PII]
  end

  subgraph 作用域["作用域保护"]
    R1[默认只改 BTIMService/]
    R2[默认只改 BTIMModule/]
    R3[禁止改 Pods/]
    R4[禁止改 vendor SDK]
  end

  style SDK fill:#ffab91
  style MOD fill:#90caf9
  style SVC fill:#a5d6a7
  style APP fill:#fff59d
```

约束的事实源：`skills/im-knowledge/constraints.md`（拆分为 `constraints-core.md` 给 subagent / `constraints-extended.md` 给主 agent，节省上下文）。

---

## 9. CodeGraph vs Knowledge Base 分工

```mermaid
graph LR
  Q[Agent 查询]

  Q -->|"调用关系/影响半径\n动态分发/Swift↔ObjC bridging"| CG["CodeGraph\n(AST 索引, 实时)"]
  Q -->|"组件入口/业务 topic\nCurated Notes/架构决策"| KB["Knowledge Base\n(Markdown Wiki)"]
  Q -->|"Public API 签名"| BOTH["两者互补:\nKB 给清单, CG 给精准 caller"]
  Q -->|"Cross-pod 契约校验"| CO["contracts.md +\ncodegraph_impact 双源"]

  CG -. 未安装时回退到 .-> KB

  style CG fill:#ffab91
  style KB fill:#a5d6a7
```

---

## 10. 文件 / 路径 全景

```text
项目源(可 git clone)               用户机器(安装后产物)
─────────────────────────          ────────────────────────────────
wk-im-dev/                         ~/.wk-im-dev/
├── .claude-plugin/                ├── wk-im-dev-core.md         (从 core/ 复制)
│   └── plugin.json                ├── workspace.json            (由 init 写)
├── agents/                        └── bin/
│   ├── wk-im-dev.md                   ├── wk-im-dev             (launcher)
│   ├── wk-im-explorer.md              ├── wk-im-init.sh
│   ├── wk-im-planner.md               ├── wk-im-detect-env.sh
│   ├── wk-im-debugger.md              ├── wk-im-kb-scan.sh
│   ├── wk-im-executor.md              ├── wk-im-kb-check.sh
│   ├── wk-im-verifier.md              ├── wk-im-kb-bootstrap.sh
│   └── wk-im-knowledge-maintainer.md  ├── wk-im-guard.sh
├── bin/                               ├── wk-im-verify.sh
│   └── (同上,源)                       └── wk-im-codegraph.sh
├── codex/
│   ├── AGENTS.md  ──→ 合并到目标仓库 <target>/AGENTS.md
│   ├── wk-im-dev.toml ──→ ~/.codex/agents/wk-im-dev.toml
│   └── profile.toml ──→ 合并到 ~/.codex/config.toml
│                                  ~/.codex/
├── core/                          ├── agents/wk-im-dev.toml
│   └── wk-im-dev-core.md          └── config.toml ([profiles.wk-im-dev] 块)
├── docs/
│   ├── architecture.md (本文)     <target repo>/
│   ├── advanced-install.md        ├── AGENTS.md  (含 WK-IM-DEV marker 块)
│   ├── agent-knowledge.md         ├── docs/agent-knowledge/      (init 写)
│   └── codegraph-integration.md   └── .codegraph/                (可选)
├── hooks/
│   ├── hooks.json
│   ├── scope-check.sh             ~/.zshrc 或 ~/.bashrc
│   └── kb-refresh.sh              # wk-im-dev
├── scripts/                       export PATH="$HOME/.wk-im-dev/bin:$PATH"
│   ├── bootstrap.sh
│   ├── install.sh
│   ├── uninstall.sh
│   └── verify.sh
└── skills/
    ├── setup/SKILL.md
    ├── feature/SKILL.md
    ├── bugfix/SKILL.md
    ├── im-review/SKILL.md
    ├── im-knowledge/...
    └── guard/...
```

---

## 11. 状态机：用户视角的会话生命周期

```mermaid
stateDiagram-v2
  [*] --> 未安装

  未安装 --> 已安装: curl bootstrap.sh | bash
  已安装 --> 已初始化: install 自动触发\n或手动 wk-im-init.sh
  已初始化 --> 会话就绪: wk-im-dev 启动

  会话就绪 --> 首次自检中: 用户首条消息
  首次自检中 --> 正常工作: workspace.json 存在
  首次自检中 --> 提示后工作: workspace.json 缺失

  正常工作 --> 探索: 任务需定位
  正常工作 --> 规划: 任务非平凡
  正常工作 --> 调试: bug/crash
  探索 --> 规划
  调试 --> 实现
  规划 --> 用户确认
  用户确认 --> 实现: 同意
  实现 --> 知识库同步
  知识库同步 --> 验证
  验证 --> 报告: 通过
  验证 --> 实现: 失败回修

  报告 --> [*]
  提示后工作 --> 正常工作: 用户跑了 setup
```

---

## 12. 设计要点速记（用于面试 / 复述）

| 主题 | 设计选择 | 原因 |
|---|---|---|
| 双 runtime | 同时支持 Codex CLI + Claude Code plugin | 团队混用，不强制迁移 |
| 统一 launcher | `wk-im-dev` 自动派发 | 用户只记一个命令 |
| 人格存储 | core spec 单一事实源 | Codex 与 Claude Code 引用同一份避免漂移 |
| Subagent 拆分 | explorer / planner / debugger / executor / verifier / kb-maintainer | 各自只读 / 只写 / 只验，权责清晰，可并行 |
| 知识库 | per-repo Markdown，git tracked | 长期知识沉淀，可 review，可 diff |
| Workspace 配置 | `~/.wk-im-dev/workspace.json` 全局单文件 | 任意仓库下都能读到组件路径，跨仓联调 |
| 跨 Pod 边界 | 硬约束 + scope-check hook | 防止 LLM 幻觉破坏依赖方向 |
| 隐私保护 | guard 静默扫描日志关键词 | 防止 LLM 误把 PII 写入日志/注释 |
| CodeGraph 集成 | 可选，未安装自动回退 | 不强加依赖，已装时显著降本 |
| 安装幂等 | marker 包裹 (`WK-IM-DEV:START/END`) | 多次安装不复写，可干净卸载 |
| 自检 | 首次激活检 workspace.json + `wk-im-dev doctor` | 出错时一行可见 |

---

## 13. 如何用本文档重新生成图

把任意一节 Mermaid 代码块单独投喂到 Mermaid Live Editor、Excalidraw、draw.io 或任何支持 mermaid 的 LLM/工具，即可重渲染。需要 PlantUML 或飞书画板版本时，按以下提示词：

> 帮我把这段 mermaid 转成 PlantUML / 飞书画板 DSL，保留所有节点、连线、子图分组和样式。

需要更精简的 high-level 单张图，用第 1 节；需要面试讲解流程，用第 5 节 + 第 12 节表格；需要排错，看第 6 节 + `wk-im-dev doctor`。

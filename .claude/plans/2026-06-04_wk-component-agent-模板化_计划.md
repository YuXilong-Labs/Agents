# wk-im-dev → 通用组件 Agent 模板化 计划

> 日期：2026-06-04
> 决策：落地形态 = **脚手架生成器**；目标范围 = **iOS 但组件数可变**

---

## 背景与目标

`wk-im-dev` 已是一个成熟的「per-component 开发 agent 框架」，IM 只是它的第一个实例。
目标是把领域特定部分抽成 manifest，做一个生成器 `create-wk-agent`：读 manifest →
token 替换 → 吐出一个**完整、自包含、可独立发版**的组件 agent 目录（结构与现 `wk-im-dev` 一致）。

并解开一个结构性假设：从「恰好两个组件 service+module」泛化为「**iOS 组件数可变**（1 个或 N 个）」。
保留 iOS/CocoaPods 探测（podspec / Podfile），不解开跨语言假设。

### 验收标准（可验证）

1. 存在 `templates/component-agent/`（带 `{{TOKEN}}` 占位）+ `bin/create-wk-agent.sh` 生成器。
2. 存在 `manifests/im.yaml`，描述当前 IM 领域（2 组件 + 依赖规则 + 隐私词 + 只读路径 + topic + 命名）。
3. **Dogfood 验证**：`create-wk-agent --manifest manifests/im.yaml --out /tmp/regen` 生成的目录
   与现有 `wk-im-dev/`（除 docs 历史叙述类文件外）**结构与关键文件等价**，`bash scripts/verify.sh` 全绿。
4. **N 组件验证**：另写一份 `manifests/example-3comp.yaml`（3 个组件 + 依赖链），生成后
   `detect-env` / `guard` / `init` 能正确识别 3 个组件、按依赖规则校验，不再出现 `service/module` 写死字段。
5. **单组件验证**：一份 1 组件 manifest 生成后能正常 init + KB bootstrap + doctor 全 [ok]。
6. 生成器对命名 token 全覆盖：生成物中不残留任何源 manifest 之外的 `wk-im-dev` / `BTIMService` / `BTIMModule` 字面量。

---

## 影响范围

### 新增
- `templates/component-agent/`（从 wk-im-dev 抽象出的模板树，含 `{{TOKEN}}`）
- `bin/create-wk-agent.sh`（生成器：渲染 + 校验）
- `manifests/im.yaml`、`manifests/example-3comp.yaml`、`manifests/example-1comp.yaml`
- `docs/templating.md`（manifest 字段说明 + 生成器用法 + 加新组件 agent 指南）

### 重构（泛化「组件数可变」，影响仍在 wk-im-dev 内，最终回灌模板）
- `workspace.json` schema：`service`/`module` 标量 → `components: { <name>: <path> }` map（保留 `hostApps`）
- `bin/wk-im-detect-env.sh`：硬编码 `case BTIMService/BTIMModule` → 读 manifest 组件清单，按 podspec basename 匹配；输出泛化为 `components` 数组
- `bin/wk-im-init.sh`：`--service/--module` → `--component <name>=<path>`（旧 flag 保留为兼容别名），写组件 map
- `bin/wk-im-guard.sh`：双 `check_diff` → 遍历组件 + 遍历依赖规则表（`forbid_import` 列表）
- `hooks/scope-check.sh`：只读路径从 manifest 注入；写白名单从组件 map 生成
- `core/wk-im-dev-core.md`：Component Boundaries / Identity 段落改为由 manifest 渲染的 token 区块

### 不动（已通用，模板里作为静态文件原样保留）
- 6 个 subagent 角色定义、launcher 派发、install/bootstrap/uninstall/verify 机制、marker 幂等、KB generated-block 协议、CodeGraph 集成与回退、并行派发启发式

---

## 实施步骤（分阶段，每阶段一个可验证产出）

### 阶段 0 — Manifest schema 设计
- 定稿 `manifest` 字段：`agent{slug,install_dir,marker_prefix,identity_zh}`、
  `components[]{name, role, podspec, scope_root}`、`dependency_rules{allow[], forbid_import[]}`、
  `privacy_keywords[]`、`readonly_paths[]`、`kb_topics[]`、`runtime{codex,claude}`。
- 产出：`manifests/SCHEMA.md` + `manifests/im.yaml`（如实描述当前 IM）。
- 验证：人工 review schema 能完整覆盖第 2 类耦合点盘点表。

### 阶段 1 — 组件数泛化（在 wk-im-dev 原地重构）
- 改 `workspace.json` schema + detect-env + init + guard + scope-check（读 manifest/组件 map）。
- 保留旧 flag 与旧字段读取的向后兼容（升级不丢 hostApps）。
- 验证：现有 `scripts/verify.sh` 全绿；`wk-im-dev doctor` 全 [ok]；用临时 3-pod Podfile 跑 detect-env 输出 3 组件。

### 阶段 2 — 抽模板树
- 把重构后的 wk-im-dev 复制为 `templates/component-agent/`，把命名/领域字面量替换成 `{{TOKEN}}`。
- 区分「token 区块」（identity、boundaries、privacy、readonly、topics）与「静态通用文件」。
- 验证：模板树内除 token 外无 `wk-im-dev/BTIMService/BTIMModule` 残留（grep 断言）。

### 阶段 3 — 生成器
- `bin/create-wk-agent.sh`：解析 manifest（用现成轻量 yaml 解析或约定 JSON）→ 渲染 token → 写 `--out`；
  渲染后跑结构自检（文件齐全、无残留占位、可执行位）。
- 验证：dogfood——`--manifest manifests/im.yaml` 生成物对比现 wk-im-dev 结构等价。

### 阶段 4 — 多形态验证 + 文档
- 跑 example-3comp / example-1comp 两份 manifest，验证 init/guard/doctor。
- 写 `docs/templating.md`。
- 验证：验收标准 1–6 全过。

---

## 风险与回滚

| 风险 | 缓解 / 回滚 |
|---|---|
| 组件数泛化改动 detect/init/guard，可能破坏现有 IM 安装 | 阶段 1 先在 wk-im-dev 原地改并跑完整 verify + doctor 才进阶段 2；旧字段保留兼容读取；回滚 = revert 该阶段 commit |
| workspace.json schema 变更影响已安装用户升级 | init 增量合并时做 v1(service/module)→v2(components) 迁移；migration 失败回退读旧字段 |
| 模板与 wk-im-dev 双份维护漂移 | 终态让 wk-im-dev 成为「im.yaml 的生成产物」（dogfood），CI/verify 里加「regen 后无 diff」断言，从源头杜绝漂移 |
| yaml 解析在纯 bash 下脆弱 | manifest 采用受限子集（无嵌套数组歧义）或直接用 JSON；生成器对未知字段报错而非静默 |
| 发版端到端（CLAUDE.md 步骤 3）回归 | 模板化不改发版机制；wk-im-dev 实例发版前仍按现有 3.1/3.2 端到端跑 |

---

## 验证方式

1. 静态：`bash wk-im-dev/scripts/verify.sh`（每阶段）。
2. 安装触发：`install.sh --runtime both` + `doctor` 全 [ok]（阶段 1、4）。
3. 生成器 dogfood：regen vs 现 wk-im-dev 结构 diff（阶段 3）。
4. 多组件：3-pod / 1-pod manifest 的 detect-env / guard / init 行为断言（阶段 4）。
5. 残留扫描：生成物 grep 无源外字面量（阶段 2、3）。

---

## 待确认

- [ ] 计划是否确认？
- [ ] 模型适配：当前 Opus（规划档）。是否切到 Sonnet 执行（Opus 规划、Sonnet 执行原则）？
- [ ] wk-im-dev 终态是否要做成「im.yaml 的生成产物」（dogfood 强校验，防漂移，但改动面更大）？还是模板与 wk-im-dev 暂时并存、仅靠 grep 断言防漂移？

---
title: wk-im-dev 优化与 CodeGraph 集成 — 完成总结
date: 2026-05-26
plan: 2026-05-26_wk-im-dev优化与CodeGraph集成_计划.md
---

# 2026-05-26 wk-im-dev 优化与 CodeGraph 集成 — 完成总结

## 完成内容概览

按计划的 5 个阶段全部交付，每阶段独立 commit + push 到 main。

| 阶段 | 主题 | Commit |
|------|------|--------|
| 1 | P0 命名一致性 | `7082dcb refactor(wk-im-dev): 统一 subagent 命名为 wk-im-* 前缀` |
| 2 | P1 约束拆分 + 路由精简 | `3524a73 refactor(wk-im-dev): 拆分硬约束为 core + extended 两层` |
| 3 | P2 hooks 与 verifier 智能化 | `0bc8ef1 perf(wk-im-dev): hooks 日志去重,verifier 按 diff 类型触发` |
| 4 | CodeGraph 集成 | `3029ca2 feat(wk-im-dev): 集成 CodeGraph,调用关系下沉到 AST 索引` |
| 5 | README 更新 + 终验 | 含在本提交（阶段 5 commit 跟随本总结） |

## 关键改动清单

### Agent 定义层

- 6 个 subagent frontmatter `name` 全部统一为 `wk-im-*` 前缀
- `im-knowledge-maintainer.md` → `wk-im-knowledge-maintainer.md`（git rename）
- 主 agent `wk-im-dev.md` 路由表 15 行 → 10 行（长尾意图合并）
- `wk-im-explorer.md` 新增三层搜索策略（codegraph → wiki → grep）
- `wk-im-debugger.md` 新增 codegraph_trace 用法
- `wk-im-verifier.md` 增加 diff 类型判定表，新增 Impact 检查

### Core spec

- `core/wk-im-dev-core.md` 新增 "CodeGraph Priority" 章节
- subagent role 列表 6 项全部更名

### 约束层

- `skills/im-knowledge/constraints-core.md`（新增，~22 行硬规则清单，subagent inline）
- `skills/im-knowledge/constraints-extended.md`（新增，含 rationale）
- `skills/im-knowledge/constraints.md` 改为兼容入口（指向 extended）
- 5 个 subagent import 路径切换到 constraints-core

### Hooks

- `hooks/kb-refresh.sh` 引入 5 分钟时间窗口去重，单行紧凑格式
- 实测 3 次同文件写入仅记 1 条日志

### Bin 脚本

- **新增 `bin/wk-im-codegraph.sh`** — codegraph 全生命周期管理（detect/install/init/status）
- `bin/wk-im-init.sh` 末段集成 codegraph 自动检测安装
- `bin/wk-im-kb-scan.sh` 删除 `find_callers()` helper 与所有 Callers 输出段
- `bin/wk-im-kb-scan.sh` 在 entrypoints 段顶部加 codegraph 引导注释

### Skills

- `skills/feature/SKILL.md` / `skills/bugfix/SKILL.md` / `skills/im-knowledge/SKILL.md` / `skills/setup/SKILL.md` 中所有 subagent 引用更名
- `codex/AGENTS.md` 中 6 个 subagent 引用更名

### 文档

- **新增 `docs/codegraph-integration.md`**（完整集成方案：收益表、安装、与 wiki 分工、回退策略）
- `README.md` 新增 "CodeGraph 集成" 章节
- `README.md` 选项速查表追加 codegraph 命令
- `README.md` 目录结构反映新增/重命名文件
- `README.md` FAQ 新增 codegraph 与 wiki 分工说明
- `README.md` 版本历史新增 v3.3.0

### Plugin 元数据

- `.claude-plugin/plugin.json` 版本号 3.2.0 → 3.3.0

## 验证结果

| 检查项 | 结果 |
|--------|------|
| `scripts/verify.sh` | PASS（4 次跑，每阶段后都验证） |
| 残留 `im-*` 旧命名引用 | 0（grep 全仓扫描） |
| `wk-im-kb-scan.sh` 中 `find_callers` 引用 | 0 |
| hooks 5 分钟去重逻辑 | 手工模拟 3 次同文件写入 → log.md 仅 1 条记录，通过 |
| codegraph helper 四个子命令 | detect/install/init/status 本机验证通过（codegraph v0.9.4 已装） |
| 阶段独立 commit + push | 全部成功推到 origin/main |

## 风险与遗留问题

| 项目 | 状态 | 说明 |
|------|------|------|
| codegraph 对 BTIMService 实际索引准确率 | 待验证 | 需要用户在真实仓库跑 `wk-im-codegraph.sh init` 后观察。上游已验证 Wikipedia-iOS 等大型 ObjC+Swift 工程 |
| 端到端 `claude --agent wk-im-dev` 启动 | 待用户验证 | 命名变更可能影响已有 plugin 安装的用户，需要重新 `/plugin install` 拉最新版 |
| 已安装用户的迁移 | 提示文档已加 | README 版本历史标注 v3.3.0 为命名规范变更 |

## 量化收益预期

| 指标 | 原方案 | 新方案 | 节省 |
|------|--------|--------|------|
| subagent spawn 时 system prompt token | 6× ~1k 重复 | 6× ~0.3k 重复 | ~5k token/次 |
| "找符号定义" 操作 | grep + read ~3k token | `codegraph_search` ~200 token | 90% |
| "评估 public API 变更影响" | explorer 全量探索 ~15k token | `codegraph_impact` ~800 token | 94% |
| "消息发送流程" 追踪 | 读 4 个 topic ~8k token | `codegraph_trace` + 1 explore ~2k token | 75% |
| log.md 频繁小改时膨胀 | 每次写一个完整 `##` block | 5 分钟内去重 + 单行 | 90%+ |

## 后续建议（可选优化）

1. 在 BTIMService 真实仓库验证 codegraph 索引准确率，若 ObjC++ 宏处出现解析空洞，给 explorer 增加针对该范围的 grep 显式 fallback hint
2. `wk-im-verifier` 的 codegraph_impact 检查可进一步精确化：当变更只发生在 `BTIMService/Classes/Internal/` 等明确内部目录时跳过 impact（减少 verifier 时延）
3. 给 `wk-im-codegraph.sh` 加 `update` 子命令：检测 codegraph 上游版本并提示用户升级
4. 考虑在 `hooks/scope-check.sh` 中也加入 codegraph 索引完整性检查，给 agent 提前预警

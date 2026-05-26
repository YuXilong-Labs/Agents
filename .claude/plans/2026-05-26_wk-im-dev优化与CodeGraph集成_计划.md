---
title: wk-im-dev 优化与 CodeGraph 集成
date: 2026-05-26
---

# 2026-05-26_wk-im-dev优化与CodeGraph集成_计划

## 背景与目标

基于评估报告，对 `wk-im-dev` 进行系统性优化，包括 P0 命名一致性修复、P1/P2 性能与可维护性提升，以及集成 CodeGraph (https://github.com/colbymchenry/codegraph) 实现 token 节省与查找加速。

### 验收标准

1. 所有 subagent 文件名与 frontmatter `name` 字段一致
2. constraints.md 拆分为硬约束（必带）与扩展说明（按需）两层，subagent 只 inline 硬约束
3. 主 agent 路由表精简到 ≤ 10 行核心意图，长尾合并
4. kb-refresh.sh 引入时间窗口去重，同一文件 5 分钟内多次写入只追加一条日志
5. im-verifier 按 diff 类型触发对应验证子集
6. CodeGraph 集成：
   - 提供 `wk-im-codegraph.sh` 检测脚本，缺失自动安装并初始化索引
   - im-explorer 优先 codegraph，回退 grep
   - im-debugger 新增 codegraph_trace 流程
   - im-verifier 增加 codegraph_impact 校验
   - wk-im-kb-scan.sh 删除 find_callers 段，调用关系下沉到 codegraph
7. README 与 docs 同步更新
8. `scripts/verify.sh` 通过

## 影响范围

| 类别 | 文件 |
|------|------|
| Agent 定义 | `agents/wk-im-explorer.md`, `wk-im-planner.md`, `wk-im-debugger.md`, `wk-im-executor.md`, `wk-im-verifier.md`, `im-knowledge-maintainer.md`, `wk-im-dev.md` |
| Core spec | `core/wk-im-dev-core.md` |
| 约束 | `skills/im-knowledge/constraints.md`（拆为 constraints-core.md + constraints-extended.md） |
| Hooks | `hooks/kb-refresh.sh` |
| Bin 脚本 | `bin/wk-im-kb-scan.sh`（删 find_callers 段）、`bin/wk-im-codegraph.sh`（新增）、`bin/wk-im-init.sh`（追加 codegraph 检测）、`bin/wk-im-verify.sh`（追加 impact 检查） |
| Skills | `skills/feature/SKILL.md`, `skills/bugfix/SKILL.md`, `skills/im-review/SKILL.md`, `skills/im-knowledge/SKILL.md` |
| 文档 | `README.md`, `docs/agent-knowledge.md`, `docs/codegraph-integration.md`（新增） |

## 实施步骤

### 阶段 1：P0 命名一致性（保证 plugin 不破坏现状）

1. 统一 6 个 subagent 的 frontmatter `name`：`wk-im-explorer` / `wk-im-planner` / `wk-im-debugger` / `wk-im-executor` / `wk-im-verifier` / `wk-im-knowledge-maintainer`
2. 同步更新主 agent (`wk-im-dev.md`) 路由表中的 subagent 名引用
3. 同步更新 core spec 中的 subagent 列表
4. 同步更新 skills/*/SKILL.md 中的 subagent 名引用
5. 同步更新 README.md 工作流章节
6. 运行 `scripts/verify.sh`，确保无破坏

**阶段产出**：单次 commit `refactor(wk-im-dev): 统一 subagent 命名为 wk-im-* 前缀`

### 阶段 2：P1 约束拆分 + 路由表精简

1. 把 `skills/im-knowledge/constraints.md` 拆为：
   - `constraints-core.md`（≤ 30 行，仅硬约束清单）
   - `constraints-extended.md`（详细说明，按需读取）
2. 所有 subagent 改为 `@../skills/im-knowledge/constraints-core.md`
3. 主 agent (wk-im-dev.md) 仍 import 完整版（路由层需要语境）
4. 精简 wk-im-dev.md 路由表为 8 类核心意图，长尾意图（重构/补测试/性能）合并到说明段
5. 运行 verify

**阶段产出**：commit `refactor(wk-im-dev): 拆分硬约束减少重复注入,精简意图路由`

### 阶段 3：P2 hooks 与 verifier 智能化

1. `hooks/kb-refresh.sh`：
   - 引入时间窗口去重，同一文件路径 5 分钟内重复写入跳过追加
   - 改为单行格式 `- YYYY-MM-DD HH:MM | <relpath> | source-change`，减少 log.md 膨胀
2. `agents/wk-im-verifier.md`：
   - 增加 diff 类型识别段，纯 .md / .h / 测试文件触发不同验证子集
   - 输出格式中标注 SKIPPED 的项给出原因
3. 运行 verify

**阶段产出**：commit `perf(wk-im-dev): hooks 日志去重,verifier 按 diff 触发验证`

### 阶段 4：CodeGraph 集成

1. 新增 `bin/wk-im-codegraph.sh`：
   - `detect` 子命令：检测 `~/.local/bin/codegraph` 或 PATH 中的 codegraph，输出 `installed` / `missing`
   - `install` 子命令：从 `colbymchenry/codegraph` 自动安装（cargo install 或 release binary，按 release 真实情况选）
   - `init` 子命令：在指定 root 跑 `codegraph init -i`，并校验 `.codegraph/` 生成
   - `status` 子命令：调 `codegraph_status` 等价命令检查索引健康度
2. `bin/wk-im-init.sh` 末段追加：检测 codegraph，缺失则提示自动安装（交互式 yes/no，--quiet 默认 yes）
3. `bin/wk-im-kb-scan.sh`：
   - 删除 `find_callers()` 段（第 312-321 行及调用处第 391-401、414-424 行）
   - 在生成的 contracts.md / entrypoints.md 顶部加注释：`Caller 关系请用 codegraph_callers 查询，本文件只列签名`
4. `agents/wk-im-explorer.md`：增加 "优先策略" 段，指引先调 codegraph_* MCP 工具，缺失时降级 grep
5. `agents/wk-im-debugger.md`：增加 codegraph_trace 用法
6. `agents/wk-im-verifier.md`：新增检查项 "Impact: 用 codegraph_impact 评估 public API 变更影响"
7. `core/wk-im-dev-core.md`：新增 "CodeGraph 优先策略" 段
8. 新增 `docs/codegraph-integration.md`：完整方案文档（适用场景、回退策略、accuracy 注意事项）
9. 运行 verify

**阶段产出**：commit `feat(wk-im-dev): 集成 CodeGraph,调用关系下沉到 AST 索引`

### 阶段 5：README 更新与最终验证

1. README.md 增加：
   - Quick Start 增加可选 codegraph 安装步骤
   - 新增 "CodeGraph 集成" 章节，说明 token 节省与回退策略
   - 选项速查表追加 codegraph 相关命令
   - 目录结构同步更新
2. 运行 `scripts/verify.sh` 终验
3. 输出总结到 `./.claude/plans/2026-05-26_wk-im-dev优化与CodeGraph集成_总结.md`

**阶段产出**：commit `docs(wk-im-dev): 更新 README 反映 codegraph 集成与命名规范`

## 风险与回滚方案

### 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| codegraph 对 ObjC++ / 宏的解析准确率不足 | impact 漏报 | 保留 wiki contracts.md 作为 fallback，agent 显式标注 "AST + wiki 双源校验" |
| codegraph 安装失败（无 cargo 或 network） | init 阻塞 | install 脚本失败时仅警告不退出 1，agent 自动 fallback 到 grep |
| subagent name 变更打破已有用户 plugin | 已安装用户路由失败 | core spec 版本升到 1.1，README 写明 breaking change 与迁移命令 |
| constraints 拆分后 subagent 行为漂移 | 隐私 / 依赖方向被误触 | 硬约束清单保留所有原文 hard rules，仅删冗余说明 |

### 回滚

- 每个阶段独立 commit，可单独 `git revert`
- constraints.md 拆分前留 `.bak` 备份在仓库外
- codegraph 相关变更隔离在阶段 4-5，前 3 个阶段不依赖

## 验证方式

### 静态验证（每阶段后）

```bash
cd wk-im-dev
bash scripts/verify.sh
```

### 端到端验证（最终）

```bash
# 1. 安装到测试目录
bash scripts/install.sh --runtime claude --target /tmp/test-btim-service

# 2. 触发 agent，确认命名生效
claude --agent wk-im-dev --no-interactive "你好"

# 3. 触发 codegraph 检测
bash bin/wk-im-codegraph.sh detect

# 4. 跑 kb-scan 验证 find_callers 已下沉
bash bin/wk-im-kb-scan.sh --root <test-repo>
grep -L "Callers of" <test-repo>/docs/agent-knowledge/topics/entrypoints.md  # 应该无 Callers 字样
```

### 验收清单

- [ ] 6 个 subagent 文件名 = frontmatter name
- [ ] subagent system prompt 中只 import constraints-core
- [ ] 路由表 ≤ 10 行
- [ ] kb-refresh.sh 5 分钟去重生效
- [ ] verify.sh 全绿
- [ ] wk-im-codegraph.sh 四个子命令全部可用
- [ ] kb-scan 输出不再含 "Callers of" 字段
- [ ] README 包含 codegraph 章节
- [ ] 所有阶段都已 commit + push

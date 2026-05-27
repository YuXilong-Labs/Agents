# wk-im-dev Agent 定义优化 - 计划

> 日期：2026-05-27
> 范围：`wk-im-dev/agents/*.md`、`wk-im-dev/core/wk-im-dev-core.md`、`wk-im-dev/skills/*/SKILL.md`
> 不在范围内：`wk-im-dev/codex/AGENTS.md` 的整体重构（仅做必要同步），`SessionStart` hook 的实现（仅在 prompt 中标注 TODO）

## 背景与目标

前置审查发现 12 项可优化点（HIGH × 3、MEDIUM × 5、LOW × 4），覆盖工具权限约束、输出规范、路由清晰度、可维护性。
本次目标：把所有可在 prompt/frontmatter 层完成的优化落地，达到：

- 所有 read-only subagent 在 frontmatter 层强制写入禁止
- 输出模板与 Claude Code 系统规则（无 emoji）一致
- 颜色全部唯一，便于流式输出区分
- 每个 subagent description 含 "Use PROACTIVELY" 提升 Claude Code 自动路由命中率
- 主 agent 路由表分层清晰：用户意图→skill 与 skill 内部→subagent 分开
- 跨组件提交顺序、Verifier 维度定义等"规则归属"修正到合适层级

验收标准：
1. `bash wk-im-dev/scripts/verify.sh` 通过
2. 7 个 agent 的 frontmatter 颜色互不相同
3. agents/skills 目录下无 emoji（除 markdown 自身标记外）
4. read-only subagent 全部有 `disallowedTools` 约束

## 影响范围

| 文件 | 改动 |
|---|---|
| `agents/wk-im-dev.md` | 路由表分层、identity 同步注释、自检 TODO hook 注 |
| `agents/wk-im-explorer.md` | description 规范化、输出预算具体化 |
| `agents/wk-im-planner.md` | 加 PROACTIVELY、去 emoji、删残留指令 |
| `agents/wk-im-executor.md` | 加 PROACTIVELY、删 git 提交顺序（上移） |
| `agents/wk-im-verifier.md` | 加 PROACTIVELY、Build/Test vs Tests 边界 |
| `agents/wk-im-debugger.md` | 加 `disallowedTools`、加 PROACTIVELY、改色 orange、去 emoji |
| `agents/wk-im-knowledge-maintainer.md` | 加 PROACTIVELY、改色 pink、prose 强化写入边界 |
| `core/wk-im-dev-core.md` | 增加跨组件提交顺序到 Workflow |
| `skills/im-review/SKILL.md` | ✅/❌ → PASS/FAIL |

## 实施步骤（按依赖顺序）

### 阶段 1：subagent 权限与样式（独立改动）
1. `wk-im-debugger.md`：frontmatter + 去 emoji + 描述
2. `wk-im-explorer.md`：输出预算 + 描述
3. `wk-im-planner.md`：去 emoji + 描述 + 删残留
4. `wk-im-verifier.md`：维度定义 + 描述
5. `wk-im-executor.md`：删提交顺序 + 描述
6. `wk-im-knowledge-maintainer.md`：颜色 + 描述 + prose 边界

### 阶段 2：core 与主 agent 同步（依赖阶段 1 完成）
7. `core/wk-im-dev-core.md`：补提交顺序章节
8. `agents/wk-im-dev.md`：路由表分层 + identity 同步注释

### 阶段 3：skill 一致性
9. `skills/im-review/SKILL.md`：去 ✅/❌

### 阶段 4：验证
10. 运行 `bash wk-im-dev/scripts/verify.sh`
11. 输出总结到 `.claude/plans/2026-05-27_..._总结.md`

## 风险与回滚

- **风险**：`disallowedTools` 不被 Codex 识别 → Codex runtime 影响为 0（Codex 不读 frontmatter），仅影响 Claude Code 行为
- **风险**：颜色字符串不被某些 Claude Code 版本识别 → 退化为默认，不阻塞行为
- **回滚**：本次改动全在 prompt/frontmatter 层，纯 Markdown 编辑，`git checkout -- wk-im-dev/agents/ wk-im-dev/core/ wk-im-dev/skills/` 即可全量回滚

## 验证方式

- `bash wk-im-dev/scripts/verify.sh`
- 人工 grep 检查 emoji 与颜色唯一性
- 不强制要求执行端到端 install + 触发，因为本次纯 prompt 改动且仓库已有大量历史 install/verify 记录

## 不在本次范围

- `codex/AGENTS.md` 与 core 的内容去重（涉及 install 脚本，留作后续）
- `SessionStart` hook 实现首次激活自检（需要独立设计与安装流程）

# wk-im-dev Agent 定义优化 - 总结

> 日期：2026-05-27
> 计划：`.claude/plans/2026-05-27_wk-im-dev-agent定义优化_计划.md`
> 状态：完成

## 完成内容

按计划清单 12 项已落地 10 项，2 项明确延后（见"遗留与后续"）。

### HIGH

| # | 项 | 落地方式 |
|---|---|---|
| 1 | read-only subagent 工具约束 | `wk-im-debugger.md` 补 `disallowedTools: Write, Edit, MultiEdit`；`wk-im-knowledge-maintainer.md` prose 强化"写前路径检查"；`wk-im-executor.md` 保留写权限（本职即写）|
| 2 | 主 agent 路由表重叠 | `wk-im-dev.md` 路由表拆成两层：第一层"用户意图→skill"，第二层"skill 内部/补漏→subagent" |
| 3 | 首次激活自检 prompt 不可靠 | 暂保留 prompt 层提示，加 `> 注` 标注 SessionStart hook 是后续稳定化方向 |

### MEDIUM

| # | 项 | 落地方式 |
|---|---|---|
| 4 | 模板含 emoji | `wk-im-planner.md` / `wk-im-debugger.md` 去掉 `📋` / `🔍`；`skills/im-review/SKILL.md` `✅/❌` → `[PASS/FAIL]` |
| 5 | 颜色冲突 | `wk-im-debugger` yellow → **orange**；`wk-im-knowledge-maintainer` green → **pink**；7 个 agent 颜色全部唯一 |
| 6 | explorer "Top 5" 不具体 | `wk-im-explorer.md` 新增"输出预算"硬表：文件≤5/类≤3/链=1/Pod 各列≤3，超额时按"总结 > 调用链 > 关键类 > 相关文件 > Pod 归属"优先级保留 |
| 7 | 各 subagent description 缺 PROACTIVELY | 7 个 agent 的 description 全部含 "Use PROACTIVELY" |
| 8 | identity 双份 | 加 `<!-- KEEP IN SYNC WITH core/wk-im-dev-core.md Identity section -->` 注释，避免静默漂移 |

### LOW

| # | 项 | 落地方式 |
|---|---|---|
| 9 | planner 残留指令 | 删除 "不硬编码具体模型名称" 段落（这是开发者笔记不是 prompt） |
| 10 | Build/Test vs Tests 边界模糊 | `wk-im-verifier.md` 增加"验证维度定义"小节，明确：Build/Test = 编译+全量套件；Tests = 仅新行为的覆盖度评估 |
| 11 | executor 含 git 提交顺序 | 上移到 `core/wk-im-dev-core.md` 新增的 "Cross-component change ordering" 章节；executor 留一行指向 core |
| 12 | codex/AGENTS.md 与 core 重复 | **本次未做**（涉及 install.sh 拼接逻辑，留作后续） |

## 关键改动清单

```
 wk-im-dev/agents/wk-im-debugger.md             | 15 ++++++---
 wk-im-dev/agents/wk-im-dev.md                  | 43 +++++++++++++++++---------
 wk-im-dev/agents/wk-im-executor.md             |  8 ++---
 wk-im-dev/agents/wk-im-explorer.md             | 16 ++++++++--
 wk-im-dev/agents/wk-im-knowledge-maintainer.md | 21 ++++++++-----
 wk-im-dev/agents/wk-im-planner.md              | 11 +++----
 wk-im-dev/agents/wk-im-verifier.md             | 39 ++++++++++++-----------
 wk-im-dev/core/wk-im-dev-core.md               |  9 ++++++
 wk-im-dev/skills/im-review/SKILL.md            |  8 ++---
 9 files changed, 110 insertions(+), 60 deletions(-)
```

## 验证结果

- `bash wk-im-dev/scripts/verify.sh` → **PASS** (`wk-im-dev verification passed`)
- emoji grep → **clean**
- 颜色唯一性 → **7 unique** (blue/cyan/green/orange/pink/purple/yellow)
- PROACTIVELY 覆盖 → **7/7 agents**
- read-only subagent `disallowedTools` → **4/4** (explorer/planner/verifier/debugger)

## 风险与遗留

### 遗留（明确延后）

1. **SessionStart hook 化首次自检**
   - 现状：prompt 层提示，靠模型自觉，长上下文压缩后可能丢失
   - 后续：写 `wk-im-init-check.sh`，配 `SessionStart` hook，把检测结果作为首条系统消息注入
   - 触发时机：下一次有用户报告"自检没跑"再做

2. **codex/AGENTS.md 与 core 去重**
   - 现状：codex/AGENTS.md 129 行手抄了 80% 的 core 内容
   - 候选方案：`install.sh` 在拷贝时用 `cat core/wk-im-dev-core.md codex/codex-specific.md > AGENTS.md` 生成
   - 风险：变更 install 流程影响所有现有 codex 用户的安装，需要一轮单独 verify + dry-run
   - 后续：作为下个 minor 版本的独立任务

### 行为风险（已规避）

- `disallowedTools` 在 Codex 不被识别：Codex 不读 frontmatter，本身就靠 prose 约束；Claude Code 侧得到强约束。两侧都不退化。
- 颜色字符串 `pink` / `orange` 在某些旧版 Claude Code 中可能落到默认色：仅影响显示，不阻塞执行流。

## 后续建议

短期：
- 把"首次激活自检"做成 hook（成本约 0.5 天）
- 把 codex/AGENTS.md 改成拼接生成（成本约 0.5 天）

中期：
- 给 `wk-im-knowledge-maintainer` 加 PreToolUse hook，硬拦截 `Write`/`Edit` 路径不在 `docs/agent-knowledge/` 的尝试
- 给 `wk-im-executor` 加同样的 PreToolUse hook，拦截 `Pods/` / `ThirdPartySDK/` 路径写入

长期：
- subagent 之间引入 trace ID 串联，便于排查多轮委派失败原因

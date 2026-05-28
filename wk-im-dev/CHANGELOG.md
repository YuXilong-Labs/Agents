# wk-im-dev Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

未发布的改动放在 **Unreleased**；打 tag 时把它的内容移到对应版本下并标注日期。

---

## Unreleased

（无）

---

## v1.0.1 — 2026-05-28 (hotfix)

### Fixed

- `bin/wk-im-dev` 的 `claude_plugin_installed()` 用 `grep -q '"wk-im-dev"'` 检测 `~/.claude/settings.json`，但 Claude Code 实际写入的 key 是 `"wk-im-dev@yuxilong-agents"`（带 marketplace 后缀），字面字符串不匹配 → `wk-im-dev doctor` 误报 `[miss] Claude plugin wk-im-dev not enabled`，并连带 `detect_runtime()` 把"有 Claude plugin 已启用"判为否，**装了 Claude plugin 的用户被静默回退到 codex 路径**。grep 改为 extended regex `'"wk-im-dev(@[A-Za-z0-9._-]+)?"'`，同时兼容带/不带 marketplace 后缀两种写法。
- 影响：仅装 Codex 的用户不受影响；同时装 Claude plugin 的用户在 v1.0.0 实际走的是 codex 路径而非 claude plugin。launcher 行为本身可用，但 runtime detection 不准。

### Migration

- **从 v1.0.0 升级**：直接重跑 bootstrap：
  ```
  curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.1/wk-im-dev/scripts/bootstrap.sh \
    | bash -s -- --target . --ref v1.0.1
  ```
  Claude Code 用户：`claude plugin update wk-im-dev@yuxilong-agents`。
- 装完跑 `wk-im-dev doctor`，本次应能看到 `[ok] Claude plugin wk-im-dev enabled`。

---

## v1.0.0 — 2026-05-28（首个正式版本）

主线主题：**多 agent 并行能力补完 + 主 agent 身份模板重写 + 版本号体系重置**。

> ⚠️ **版本号体系重置**：本版同步把 plugin 版本号体系从历史 v3.x（开发期内部编号）重置为 v1.0.0，作为对外首个正式 v1 release。历史 v3.x git tag 已从 GitHub 删除，所有团队成员请重新从 `--ref v1.0.0` 安装。`wk-im-dev --version` 现在输出 `1.0.0`。详见下方"版本号体系说明"段。

### Added

- **主 agent 身份介绍**改为"能力 + 示例 + 子 agent 协作"模板，workspace 缺失时自动追加 `/wk-im-dev:setup` 提示，帮助用户快速判断"找对人没"并降低首次 setup 遗漏率。`agents/wk-im-dev.md`、`core/wk-im-dev-core.md`、`codex/AGENTS.md` 三处同步。
- **三处子 agent 并行能力补完**：
  - `wk-im-explorer`：description 与正文新增 "单组件内 ≥3 个独立子系统并行" 语义，附拆分模板（"消息撤回 / 未读数统计 / 同类调用者"三类示例）。
  - `wk-im-debugger`：新增"多假说并行模式"——bug 有 ≥2 个互不依赖的可疑根因时，主 agent 同时派出多个 debugger 各验一个假说，收敛阶段择证据最强项。
  - `wk-im-verifier`：新增"并行执行规则"段 + A/B 组依赖关系表，独立维度（Build/Test、Guard、Knowledge、Diff Scope、Architecture、Privacy）在同条消息内并发启动 Bash，依赖维度（Tests-coverage、Impact）顺次执行。预期总耗时从 ~150s 降至 max(Build/Test) + ~10s。
- `core/wk-im-dev-core.md` 新增 **Parallel dispatch heuristic** 通用判断标准（独立子任务 ≥3 + 无数据依赖 + 目标明确，三条全满足才并行），并在每个 Subagent Role 上注明可并行性。
- `.claude/plans/2026-05-28_多agent并行优化_{计划,总结}.md` 沉淀本次发版的 plan 与总结文档。

### Removed

- wk-im-developer (v2) 模块的 `wk-im-review` skill 文件（`.claude/` 与 `claude/` 双 runtime 都删），agent 触发表"review → 调用 skill"改为"直接执行代码审查流程"。同时清理与 agent 同名冗余的 `wk-im-developer/SKILL.md`。v2 整体进入退场窗口（CLAUDE.md 已标注弃用）。
- `wk-im-developer/uninstall.sh` 同步追加 `wk-im-developer` 子目录到清理列表，保证 v2 卸载干净。
- **历史 v3.4.1 / v3.4.2 / v3.4.3 / v3.5.0 git tag 从 GitHub 删除**（v3.0.0 → v3.4.0 从未打过 tag），所有 pre-1.0 版本仅在本 CHANGELOG 中保留为可追溯证据。

### Migration

- **首次安装或从历史 v3.x 升级**：
  ```
  curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.0/wk-im-dev/scripts/bootstrap.sh \
    | bash -s -- --target . --ref v1.0.0
  ```
  Claude Code 用户：`claude plugin update wk-im-dev@yuxilong-agents`。
- **本地仍残留旧 v3.x tag 的开发者**：
  ```
  git fetch --prune --prune-tags origin
  # 或手动:
  for t in v3.0.0 v3.1.0 v3.2.0 v3.3.0 v3.4.0 v3.4.1 v3.4.2 v3.4.3 v3.5.0; do
    git tag -d "$t" 2>/dev/null
  done
  ```
- **装过 v2 (`wk-im-developer`) 的用户**：`wk-im-review` skill 文件已下架，agent 内部已改为"直接执行 review 流程"，体验上等价。v2 计划近期整体移除，建议迁移到 v1 (`wk-im-dev`)。

---

## 版本号体系说明

`wk-im-dev` 在 2026-05-28 之前使用了 v3.0.0 → v3.5.0 的内部开发版本号。这套版本号没有对外发布稳定承诺（属于工具自迭代期），但在 git tag 中留下了痕迹。

**v1.0.0 重置后**：

- 历史 v3.x git tag 全部从 GitHub 删除，避免命名空间长期占用 + 避免新人误以为有 v2.x 跳过
- 历史 v3.x CHANGELOG 段保留并标注 `(pre-1.0 开发期版本号)`，作为变更可追溯证据
- 未来按标准 SemVer 演进：
  - bugfix → `v1.0.x`
  - 行为增强（向后兼容）→ `v1.x.0`
  - 破坏性变更 → `v2.0.0`

下方所有 `v3.x.x` 段均为 **pre-1.0 开发期版本号**，仅供历史参考，不再有对应 git tag。

---

## v3.4.3 — 2026-05-27 (pre-1.0 hotfix 2)

### Fixed

- `bin/wk-im-dev`：`read_version()` 在 Codex-only 安装下，`candidates=()` 数组为空时 `for file in "${candidates[@]}"` 在 `set -u` + bash 3.2/4.x 触发 `unbound variable: candidates[@]`。导致 `wk-im-dev --version` 和 `wk-im-dev doctor` 在新装机器上**几乎一定挂**。重写为顺序 try_read，不依赖空数组展开。
- `scripts/install.sh`：`install_core_spec` 顺便把 `.claude-plugin/plugin.json` copy 到 `~/.wk-im-dev/.claude-plugin/`，让 Codex-only 安装也能正确报告版本号（之前 launcher 找不到任何 plugin.json）。
- `hooks/kb-refresh.sh`：`find_component_root` 改为纯字符串向上解析，不再 `cd` 父目录。原实现在父目录已被消除/不存在的极端场景下会 silent skip 而错过 source-change 日志。
- 测试侧发现：v3.4.2 的 bootstrap 一切正常，但安装完跑 `doctor` 立刻挂 — 这是 v3.4.1 + v3.4.2 都有的旧 bug，因为本地源码树有 `.claude-plugin/plugin.json` 直接被 path-4 命中所以从没暴露。

### Migration

- **从 v3.4.1 / v3.4.2 升级**：直接重跑 bootstrap 即可：
  ```
  curl ... bootstrap.sh | bash -s -- --target . --ref v3.4.3
  ```
  无需手动清理。`~/.wk-im-dev/.claude-plugin/plugin.json` 由本次 install 自动 copy。

---

## v3.4.2 — 2026-05-27 (pre-1.0 hotfix)

### Fixed

- `scripts/bootstrap.sh`：line 127 的 `echo "...(...$REPO_URL）..."` 在 `set -u` 下因 bash 把中文全角括号 `）` 的 UTF-8 高位字节误当作变量名续 → `unbound variable: REPO_URL�`。改为 `${REPO_URL}` 显式定界。**所有 v3.4.1 安装命令实际会立即失败**，请改用 v3.4.2。
- 影响：从 v3.4.1 tag `curl ... bootstrap.sh | bash ...` 无论传什么参数都会在下载阶段挂掉。issue 由 Docker/clean HOME 真实环境验证发现。

### Migration

- **已经从 v3.4.1 安装但失败的团队成员**：直接重跑 `... --ref v3.4.2`，无需手动清理。
- **v3.4.1 tag 保留**（不移动），但 README/文档示例统一指向 v3.4.2。

---

## v3.4.1 — 2026-05-27 (pre-1.0)

### Added

- `scripts/bootstrap.sh` 新增 `--ref` / `--repo-url` / `--marketplace` 参数（同时支持 `WK_IM_DEV_REF` / `WK_IM_DEV_REPO_URL` / `WK_IM_DEV_MARKETPLACE` 环境变量），允许团队成员钉死版本 tag、走内网 mirror、覆盖 Claude marketplace。commit SHA 走 `git fetch` 兜底。
- `scripts/bootstrap.sh` 默认 `--runtime auto`：检测 `claude` CLI → 走 Claude plugin marketplace add + install；否则走 git clone + install.sh。支持 `--runtime both` 双装。
- `scripts/install.sh` 新增 `--dry-run-shell-rc`：打印将要追加到 shell rc 的内容但不写入，方便自管 dotfiles 的团队成员。
- `scripts/install.sh` 入口加 `check_prerequisites`：缺少 git/grep/sed/awk 立即 fail-fast，codex/claude CLI 缺失只 warn。
- `bin/wk-im-dev` 新增 `--version` / `-V` 子命令，从 `plugin.json` 读出版本号 + 来源路径；`doctor` 顶部也打印版本号。
- `bin/wk-im-dev` 新增 `doctor --fix`：检测出问题时输出可粘贴的修复命令（不主动执行），覆盖 Claude plugin 未启用 / Codex profile 缺失 / workspace.json 缺失 / PATH 未配置 / CodeGraph 未装等场景。
- `bin/wk-im-init.sh` 写 `~/.wk-im-dev/workspace.json` 时合并旧 `hostApps` 数组：保留旧条目（失效目录自动剔除）、追加新条目并去重；service/module 路径变更时打印 `Note` 不再静默覆盖。
- `docs/architecture.md` 纳入版本控制（13 节 Mermaid 架构图）。
- `docs/team-distribution.md` 团队分发指南：tag 发布流程、内网 mirror、私有 token、Claude plugin 内网过渡方案、升级流程、排错速查、安全/审计建议、onboarding 模板。
- `docs/feishu-bot.md` 飞书 bot 部署单独文档：场景适配、依赖、飞书侧准备、部署形态、安全合规、生产化清单。
- `CHANGELOG.md`：本文件首次创建，按 Keep a Changelog 规范整理过往版本。

### Changed

- `codex/profile.toml` 移除 `model = "gpt-5.4"` 写死，避免团队成员账号没有该模型权限时直接挂；Codex 会回退到 `~/.codex/config.toml` 的全局 model 或默认值。
- `bin/wk-im-dev` launcher 在没有 profile 时的 fallback 同步去掉 `-c model`，只覆盖 `model_reasoning_effort`。
- `hooks/hooks.json`：`scope-check.sh` 从 `PostToolUse` 移到 `PreToolUse`，写 `Pods/` / `ThirdPartySDK/` 现在真正被阻止（之前只是事后报警）。
- `hooks/scope-check.sh` 阻断消息改为中文，明确"需用户在对话中显式授权"。
- `codex/install.sh` 标记 DEPRECATED，转发时打印 warning，计划 v4 移除。
- README 顶部加导航三连（架构 / 团队分发 / CHANGELOG）；新增"升级"和"团队分发"章节；目录结构补齐新文档。

### Migration

- **从 v3.4.0 升级到 v3.4.1**：直接重跑 bootstrap 或 `claude plugin update`。
  - `workspace.json` 自动 backward-compatible（读取旧格式 + 合并）。
  - 旧的 `profile.toml` 中的 `model = "gpt-5.4"` 行会被新 installer 的 marker 块覆盖（无 `model` 字段）。如果你的团队需要为本 profile 钉死模型，在 marker 块**外面**手写 `model = "..."` 一行即可（不会被 installer 覆盖）。
  - 调用 `codex/install.sh` 的脚本会看到 deprecation warning，请改用 `scripts/install.sh --runtime codex` 或 `scripts/bootstrap.sh`。

---

## v3.4.0 — 2026-05-26 (pre-1.0)

### Added

- Installer 默认级联调用 `wk-im-init.sh`，目标看起来像 IM 仓库时自动初始化知识库。
- `bootstrap.sh` `--target` 默认 `pwd`。
- `bin/wk-im-dev` 统一 launcher：自动派发 Claude/Codex；新增 `doctor` 子命令。
- Agent 首次激活做 `workspace.json` 自检。

### Changed

- README 精简到三步上手，高级 flag 抽到 `docs/advanced-install.md`。
- `wk-im-init.sh` 在 pwd 不是 IM 仓库时向上查找；fallback 到 `workspace.json`。

---

## v3.3.0 (pre-1.0)

### Added

- 集成 CodeGraph（AST 索引），`wk-im-explorer` / `wk-im-debugger` 优先使用 `codegraph_*` MCP 工具。
- Subagent 命名统一为 `wk-im-*` 前缀。
- 硬约束拆分为 `constraints-core.md` + `constraints-extended.md` 两层。

### Changed

- marketplace name 从 `yuxilong-labs` 改为 `yuxilong-agents`（升级需 `remove` 旧的再 `add` 新的）。

---

## v3.2.0 (pre-1.0)

### Changed

- `plugin.json` name 统一为 `wk-im-dev`。
- Codex TOML 精简。

---

## v3.1.0 (pre-1.0)

### Added

- 知识库 LLM Wiki 系统（`docs/agent-knowledge/`）。

---

## v3.0.0 (pre-1.0)

### Changed

- 重大重构：聚焦 BTIMService / BTIMModule，6 子 Agent 分工。

---

旧命名迁移见 [docs/rename-from-wk-im-developer.md](docs/rename-from-wk-im-developer.md)。

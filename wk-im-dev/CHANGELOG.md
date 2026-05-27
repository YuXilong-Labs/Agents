# wk-im-dev Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

未发布的改动放在 **Unreleased**；打 tag 时把它的内容移到对应版本下并标注日期。

---

## Unreleased

（无）

---

## v3.4.2 — 2026-05-27 (hotfix)

### Fixed

- `scripts/bootstrap.sh`：line 127 的 `echo "...(...$REPO_URL）..."` 在 `set -u` 下因 bash 把中文全角括号 `）` 的 UTF-8 高位字节误当作变量名续 → `unbound variable: REPO_URL�`。改为 `${REPO_URL}` 显式定界。**所有 v3.4.1 安装命令实际会立即失败**，请改用 v3.4.2。
- 影响：从 v3.4.1 tag `curl ... bootstrap.sh | bash ...` 无论传什么参数都会在下载阶段挂掉。issue 由 Docker/clean HOME 真实环境验证发现。

### Migration

- **已经从 v3.4.1 安装但失败的团队成员**：直接重跑 `... --ref v3.4.2`，无需手动清理。
- **v3.4.1 tag 保留**（不移动），但 README/文档示例统一指向 v3.4.2。

---

## v3.4.1 — 2026-05-27

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

## v3.4.0 — 2026-05-26

### Added

- Installer 默认级联调用 `wk-im-init.sh`，目标看起来像 IM 仓库时自动初始化知识库。
- `bootstrap.sh` `--target` 默认 `pwd`。
- `bin/wk-im-dev` 统一 launcher：自动派发 Claude/Codex；新增 `doctor` 子命令。
- Agent 首次激活做 `workspace.json` 自检。

### Changed

- README 精简到三步上手，高级 flag 抽到 `docs/advanced-install.md`。
- `wk-im-init.sh` 在 pwd 不是 IM 仓库时向上查找；fallback 到 `workspace.json`。

---

## v3.3.0

### Added

- 集成 CodeGraph（AST 索引），`wk-im-explorer` / `wk-im-debugger` 优先使用 `codegraph_*` MCP 工具。
- Subagent 命名统一为 `wk-im-*` 前缀。
- 硬约束拆分为 `constraints-core.md` + `constraints-extended.md` 两层。

### Changed

- marketplace name 从 `yuxilong-labs` 改为 `yuxilong-agents`（升级需 `remove` 旧的再 `add` 新的）。

---

## v3.2.0

### Changed

- `plugin.json` name 统一为 `wk-im-dev`。
- Codex TOML 精简。

---

## v3.1.0

### Added

- 知识库 LLM Wiki 系统（`docs/agent-knowledge/`）。

---

## v3.0.0

### Changed

- 重大重构：聚焦 BTIMService / BTIMModule，6 子 Agent 分工。

---

旧命名迁移见 [docs/rename-from-wk-im-developer.md](docs/rename-from-wk-im-developer.md)。

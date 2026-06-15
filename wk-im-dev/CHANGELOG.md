# wk-im-dev Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

未发布的改动放在 **Unreleased**；打 tag 时把它的内容移到对应版本下并标注日期。

---

## Unreleased

（暂无）

---

## v1.1.0 — 2026-06-15

主题：**Codex plugin-native 兼容 + 行为契约单一事实源 + 组件数泛化 + 模板化生成器**。

### Added (组件数泛化 / Phase 4)

- **运行时组件清单** `components.conf`（TAB 分隔，纯 bash 可解析）：组件名、角色、依赖规则（`forbid_import`）、隐私词、只读路径的唯一事实源。
- **`bin/wk-im-components.sh`**：清单定位与解析库，被 detect-env / guard / scope-check / init 共用，hook 上下文不依赖 jq。
- `wk-im-init.sh` 新增 `--component <Name>=<path>`（可重复），`--service` / `--module` 保留为 IM 实例的 back-compat 别名。

### Changed (组件数泛化 / Phase 4)

- **从「恰好 service+module 两个标量」泛化为「1..N 个组件」**：`detect-env` / `guard` / `scope-check` / `init` 不再硬编码 `BTIMService`/`BTIMModule`，改为读 `components.conf` 遍历。
- **`workspace.json` schema v2**：`service`/`module` 标量 → `components: { <Name>: <path> }` 映射；保留 `hostApps`。init 自动把 v1 旧格式迁移到 v2，hostApps 增量合并不丢。
- `detect-env` 输出从 `service_path`/`module_path` 改为 `components` 映射；env 值 `btim-service`/`btim-module` 归并为通用 `component`。

### Added

- **Codex plugin 清单** `.codex-plugin/plugin.json`，声明 `skills` / `hooks` / `commands`，让 Codex 原生加载技能与钩子。
- **`.claude-plugin/plugin.json`** 补充 `commands` / `skills` / `hooks` 字段声明。
- **`SessionStart` hook**（`hooks/session-init.sh`）：在 IM 仓库启动会话时自动 init workspace 并注入**精炼的 wk-im-dev 激活摘要**；非 IM 仓库静默 `exit 0`。
- **`/wk-im-dev` 命令**（`commands/wk-im-dev.md`）：非 IM 仓库下的手动激活入口。

### Changed

- **行为契约收敛为单一事实源**：`agents/wk-im-dev.md` 现为 identity / 约束 / 路由 / 工作流的唯一来源；`codex/AGENTS.md` 与 launcher 降级为离线 fallback，引用而不重定义规则。
- **launcher 离线 Codex 路径**：改为注入 `~/.wk-im-dev/wk-im-dev-agent.md`（自动剥离 YAML frontmatter），不再依赖 profile 的 `-p`。
- **`scripts/install.sh`**：安装 agent spec 取代 core spec；移除 `--skip-codex-agent` / `--skip-codex-profile` flag 及 `~/.codex/agents/*.toml`、`~/.codex/wk-im-dev.config.toml` 写入。
- **`doctor`**：检查 `agent spec` 取代 `core spec`；检测到旧版 Codex 产物时提示清理。

### Removed

- `core/wk-im-dev-core.md`（合并进 `agents/wk-im-dev.md`）。
- `codex/wk-im-dev.toml`、`codex/profile.toml`、`codex/install.sh`（plugin-native 后不再需要；`codex/install.sh` 早已 DEPRECATED）。

### Migration

- ⚠️ 对已安装旧版用户是 **breaking change**（launcher 改读 agent spec；旧 toml/profile 弃用）。已安装用户重跑 bootstrap 即可迁移；旧 toml/profile 由 `uninstall.sh` 或 `doctor` 提示清理，launcher 保留对旧 core spec 的 fallback 读取。
- **发版前必须按 `CLAUDE.md` 步骤 3 跑完整端到端（3.1 Codex + 3.2 Claude plugin）**，本地 install.sh 不暴露 plugin 加载问题。

---

## v1.0.5 — 2026-05-28 (hotfix)

### Fixed

- **`codex -p wk-im-dev` 无法激活 agent**：`codex/profile.toml`（→ `~/.codex/wk-im-dev.config.toml`）只有 settings（`model_reasoning_effort`、`personality`），缺少 `developer_instructions`，导致 `codex -p wk-im-dev` 启动后 Codex 不知道自己是 wk-im-dev，无 agent 身份。现在 profile 加入了 `developer_instructions` 字段，包含 agent 身份、职责和工作语言的紧凑描述，完整规范仍由 AGENTS.md 提供。

- **launcher `launch_codex()` 永远不用 profile**：`-p wk-im-dev` 触发条件是 `grep '[profiles.wk-im-dev]' config.toml`（v1.0.1 旧格式），v1.0.2 已改为独立文件但 launcher 未同步，导致每次都走 else 分支（只传 `-c model_reasoning_effort`，不带 profile 名），profile 里的 `personality`、`developer_instructions` 从未被加载。现在改为检测 `~/.codex/wk-im-dev.config.toml` 是否存在，存在则传 `-p wk-im-dev`。

- **doctor codex profile 检查误报 miss**：与上同源，doctor 也在检查旧格式，始终报 `[miss] codex profile [profiles.wk-im-dev] missing`。现在改为检查新文件 `~/.codex/wk-im-dev.config.toml`。

- **`uninstall.sh` 漏删两项**：① 未删 `~/.codex/wk-im-dev.config.toml`（v1.0.2+ 写入的独立 profile 文件）；② 未删 `~/.local/bin/wk-im-dev` symlink（v1.0.3+ 写入）。现在补全清理，卸载后 4 项产物（`~/.wk-im-dev/`、`codex agent`、`profile`、`symlink`）全部清除。

### Migration

- 已安装用户重跑 bootstrap 即可获得修复后的 profile：
  ```
  curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.5/wk-im-dev/scripts/bootstrap.sh \
    | bash -s -- --target /path/to/im-repo --ref v1.0.5 --runtime codex
  ```
  Claude Code 用户：`claude plugin update wk-im-dev@yuxilong-agents`（发版后）。
- 运行 `wk-im-dev doctor` 验证：`[ok] codex profile: ~/.codex/wk-im-dev.config.toml` 即为修复后状态。

---

## v1.0.4 — 2026-05-28 (hotfix)

### Fixed

- **bootstrap.sh `--runtime claude`（含 `--runtime auto` 检测到 claude CLI）不安装 `wk-im-dev` 命令**：`install_claude_plugin()` 之前只调用 `claude plugin install`，完全跳过 sparse clone 和 `install.sh`，导致 `~/.wk-im-dev/bin/`、launcher、symlink 均未安装，用完 bootstrap 后 `wk-im-dev` 命令找不到。
  - `install_claude_plugin()` 和 `install_codex_curl()` 合并重构为 `clone_and_install_sh(rt)` + `add_claude_plugin()`。
  - `--runtime claude`：现在先跑 `install.sh --runtime claude`（安装 helpers/launcher/symlink，跳过 codex agent/profile），再调 `claude plugin install`。
  - `--runtime both`：改为单次 clone，跑 `install.sh --runtime both`（全套），再调 `claude plugin install`，消除之前的 double clone。
  - `--runtime codex`：行为不变。

### Notes

- 此 bug 只影响通过 `bootstrap.sh` 安装的用户（curl pipe bash）；`claude plugin update` 路径不受影响。
- 已通过 `--runtime both` 安装的用户（helpers 来自 codex 路径）无需操作。
- 受影响用户（用过 `--runtime auto`/`claude` 且 `wk-im-dev` 命令缺失）重跑 bootstrap 即可修复。

---

## v1.0.3 — 2026-05-28 (patch)

### Fixed

- **ccswitch 兼容**：cc-switch < v3.11 切换供应商时会用模板完全覆写 `~/.claude/settings.json`，清空 `enabledPlugins` 对象，导致 wk-im-dev plugin 被静默禁用（表现：`claude --agent wk-im-dev` 进入普通对话，或 launcher 回退到 codex 路径）。
  - `bin/wk-im-dev`：`claude_plugin_installed()` 拆分为 `plugin_status()` + wrapper，新增 `installed-but-disabled` 状态检测（从 `installed_plugins.json` + cache 目录双重确认 plugin 已安装但 key 被清除）。
  - 新增 `fix-plugin` 子命令：自动把 `"wk-im-dev@yuxilong-agents": true` 写回 `enabledPlugins`，优先用 jq，退回 python3，写入前备份 settings.json。
  - `doctor` 新增 `installed-but-disabled` 诊断分支，明确提示 cc-switch 根因 + `wk-im-dev fix-plugin` 一键修复命令。
  - 主调度 `none` case 检测 `installed-but-disabled` 时给出专属错误提示而非通用"runtime not found"。

- **install 后立即可用**：`scripts/install.sh` 跑完后，当前终端不执行 `source` 也能直接使用 `wk-im-dev`。
  - 新增 `install_symlink()`：在第一个已存在、在 PATH 中、可写的候选目录（`~/.local/bin` → `/usr/local/bin` → `/opt/homebrew/bin`）创建 `wk-im-dev` symlink 指向 launcher，当前 shell 立即可用。
  - install 输出末尾 banner 明确区分"立即可用"与"需要 source"两种状态并突出提示。

### Migration

- **从 v1.0.2 升级**：
  ```
  bash scripts/install.sh --runtime both
  wk-im-dev --version   # 应输出 1.0.3
  ```
  Claude Code 用户：`claude plugin update wk-im-dev@yuxilong-agents`（发版后）。
- 如果已遭遇 ccswitch 禁用问题，运行一次 `wk-im-dev fix-plugin` 恢复。
- 建议将 cc-switch 升级到 >= v3.11.0 防止复发。

---

## v1.0.2 — 2026-05-28 (hotfix)

### Fixed

- 新版 Codex 不再支持 `[profiles.xxx]` 写在 `~/.codex/config.toml` 里，改用独立的 `~/.codex/<name>.config.toml`；旧格式会导致 `codex -p wk-im-dev` 启动时报错退出：`--profile wk-im-dev cannot be used while config.toml contains legacy [profiles.wk-im-dev]`。
  - `codex/profile.toml`：移除 `[profiles.wk-im-dev]` 表头和 `WK-IM-DEV-PROFILE` markers，改为纯 flat key-value（文件名即 profile 名）。
  - `scripts/install.sh`：`install_codex_profile()` 改写目标为 `~/.codex/wk-im-dev.config.toml`；保留 migration 逻辑，重新安装时自动清除旧 `config.toml` 中的 legacy block。
  - `scripts/verify.sh`：移除旧格式断言，改验 `model_reasoning_effort` 存在 + `[profiles.wk-im-dev]` 不存在。

### Migration

- **从 v1.0.1 升级**：直接重跑 bootstrap（Codex 路径）：
  ```
  curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.2/wk-im-dev/scripts/bootstrap.sh \
    | bash -s -- --target . --ref v1.0.2
  ```
  Claude Code 用户：`claude plugin update wk-im-dev@yuxilong-agents`。
- 装完跑 `codex -p wk-im-dev`，不应再出现 `Error loading config.toml` 报错。

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

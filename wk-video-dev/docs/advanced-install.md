# wk-video-dev 安装高级选项

> 主流程见 [../README.md](../README.md)。本页收纳 `install.sh` / `bootstrap.sh` / `wk-video-init.sh` 的高级 flag、marker 机制和卸载细节。

## 1. `scripts/install.sh` 全部 flag

```text
Usage: bash scripts/install.sh [options]

Options:
  --runtime <codex|claude|both>   要安装的运行时支持，默认 both
  --target <project_dir>          目标组件仓库或 HostApp，默认当前目录
  --skip-init                     安装后不自动跑 wk-video-init.sh
  --with-codegraph                安装时一并安装 + 索引 CodeGraph（默认不装）
  --skip-project-agents           不创建/合并 target AGENTS.md
  --replace-project-agents        备份后整体替换 target AGENTS.md（默认 marker 合并）
  --no-shell-rc                   不向 ~/.zshrc / ~/.bashrc 追加 PATH
```

默认行为：当 `--target` 看起来是 VideoEditCore/VideoEditUI/HostApp 时，安装末尾会自动调用 `wk-video-init.sh --root <target> --quiet` 完成知识库初始化。临时目录不会触发。

## 2. `scripts/bootstrap.sh` 全部 flag

```text
curl -fsSL <url>/bootstrap.sh | bash -s -- [options]

  --target <path>      目标仓库，默认当前目录
  --runtime <value>    auto（默认）/ codex / claude / both
                       auto：装了 claude CLI → claude，否则 codex
                       codex：git clone + install.sh（Codex 主路径）
                       claude：claude plugin marketplace add + install
                       both：先 codex 流程，再附加 claude plugin（双装）
  --ref <git-ref>      要拉取的 git tag/branch/commit，默认 main
                       也可用 env WK_VIDEO_DEV_REF
  --repo-url <url>     覆盖默认仓库地址（团队内网镜像）
                       也可用 env WK_VIDEO_DEV_REPO_URL
  --no-shell-rc        不改 shell rc
  --skip-init          安装后不自动跑 wk-video-init.sh
  --with-codegraph     安装时一并安装 + 索引 CodeGraph
```

**版本固定建议**：CI/Release 流程打 tag 后，团队成员安装时显式 `--ref v1.1.1`（当前最新 tag），避免 `main` 引入未稳定提交时全员遭殃。

**内网镜像**：把 Agents 仓库 mirror 到内网（如 `git@gitlab.intra/.../Agents.git`），安装时：

```bash
export WK_VIDEO_DEV_REPO_URL="https://gitlab.intra/team/Agents.git"
export WK_VIDEO_DEV_REF="v1.1.1"
curl -fsSL https://gitlab.intra/team/Agents/-/raw/main/wk-video-dev/scripts/bootstrap.sh | bash -s -- --target .
```

## 3. `wk-video-init.sh` 全部 flag

```text
~/.wk-video-dev/bin/wk-video-init.sh [options]

  --root <repo>           手动指定视频编辑组件仓库或 HostApp（默认自动定位）
  --component <Name>=<path>  手动指定某组件路径（可重复，组件名取自 components.conf）
  --service <path>        VideoEditCore 路径（模板实例的 --component VideoEditCore= 别名）
  --module <path>         VideoEditUI 路径（模板实例的 --component VideoEditUI= 别名）
  --host-app <path>       添加 HostApp（可重复多次）
  --with-codegraph        安装并索引 CodeGraph（默认不装）
  --quiet                 静默输出
```

> 组件名不再硬编码，来自 `components.conf`。`--service` / `--module` 仅是 模板实例的 back-compat 别名；生成的其他组件 agent 用 `--component <Name>=<path>` 指定任意组件。

自动定位顺序：

1. 显式 `--root` 优先。
2. 从 pwd 向上找最近的 `VideoEditCore.podspec` / `VideoEditUI.podspec`，或同时引用两个 pod 的 `Podfile`。
3. 仍未命中时，读 `~/.wk-video-dev/workspace.json`，按 hostApps → service → module 顺序选第一个仍存在的目录。
4. 都不行就用 pwd（`wk-video-detect-env.sh` 会返回 `unknown`，提示用户手动指定）。

## 4. Marker 机制

### `AGENTS.md` marker 块（Codex）

`install.sh` 默认通过 marker 块合并目标仓库的 `AGENTS.md`：

```text
<!-- WK-VIDEO-DEV:START -->
... wk-video-dev 维护的内容 ...
<!-- WK-VIDEO-DEV:END -->
```

- 目标文件不存在 → 直接写入。
- 目标存在且无 marker → 追加 wk-video-dev 区块，原内容备份到 `AGENTS.md.wk-video-dev-backup-<timestamp>`。
- 目标存在且 marker 数量异常 → 报错退出，用户手动修复。
- 显式 `--replace-project-agents` → 备份后整体替换。
- `--skip-project-agents` → 完全不动目标 `AGENTS.md`。

### `~/.codex/config.toml` profile 区块（已废弃）

> 2026-06-15 起 Codex 转为 plugin-native，**不再写入** `~/.codex/config.toml` 的 `[profiles.wk-video-dev]`、`~/.codex/agents/wk-video-dev.toml` 或 `~/.codex/wk-video-dev.config.toml`。激活改走 plugin `agents/` + `SessionStart` hook + `/wk-video-dev` 命令；离线 fallback 由 launcher 注入 `~/.wk-video-dev/wk-video-dev-agent.md`。
>
> 旧版安装残留的 `# WK-VIDEO-DEV-PROFILE` 区块与 toml 文件，`uninstall.sh` / `doctor` 仍会识别并清理（见第 5 节）。

## 5. 卸载

```bash
# 本地仓库
bash scripts/uninstall.sh                     # 清理全局安装产物
bash scripts/uninstall.sh --target <repo>     # 同时清理目标仓库 AGENTS.md marker

# curl 方式
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-video-dev/scripts/uninstall.sh | bash
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-video-dev/scripts/uninstall.sh | bash -s -- --target /path/to/repo

# Claude Code plugin
claude plugin uninstall wk-video-dev@yuxilong-agents
claude plugin marketplace remove YuXilong-Labs/Agents
```

卸载会移除：

- `~/.wk-video-dev/`（含 `wk-video-dev-agent.md`、helper 脚本、workspace.json）
- 旧版残留：`~/.codex/agents/wk-video-dev.toml`、`~/.codex/wk-video-dev.config.toml`、`~/.codex/config.toml` 中的 `# WK-VIDEO-DEV-PROFILE` 区块（plugin-native 后不再生成，卸载仍会清理）
- shell rc 中 `# wk-video-dev` + `export PATH=...` 两行
- （传 `--target` 时）目标仓库 `AGENTS.md` 中的 wk-video-dev 区块

保留：

- 每个组件仓库的 `docs/agent-knowledge/`（视为业务知识资产，不主动删除）。如不再需要可手动删。

## 6. 离线 / 本地源码模式

```bash
# 不走 curl 时直接调用本地脚本
bash /path/to/Agents/wk-video-dev/scripts/install.sh --runtime codex --target /path/to/VideoEditCore

# Claude Code 不安装到全局
claude --plugin-dir /path/to/Agents/wk-video-dev
```

## 7. 验证与排错

```bash
bash scripts/verify.sh                        # 源码布局静态检查
~/.wk-video-dev/bin/wk-video-dev doctor             # 安装状态自检
```

doctor 输出涵盖：runtime 探测、关键文件、PATH、`workspace.json` 内容、CodeGraph 状态。报错时优先看这个。

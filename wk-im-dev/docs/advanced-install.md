# wk-im-dev 安装高级选项

> 主流程见 [../README.md](../README.md)。本页收纳 `install.sh` / `bootstrap.sh` / `wk-im-init.sh` 的高级 flag、marker 机制和卸载细节。

## 1. `scripts/install.sh` 全部 flag

```text
Usage: bash scripts/install.sh [options]

Options:
  --runtime <codex|claude|both>   要安装的运行时支持，默认 both
  --target <project_dir>          目标组件仓库或 HostApp，默认当前目录
  --skip-init                     安装后不自动跑 wk-im-init.sh
  --with-codegraph                安装时一并安装 + 索引 CodeGraph（默认不装）
  --skip-project-agents           不创建/合并 target AGENTS.md
  --replace-project-agents        备份后整体替换 target AGENTS.md（默认 marker 合并）
  --skip-codex-agent              不安装 ~/.codex/agents/wk-im-dev.toml
  --skip-codex-profile            不写入 [profiles.wk-im-dev] 到 ~/.codex/config.toml
  --no-shell-rc                   不向 ~/.zshrc / ~/.bashrc 追加 PATH
```

默认行为：当 `--target` 看起来是 BTIMService/BTIMModule/HostApp 时，安装末尾会自动调用 `wk-im-init.sh --root <target> --quiet` 完成知识库初始化。临时目录不会触发。

## 2. `scripts/bootstrap.sh` 全部 flag

```text
curl -fsSL <url>/bootstrap.sh | bash -s -- [options]

  --target <path>      目标仓库，默认当前目录
  --runtime <value>    codex（默认）
  --ref <git-ref>      要拉取的 git tag/branch/commit，默认 main
                       也可用 env WK_IM_DEV_REF
  --repo-url <url>     覆盖默认仓库地址（团队内网镜像）
                       也可用 env WK_IM_DEV_REPO_URL
  --no-shell-rc        不改 shell rc
  --skip-init          安装后不自动跑 wk-im-init.sh
  --with-codegraph     安装时一并安装 + 索引 CodeGraph
```

**版本固定建议**：CI/Release 流程打 tag 后，团队成员安装时显式 `--ref v3.4.0`，避免 `main` 引入未稳定提交时全员遭殃。

**内网镜像**：把 Agents 仓库 mirror 到内网（如 `git@gitlab.intra/.../Agents.git`），安装时：

```bash
export WK_IM_DEV_REPO_URL="https://gitlab.intra/team/Agents.git"
export WK_IM_DEV_REF="v3.4.0"
curl -fsSL https://gitlab.intra/team/Agents/-/raw/main/wk-im-dev/scripts/bootstrap.sh | bash -s -- --target .
```

## 3. `wk-im-init.sh` 全部 flag

```text
~/.wk-im-dev/bin/wk-im-init.sh [options]

  --root <repo>           手动指定 IM 仓库或 HostApp（默认自动定位）
  --service <path>        手动指定 BTIMService 路径
  --module <path>         手动指定 BTIMModule 路径
  --host-app <path>       添加 HostApp（可重复多次）
  --with-codegraph        安装并索引 CodeGraph（默认不装）
  --quiet                 静默输出
```

自动定位顺序：

1. 显式 `--root` 优先。
2. 从 pwd 向上找最近的 `BTIMService.podspec` / `BTIMModule.podspec`，或同时引用两个 pod 的 `Podfile`。
3. 仍未命中时，读 `~/.wk-im-dev/workspace.json`，按 hostApps → service → module 顺序选第一个仍存在的目录。
4. 都不行就用 pwd（`wk-im-detect-env.sh` 会返回 `unknown`，提示用户手动指定）。

## 4. Marker 机制

### `AGENTS.md` marker 块（Codex）

`install.sh` 默认通过 marker 块合并目标仓库的 `AGENTS.md`：

```text
<!-- WK-IM-DEV:START -->
... wk-im-dev 维护的内容 ...
<!-- WK-IM-DEV:END -->
```

- 目标文件不存在 → 直接写入。
- 目标存在且无 marker → 追加 wk-im-dev 区块，原内容备份到 `AGENTS.md.wk-im-dev-backup-<timestamp>`。
- 目标存在且 marker 数量异常 → 报错退出，用户手动修复。
- 显式 `--replace-project-agents` → 备份后整体替换。
- `--skip-project-agents` → 完全不动目标 `AGENTS.md`。

### `~/.codex/config.toml` profile 区块

```text
# WK-IM-DEV-PROFILE:START
[profiles.wk-im-dev]
... model / reasoning_effort 等 ...
# WK-IM-DEV-PROFILE:END
```

`install.sh` 走 marker 幂等更新；`uninstall.sh` 按同样的 marker 删除。`--skip-codex-profile` 完全跳过。

## 5. 卸载

```bash
# 本地仓库
bash scripts/uninstall.sh                     # 清理全局安装产物
bash scripts/uninstall.sh --target <repo>     # 同时清理目标仓库 AGENTS.md marker

# curl 方式
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/uninstall.sh | bash
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/uninstall.sh | bash -s -- --target /path/to/repo

# Claude Code plugin
claude plugin uninstall wk-im-dev@yuxilong-agents
claude plugin marketplace remove YuXilong-Labs/Agents
```

卸载会移除：

- `~/.wk-im-dev/`
- `~/.codex/agents/wk-im-dev.toml`
- `~/.codex/config.toml` 中的 `# WK-IM-DEV-PROFILE` 区块
- shell rc 中 `# wk-im-dev` + `export PATH=...` 两行
- （传 `--target` 时）目标仓库 `AGENTS.md` 中的 wk-im-dev 区块

保留：

- 每个组件仓库的 `docs/agent-knowledge/`（视为业务知识资产，不主动删除）。如不再需要可手动删。

## 6. 离线 / 本地源码模式

```bash
# 不走 curl 时直接调用本地脚本
bash /path/to/Agents/wk-im-dev/scripts/install.sh --runtime codex --target /path/to/BTIMService

# Claude Code 不安装到全局
claude --plugin-dir /path/to/Agents/wk-im-dev
```

## 7. 验证与排错

```bash
bash scripts/verify.sh                        # 源码布局静态检查
~/.wk-im-dev/bin/wk-im-dev doctor             # 安装状态自检
```

doctor 输出涵盖：runtime 探测、关键文件、PATH、`workspace.json` 内容、CodeGraph 状态。报错时优先看这个。

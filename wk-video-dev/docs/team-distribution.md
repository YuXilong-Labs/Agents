# wk-video-dev 团队分发指南

> 适用于：把 wk-video-dev 推广给团队成员、内网/私有源场景、CI 把关的发布流程。
> 单人本地体验请直接看 [../README.md](../README.md)。

---

## 0. TL;DR

```bash
# 团队成员一行命令（钉死 tag + 走内网镜像）
WK_VIDEO_DEV_REPO_URL="https://gitlab.intra/team/Agents.git" \
WK_VIDEO_DEV_REF="v1.0.1" \
  curl -fsSL https://gitlab.intra/team/Agents/-/raw/v1.0.1/wk-video-dev/scripts/bootstrap.sh \
  | bash -s -- --target .
```

```bash
# 装完自检
wk-video-dev --version
wk-video-dev doctor
```

---

## 1. 推广前发布者要做的事

### 1.1 在公开仓库（GitHub）打 tag

```bash
git tag v1.0.1
git push origin v1.0.1
```

发布给团队的安装命令里**始终带 `--ref v1.0.1`**，避免某次 `main` 上的未稳定 commit 让全员安装挂掉。

### 1.2（可选）把 Agents 仓库 mirror 到团队内网

适用场景：GitHub 不可访问、团队要求所有依赖走内网。

```bash
# 在内网 GitLab/Gitea/自建 GitHub 上创建空仓库 team/Agents
git clone --mirror https://github.com/YuXilong-Labs/Agents.git
cd Agents.git
git remote set-url --push origin https://gitlab.intra/team/Agents.git
git push --mirror
```

然后定期同步（每周 / Release 触发）：

```bash
git fetch --all
git push --mirror
```

或者写到团队 CI（GitHub Actions / GitLab Schedule）里定时跑。

### 1.3 验证 release 在拉取端工作

发布前在一台 clean 环境上跑一次：

```bash
# 模拟团队成员从零安装
docker run --rm -it -v $PWD:/work ubuntu:22.04 bash -c '
  apt-get update && apt-get install -y curl git bash
  curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.1/wk-video-dev/scripts/bootstrap.sh \
    | bash -s -- --target /work --ref v1.0.1 --no-shell-rc --skip-init
  ls ~/.wk-video-dev/bin
'
```

---

## 2. 团队成员安装路径

按运行时和访问情况二选一。

### 2.1 公开 GitHub + 公网

```bash
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.1/wk-video-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/BTVideoRecorderKit --ref v1.0.1
```

### 2.2 内网 mirror（推荐 GitLab）

把 bootstrap 一行命令写进团队 wiki / 入职 checklist：

```bash
export WK_VIDEO_DEV_REPO_URL="https://gitlab.intra/team/Agents.git"
export WK_VIDEO_DEV_REF="v1.0.1"
curl -fsSL \
  "https://gitlab.intra/team/Agents/-/raw/${WK_VIDEO_DEV_REF}/wk-video-dev/scripts/bootstrap.sh" \
  | bash -s -- --target .
```

或者把这两步揉成一个团队脚本 `team/install-wk-video-dev.sh`，团队成员只跑：

```bash
curl -fsSL https://gitlab.intra/team/install-wk-video-dev.sh | bash
```

### 2.3 私有仓库需要 token

如果内网仓库要鉴权（GitLab personal access token / GitHub PAT），bootstrap 走 git clone，要么：

- 用 SSH：把 `WK_VIDEO_DEV_REPO_URL` 设为 `git@gitlab.intra:team/Agents.git`，确保 `~/.ssh/id_*` 已登记
- 用 HTTPS + token：把 token 写到 `~/.netrc` 或 `git config credential.helper store` 一次

不要把 token 写进 README 示例命令里。

### 2.4 Claude Code 用户

`claude plugin install` 走的是 Claude Code 自己的 marketplace 协议，不读 `WK_VIDEO_DEV_REPO_URL`。

公网场景：

```bash
claude plugin marketplace add YuXilong-Labs/Agents
claude plugin install wk-video-dev@yuxilong-agents
```

内网场景目前没有"plugin marketplace 镜像"的官方机制；过渡方案：

1. 团队成员先 clone 内网 mirror 到本地：`git clone https://gitlab.intra/team/Agents.git ~/wk-video-dev-src`
2. 用 `claude --plugin-dir ~/wk-video-dev-src/wk-video-dev` 启动（每次都需要 `--plugin-dir`）
3. 或者把 `wk-video-dev/` 拷贝到 `~/.claude/plugins/installed/wk-video-dev/`，自行管理升级

---

## 3. 升级流程

### 3.1 Codex 用户

```bash
# 重新跑 bootstrap，目标版本会覆盖现有安装
curl -fsSL .../bootstrap.sh | bash -s -- --target . --ref v1.0.1
```

bootstrap 会重新 install 全部脚本 + 更新 `~/.wk-video-dev/wk-video-dev-agent.md`（agent spec）、`AGENTS.md` 的 marker 块。**不会**重置 `~/.wk-video-dev/workspace.json`（hostApps 走增量合并）。

### 3.2 Claude Code 用户

```bash
claude plugin update wk-video-dev@yuxilong-agents
# 如果改了 marketplace name，需要先 remove 再 add
```

### 3.3 升级后是否要重跑 init？

| 情况 | 是否需要 |
|---|---|
| 升级只动了 agent 文件 / hooks / docs | 不需要 |
| 升级动了 `bin/wk-video-init.sh` 或 kb-scan 逻辑 | 推荐 `wk-video-init.sh` 重扫一次 |
| 升级了 CodeGraph 集成版本 | `wk-video-codegraph.sh init --root <repo>` 重建索引 |

不确定时统一跑：

```bash
wk-video-dev doctor
wk-video-init.sh   # 在视频拍摄编辑组件仓库里跑
```

---

## 4. 排错速查

| 症状 | 原因 / 修复 |
|---|---|
| `git clone --branch v1.0.1` 失败 | tag 没推到默认 remote → 发布者 `git push origin v1.0.1` |
| `curl` 返回 403 / 404 | 私有仓库未鉴权 → 改 SSH 或 netrc |
| `claude plugin marketplace add` 找不到 | marketplace name 是 `yuxilong-agents`，pre-1.0 老名字 `yuxilong-labs` 已废弃 |
| `wk-video-dev` 命令找不到 | `~/.wk-video-dev/bin` 没在 PATH → 看 doctor 输出，按提示 export |
| 本地残留 v3.x tag | pre-1.0 内部版本号，已全部从 GitHub 删除 → `git fetch --prune --prune-tags origin` |

---

## 5. 安全 / 审计建议

团队 IT 不允许 `curl ... | bash` 的环境（怕中间人篡改、怕未审计代码进生产环境），有两种替代方案：

### 5.1 先下载再审计后运行

```bash
# 1. 下载到本地
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.0.1/wk-video-dev/scripts/bootstrap.sh \
  -o /tmp/wk-video-dev-bootstrap.sh

# 2. 审计（人工 review 或交给团队安全工具）
less /tmp/wk-video-dev-bootstrap.sh

# 3.（可选）记录 sha256 入团队 manifest
shasum -a 256 /tmp/wk-video-dev-bootstrap.sh

# 4. 运行
bash /tmp/wk-video-dev-bootstrap.sh --target . --ref v1.0.1
```

### 5.2 团队级集中安装（推荐）

不让每个团队成员各自 `curl | bash`，改成团队基础设施的一部分：

1. CI/Release 流程在内网 mirror 上打 `v1.x` tag
2. 团队基础镜像 / Mac 准备脚本里集成：
   ```bash
   git clone --depth 1 --branch v1.0.1 https://gitlab.intra/team/Agents.git /opt/Agents
   bash /opt/Agents/wk-video-dev/scripts/install.sh --runtime both --target $HOME --skip-init
   ```
3. 团队成员只跑入职脚本，不直接接触 bootstrap 命令

`install.sh` 里所有写动作都集中在 `~/.wk-video-dev/`、`~/.codex/`、可选 shell rc 和目标仓库的 `AGENTS.md` marker 块，没有 root 操作、没有网络下载（git clone 在 bootstrap 阶段完成）。审计点已经收敛得很小。

### 5.3 已知不会清理的备份文件

`install.sh` 每次修改 `~/.codex/config.toml` 或目标 `AGENTS.md` 时会留备份文件（`*.wk-video-dev-backup-<timestamp>`），不会自动清理。多次升级后会累积，定期手动清理即可：

```bash
find ~ -maxdepth 3 -name "*.wk-video-dev-backup-*" -mtime +30 -delete
```

---

## 6. 团队 onboarding 模板

放到团队 wiki 顶部：

```markdown
## iOS 视频拍摄编辑团队成员入职 checklist

1. 安装 Codex CLI 或 Claude Code（任一即可）
2. 安装 wk-video-dev：
   ```
   WK_VIDEO_DEV_REF=v1.0.1 curl -fsSL .../bootstrap.sh | bash -s -- --target .
   ```
3. 验证：
   ```
   wk-video-dev --version    # 应输出 1.0.0
   wk-video-dev doctor       # 检查 runtime / workspace / PATH
   ```
4. 在 BTVideoRecorderKit 或 BTVideoRecorderUIKit 仓库内跑一次：
   ```
   wk-video-dev
   > 你好，你是谁？
   ```
   应该看到中文自我介绍。
5. 出问题先看 `wk-video-dev doctor` 输出 + 本文档第 4 节排错速查。
```

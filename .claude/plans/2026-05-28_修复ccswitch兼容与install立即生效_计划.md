# 修复 ccswitch 兼容性与 install 立即生效

> 日期：2026-05-28
> 主题：wk-im-dev v1.0.3（patch）
> 范围：`wk-im-dev/bin/wk-im-dev`、`wk-im-dev/scripts/install.sh`、`CHANGELOG.md`、`plugin.json`

---

## 背景

用户反馈两个独立问题：

### 问题 1：ccswitch 切换 Claude Code 供应商后 agent 激活失败

- cc-switch（farion1231/cc-switch）v3.11.0 之前的版本在切换供应商时会**完全覆写** `~/.claude/settings.json`，**清空 `enabledPlugins` 字段**，导致所有 plugin（含 wk-im-dev）被静默禁用。
- 现象：用户运行 `claude --agent wk-im-dev` 时 claude CLI 进入普通对话（agent 未被识别）；`wk-im-dev` launcher 因为 `claude_plugin_installed()` 在 `settings.json` 里 grep 不到 key 而 fallback 到 codex（如果 codex 装了），或直接报"no supported runtime"。
- cc-switch v3.11+ 已修复（改为按字段合并），但**老版本用户和回滚到老版本的用户仍会遇到**。

### 问题 2：install.sh 跑完后命令找不到

- install.sh 把 `export PATH="$HOME/.wk-im-dev/bin:$PATH"` 追加到 `~/.zshrc`，**当前 shell 不会自动 reload**。
- 用户直接在当前终端敲 `wk-im-dev` 命令找不到，必须 `source ~/.zshrc` 或重开终端，体验差。
- 现有提示信息埋在 install 输出末尾，容易被刷屏忽略。

---

## 目标 / 验收标准

### 问题 1 修复后

- [ ] **检测稳健**：launcher `claude_plugin_installed()` 即使 cc-switch 清掉了 `enabledPlugins`，只要 plugin 实际安装在 `~/.claude/plugins/cache/yuxilong-agents/wk-im-dev/`（或 `installed_plugins.json` 里有记录），也能正确识别为可用，并自动把 key 补回 `settings.json`。
- [ ] **诊断清晰**：`wk-im-dev doctor` 在 plugin 被 cc-switch 禁用时给出明确诊断：「Plugin installed but disabled (likely by cc-switch overwriting settings.json)」+ 一行 fix 命令。
- [ ] **一键修复**：提供 `wk-im-dev fix-plugin` 子命令，自动把 `"wk-im-dev@yuxilong-agents": true` 写回 `~/.claude/settings.json`，无需手动编辑 JSON。

### 问题 2 修复后

- [ ] **当前 shell 立即可用**：install.sh 跑完后，**无需 source、无需重开终端**，当前 shell 直接 `wk-im-dev --version` 即可运行。
- [ ] **方案优先 symlink**：检测到 `~/.local/bin/` 已存在且在 PATH 中（绝大多数 macOS 用户都满足），就在那里创建 symlink 指向 launcher。如果 `~/.local/bin/` 不在 PATH，则降级到 `/usr/local/bin/`（如果可写）或现有的 zshrc 方案。
- [ ] **提示更醒目**：保留 zshrc 写入作为新终端的兜底，但 install 输出末尾用清晰的 banner 强调"立即可用：/path/to/symlink"。

---

## 影响范围

| 文件 | 改动 |
|---|---|
| `wk-im-dev/bin/wk-im-dev` | 增强 `claude_plugin_installed()`；新增 `fix-plugin` 子命令；doctor 新增 cc-switch 场景诊断 |
| `wk-im-dev/scripts/install.sh` | 新增 `install_symlink()` 优先创建 `~/.local/bin/wk-im-dev` symlink；末尾输出 banner |
| `wk-im-dev/CHANGELOG.md` | 新增 v1.0.3 Unreleased → Released 节 |
| `wk-im-dev/.claude-plugin/plugin.json` | 版本号 1.0.2 → 1.0.3 |
| `.claude-plugin/marketplace.json` | 同步版本号（如果有） |

无需改动：`core/`、`agents/`、`skills/`、`hooks/`、`docs/`（功能逻辑不变，仅 launcher / installer 增强）。

---

## 实施步骤

### 阶段 1：launcher 增强（问题 1）

1.1 修改 `claude_plugin_installed()`：
   - 现有的 settings.json grep 保留
   - 新增 fallback：检查 `~/.claude/plugins/installed_plugins.json` 是否有 `wk-im-dev@yuxilong-agents`，且对应 installPath 存在
   - 区分三种状态：`enabled` / `installed-but-disabled` / `not-installed`

1.2 新增 `fix-plugin` 子命令：
   - 用 sed/awk 安全地在 `settings.json` 的 `enabledPlugins` 对象里补回 `"wk-im-dev@yuxilong-agents": true`
   - 如果 settings.json 不存在或没有 enabledPlugins 字段，引导用户跑 `claude plugin install`
   - 备份原 settings.json 到 `settings.json.wk-im-dev-backup-<时间戳>`

1.3 doctor 增强：
   - 检测到 `installed-but-disabled` 时打印明确诊断
   - Suggested fixes 列出 `wk-im-dev fix-plugin`

1.4 主调度逻辑保持不变（当 plugin enabled 时还是 launch_claude）。

**阶段验证**：
- 手动把 settings.json 中的 `wk-im-dev@yuxilong-agents` 行删掉，跑 doctor 看是否报「installed-but-disabled」
- 跑 `wk-im-dev fix-plugin`，验证 key 被恢复，再跑 doctor 确认 [ok]
- `claude --agent wk-im-dev --print "hello"` 能正常激活 agent

### 阶段 2：install.sh symlink（问题 2）

2.1 新增 `install_symlink()`：
   - 候选目录：`~/.local/bin/`、`/usr/local/bin/`、`/opt/homebrew/bin/`
   - 取第一个**已存在 + 在 PATH 中 + 可写**的目录
   - 创建 symlink `<dir>/wk-im-dev -> $HOME/.wk-im-dev/bin/wk-im-dev`
   - 如果 symlink 已存在但指向不一致，备份后重建
   - 失败时降级到现有的 zshrc 方案（不报错）

2.2 把 `install_symlink` 在 install.sh 主流程里加入（紧跟 `install_helper_scripts` 之后）。

2.3 install 输出 banner：
   - 顶部突出显示「✓ wk-im-dev 已安装并立即可用 → 当前终端直接敲 `wk-im-dev` 即可」
   - 保留 PATH/source 提示作为兜底

**阶段验证**：
- 在 `~/.local/bin/` 没有 `wk-im-dev` symlink 的状态下重跑 install.sh
- 验证 symlink 创建成功且 `wk-im-dev --version` 在 current shell 直接可跑
- 验证重复跑 install.sh 时 symlink 检查幂等（不会乱备份）

### 阶段 3：版本号 + CHANGELOG + 验证

3.1 `plugin.json` 1.0.2 → 1.0.3
3.2 `CHANGELOG.md` 加 v1.0.3 节，列出两个修复
3.3 跑 `bash scripts/verify.sh`（静态）
3.4 跑 `bash scripts/install.sh --runtime both` 本地端到端
3.5 跑 `~/.wk-im-dev/bin/wk-im-dev doctor` 应全 [ok] 且 effective runtime: claude

### 阶段 4（可选，发版前再做）：远端端到端

按 CLAUDE.md 步骤 3 跑 Codex 路径 + Claude plugin 路径端到端。**本计划只做到本地验证；发版动作单独提议。**

---

## 风险与回滚

| 风险 | 缓解 |
|---|---|
| `fix-plugin` 写 settings.json 时 JSON 语法被破坏 | 改写前先备份；用 awk/jq 谨慎处理；如果 jq 可用优先 jq |
| `~/.local/bin/` symlink 与其他工具冲突 | 创建前检查目标文件存在性，若不是 symlink 或指向非 wk-im-dev 则报错跳过，不强制覆盖 |
| cc-switch 下次切换又把 enabledPlugins 删了 | 在 doctor / 文档里说明：升级 cc-switch ≥ 3.11.0；本工具只兜底单次修复，不能阻止 cc-switch 再次覆写 |
| launcher 在 codex-only 安装场景下 fix-plugin 子命令报错 | fix-plugin 子命令需先检测 claude CLI 是否存在，不存在则提示而不是失败 |

**回滚方案**：所有改动都在 launcher / installer / 文档层；plugin 内容（agent 定义、skill）零改动。回滚 = revert 这次 commit。

---

## 验证方式

### 静态验证
```bash
cd wk-im-dev
bash scripts/verify.sh
```

### 本地端到端
```bash
# install
bash scripts/install.sh --runtime both --target /tmp

# 立即可用检查（关键 — 不开新终端、不 source）
wk-im-dev --version    # 应输出 1.0.3
wk-im-dev doctor       # 应全 [ok]

# cc-switch 场景模拟
python3 -c "import json,sys; d=json.load(open('$HOME/.claude/settings.json')); d.get('enabledPlugins',{}).pop('wk-im-dev@yuxilong-agents',None); json.dump(d, open('$HOME/.claude/settings.json','w'), indent=2)"
wk-im-dev doctor       # 应报 installed-but-disabled，并提示 fix-plugin
wk-im-dev fix-plugin   # 自动恢复
wk-im-dev doctor       # 应全 [ok]

# agent 激活
claude --agent wk-im-dev --print "hello" | head -5   # 应输出 wk-im-dev 自我介绍
```

### 手工验证
- 在一个全新终端跑安装脚本，确认 install 输出末尾 banner 醒目
- symlink 检查：`ls -la ~/.local/bin/wk-im-dev` 应指向 `~/.wk-im-dev/bin/wk-im-dev`

---

## 不做的事

- 不动 plugin 内容（agent / skill / hook 定义）
- 不动 codex 侧的 profile / agent 安装逻辑
- 不发 tag / 不 push 到远端（本计划只做到本地验证；发版动作另起一次执行）
- 不修复 cc-switch 本身（只在 wk-im-dev 侧兜底）

---

## 后续建议

- 在 README.md / docs/ 加一节"cc-switch 兼容性"，提示用户升级到 ≥3.11.0
- 长期看，可以引入 `wk-im-dev guard` 周期检测 + auto-fix（但属于 v1.1+ feature，不在本 patch 范围）

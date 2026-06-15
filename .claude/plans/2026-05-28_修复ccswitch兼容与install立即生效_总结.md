# 修复 ccswitch 兼容性与 install 立即生效 — 总结

> 日期：2026-05-28
> 版本：v1.0.3（patch）
> Commit：d420c67

---

## 完成内容

### 问题 1：ccswitch 切换供应商后 agent 激活失败

**根因**：cc-switch < v3.11 切换供应商时完全覆写 `~/.claude/settings.json`，清空 `enabledPlugins` 对象，导致 wk-im-dev plugin 静默禁用。

**修复**：
- `claude_plugin_installed()` 拆分为 `plugin_status()` + wrapper，支持三态：`enabled` / `installed-but-disabled` / `not-installed`
- `installed-but-disabled` 检测逻辑：`installed_plugins.json` 有记录 **且** cache 目录存在 **但** settings.json 里 key 缺失
- 新增 `fix-plugin` 子命令：自动把 `"wk-im-dev@yuxilong-agents": true` 写回 `enabledPlugins`，优先 jq，退回 python3，写入前自动备份
- doctor 诊断新增 `installed-but-disabled` 分支，明确提示 cc-switch 根因 + 一键修复命令
- 主调度 `none` case 检测 `installed-but-disabled` 给出专属错误信息

### 问题 2：install 后命令找不到

**根因**：install.sh 只写 zshrc，当前 shell 不 source 就找不到 `wk-im-dev`。

**修复**：
- 新增 `install_symlink()`：在 `~/.local/bin`（已在 PATH）创建 symlink，当前 shell 立即可用
- install 末尾 banner 明确区分"立即可用"与"需要 source"两种状态

---

## 关键改动清单

| 文件 | 改动类型 |
|---|---|
| `bin/wk-im-dev` | 新增 `plugin_status()`、`fix_plugin()`；更新 doctor、主调度、show_help |
| `scripts/install.sh` | 新增 `install_symlink()`；主流程 + banner 更新 |
| `.claude-plugin/plugin.json` | 1.0.2 → 1.0.3 |
| `CHANGELOG.md` | 新增 v1.0.3 节 |

---

## 验证结果

| 场景 | 结果 |
|---|---|
| `bash scripts/verify.sh` | ✓ passed |
| `bash scripts/install.sh --runtime both --target /tmp` | ✓ symlink 创建，banner 正确 |
| `wk-im-dev --version` | ✓ 1.0.3（当前终端，无需 source） |
| 模拟 ccswitch 清空 enabledPlugins → `doctor` | ✓ 显示 `installed-but-disabled` + fix-plugin 提示 |
| `wk-im-dev fix-plugin` | ✓ jq 写回 key，备份成功 |
| `wk-im-dev doctor` 修复后 | ✓ 全 [ok]，effective runtime: claude |
| `claude --agent wk-im-dev --print "hello"` | ✓ wk-im-dev 正常激活 |

---

## 风险与遗留

- cc-switch 每次切换仍会清空 enabledPlugins（根本修复需升级 cc-switch ≥ v3.11）；wk-im-dev 只提供单次恢复，不拦截重复发生
- 远端端到端（Codex curl 路径 + Claude plugin update）未验证，发版前补跑

---

## 后续建议

- 发版：打 tag `v1.0.3`，push，按 CLAUDE.md 步骤 3 跑端到端验证
- 可在 README 加一节"cc-switch 兼容说明"，提示升级 ≥ v3.11

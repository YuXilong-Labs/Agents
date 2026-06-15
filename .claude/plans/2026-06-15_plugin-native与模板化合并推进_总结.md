# wk-im-dev：plugin-native 兼容 + 模板化 合并推进 总结

> 日期：2026-06-15
> 分支：`wk-im-dev/plugin-native-and-templating`（未 push，按你的选择保留本地）
> 计划：见同名 `_计划.md`

---

## 完成内容（5 阶段全部落地）

| Phase | 主题 | commit |
|---|---|---|
| 1+2 | Codex plugin-native 激活：`.codex-plugin/plugin.json` + 两端声明 skills/hooks/commands + SessionStart hook + `/wk-im-dev` 命令 | `a813e14` |
| 3 | 行为契约收敛单一事实源 `agents/wk-im-dev.md`，删除 `core/` 与 codex toml/profile/install.sh | `9726d6c` |
| 4 | 组件数泛化：`service/module` 标量 → `components.conf` 清单驱动，支持 1..N 组件；workspace.json v1→v2 迁移 | `dd9c602` |
| 5 | `tools/create-wk-agent.sh` 生成器 + `manifests/`：wk-im-dev 即模板，从 manifest 生成新组件 agent | `1295b96` |

## 关键改动清单

**新增**：`wk-im-dev/.codex-plugin/plugin.json`、`commands/wk-im-dev.md`、`hooks/session-init.sh`、`components.conf`、`bin/wk-im-components.sh`、`tools/create-wk-agent.sh`、`tools/README.md`、`manifests/im.json`、`manifests/example-pay.json`。

**删除**：`core/wk-im-dev-core.md`、`codex/wk-im-dev.toml`、`codex/profile.toml`、`codex/install.sh`。

**重构**：`agents/wk-im-dev.md`（单一事实源）、`bin/wk-im-dev`（launcher 注入 agent spec、剥 frontmatter、去 profile）、`bin/wk-im-{detect-env,guard,init}.sh` + `hooks/scope-check.sh`（清单驱动）、`scripts/{install,verify}.sh`、`codex/AGENTS.md`（降级 fallback）、README/CHANGELOG/docs。

## 验证结果

- `wk-im-dev/scripts/verify.sh` 全绿；所有改动脚本 `bash -n` 通过。
- 隔离 HOME 跑真实 `install.sh --runtime both`：agent spec 安装、无 core spec 残留、AGENTS.md marker 生成、`doctor` 显示 `agent spec [ok]`。
- detect-env：单组件 / main-app / 3 组件均正确识别。
- guard：命中 forbid_import + privacy + scope（exit 1），clean 仓库 pass。
- init：写 2 组件与 3 组件 `components` map；v1 旧格式（service/module 标量）自动迁移到 v2 且 hostApps 保留。
- **生成器**：生成 `wk-pay-dev`（PayCore/PayUI）→ 其 `verify.sh` 全绿、detect-env 识别 PayCore、guard 命中 PayUI→PaymentGatewaySDK + cvv 隐私（exit 1）、无残留引用。
- **dogfood**：`im.json` 重生成与现 `wk-im-dev/` 除版本号、JSON 数组缩进外字节一致。

## 风险与遗留

- ⚠️ **未做发版端到端（CLAUDE.md 步骤 3）**：本环境无法跑真实 `codex plugin add` / `claude plugin update`。Phase 3 是 breaking change（launcher 改读 agent spec、旧 toml/profile 弃用），**正式发版前必须跑完整 3.1/3.2 端到端**。launcher 已保留对旧 core spec 的 fallback；旧产物由 uninstall/doctor 提示清理。
- `docs/architecture.md` 的 Mermaid 图块仍是旧 Codex 流程，已加 banner 标注，待整体重绘。
- 生成器对**组件数 ≠ 2** 的目标按位置映射前 N 个，依赖方向图等散文需人工 review（残留扫描会提示）；`skills/im-knowledge/` 的领域散文（message-flow 等）按新领域需重写。
- 分支未 push（按你的选择）。`tools/` 测试期间在 `/usr/local/bin` 留下的 dangling symlink 已清理，未影响你的真实安装（`~/.local/bin/wk-im-dev`）。

## 后续建议

1. 发版前：bump `plugin.json` 版本（plugin-native 是行为增强 → v1.1.0；含 breaking 可议 v2.0.0），把 CHANGELOG Unreleased 移到版本节，跑步骤 3 端到端。
2. 重绘 `docs/architecture.md` 的安装流程图为 plugin-native 版。
3. 若要支持真正 1 或 N(≠2) 组件 agent，补 manifest 驱动的散文模板（identity/依赖图用 token 块），让生成器对任意组件数零残留。
4. push 分支 + 开 PR（`/code-review ultra` 可做多 agent 云端 review）。

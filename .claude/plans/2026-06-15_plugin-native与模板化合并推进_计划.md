# wk-im-dev：plugin-native 兼容 + 模板化 合并推进计划

> 日期：2026-06-15
> 分支：`wk-im-dev/plugin-native-and-templating`
> 合并自：`2026-06-08_wk-im-dev-plugin-native进化_计划.md` + `2026-06-04_wk-component-agent-模板化_计划.md`

---

## 背景与目标

两件事存在**依赖顺序**：内容当前在 3 处重复（`core/wk-im-dev-core.md` + `agents/wk-im-dev.md` + `codex/AGENTS.md`，靠 `<!-- KEEP IN SYNC -->` 人肉同步）。
若先做模板化，生成器要渲染 3 份同步文件，复杂度与漂移风险翻三倍。
因此：**先收敛单一事实源（plugin-native），再泛化组件数，最后抽模板。**

### 验收标准

1. `plugin.json` 声明 `skills` + `hooks`，Codex 能原生加载技能与钩子。
2. Codex 在 IM 仓库启动时经 SessionStart hook 自动激活人格；非 IM 仓库可用 `/wk-im-dev` 手动激活。
3. agent 人格/约束/路由收敛为单一事实源，其余文件引用而非复制。
4. 组件数从「service+module 两个标量」泛化为 `components` map，detect-env/guard/init 按清单遍历。
5. 存在 manifest + 生成器，dogfood 重生成 wk-im-dev 结构等价、`verify.sh` 全绿。

---

## 分阶段（每阶段独立可验证 + commit）

### Phase 1 — plugin.json 能力声明（零风险，纯增量）✅ 本次
- `.claude-plugin/plugin.json` 补 `skills` + `hooks` 字段。
- 新建 `.codex-plugin/plugin.json`（Codex 清单）。
- 验证：`verify.sh` 全绿；JSON 合法。

### Phase 2 — Codex 原生激活（纯增量）✅ 本次
- 新建 `commands/wk-im-dev.md`（`/wk-im-dev` 手动激活入口）。
- 新建 `hooks/session-init.sh`（SessionStart：IM 仓库自动激活 + auto-init；非 IM 仓库 exit 0）。
- `hooks/hooks.json` 增 `SessionStart` event。
- session-init 注入**精炼激活摘要**，不 cat 整篇 agent.md（控 token、避免抢戏）。
- `verify.sh` 增加对新文件的校验。

### Phase 3 — 单一事实源收敛（破坏性，需端到端）
- 合并 `core/wk-im-dev-core.md` → `agents/wk-im-dev.md`。
- `codex/AGENTS.md`、`codex/*.toml`、launcher 改为引用单一源。
- 更新 `verify.sh` 去掉对 `core/`、`codex/*.toml` 的强制存在校验（或调整为新结构）。
- 删除 `codex/install.sh`（已 DEPRECATED）。
- 按 CLAUDE.md 步骤 3 端到端验证后才发版。

### Phase 4 — 组件数泛化
- `workspace.json`：`service/module` 标量 → `components` map（旧字段兼容读取 + 迁移）。
- `detect-env.sh` / `guard.sh` / `init.sh` 按组件清单遍历，依赖规则表驱动。

### Phase 5 — 抽模板 + 生成器 + dogfood
- `templates/component-agent/`（`{{TOKEN}}`）+ `bin/create-wk-agent.sh` + `manifests/*.yaml`。
- dogfood：`im.yaml` 重生成 == 现 wk-im-dev；CI 加「regen 无 diff」断言。

---

## 风险与回滚

| 风险 | 缓解 |
|---|---|
| Phase 3 删除 core/toml 中断旧版用户 | 保留 bootstrap/AGENTS.md fallback；CHANGELOG 标 breaking；端到端验证 |
| SessionStart 在非 IM 仓库误触发 | 首行检测 podspec/Podfile，不匹配 exit 0 |
| SessionStart 全量注入费 token | 只注入精炼激活摘要 + 指向完整规范 |
| 组件数泛化破坏现有 IM 安装 | Phase 4 原地改 + 跑完整 verify/doctor 才进 Phase 5；旧字段兼容 |

每阶段 commit；Phase 3/5 发版前跑 CLAUDE.md 步骤 3 端到端。

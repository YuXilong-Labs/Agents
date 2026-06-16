# create-wk-agent — per-component agent 生成器

从一份 manifest 生成一个**完整、自包含、可独立发版**的 per-component 开发 agent，
结构与 `wk-im-dev/` 一致（plugin 清单、launcher、subagents、skills、hooks、安装脚本、知识库工具）。

## 核心设计：wk-im-dev 即模板

不维护单独的 `templates/` token 树（会与 wk-im-dev 漂移）。生成器直接克隆 `wk-im-dev/`，然后：

1. **slug 改名**：`wk-im-dev`→新 slug，`wk-im-`→新文件前缀，`WK-IM-`→新 marker 前缀，`WK_IM_`→新环境变量前缀（含文件重命名）。
2. **组件名替换**：模板组件 `BTIMService`/`BTIMModule` → manifest 组件名（按顺序定位）。这一步顺带把 identity / 约束 / 文档散文里的旧组件名改掉，无需单独模板化散文。
3. **`components.conf` 重生成**：依据 manifest 的组件、依赖规则、隐私词、只读路径权威重写（detect-env/guard/scope-check/init 都读它）。
4. **plugin 清单**：从 manifest 写 name/version/description/keywords。
5. **残留扫描**：列出仍含旧 slug/组件名的文件（通常是文档散文），供人工 review。

dogfood 验证：`--manifest manifests/im.json` 重生成的结果与现有 `wk-im-dev/` 除版本号、JSON 数组缩进外字节一致——证明"wk-im-dev 即模板"不漂移。

## 用法

```bash
# 生成进仓库（推荐）：--out 直接位于仓库根下 → 自动注册到 .claude-plugin/marketplace.json
tools/create-wk-agent.sh --manifest manifests/video-recorder.json --out wk-video-dev

# 生成到仓库外做预览/试验：--out 不在仓库根下 → 跳过 marketplace 注册
tools/create-wk-agent.sh --manifest manifests/example-pay.json --out /tmp/wk-pay-dev --force

# 不想自动注册时显式关闭
tools/create-wk-agent.sh --manifest manifests/video-recorder.json --out wk-video-dev --no-register

# dogfood：重生成 wk-im-dev 自身（应与现有目录等价）
tools/create-wk-agent.sh --manifest manifests/im.json --out /tmp/regen --force
```

> **marketplace 自动注册**：当 `--out` 是仓库根的直接子目录时，生成器按新 agent 的 `plugin.json`
> upsert 一条 `git-subdir` 记录到 `.claude-plugin/marketplace.json`（复用首条记录的 repo URL，
> 兼容内网 mirror）。生成到仓库外（如 `/tmp`）则自动跳过，不污染 marketplace。`--no-register` 强制关闭。
> 生成结束会打印 `marketplace: added/updated/skipped ...` 一行说明本次行为。

生成后验证：

```bash
bash /tmp/wk-pay-dev/scripts/verify.sh                 # 结构/语法/JSON
WK_IM_DEV_COMPONENTS=/tmp/wk-pay-dev/components.conf \
  bash /tmp/wk-pay-dev/bin/<slug>-detect-env.sh <repo> # 组件识别
```

## Manifest 字段（JSON）

| 字段 | 必填 | 说明 |
|---|---|---|
| `slug` | ✓ | agent slug，建议 `wk-<domain>-dev`。派生 marker(`WK-<DOMAIN>-`)、env 前缀、文件前缀。 |
| `description` | ✓ | plugin 描述。 |
| `keywords` | | plugin keywords 数组。 |
| `components[]` | ✓ | `{name, role, scope_root}`。`role` 仅语义标注；`scope_root` 缺省=name。**按顺序**定位映射到模板的 BTIMService/BTIMModule。 |
| `forbid_import[]` | | `{component, targets[]}`：该组件源码新增 import targets 中任一项即违规。 |
| `privacy_keywords[]` | | 日志中出现即告警的关键词。 |
| `readonly_paths[]` | | 写入被拦截的路径前缀。 |
| `sdk_literal` | | 模板里 `ThirdPartyIMSDK` 字面量替换目标（散文用）。 |
| `version` | | 生成 agent 的初始版本，默认 `1.0.0`。 |

## 覆盖范围与限制

**完全自动**：slug 全量改名 + 文件重命名、组件名替换（含 identity/约束散文）、components.conf、plugin 清单、CHANGELOG 重置、marketplace 注册（`--out` 在仓库根下时）、领域散文残留扫描（列出仍含 IM 名词的文件供人工重写）。

> 隐私约束散文已泛化为「以 `components.conf` 的 `privacy` 项为准」，生成的 agent 不再携带 IM 隐私名词（messageBody 等）；隐私词的真正数据源始终是 `components.conf`（由 manifest 渲染）。

**需人工 review**（残留扫描会列出）：
- **组件数与模板不同（非 2 个）**：组件名按位置映射前 N 个；依赖方向图、跨组件顺序等散文需人工调整。
- 模板里与 IM 强绑定的领域散文（如消息流程示例、`skills/im-knowledge/` 的 message-flow 内容）需按新领域重写。
- `skills/im-knowledge/` 目录名含 `im` 未改（功能不受影响，cosmetic）。

生成后务必跑生成 agent 的 `verify.sh`，并按其 `CLAUDE.md`（继承自模板）的发版流程做端到端验证。

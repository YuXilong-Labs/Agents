# CodeGraph 集成

`wk-video-dev` 集成 [CodeGraph](https://github.com/colbymchenry/codegraph) — 基于 tree-sitter AST 的本地代码知识图谱（SQLite），用于加速 agent 的结构化查询并节省 token。

CodeGraph 是 100% 本地工具：建库与查询都在本机，索引存放在每个组件仓库的 `.codegraph/`。

## 为什么集成

| 任务 | 仅 Wiki + grep | 加 CodeGraph |
|------|---------------|-------------|
| 找符号定义 | grep + read 2-3 文件，~3k token | `codegraph_search`，~200 token |
| 找方法的所有 caller | grep 正则 + 5 条上限，漏 dynamic dispatch | `codegraph_callers`，完整准确 |
| 评估 public API 变更影响 | 不支持，需要人工 review | `codegraph_impact` 一次返回全调用链 |
| 跨 Swift ↔ ObjC bridge 流程 | grep 跟不上 selector + `@objc` 桥接 | `codegraph_trace` 自动桥接 |
| 业务流程追踪 X → Y | 多次 explorer 串联 | `codegraph_trace` 一次返回完整路径 |

CodeGraph 在 Wikipedia-iOS 等大型 ObjC+Swift 工程上经过验证，对 VideoEditCore（ObjC + 部分 Swift） 的解析与 caller/callee 识别准确率可用于 agent 决策。

## 安装与初始化

`wk-video-init.sh` 已经自动集成 codegraph 检测与初始化：

```bash
~/.wk-video-dev/bin/wk-video-init.sh --root /path/to/VideoEditCore
# 会自动：
#   1. 检测 codegraph 是否安装
#   2. 缺失时提示安装（curl 或 npm 自动选择）
#   3. 给每个扫描根目录初始化 .codegraph/ 索引
```

也可单独使用 helper：

```bash
# 检测
~/.wk-video-dev/bin/wk-video-codegraph.sh detect

# 安装（curl 或 npm 自动选择）
~/.wk-video-dev/bin/wk-video-codegraph.sh install

# 给指定 root 建索引
~/.wk-video-dev/bin/wk-video-codegraph.sh init --root /path/to/VideoEditCore

# 查看索引状态
~/.wk-video-dev/bin/wk-video-codegraph.sh status --root /path/to/VideoEditCore
```

非交互模式（CI、脚本调用）：

```bash
wk-video-codegraph.sh install --yes --quiet
wk-video-codegraph.sh init --root <repo> --yes --quiet
```

## Agent 调用顺序

`wk-video-explorer` 与 `wk-video-debugger` 的优先级：

1. **CodeGraph（如可用）** — `codegraph_*` MCP 工具
2. **Knowledge Base** — `docs/agent-knowledge/index.md` 与 topic 页
3. **grep / Read fallback** — codegraph 不可用且 wiki 信息不足时

`wk-video-verifier` 会在 public header 变更时调 `codegraph_impact` 评估影响半径。

## 与 Knowledge Base 的分工

| 责任 | 归属 |
|------|------|
| 调用关系 / 影响半径 / 流程追踪 | CodeGraph（实时索引，AST 精度） |
| 组件入口路由、business topic、curated notes | Knowledge Base（人工 + 脚本维护） |
| 公开 API 签名清单 | Knowledge Base（脚本生成） + CodeGraph（精准 caller） |
| 架构决策、隐私约束、风险点 | Knowledge Base curated notes |
| Cross-pod 契约 | `contracts.md` + `codegraph_impact` 双源校验 |

Wiki 不再生成 "Callers of …" 段（已在 `wk-video-kb-scan.sh` 中删除）。所有调用关系问题由 codegraph 回答。

## 故障与回退

| 场景 | 处理 |
|------|------|
| codegraph 未安装 | install 自动调用 curl/npm，失败仅警告，agent 自动回退 |
| 网络不通无法安装 | agent 完全回退 grep + wiki，功能不丢失 |
| `.codegraph/` 不存在 | 单次 `wk-video-codegraph.sh init --root <repo>` 解决 |
| codegraph 索引过期 | codegraph 自带 file watcher 自动增量更新；停服后下次 init 重建 |
| ObjC++ 宏导致解析失败 | 该符号回退 grep + wiki；codegraph 不破坏现有流程 |

## 卸载

CodeGraph 完全独立于 wk-video-dev：

```bash
codegraph uninstall                 # 移除 codegraph 本体 + 所有 agent 配置
codegraph uninit                     # 仅移除某 repo 的 .codegraph/ 索引
```

`wk-video-dev` 不会强依赖 codegraph，卸载后 agent 自动回退到 grep + wiki。

# wk-video-dev Changelog

> **Tag 约定**：本仓库是多 agent monorepo，plain `vX.Y.Z` tag 属于 wk-im-dev。
> wk-video-dev 用 **agent 作用域、无斜杠** 的 tag：`wk-video-dev-vX.Y.Z`
> （无斜杠保证 `raw.githubusercontent.com/.../<tag>/...` bootstrap URL 不歧义）。

## wk-video-dev-v1.0.0 — 2026-06-16

首个正式版本。iOS 视频录制组件开发 Agent（`BTVideoRecorderKit` + `BTVideoRecorderUIKit`），
由仓库根 `tools/create-wk-agent.sh` 从 `manifests/video-recorder.json` 生成（模板 = wk-im-dev）。

- **双运行时 plugin-native**：Claude Code（marketplace `wk-video-dev@yuxilong-agents`）+ Codex（curl bootstrap + SessionStart hook + 离线 launcher fallback）。
- **组件约束**：依赖方向 `BTVideoRecorderUIKit → BTVideoRecorderKit → VideoEngineSDK`；UI 不得直连第三方视频引擎 SDK（系统 AVFoundation 预览允许）；隐私字段 `sourceURL/outputURL/licenseKey/...` 由 `components.conf` 驱动 guard。
- **领域**：相机采集 → 实时预览/滤镜 → 录制编码 → 产物落盘；知识库、subagent 分工、CodeGraph 集成同构于 wk-im-dev。

> SDK 字面量 `VideoEngineSDK` 为占位；接入真实录制 SDK 后改 `manifests/video-recorder.json` 重跑生成器。

# wk-video-dev Changelog

> **Tag 约定**：本仓库是多 agent monorepo，plain `vX.Y.Z` tag 属于 wk-im-dev。
> wk-video-dev 用 **agent 作用域、无斜杠** 的 tag：`wk-video-dev-vX.Y.Z`
> （无斜杠保证 `raw.githubusercontent.com/.../<tag>/...` bootstrap URL 不歧义）。

## wk-video-dev-v1.0.1 — 2026-06-16

据真实仓库（`BTVideoRecorderKit` / `BTVideoRecorderUIKit`）实现校正定位与跨 pod 契约。

- **定位**：从"视频录制"校正为 **短视频拍摄 + 编辑** 组件。
- **真实底层引擎**：默认美摄 `NvStreamingSdkCore`（`Classes/NvsEditor/NvsEngine`，`BTVideoEditorEngineNvs`，`NvsStreamingContext.verifySdkLicenseFile` 校验授权）；可选阿里 `AliVCSDK_UGC`（`Classes/Services/AliEditor`，`Ali` 子 spec）；字节 `BTBytedEffect` 美颜 + 阿里 `MNN` 推理。
- **公开入口**：`BTVideoRecorderUIKit` 的 BTRouter Target-Action（`Target_BTVideoRecorderUIKit`：`Action_openCameraController`/`startVideoCapture`/`editorViewController`/`triggerProEditExport`/`openMusicPicker` 等）。
- **依赖约束（已核实）**：UIKit 当前 0 处直连厂商 SDK；`components.conf` `forbid_import` 改为真实目标 `NvStreamingSdkCore`/`NvsStreamingContext`/`AliVCSDK_UGC`。
- **隐私词校正**：`videoPath`/`outputPath`/`outputURL`/`deviceId`/`userId`/`token`（取代占位 `sourceURL`/`licenseKey`），驱动 guard 与 review。
- **知识库重写**：`architecture.md`/`contracts.md`/`pipeline.md` 改为真实分层（Contract / NvsEngine / Services；UIKit Camera/Edit/Filter/Sticker/MusicPicker）与真实拍摄→编辑→导出流程。

> SDK 字面量从占位 `VideoEngineSDK` 更正为美摄 `NvStreamingSdkCore`。

## wk-video-dev-v1.0.0 — 2026-06-16

首个正式版本。iOS 视频拍摄编辑组件开发 Agent（`BTVideoRecorderKit` + `BTVideoRecorderUIKit`），
由仓库根 `tools/create-wk-agent.sh` 从 `manifests/video-recorder.json` 生成（模板 = wk-im-dev）。

- **双运行时 plugin-native**：Claude Code（marketplace `wk-video-dev@yuxilong-agents`）+ Codex（curl bootstrap + SessionStart hook + 离线 launcher fallback）。
- **组件约束**：依赖方向 `BTVideoRecorderUIKit → BTVideoRecorderKit → NvStreamingSdkCore`；UI 不得直连第三方视频引擎 SDK（系统 AVFoundation 预览允许）；隐私字段 `sourceURL/outputURL/licenseKey/...` 由 `components.conf` 驱动 guard。
- **领域**：相机采集 → 实时预览/滤镜 → 录制编码 → 产物落盘；知识库、subagent 分工、CodeGraph 集成同构于 wk-im-dev。

> SDK 字面量 `NvStreamingSdkCore` 为占位；接入真实录制 SDK 后改 `manifests/video-recorder.json` 重跑生成器。

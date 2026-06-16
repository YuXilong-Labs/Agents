# 视频拍摄编辑流程（Pipeline）

公开入口走 `BTVideoRecorderUIKit` 的 BTRouter Target-Action；底层默认走美摄 `BTVideoEditorEngineNvs`。

## 拍摄流程 (Capture)

```
HostApp --BTRouter: Action_openCameraController / Action_startVideoCapture--> Camera UI
  → BTBeautyRecorderManager（拍摄 + 美颜：字节 BTBytedEffect / MNN）
    → 美摄采集（NvsStreamingContext，仅 NvsEditor/NvsEngine adapter）
    → 分段录制 / 录制时长(BTRecordDurationSelector) / 控制栏(BTRecordingControlBar)
    → 产物 videoPath/outputURL
  → Action_saveCameraEditVideoCallback 回传 HostApp
```

## 编辑流程 (Edit)

```
HostApp --BTRouter: Action_editorViewController / Action_showEditorViewController--> Editor UI
  → BTVideoEditorEngineNvs（美摄时间线引擎）
    +Effect  特效（Fx/FxUI）
    +Filter  滤镜
    +Sticker 图片/文字贴纸（ImageSticker/TextSticker）
    +Text    字幕（BTVideoEditorCaptionMenuView）
  → 配乐 Action_openMusicPicker（MusicPicker：列表/搜索/本地/裁剪/卡点/音量）
  → 预览（系统 AVFoundation 预览层允许在 UI）
```

## 导出流程 (Export)

```
HostApp/Editor --Action_triggerProEditExport--> BTVideoEditorEngineNvs.export
  → 美摄编码（时间线合成 → H.264/HEVC）
  → onProgress: 进度回调（主线程）→ UI
  → 产物 outputPath；失败回错误码（磁盘满/授权失效/被打断）
```

## 关键约束

- 美摄授权：`NvsStreamingContext.verifySdkLicenseFile(licPath)` 校验 license 文件；失败则引擎不可用。
- `videoPath` / `outputPath` / `outputURL` / `deviceId` / `userId` 不写日志（privacy，权威清单见 `components.conf`）。
- 拍摄/编辑/导出进度与保存回调**必须主线程**派发（UIKit 安全）。
- 采集与编码在专用队列，不阻塞主线程（否则掉帧/卡顿）。
- `BTVideoRecorderUIKit` 只经 `BTVideoEditorEngineNvs` 等抽象访问引擎，**不直连**美摄/阿里 SDK；厂商访问只在 `NvsEditor/NvsEngine`、`Services` adapter。
- 多引擎：默认美摄 `NvStreamingSdkCore`；阿里 `AliVCSDK_UGC` 为可选 `Ali` 子 spec（`Classes/Services/AliEditor`）。

# 视频录制流程（Pipeline）

## 采集会话流程 (Capture Session)

```
BTVideoRecorderUIKit (UI)
  → BTVideoRecorderKit.startSession(config)
    → 配置相机（分辨率 / 帧率 / 方向 / 前后置 / 闪光）
    → VideoEngineSDK.configureCapture()
    → 启动预览（AVCaptureVideoPreviewLayer / Metal）
    → notify UI via onSessionReady()
```

## 预览处理流程 (Preview)

```
相机帧（CMSampleBuffer）
  → BTVideoRecorderKit 采集回调
    → 应用实时滤镜 / 美颜 / 贴纸
    → VideoEngineSDK.process(frame)
    → 回调处理后帧 → UI 预览层（系统 AVFoundation 预览允许在 UI 层）
```

## 录制流程 (Record)

```
BTVideoRecorderUIKit → BTVideoRecorderKit.startRecording(outputURL)
  → 校验磁盘空间 & 输出参数（分辨率 / 码率 / 编码格式）
  → VideoEngineSDK.startEncode()
    → 逐帧编码（H.264 / HEVC）+ 音频采集混音
    → onProgress: 回调时长 / 进度 → UI
    → onSuccess: 产出 outputURL → UI
    → onFailure: 错误码（磁盘满 / 被来电打断）→ UI
  → notify UI via onRecordStateChanged()
```

## 录制状态机 (Record State Machine)

```
[idle] → previewing → recording → paused → recording
                    → recording → finishing → success
                                            → failed → [retry]
       interrupted（来电 / 切后台）→ paused
```

## 关键约束

- `sourceURL` / `outputURL` / `licenseKey` 不写日志（privacy，权威清单见 `components.conf`）。
- 进度 / 状态 / 中断（来电、后台）回调始终在主线程派发（UIKit 安全）。
- 采集与编码跑在专用队列，不阻塞主线程（否则掉帧 / 卡顿）。
- `BTVideoRecorderKit` 是录制事实源；`VideoEngineSDK` 只做采集 / 编码 / 帧处理（transport/compute）。
- `BTVideoRecorderUIKit` 只通过 `BTVideoRecorderKit` 访问录制能力，不直接调用 `VideoEngineSDK`。

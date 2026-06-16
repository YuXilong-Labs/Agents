# 视频编辑 / 导出流程（Pipeline）

## 编辑会话流程 (Edit Session)

```
VideoEditUI (UI)
  → VideoEditCore.openProject(asset)
    → 构建时间线 Timeline（tracks: video / audio / overlay）
    → 加载素材元数据（时长 / 分辨率 / 帧率 / 方向）
    → VideoEngineSDK.prepare()
    → notify VideoEditUI via onProjectReady()
```

## 预览渲染流程 (Preview)

```
VideoEditUI seek / play
  → VideoEditCore.renderFrame(time)
    → 合成时间线各 track → 应用滤镜 / 转场 / 贴纸
    → VideoEngineSDK.decode + compose
    → 回调 CVPixelBuffer → VideoEditUI 预览层
      （AVSampleBufferDisplayLayer / Metal；系统 AVFoundation 预览允许在 UI 层）
```

## 导出流程 (Export)

```
VideoEditUI → VideoEditCore.export(preset)
  → 校验时间线 & 输出参数（分辨率 / 码率 / 编码格式）
  → VideoEngineSDK.export()
    → 逐帧合成 + 编码（H.264 / HEVC）
    → onProgress: 回调进度 → VideoEditUI 进度条
    → onSuccess: 产出 exportPath → VideoEditUI
    → onFailure: 错误码 → VideoEditUI
  → notify VideoEditUI via onExportStateChanged()
```

## 导出状态机 (Export State Machine)

```
[idle] → exporting → success
                   → failed → [retry] → exporting
                   → cancelled
```

## 关键约束

- `sourceURL` / `exportPath` / `licenseKey` 不写日志（privacy，权威清单见 `components.conf`）。
- 进度 / 状态回调始终在主线程派发（UIKit 安全）。
- 时间线 Timeline 是事实源；`VideoEngineSDK` 只做解码 / 编码 / 合成（transport/compute）。
- 导出、转码等耗时操作不阻塞主线程。
- `VideoEditUI` 只通过 `VideoEditCore` 访问编辑能力，不直接调用 `VideoEngineSDK`。

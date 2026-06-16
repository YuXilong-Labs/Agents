# 跨 Pod / 公开 API 契约

公开入口是 `BTVideoRecorderUIKit` 的 BTRouter Target-Action（`Classes/UIKit/Router/Target_BTVideoRecorderUIKit`）；
跨 pod 能力经 `BTVideoRecorderKit` 的引擎抽象（`BTVideoEditorEngineNvs` 等）+ Contract 类型。

## 公开入口（HostApp → BTVideoRecorderUIKit，BTRouter Action）

| Action | 说明 |
|---|---|
| `Action_openCameraController` / `Action_startVideoCapture` | 打开相机 / 启动拍摄 |
| `Action_editorViewController` / `Action_showEditorViewController` | 获取 / 展示编辑器 VC |
| `Action_triggerProEditExport` | 触发专业编辑导出 |
| `Action_openMusicPicker` | 打开音乐选择器 |
| `Action_saveCameraEditVideoCallback` | 相机→编辑后保存视频回调 |
| `Action_getVideoPathWithAsset` / `...AssetList` | 取素材视频路径（单个 / 列表） |

> 参数走 `NSDictionary`（Target-Action 约定）；新增 Action 时同步更新此表与 `Target_BTVideoRecorderUIKit.h`。

## 引擎抽象（BTVideoRecorderUIKit → BTVideoRecorderKit）

| 抽象 | 职责 |
|---|---|
| `BTVideoEditorEngineNvs`(+Effect/+Filter/+Sticker/+Text) | 美摄编辑引擎：时间线、特效、滤镜、贴纸、字幕 |
| `BTBeautyRecorderManager` | 拍摄录制 + 美颜（字节 BTBytedEffect / MNN） |
| `BTNvsAssetManager` | 素材/资源管理 |
| `BTVideoEditorAssetType`(Contract) | 厂商无关素材类型 |

## 契约规则

1. UIKit 的参数/回调**不得**出现美摄 `Nvs*` / 阿里 `AliVC*` 类型；只用 Contract 抽象或内部模型。
2. 跨 pod 回调（拍摄/编辑/导出进度、保存完成）**必须在主线程**派发（UIKit 安全）。
3. 第三方引擎（美摄/阿里）仅在 `Classes/NvsEditor/NvsEngine`、`Classes/Services` adapter 层访问。
4. 破坏性变更须升版本号 + 迁移说明；公开 Action 增删须更新 `Target_BTVideoRecorderUIKit.h` 与本文件。

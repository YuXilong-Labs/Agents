# BTVideoRecorderKit & BTVideoRecorderUIKit 架构

短视频**拍摄 + 编辑**组件。HostApp 经 `BTRouter` Target-Action 进入 UI，UI 经引擎抽象调用核心，核心适配多家底层引擎。

## 组件边界

```
HostApp
  └──(BTRouter Target-Action)──> BTVideoRecorderUIKit  (拍摄/编辑 UI)
        └── BTVideoRecorderKit  (引擎核心 + Contract 抽象)
              ├── 美摄 NvStreamingSdkCore   (默认引擎；仅 Classes/NvsEditor/NvsEngine adapter)
              ├── 阿里 AliVCSDK_UGC         (可选子 spec；Classes/Services/AliEditor)
              ├── 字节 BTBytedEffect        (美颜/特效)
              └── 阿里 MNN                  (端侧 ML 推理)
```

## BTVideoRecorderKit（引擎核心）分层

| 层 | 目录 | 职责 |
|---|---|---|
| **Contract** | `Classes/Contract` | 厂商无关的类型抽象（如 `BTVideoEditorAssetType`），跨 pod 契约 |
| **Engine/Adapter** | `Classes/NvsEditor/NvsEngine` | 美摄封装：`BTVideoEditorEngineNvs`(+Effect/+Filter/+Sticker/+Text)、`BTBeautyRecorderManager`(拍摄美颜)、`BTNvsAssetManager`(素材)。`NvsStreamingContext.verifySdkLicenseFile` 校验授权 |
| **Services** | `Classes/Services/AliEditor` | 阿里 `AliVCSDK_UGC` 适配（可选 `Ali` 子 spec） |
| **Base / Common** | `Classes/Base`,`Classes/Common` | 工具、基础能力 |
| **Resource** | `Assets`,`Resources/NvsEditor` | 美摄资源 bundle、图片、xcassets |

> 子 spec：`Core`(默认)=Contract+Base+NvsEditor+Resource；`Ali`(可选)；`CoreFramework`(预编译, vendored MNN/NvMSAutoTemplate/NvStreamingSdkCore)。

## BTVideoRecorderUIKit（拍摄/编辑 UI）模块

| 模块 | 目录 | 职责 |
|---|---|---|
| **Router** | `Classes/UIKit/Router` | 公开入口 `Target_BTVideoRecorderUIKit`（BTRouter Target-Action） |
| **Camera** | `Classes/UIKit/Camera` | 拍摄、相机、`Inspiration` 灵感/模板、`BTRecordingControlBar`、`BTRecordDurationSelector` |
| **Edit** | `Classes/UIKit/Edit` | 编辑、`Effect`(Fx/FxUI 特效)、`SelectionPreview` |
| **Filter** | `Classes/UIKit/Filter` | 滤镜 |
| **Sticker** | `Classes/UIKit/ImageSticker`,`TextSticker` | 图片贴纸、文字贴纸（字体/样式/范围） |
| **MusicPicker** | `Classes/UIKit/MusicPicker` | 配乐：列表/搜索/本地/裁剪/卡点/音量 |
| **EditorMenu / Pop / PreviewSlider** | `Classes/UIKit/*` | 编辑菜单栏、弹层、预览滑条 |

依赖 BaiTu 基础设施：`BTRouter`/`BTBaseKit`/`BTLogger`/`BTNetwork`/`BTToast`/`BTComponentsKit`/`BTGlobalConfig` 等；UI 第三方：`Masonry`/`MMKV`/`libpag`/`pop`/`YY*`/`SDWebImage`。

## 跨 Pod API

UIKit 经 BTVideoRecorderKit 的**引擎抽象**（`BTVideoEditorEngineNvs` 等）+ Contract 类型访问编辑能力，**不直连**美摄/阿里 SDK。新增跨 pod API 须更新抽象/Contract 并记到 `contracts.md`。

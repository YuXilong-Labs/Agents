# 消息流程

> TODO: 基于实际代码填充。

## 发送消息流程（待填充）

```
User taps Send
→ ChatViewModel.sendMessage()
→ BTIMServiceProtocol.sendMessage()
→ BTIMService adapter layer
→ ThirdPartyIMSDK.sendMessage()
→ SDK callback → update message status
→ ViewModel receives status update → UI refresh
```

## 接收消息流程（待填充）

```
ThirdPartyIMSDK receives message
→ BTIMService adapter callback
→ BTIMService processes & stores
→ Notify observers (BTIMModule ViewModel)
→ ChatViewModel appends message
→ UI refresh
```

## 重试流程（待填充）

```
User taps retry on failed message
→ ChatViewModel.retryMessage()
→ BTIMServiceProtocol.retryMessage()
→ Re-enter send flow
```

## 媒体消息上传流程（待填充）

```
User selects image/video
→ BTIMModule picks media
→ BTIMService.uploadMedia() (adapter layer)
→ Upload to CDN
→ Send message with media URL
```

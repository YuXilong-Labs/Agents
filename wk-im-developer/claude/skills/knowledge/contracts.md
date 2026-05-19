# BTIMService Public API Contracts

> 此文件记录 BTIMService 暴露给 BTIMModule 的 public protocol 契约。
> **Public API 变更必须同步更新此文件。**
> TODO: 基于实际代码填充。

## 规则

- BTIMModule 只能通过此文件中列出的 protocol 访问 BTIMService 能力
- 不得直接依赖 BTIMService 的具体实现类
- 不得直接 import ThirdPartyIMSDK

## 消息相关（待填充）

```swift
// TODO: 从实际代码中提取
protocol BTIMMessageServiceProtocol {
    func sendMessage(_ message: BTIMMessageProtocol, completion: @escaping (Error?) -> Void)
    func retryMessage(_ messageId: String)
    func deleteMessage(_ messageId: String)
}
```

## 会话相关（待填充）

```swift
// TODO: 从实际代码中提取
protocol BTIMConversationServiceProtocol {
    func getConversationList() -> [BTIMConversationProtocol]
    func markConversationRead(_ conversationId: String)
    var unreadCount: Int { get }
}
```

## 变更记录

| 日期 | 变更内容 | 影响范围 |
|---|---|---|
| (待填充) | 初始版本 | — |

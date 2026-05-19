# 状态机文档

> TODO: 基于实际代码填充。

## 消息状态机（待填充）

```
[sending] → [sent] → [delivered] → [read]
    ↓
[failed] → (retry) → [sending]
```

状态说明：
- `sending`: 已提交给 SDK，等待回调
- `sent`: SDK 确认发送成功
- `delivered`: 对方设备已收到
- `read`: 对方已读（需服务端支持已读回执）
- `failed`: 发送失败（超时 / 网络错误 / SDK 错误）

## 会话状态（待填充）

```
[normal] → [muted] → [normal]
         → [archived]
         → [deleted]
```

## 连接状态（待填充）

```
[disconnected] → [connecting] → [connected]
                                    ↓
                              [reconnecting] → [connected]
                                    ↓
                              [disconnected]
```

连接状态变化时的行为：
- 断开连接：停止发送队列，标记 pending 消息
- 重连成功：重新拉取未同步消息，恢复发送队列
- 重连失败：指数退避重试

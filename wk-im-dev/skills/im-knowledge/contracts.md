# Cross-Pod API Contracts

All public APIs are defined in `BTIMService/Public/` as Swift protocols.

## Message APIs

| Method | Description |
|--------|-------------|
| `sendMessage(content:to:)` | Send a message to a conversation |
| `revokeMessage(messageId:)` | Revoke a sent message (within time limit) |
| `deleteMessage(messageId:)` | Delete a message locally |
| `markAsRead(conversationId:)` | Mark all messages in conversation as read |

## Session APIs

| Method | Description |
|--------|-------------|
| `getSessions()` | Get all conversation sessions |
| `getMessages(conversationId:offset:limit:)` | Paginated message history |
| `getUnreadCount(conversationId:)` | Unread message count |

## Event Callbacks (BTIMModule implements)

| Callback | Description |
|----------|-------------|
| `onMessageReceived(message:)` | New message arrived |
| `onMessageStatusChanged(messageId:status:)` | Send status update |
| `onSessionUpdated(session:)` | Session metadata changed |
| `onUnreadCountChanged(conversationId:count:)` | Unread count changed |

## Contract Rules

1. Parameters MUST use internal model types (never ThirdPartyIMSDK types)
2. Callbacks MUST be dispatched on main thread
3. Async APIs use Swift async/await or completion handlers (not delegates)
4. Breaking changes require version bump and migration guide

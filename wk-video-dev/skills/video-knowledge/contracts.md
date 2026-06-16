# Cross-Pod API Contracts

Public APIs are exposed through Objective-C headers exported by the VideoEditCore pod, especially `VideoEditCoreTool.h`, `VideoEditCoreProtocol.h`, and router-facing model headers.

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

## Event Callbacks (VideoEditUI implements)

| Callback | Description |
|----------|-------------|
| `onMessageReceived(message:)` | New message arrived |
| `onMessageStatusChanged(messageId:status:)` | Send status update |
| `onSessionUpdated(session:)` | Session metadata changed |
| `onUnreadCountChanged(conversationId:count:)` | Unread count changed |

## Contract Rules

1. Parameters MUST use internal model types (never VideoEngineSDK types)
2. Callbacks MUST be dispatched on main thread
3. Async APIs use completion blocks, notifications, or existing Objective-C delegate-style surfaces
4. Breaking changes require version bump and migration guide

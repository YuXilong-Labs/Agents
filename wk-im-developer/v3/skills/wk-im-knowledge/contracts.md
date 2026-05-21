# Cross-Pod API Contracts

## BTIMService Public API (consumed by BTIMModule)

All public APIs are defined in `BTIMService/Public/` as Swift protocols.

### Message APIs
- `sendMessage(content:to:)` — send a message to a conversation
- `revokeMessage(messageId:)` — revoke a sent message (within time limit)
- `deleteMessage(messageId:)` — delete a message locally
- `markAsRead(conversationId:)` — mark all messages in conversation as read

### Session APIs
- `getSessions()` — get all conversation sessions
- `getMessages(conversationId:offset:limit:)` — paginated message history
- `getUnreadCount(conversationId:)` — unread message count

### Event Callbacks (BTIMModule implements)
- `onMessageReceived(message:)` — new message arrived
- `onMessageStatusChanged(messageId:status:)` — send status update
- `onSessionUpdated(session:)` — session metadata changed
- `onUnreadCountChanged(conversationId:count:)` — unread count changed

## Contract Rules

1. All parameters must use internal model types (never ThirdPartyIMSDK types)
2. Callbacks must be dispatched on main thread
3. Async APIs use Swift async/await or completion handlers (not delegates)
4. Breaking changes require version bump and migration guide

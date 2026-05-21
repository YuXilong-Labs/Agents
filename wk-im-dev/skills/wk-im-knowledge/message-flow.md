# Message Lifecycle

## Send Flow

```
BTIMModule (UI)
  → BTIMService.sendMessage()
    → validate content & session
    → persist to local DB (status: sending)
    → ThirdPartyIMSDK.sendMessage()
      → [network]
      → onSuccess: update DB status → sending_success
      → onFailure: update DB status → sending_failed
    → notify BTIMModule via onMessageStatusChanged()
```

## Receive Flow

```
ThirdPartyIMSDK (push/pull)
  → BTIMService Adapter.onMessageReceived()
    → parse SDK message → internal Message model
    → persist to local DB
    → update session unread count
    → notify BTIMModule via onMessageReceived()
      → BTIMModule updates UI
```

## Message Status State Machine

```
[draft] → sending → sending_success
                  → sending_failed → [retry] → sending
[received] → read
[any] → revoked
```

## Revoke Flow

```
BTIMModule → BTIMService.revokeMessage(messageId)
  → check time limit (default 2 min)
  → ThirdPartyIMSDK.revokeMessage()
  → update local DB: status = revoked
  → notify all sessions via onMessageStatusChanged()
```

## Key Constraints

- Message body is NEVER logged (privacy)
- Status updates always dispatched on main thread
- Local DB is source of truth; SDK is transport only

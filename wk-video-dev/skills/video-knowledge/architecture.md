# BTVideoRecorderKit & BTVideoRecorderUIKit Architecture

## Component Boundaries

```
HostApp
  └── BTVideoRecorderUIKit (UI layer)
        └── BTVideoRecorderKit (Core layer)
              └── VideoEngineSDK (SDK adapter)
```

## BTVideoRecorderKit Layers

| Layer | Responsibility |
|-------|---------------|
| **Adapter** | VideoEngineSDK wrapper, translates SDK events to internal models |
| **Domain** | Message, Session, User models and business logic |
| **Repository** | Local persistence (CoreData/SQLite) |
| **Service** | Public API exposed to BTVideoRecorderUIKit through Objective-C headers such as `BTVideoRecorderKitTool.h` and `BTVideoRecorderKitProtocol.h` |

## BTVideoRecorderUIKit Layers

| Layer | Responsibility |
|-------|---------------|
| **Router** | Navigation between chat pages |
| **ViewModel** | Business logic for UI |
| **View** | UIKit/SwiftUI components (bubbles, input bar, chat list) |
| **Coordinator** | Cross-feature coordination |

## Cross-Pod API

BTVideoRecorderUIKit calls BTVideoRecorderKit through the Objective-C public headers exported by the BTVideoRecorderKit pod.
New cross-pod APIs must update the relevant public header and be documented in `contracts.md`.

# BTIMService & BTIMModule Architecture

## Component Boundaries

```
HostApp
  └── BTIMModule (UI layer)
        └── BTIMService (Core layer)
              └── ThirdPartyIMSDK (SDK adapter)
```

## BTIMService Layers

| Layer | Responsibility |
|-------|---------------|
| **Adapter** | ThirdPartyIMSDK wrapper, translates SDK events to internal models |
| **Domain** | Message, Session, User models and business logic |
| **Repository** | Local persistence (CoreData/SQLite) |
| **Service** | Public API exposed to BTIMModule through Objective-C headers such as `BTIMServiceTool.h` and `BTIMServiceProtocol.h` |

## BTIMModule Layers

| Layer | Responsibility |
|-------|---------------|
| **Router** | Navigation between chat pages |
| **ViewModel** | Business logic for UI |
| **View** | UIKit/SwiftUI components (bubbles, input bar, chat list) |
| **Coordinator** | Cross-feature coordination |

## Cross-Pod API

BTIMModule calls BTIMService through the Objective-C public headers exported by the BTIMService pod.
New cross-pod APIs must update the relevant public header and be documented in `contracts.md`.

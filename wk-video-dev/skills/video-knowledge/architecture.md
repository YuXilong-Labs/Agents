# VideoEditCore & VideoEditUI Architecture

## Component Boundaries

```
HostApp
  └── VideoEditUI (UI layer)
        └── VideoEditCore (Core layer)
              └── VideoEngineSDK (SDK adapter)
```

## VideoEditCore Layers

| Layer | Responsibility |
|-------|---------------|
| **Adapter** | VideoEngineSDK wrapper, translates SDK events to internal models |
| **Domain** | Message, Session, User models and business logic |
| **Repository** | Local persistence (CoreData/SQLite) |
| **Service** | Public API exposed to VideoEditUI through Objective-C headers such as `VideoEditCoreTool.h` and `VideoEditCoreProtocol.h` |

## VideoEditUI Layers

| Layer | Responsibility |
|-------|---------------|
| **Router** | Navigation between chat pages |
| **ViewModel** | Business logic for UI |
| **View** | UIKit/SwiftUI components (bubbles, input bar, chat list) |
| **Coordinator** | Cross-feature coordination |

## Cross-Pod API

VideoEditUI calls VideoEditCore through the Objective-C public headers exported by the VideoEditCore pod.
New cross-pod APIs must update the relevant public header and be documented in `contracts.md`.

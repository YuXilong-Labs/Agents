# BTIMService & BTIMModule Architecture

## Component Boundaries

```
HostApp
  └── BTIMModule (UI layer)
        └── BTIMService (Core layer)
              └── ThirdPartyIMSDK (SDK adapter)
```

## Dependency Rules (HARD CONSTRAINTS)

| Rule | Reason |
|------|--------|
| BTIMModule MAY depend on BTIMService | UI calls core APIs |
| BTIMService MUST NOT depend on BTIMModule | Core must be UI-agnostic |
| BTIMModule MUST NOT import ThirdPartyIMSDK | SDK isolation in BTIMService adapter |
| ThirdPartyIMSDK access ONLY in BTIMService adapter layer | Vendor lock-in protection |

## BTIMService Layers

- **Adapter**: ThirdPartyIMSDK wrapper, translates SDK events to internal models
- **Domain**: Message, Session, User models and business logic
- **Repository**: Local persistence (CoreData/SQLite)
- **Service**: Public API exposed to BTIMModule

## BTIMModule Layers

- **Router**: Navigation between chat pages
- **ViewModel**: Business logic for UI
- **View**: UIKit/SwiftUI components (bubbles, input bar, chat list)
- **Coordinator**: Cross-feature coordination

## Cross-Pod API Contract

BTIMModule calls BTIMService only through the public protocol defined in `BTIMService/Public/`. Any new cross-pod API must be added there and documented in `contracts.md`.

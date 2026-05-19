# BTIMService & BTIMModule 架构概览

> TODO: 基于实际代码填充。运行以下命令让 Agent 生成初始版本：
> `Use wk-im-explorer subagent to explore Components/BTIMService and Components/BTIMModule, then generate the initial content for this file based on the actual code structure.`

## 模块职责

### BTIMService
- 消息发送 / 接收 / 重试
- 会话管理（列表、未读数）
- ThirdPartyIMSDK 适配层（唯一允许 import SDK 的地方）
- 消息状态机
- 本地持久化

### BTIMModule
- 聊天页 UI（ChatViewController）
- 消息气泡（各类型 BubbleView）
- ViewModel 层（ChatViewModel）
- 路由（Router）
- 通过 BTIMService 协议访问数据，不直接依赖 SDK

## 依赖关系

```
BTIMModule → BTIMService → ThirdPartyIMSDK
```

BTIMService 通过 protocol 暴露能力给 BTIMModule，不暴露具体实现类。

## 关键 Protocols（待填充）

- `BTIMServiceProtocol` — 主服务协议
- `BTIMMessageProtocol` — 消息模型协议
- `BTIMConversationProtocol` — 会话模型协议

## 目录结构（待填充）

```
Components/BTIMService/
├── Sources/
│   ├── Adapter/        # ThirdPartyIMSDK 适配层
│   ├── Service/        # 核心服务实现
│   ├── Model/          # 数据模型
│   └── Protocol/       # 对外暴露的 protocols
└── Tests/

Components/BTIMModule/
├── Sources/
│   ├── Chat/           # 聊天页
│   ├── Conversation/   # 会话列表
│   ├── ViewModel/      # ViewModels
│   └── Router/         # 路由
└── Tests/
```

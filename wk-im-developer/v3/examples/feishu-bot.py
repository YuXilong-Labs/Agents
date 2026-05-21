"""
feishu-bot.py — wk-im-developer 飞书 bot 示例

使用 Agent SDK 的 ClaudeSDKClient 接入飞书消息，
加载 wk-im-developer Plugin，保留 Claude Code 原生能力。

依赖:
  pip install claude-agent-sdk lark-oapi

使用:
  PLUGIN_DIR=/path/to/wk-im-developer/v3 python feishu-bot.py
"""

import asyncio
import os
from pathlib import Path

from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, AssistantMessage, TextBlock, ResultMessage

# IM 专业规则（追加到原生 system prompt，不替换）
IM_RULES = """
You are also wk-im-developer, an iOS IM component developer for BTIMService and BTIMModule.

Architecture constraints (always enforce):
- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK
- Only modify BTIMService/ or BTIMModule/ — never Pods/, ThirdPartySDK/
- Never log: messageBody, token, cookie, attachmentURL, user PII
"""

PLUGIN_DIR = os.environ.get("PLUGIN_DIR", str(Path(__file__).parent.parent))
PROJECT_DIR = os.environ.get("PROJECT_DIR", os.getcwd())


def make_options(project_dir: str) -> ClaudeAgentOptions:
    return ClaudeAgentOptions(
        system_prompt={"type": "preset", "preset": "claude_code", "append": IM_RULES},
        plugins=[{"type": "local", "path": PLUGIN_DIR}],
        skills="all",
        cwd=project_dir,
        permission_mode="acceptEdits",
    )


# ── Session 管理 ──────────────────────────────────────────────────────────────

# 每个飞书会话对应一个 ClaudeSDKClient（保持多轮对话上下文）
_sessions: dict[str, ClaudeSDKClient] = {}


async def get_or_create_session(chat_id: str) -> ClaudeSDKClient:
    if chat_id not in _sessions:
        client = ClaudeSDKClient(options=make_options(PROJECT_DIR))
        await client.connect()
        _sessions[chat_id] = client
    return _sessions[chat_id]


async def handle_message(chat_id: str, user_message: str) -> str:
    """处理飞书消息，返回回复文本。"""
    client = await get_or_create_session(chat_id)
    await client.query(user_message)

    reply_parts = []
    async for msg in client.receive_response():
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    reply_parts.append(block.text)
        elif isinstance(msg, ResultMessage) and msg.is_error:
            reply_parts.append(f"[Error: {msg.result}]")

    return "".join(reply_parts) or "(no response)"


# ── 飞书 Webhook 接入（示例骨架）────────────────────────────────────────────

async def feishu_webhook_handler(event: dict) -> dict:
    """
    飞书事件回调处理器。
    实际部署时接入 lark-oapi 的 EventDispatcherHandler。
    """
    msg = event.get("event", {}).get("message", {})
    chat_id = msg.get("chat_id", "default")
    content = msg.get("content", "{}")

    import json
    text = json.loads(content).get("text", "").strip()
    if not text:
        return {"code": 0}

    reply = await handle_message(chat_id, text)

    # 实际发送回飞书（需要 lark-oapi client）
    print(f"[{chat_id}] User: {text}")
    print(f"[{chat_id}] Bot:  {reply}")

    return {"code": 0, "reply": reply}


# ── 本地测试 ──────────────────────────────────────────────────────────────────

async def interactive_test():
    """本地交互测试，模拟飞书多轮对话。"""
    print(f"wk-im-developer bot (plugin: {PLUGIN_DIR})")
    print(f"Working dir: {PROJECT_DIR}")
    print("Type 'exit' to quit, 'new' to start a new session.\n")

    chat_id = "test-session"
    while True:
        try:
            text = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not text:
            continue
        if text == "exit":
            break
        if text == "new":
            if chat_id in _sessions:
                await _sessions[chat_id].disconnect()
                del _sessions[chat_id]
            print("(new session started)")
            continue

        reply = await handle_message(chat_id, text)
        print(f"Bot: {reply}\n")

    for client in _sessions.values():
        await client.disconnect()


if __name__ == "__main__":
    asyncio.run(interactive_test())

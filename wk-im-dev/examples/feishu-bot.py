"""
feishu-bot.py — wk-im-dev 飞书 bot 示例

使用 Agent SDK 的 ClaudeSDKClient 接入飞书消息。
wk-im-dev plugin 提供主 agent 身份、skills、hooks 和约束，
无需在 bot 代码中重复定义。

依赖:
  pip install claude-agent-sdk lark-oapi

使用:
  PLUGIN_DIR=/path/to/wk-im-dev PROJECT_DIR=/path/to/BTIMService python feishu-bot.py
"""

import asyncio
import json
import os
from pathlib import Path

from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, AssistantMessage, TextBlock, ResultMessage

PLUGIN_DIR = os.environ.get("PLUGIN_DIR", str(Path(__file__).parent.parent))
PROJECT_DIR = os.environ.get("PROJECT_DIR", os.getcwd())


def make_options(project_dir: str) -> ClaudeAgentOptions:
    return ClaudeAgentOptions(
        # wk-im-dev plugin provides the main agent identity, skills, and hooks.
        plugins=[{"type": "local", "path": PLUGIN_DIR}],
        skills="all",
        cwd=project_dir,
        permission_mode="acceptEdits",
    )


# ── Session management ────────────────────────────────────────────────────────

# Each Feishu chat_id maps to one ClaudeSDKClient (preserves multi-turn context)
_sessions: dict[str, ClaudeSDKClient] = {}


async def get_or_create_session(chat_id: str) -> ClaudeSDKClient:
    if chat_id not in _sessions:
        client = ClaudeSDKClient(options=make_options(PROJECT_DIR))
        await client.connect()
        _sessions[chat_id] = client
    return _sessions[chat_id]


async def handle_message(chat_id: str, user_message: str) -> str:
    """Process a Feishu message and return reply text."""
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


# ── Feishu webhook handler (skeleton) ────────────────────────────────────────

async def feishu_webhook_handler(event: dict) -> dict:
    """
    Feishu event callback handler.
    In production, wire this into lark-oapi's EventDispatcherHandler.
    """
    msg = event.get("event", {}).get("message", {})
    chat_id = msg.get("chat_id", "default")
    content = msg.get("content", "{}")

    text = json.loads(content).get("text", "").strip()
    if not text:
        return {"code": 0}

    reply = await handle_message(chat_id, text)

    print(f"[{chat_id}] User: {text}")
    print(f"[{chat_id}] Bot:  {reply}")

    return {"code": 0, "reply": reply}


# ── Local interactive test ────────────────────────────────────────────────────

async def interactive_test():
    """Local interactive test simulating Feishu multi-turn conversation."""
    print(f"wk-im-dev bot")
    print(f"  Plugin:  {PLUGIN_DIR}")
    print(f"  Project: {PROJECT_DIR}")
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

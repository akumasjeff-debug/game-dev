#!/usr/bin/env python3
"""
Claude Code Stop hook — appends token usage + last user message
to ~/.claude/token_monitor.json (list, newest first, max 200 entries).
"""
import json
import sys
from pathlib import Path
from datetime import datetime


def _extract_text(content) -> str:
    """Extract plain text from a message content (str or content-block list)."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get('type') == 'text':
                parts.append(block.get('text', ''))
        return ' '.join(parts).strip()
    return ''


def main():
    try:
        raw = sys.stdin.buffer.read().decode('utf-8', errors='replace').strip()
        if not raw:
            return

        data = json.loads(raw)

        # ── Find usage ────────────────────────────────────────────────
        usage = (data.get('usage')
                 or data.get('message', {}).get('usage')
                 or {})

        if not usage and isinstance(data.get('messages'), list):
            for msg in reversed(data['messages']):
                if isinstance(msg, dict) and msg.get('role') == 'assistant':
                    u = msg.get('usage')
                    if u:
                        usage = u
                        break

        if not (usage and ('input_tokens' in usage or 'output_tokens' in usage)):
            return

        # ── Find last user message ────────────────────────────────────
        last_user_msg = ''
        if isinstance(data.get('messages'), list):
            for msg in reversed(data['messages']):
                if isinstance(msg, dict) and msg.get('role') == 'user':
                    last_user_msg = _extract_text(msg.get('content', ''))
                    if last_user_msg:
                        break

        # ── Load & update history ─────────────────────────────────────
        out_file = Path.home() / '.claude' / 'token_monitor.json'
        out_file.parent.mkdir(parents=True, exist_ok=True)

        history = []
        if out_file.exists():
            try:
                stored = json.loads(out_file.read_text())
                history = stored if isinstance(stored, list) else []
            except Exception:
                history = []

        history.insert(0, {
            'input_tokens':  usage.get('input_tokens', 0),
            'output_tokens': usage.get('output_tokens', 0),
            'cache_read':    usage.get('cache_read_input_tokens', 0),
            'timestamp':     datetime.now().strftime('%H:%M:%S'),
            'message':       last_user_msg[:500],  # cap at 500 chars
        })

        out_file.write_text(json.dumps(history[:200], ensure_ascii=False))

    except Exception:
        pass


main()

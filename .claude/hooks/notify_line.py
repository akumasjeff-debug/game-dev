import hashlib
import json
import os
import sys
import urllib.request
import urllib.error
import re

CONFIG_PATH = os.path.join(os.path.dirname(__file__), '..', 'line_config.json')
STATE_PATH = os.path.join(os.path.dirname(__file__), '..', 'line_notify_state.json')
COOLDOWN_SECONDS = 30 * 60
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def load_config():
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_pending_items():
    pending = []
    for entry in os.scandir(ROOT_DIR):
        if not entry.is_dir() or entry.name.startswith('.'):
            continue
        state_path = os.path.join(entry.path, 'STATE.md')
        if not os.path.exists(state_path):
            continue
        try:
            with open(state_path, 'r', encoding='utf-8') as f:
                content = f.read()
            match = re.search(r'## 待確認\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
            if not match:
                continue
            section = match.group(1).strip()
            lines = [l.strip() for l in section.split('\n') if l.strip() and l.strip() != '-']
            if lines:
                pending.append(f"【{entry.name}】\n" + '\n'.join(lines))
        except Exception:
            pass
    return pending


def push_message(token, user_id, message):
    url = 'https://api.line.me/v2/bot/message/push'
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    }
    payload = json.dumps({
        'to': user_id,
        'messages': [{'type': 'text', 'text': message}]
    }).encode('utf-8')
    req = urllib.request.Request(url, data=payload, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status == 200
    except urllib.error.HTTPError as e:
        print(f"LINE API error: {e.code}", file=sys.stderr)
        return False


def content_hash(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()


def load_state():
    try:
        with open(STATE_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {'hash': '', 'last_sent': 0}


def save_state(h, timestamp):
    with open(STATE_PATH, 'w', encoding='utf-8') as f:
        json.dump({'hash': h, 'last_sent': timestamp}, f)


def main():
    import time

    try:
        config = load_config()
    except FileNotFoundError:
        sys.exit(0)

    if len(sys.argv) > 1:
        message = ' '.join(sys.argv[1:])
    else:
        pending = get_pending_items()
        if not pending:
            save_state('', 0)
            sys.exit(0)

        message = "Claude 有待確認事項\n\n" + '\n\n'.join(pending)
        h = content_hash(message)
        state = load_state()
        now = time.time()

        if h == state['hash']:
            sys.exit(0)
        if now - state['last_sent'] < COOLDOWN_SECONDS:
            sys.exit(0)

        save_state(h, now)

    push_message(config['channel_access_token'], config['user_id'], message)


if __name__ == '__main__':
    main()

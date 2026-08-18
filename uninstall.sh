#!/bin/bash
# uninstall.sh — settings.json 에서 fleet-hook 항목만 제거하고 ~/.claude/cockpit 을 지운다(.bashrc 줄은 손수 지우세요).
set -eu
SETTINGS="$HOME/.claude/settings.json"
python3 - "$SETTINGS" <<'EOF'
import json, sys
path = sys.argv[1]
s = json.load(open(path))
for ev, groups in list(s.get("hooks", {}).items()):
    for g in groups:
        g["hooks"] = [h for h in g.get("hooks", []) if "cockpit/hooks/fleet-hook" not in h.get("command", "")]
    s["hooks"][ev] = [g for g in groups if g.get("hooks")]
    if not s["hooks"][ev]:
        del s["hooks"][ev]
json.dump(s, open(path, "w"), ensure_ascii=False, indent=2)
print("settings.json 에서 fleet-hook 제거")
EOF
rm -rf "$HOME/.claude/cockpit"
echo "제거 완료. ~/.bashrc 의 CLAUDE_CODE_DISABLE_TERMINAL_TITLE / cockpit PATH 줄은 직접 지우세요."

#!/bin/bash
# install.sh — 파일을 ~/.claude/cockpit/ 에 복사하고 ~/.claude/settings.json 의 hooks 에 fleet-hook 을 (기존 훅 보존하며) 추가한다.
# 되돌리기: uninstall.sh
set -eu
DEST="$HOME/.claude/cockpit"
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DEST/bin" "$DEST/hooks" "$HOME/.claude/fleet-status"
cp "$SRC"/hooks/fleet-hook "$DEST/hooks/"
cp "$SRC"/bin/hands "$SRC"/bin/fleet-board "$SRC"/bin/win-flash "$DEST/bin/"
chmod +x "$DEST"/hooks/* "$DEST"/bin/*

SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak-cockpit-$(date +%Y%m%d%H%M%S)"
python3 - "$SETTINGS" "$DEST/hooks/fleet-hook" <<'EOF'
import json, sys
path, hook = sys.argv[1], sys.argv[2]
s = json.load(open(path))
hooks = s.setdefault("hooks", {})
for ev in ("SessionStart", "UserPromptSubmit", "Notification", "Stop", "SessionEnd"):
    groups = hooks.setdefault(ev, [])
    if any(h.get("command", "").endswith("fleet-hook " + ev) for g in groups for h in g.get("hooks", [])):
        continue
    entry = {"type": "command", "command": f"{hook} {ev}", "timeout": 10}
    if groups and "matcher" not in groups[0]:
        groups[0].setdefault("hooks", []).append(entry)
    else:
        groups.append({"hooks": [entry]})
json.dump(s, open(path, "w"), ensure_ascii=False, indent=2)
print("settings.json hooks 갱신 완료")
EOF

# 창 제목은 훅이 관리 — Claude 자체 제목 갱신은 끈다(안 끄면 ✋ 마커가 덮여 사라질 수 있음).
RC="$HOME/.bashrc"
if ! grep -q "CLAUDE_CODE_DISABLE_TERMINAL_TITLE" "$RC" 2>/dev/null; then
  printf '\n# claude-code-session-cockpit: 터미널 제목은 fleet-hook 이 ⏳/✋/🏁 마커로 관리\nexport CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1\n' >> "$RC"
  echo "~/.bashrc 에 CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 추가 (zsh 이면 ~/.zshrc 에 같은 줄을 넣으세요)"
fi
# hands / fleet-board 를 PATH 에
if ! grep -q 'claude/cockpit/bin' "$RC" 2>/dev/null; then
  printf 'export PATH="$HOME/.claude/cockpit/bin:$PATH"\n' >> "$RC"
fi
echo "설치 완료. 새 터미널을 열고 claude 를 시작하면 그 세션부터 반영됩니다. 확인: hands --all"

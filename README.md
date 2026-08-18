# Claude Code Session Cockpit

Claude Code 세션을 여러 개(5~15개) 동시에 굴릴 때 생기는 문제 두 가지를 푼다.

1. 누가 내 입력을 기다리는지, 누가 끝나서 닫아도 되는지 모르겠다. 훅이 세션 상태를 창 제목에 붙이고(⏳/✋/🔐/🏁), 대기로 바뀌면 창을 깜빡이며, `hands` 한 줄로 목록을 보여준다.
2. 세션끼리 어떻게 말을 시켜야 사고(이중 발주, 남의 일 끼어들기)가 안 나나. 내장 `SendMessage`/`ListAgents` 위에 얹은 규약 5개를 [docs/cross-session-messaging.md](docs/cross-session-messaging.md)에 정리했다.

세션 열 몇 개를 몇 달 굴리면서 굳은 것만 담았다. Linux/WSL 기준이고, 창 깜빡임만 Windows(WSL) 전용이다.

## 화면에서 이렇게 보인다

```
⏳ 분기 보고서 데이터 정리        ← 작업 중
✋ 인스타 DM 응답 크론 확인       ← 턴이 끝났거나 내 결정/입력을 기다림 (창이 깜빡임)
🔐 배포 스크립트 실행            ← 권한 프롬프트 대기
🏁 배터리 위젯 v1.1 릴리스        ← 세션이 "끝났다, 닫아도 된다"고 스스로 선언
```

```
$ hands
🏁 닫아도 됨 1  ✋ 대기 3  ⏳ 작업중 4   (11:10)
🏁    2분  배터리 위젯 v1.1 릴리스            0805211d  ← 릴리스 노트까지 푸시
--
✋   17분  인스타 DM 응답 크론 확인            81a6846d  ← 너가해줘 ㄱㄱ
✋   13분  PPT 스크립트 작성                  bd51a0ff  ← 2026이 아직 안 끝났으니 감소는 아니지 않나?
✋    0분  한도 위젯 UI 개선                  eb4fd9dd  ← refresh 얼마 안 남은 게 우선순위 맞지?
```

## 설치 (3단계)

```bash
git clone https://github.com/alibabagini-cyber/claude-code-session-cockpit.git
cd claude-code-session-cockpit && ./install.sh
# 새 터미널을 열고 claude 를 시작 — 그 세션부터 반영. 확인: hands --all
```

`install.sh` 는 `~/.claude/cockpit/` 에 파일을 복사하고, `~/.claude/settings.json` 의 `hooks` 에 fleet-hook 5개(SessionStart/UserPromptSubmit/Notification/Stop/SessionEnd)를 기존 훅을 건드리지 않고 덧붙인다(백업 남김). 마지막으로 `~/.bashrc` 에 `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` 과 PATH 한 줄을 넣는다. 되돌리기는 `./uninstall.sh`.

## 구성

| 파일 | 역할 |
|---|---|
| `hooks/fleet-hook` | 훅 수집기. 세션별 상태를 `~/.claude/fleet-status/<session_id>.json` 에 쓰고, 그 세션의 터미널(`/dev/pts/N`)에 제목 마커를 쓴다. Stop 때 마지막 답변 끝에 🏁 가 있으면 CLOSE-OK. 대기 전환 시 `win-flash` 호출. |
| `bin/hands` | 손 든 세션 목록(`--all`, `--json`). |
| `bin/fleet-board` | 2초 갱신 테이블(tmux 하단 스트립용). `--once` 로 1회. |
| `bin/win-flash` | (WSL) 제목 부분일치로 Windows Terminal 창을 FlashWindowEx — 전면화 없음, 클릭하면 멈춤. `--stop`. |
| `docs/cross-session-messaging.md` | 세션 간 소통 규약: 소유자 1명 원칙, 홀드 브로드캐스트, 재개 브리프, 🏁 마커, 규약 공지법, 권한 세탁 금지. |

## 꼭 알아두기

- 제목 주도권. Claude Code 는 스스로 창 제목을 바꾼다(스피너와 요약). 훅이 쓴 ✋ 가 덮이지 않게 `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` 을 켠다. 제목 텍스트는 훅이 `/rename` 이름, Claude 요약 제목(ai-title), 폴더명 순으로 채우니 잃는 건 스피너뿐이다.
- 훅엔 tty 가 없다. 그래서 조상 claude 프로세스의 stdout(`/proc/<pid>/fd/1`, 곧 `/dev/pts/N`)에 OSC 제목 시퀀스를 직접 쓴다. `claude -p` 헤드리스는 pts 가 없어 자동으로 건너뛴다.
- 🏁 는 세션이 판단해서 쓴다. 훅은 감지만 한다. 세션들이 규약을 알도록 CLAUDE.md 나 자동 로드 메모리에 한 줄 넣어라(문구는 docs 3-4).
- Notification 은 idle 60초 후에, Stop 은 턴이 끝나면 바로 온다. 둘 다 ✋ 로 취급하니 체감상 즉시다.
- Windows Terminal 이 아니면 `WIN_FLASH_CLASS=""` (전 창) 또는 그 터미널의 창 클래스명으로 바꾼다. macOS 와 순수 Linux 는 깜빡임만 없고 나머지는 같다.

## 같이 보면 좋은 것
- [claude-code-field-notes](https://github.com/alibabagini-cyber/claude-code-field-notes) — Claude Code 입문 실전 노트
- [agent-memory-ontology-playbook](https://github.com/alibabagini-cyber/agent-memory-ontology-playbook) — 메모리·온톨로지 체계

MIT

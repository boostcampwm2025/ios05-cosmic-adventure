# Draft: dev-111 Review Fixes (Protocols + WS Session Mapping)

## Context
- Repo: `ios05-cosmic-adventure`
- Focus: PR review follow-ups around NetworkKit interface cleanups + backend minor refactor.
- Hard rule: do **NOT** push unless explicitly requested.

## Requirements (confirmed)
- Separate commit for P1 review comment from @jeon-soyeong:
  - "`NetworkSessionManaging`/`WebSocketSessionManaging`에서 `activate(channelId:nickname:characterRawValue:)` 중복 선언은 `ConnectionSessionManaging`에만 있어도 되지 않나?"
  - User decision: **"응 별도 커밋으로"**

## What Changed Locally (already applied)
- Removed redundant `activate(channelId:nickname:characterRawValue:)` requirement lines from:
  - `iOS/Modules/NetworkKit/Sources/Interfaces/NetworkSessionManaging.swift`
  - `iOS/Modules/NetworkKit/Sources/Interfaces/WebSocketSessionManaging.swift`
- Rationale: Both inherit from `ConnectionSessionManaging`, which already declares the method.

## Proposed Commit
- Type: `refactor(network)`
- Suggested subject: `refactor(network): 하위 세션 프로토콜 activate 중복 선언 제거`
- Body (AS-IS / TO-BE / WHY):
  - AS-IS: `activate(channelId:nickname:characterRawValue:)`가 상위/하위 프로토콜에 중복 선언됨
  - TO-BE: `ConnectionSessionManaging`에만 요구사항을 두고 하위 프로토콜은 상속만 사용
  - WHY: 중복 제거로 유지보수 비용/변경 누락 리스크 감소

## Notes / Risks
- This should be behavior-preserving (interface cleanup only). Compile should still pass because requirement remains in `ConnectionSessionManaging`.

## Other Review Follow-ups (not part of the P1 commit)
- Backend P2 comment (@yungu0010): `getSessionsInChannel` 이미 호출한 값을 재사용하도록 리팩터링.
  - File: `backend/Sources/App/Game/GameMessageHandler.swift`
- WebSocket sessionId/playerId mapping helper signature changes:
  - `sessionId(forPlayerId:)` currently returns `String` with fallback; call sites should not use `guard let`.
  - File: `iOS/Modules/NetworkKit/Sources/WebSocket/WebSocketSessionManager.swift`

## Open Questions
- Should the `sessionId(forPlayerId:)` helper be `String` (fallback) or `String?` (drop send when mapping missing)?

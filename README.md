
## 화면

| 탭 | 내용 |
|---|---|
| 홈 | 다음 경기 카운트다운, 순위 요약, 최근 경기, 공격 포인트 TOP |
| 일정 | 월별 일정, 예정/결과 필터 |
| 경기 상세 | 통계 비교, 포메이션 라인업, 주요 장면 |
| 스쿼드 | 선수 표(정렬 가능) → 선수 상세(개요·기록·정보) |
| 리그 | 순위표, 20개 구단 목록 → 구단 정보·선수 목록 → 선수 상세 |
| 뉴스 | 한글 번역 기사 목록, 원문 전환 |

## 디자인

에버턴 브랜드 스타일: 로열 블루(#003399) 내비게이션 바·히어로, 밝은 바탕에 그림자만 있는 흰 카드, 파랑은 포인트로만 사용. 색·카드 규격은 `EvDesign/Theme.swift`·`Components.swift` 에 모여 있고, 대시보드의 iOS 메뉴 목업(`public/css/ios.css`)과 같은 토큰을 씁니다.

## 구조

```
App/                         앱 진입점
Packages/EvertonKit/
  EvCore        모델, 서비스 프로토콜, 포맷, 샘플 데이터
  EvNetworking  ESPN(기본)·API-Football(선택) 클라이언트, RSS, 디스크 캐시
  EvDesign      테마, 공용 컴포넌트, 레이더 차트
  EvFeatures    화면과 상태 관리
Config/         API 키 설정 예시
```

## 실행

1. Xcode 에서 **iOS App** 프로젝트 생성 (Interface: SwiftUI, 이름 `Everton`, 최소 iOS 18).
2. 기본 `ContentView` 와 `@main` 파일을 지우고 `App/EvertonApp.swift` 를 추가.
3. **File > Add Package Dependencies > Add Local…** 에서 `Packages/EvertonKit` 을 추가하고 앱 타깃에 `EvFeatures` 연결.
4. API 키 설정 (선택)
   - `Config/Secrets.example.xcconfig` 를 `Config/Secrets.xcconfig` 로 복사하고 키 입력
   - 프로젝트 Info > Configurations 에서 Debug/Release 에 이 파일 지정
   - 앱 타깃 Info 에 `API_FOOTBALL_KEY` = `$(API_FOOTBALL_KEY)` 추가
5. 서명 팀을 선택하고 기기에서 실행.

## 데이터 출처

- **기본: ESPN 공개 API** (키 불필요) — 2026-27 일정·스쿼드·순위·경기 요약(통계·라인업·주요 장면).
- **선택: API-Football** — 키를 넣으면 자동 전환(사진·평점 포함).
- ESPN 은 선수 평점·사진·패스/태클 지표·창단연도·수용 인원을 주지 않습니다. 이 값들은 임의로 채우지 않고,
  지표(강점·레이더)는 골·도움·슈팅·카드·선방 같은 실제 기록을 출전당으로 환산해 계산합니다.
- 비공식 API 이므로 응답을 디스크에 캐시하고, 네트워크 실패 시 오래된 캐시를 보여 줍니다.

테스트: `cd Packages/EvertonKit && swift test`

# ios_everton

Everton FC 팬을 위한 개인용 iOS 앱. 경기 일정, 경기 통계, 선수 스탯·평점, 번역된 기사를 한곳에서 봅니다.

- 최소 iOS 18, SwiftUI
- 데이터: [API-Football](https://www.api-football.com/) (경기·선수), RSS (기사)
- 기사 한글 번역: 기기 내 Translation (최초 1회 언어팩 다운로드)
- API 키가 없으면 샘플 데이터로 실행

## 화면

| 탭 | 내용 |
|---|---|
| 홈 | 다음 경기 카운트다운, 최근 5경기 폼, 지난 경기, 시즌 평점 TOP |
| 일정 | 월별 일정, 예정/결과 필터 |
| 경기 상세 | 통계 비교, 피치 라인업, 경기 평점 |
| 스쿼드 | 포지션별 선수 카드 → 선수 상세(레이더, 시즌 기록) |
| 뉴스 | 한글 번역 기사 목록, 원문 전환 |

## 구조

```
App/                         앱 진입점
Packages/EvertonKit/
  EvCore        모델, 서비스 프로토콜, 포맷, 샘플 데이터
  EvNetworking  API-Football 클라이언트, RSS, 디스크 캐시
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

테스트: `cd Packages/EvertonKit && swift test`

## 참고

- 무료 플랜은 하루 100회 호출 제한이 있어 응답을 디스크에 캐시합니다.
- 시즌은 `EvCore/Models.swift` 의 `EvertonInfo.season` 에서 바꿉니다.
- 기사 피드는 `RSSNewsService.defaultFeeds` 에서 바꿉니다.

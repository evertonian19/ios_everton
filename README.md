
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

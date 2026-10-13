# Architecture + Observation + 에러 처리

> 프로젝트 규약은 [AGENTS.md](../../AGENTS.md)를 따른다.
> 아래 구현 현황은 2026-10-13 코드 기준이다.

- 작성자: 제옹(euijjang97)

## 계층과 현재 진입점

Feature 기반 모듈 구조와 Clean Architecture를 사용한다. 의존 방향은
Presentation → Domain ← Data다. Domain의 UseCase·Repository Protocol을 앱에서 실제
구현체와 연결하며, Domain이 Data 구현을 import하지 않는다.

```text
View ↔ @Observable ViewModel → UseCase → Repository Protocol
                                          ↑ Data 구현체
                          AppDependencies / DIContainer가 연결
```

현재 `UMCDeskApp`은 `AppDependencies`를 한 번 만들고 각 창에 `AuthView`를 표시한다.
`AppDependencies`는 `DIContainer`, `UserSessionManager`, `KeychainTokenStore`,
`NetworkClient`, `MoyaNetworkAdapter`를 구성한다. Auth의 ViewModel은 아직 이 의존성을
받지 않으며 화면 상태와 폼 검증을 담당한다. Auth Domain·Data와 다른 6개 Feature는
기반 타겟 단계다. 기존 코드 주석에 등장하는 `SyncProfileStorageUseCase`는 이 저장소에 없다.

### 파일 배치

Tuist가 읽는 소스는 각 계층의 `Sources/**`다. 새 파일도 이 경로 아래에 둔다.

```text
Features/{Feature}/
├── Project.swift
├── Presentation/Sources/{Views,Components,...}
├── Domain/Sources/{Models,UseCases,Interfaces,...}
└── Data/Sources/{Repositories,DataSources,DTO,Router,...}
```

View는 렌더링과 사용자 입력, ViewModel은 화면 상태, UseCase는 업무 규칙,
Repository는 데이터 접근을 맡는다. Feature 전용 구현을 Core에 올리지 않는다.
모듈에서 소비할 Domain 타입은 타입·프로퍼티·이니셜라이저를 공개한다.

## 의존성 수명

`DIContainer`는 `@MainActor @Observable` 타입이다. 내부 사전은 `@ObservationIgnored`로
관찰 대상에서 제외한다.

| API | 동작 |
|-----|------|
| `register(_:factory:)` | 첫 resolve 때 생성하고 캐시, 같은 타입의 이전 등록 제거 |
| `registerInstance(_:instance:)` | 앱 수명의 공유 인스턴스 등록 |
| `resolve(_:)` | 공유 인스턴스 → 캐시 → factory 순서, 미등록이면 precondition 실패 |
| `resetCache()` | factory로 만든 캐시만 비움, 공유 인스턴스와 factory는 유지 |

`AppDependencies`는 공통 transport와 세션을 `registerInstance`로 등록한다.
세션 종료 콜백은 `UserSessionManager.reset()`과 `DIContainer.resetCache()`를 호출한다.
공유 인스턴스까지 새로 만드는 동작으로 설명하거나 사용하지 않는다.

`APIConfig.baseURL()`로 앱 설정을 읽으며 누락·잘못된 값은 composition root에서 실패한다.
테스트·Preview에는 의존성을 주입해 실제 토큰 저장소나 네트워크를 임의로 공유하지 않는다.

## Observation과 화면 상태

새 화면 상태는 `@Observable`을 사용한다. View가 모델을 소유할 때는 `@State private var`,
하위 View에서 모델 프로퍼티의 Binding이 필요할 때는 `@Bindable`을 사용한다.
`@StateObject`·`@ObservedObject`·`@Published`는 쓰지 않는다.
앱 생명주기 전역 관리자 `AppFlowViewModel`의 규약상 예외는 유지하지만 현재 구현된 타입은 아니다.

실제 Auth는 `@MainActor @Observable AuthViewModel`과 `AuthFormState`를 사용한다.
`AuthView`가 ViewModel을 `@State`로 소유하고 화면 enum·`navigationID`를 바꾸어 내용을 전환한다.
`AuthFormState`는 이메일·인증 상태·학교·비밀번호·약관 동의를 검증한다.
로그인·가입 제출은 현재 화면 상태만 바꾸며 실제 인증 완료를 의미하지 않는다.

인증 디자인·타이포·오류 시나리오와 자동 흐름은 `#if DEBUG || UMC_PRERELEASE`에서 제공한다.
일반 Mock은 `#if DEBUG` 원칙을 지킨다. 프리배포 플래그는 프로젝트 생성 시 설정한다.

### 라우팅 원칙과 구현 범위

모듈 간 전환·딥링크는 AppRouter, 내부 전환은 Feature Router가 맡고 Tab마다 독립적인
NavigationStack을 두는 것이 설계 원칙이다. 현재 `CoreRouting/Sources/Routing.swift`는
import만 있는 기반 파일이며 AppRouter·Feature Router·Tab 화면은 아직 없다.
Auth의 상태 전환을 전역 Router 구현 완료로 취급하지 않는다.

## 에러 처리

`UMCFoundation`에 구현된 인라인 상태는 다음과 같다. Value의 Equatable 제약은 없다.

```swift
public enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(any Error)
}
```

`NetworkError`, `RepositoryError`와 오류 심각도 `ErrorSeverity`는
`Core/Foundation/Sources/NetworkErrors.swift`에 있다. `NetworkClient`와
`MoyaNetworkAdapter`는 Aquila 오류를 앱 오류로 매핑한다. 토큰 갱신·세션 종료는
[네트워크 가이드](network-router.md)를 참고한다.

화면 안에서 재시도할 수 있는 로딩·검증·도메인 실패는 Loadable로 표현한다.
세션 만료·권한·네트워크 오류로 흐름을 중단해야 할 때 전역 Alert를 제공하는 ErrorHandler,
삭제·초기화 확인에 쓰는 AlertPrompt가 설계 원칙이다. 다만 `ErrorHandler`, `ErrorContext`,
`AlertPrompt`, `.alertPrompt(item:)`는 아직 구현되지 않았다. 현재 Auth의 오류·확인 화면은
`AuthScreen`으로 표현한다. 공통 타입이 필요하면 별도 구현·주입·표시 경로를 함께 마련한다.

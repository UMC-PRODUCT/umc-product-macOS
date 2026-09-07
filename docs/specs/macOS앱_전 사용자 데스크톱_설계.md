# UMC macOS 앱 설계

작성일: 2026-09-06
작성자: 제옹(euijjang97)

## 1. 무엇을 만드나

UMC 구성원 전체가 쓰는 데스크톱 앱입니다. 운영진 전용 도구가 아닙니다.

챌린저는 공지를 읽고 스레드에서 대화하고 프로젝트에 지원합니다. 운영진은 거기에 더해
공지를 쓰고 읽음 현황을 보고 지원서를 심사합니다. 같은 앱에서 역할에 따라 보이는 게 달라지는 구조로,
iOS 앱이 이미 이렇게 동작합니다.

데스크톱을 따로 만드는 이유는 폰에서 하기 나쁜 일들이 있기 때문입니다. 공지를 길게 쓰고,
읽음 통계를 표로 훑고, 지원서 수십 장을 넘겨 가며 심사하는 일은 운영진 쪽에 몰려 있습니다.
챌린저 쪽에도 있습니다. 노트북으로 과제하다가 스레드를 확인하려고 폰을 집어드는 일이 없어집니다.

필수 기능은 셋입니다.

- **공지** — iOS 앱의 Notice 피처와 같은 도메인
- **스레드** — iOS 앱의 Community 피처와 같은 도메인
- **프로젝트 매칭** — 웹 v2 레포에 있는 기능. iOS 앱에는 없습니다

## 2. 역할과 권한

권한 축이 셋입니다. 공지는 조직 역할을 타고, 스레드는 방 단위 관계를 타고,
매칭은 파트와 프로젝트 단위 관계를 같이 봅니다.

**조직 역할 — `ManagementTeam`.** 서버 `roleType`과 1:1로 대응하는 11단계 enum입니다.
superAdmin(110)부터 challenger(0)까지 레벨이 매겨져 있고 권한 판정은 레벨 비교로 합니다.

```swift
public var canAccessAdminMode: Bool { level >= Self.schoolEtcAdmin.level }
public var canAccessStaffNotice: Bool { level >= Self.schoolPartLeader.level }
```

`UserSessionManager`는 현재 역할과 보유 역할 목록, 운영진 모드 활성화 여부를 들고 있는
`@Observable` 객체입니다. 운영진 권한이 있는 사람도 평소에는 챌린저 화면을 보다가
모드를 켜면 운영 기능이 나타납니다. macOS에서도 같은 방식으로 가되, 토글은 툴바에 둡니다.

**파트 — 기수마다 다릅니다.** 서버 `SubjectAttributes`는 회원 하나에 `GisuChallengerInfo`
리스트를 물고 있고 `part`는 그 안에 들어 있습니다. 9기에 디자인이었다가 10기에 기획일 수 있다는
뜻이라 파트를 전역 스칼라로 잡으면 안 됩니다. 값은 `ChallengerPart` 8종
(`PLAN`·`DESIGN`·`WEB`·`ANDROID`·`IOS`·`NODEJS`·`SPRINGBOOT`·`ADMIN`)입니다.

파트가 여는 문은 둘뿐입니다. Plan 파트는 본인이 PO인 프로젝트를 만들 수 있고, 나머지 파트는
지원 폼이 허용한 파트에 들어 있으면 지원할 수 있습니다. 나머지 매칭 운영 기능은 파트가 아니라
다른 축이 정합니다.

**프로젝트 단위 관계.** 지원서 합불은 그 프로젝트의 `Project PO`만 결정합니다. 서버 권한 정책
문서에 "운영진이 별도로 합불을 결정할 수 없습니다"라고 못이 박혀 있습니다. Sub-PO는 제출된
지원서 조회까지고 지원자는 본인 지원서만 봅니다. 반대로 매칭 차수 개설·수정·삭제와 자동 선발
실행은 지부장 또는 중앙운영사무국 총괄단 이상이라 여기서는 `ManagementTeam` 레벨을 봅니다.

즉 매칭 화면을 파트 하나로 분기할 수 없습니다. 서버도 이걸 예상하고 화면 분기 전용 API를
따로 열어 뒀습니다. 컨트롤러 설명에 "프로젝트 화면 분기용 capability를 조회합니다"라고
적혀 있습니다.

```
GET /api/v1/projects/permissions?ids=1,2,3
```

프로젝트 id를 최대 100개까지 넘기면 프로젝트마다 capability 묶음이 돌아옵니다.
`canEditInfo`·`canDelete`, `applicationForm`의 `canCreate`/`canPublish`,
`application`의 `canDecide`, `member`·`statistics`가 전부 boolean입니다. 권한이 없어도
에러가 아니라 false가 옵니다. 목록을 띄울 때 한 번 받아 두고 버튼 노출은 이 응답만 보고 정합니다.
클라이언트에서 권한 규칙을 다시 구현하지 않습니다.

방 단위 권한도 같은 원칙입니다. 스레드 방장은 `ManagementTeam`과 무관하게 방 안에서만
초대·강퇴·역할 변경 권한을 갖습니다. 리소스별 권한은 서버에 물어봅니다.
(`GET /api/v1/authorization/resource-permission`)

## 3. 화면 구조

`NavigationSplitView` 3컬럼입니다.

```
┌─────────┬──────────────┬────────────────────┐
│ 사이드바 │   목록        │       상세          │
│         │              │                    │
│ 공지     │ 공지 목록     │ 공지 본문 / 읽음 통계 │
│ 스레드   │ 스레드 목록    │ 스레드 방           │
│ 매칭     │ 매칭 목록      │ 지원서 / 지원 폼     │
└─────────┴──────────────┴────────────────────┘
```

사이드바 항목은 역할과 무관하게 셋으로 고정합니다. 달라지는 건 각 항목 안쪽입니다.
챌린저에게는 공지 목록에 작성 버튼이 없습니다. 운영진 모드를 켜면 작성 버튼과 읽음 통계 탭이 붙습니다.
매칭 상세는 모드와 상관없이 서버가 준 capability로 갈립니다. `application.canDecide`가 참이면
심사 화면, 아니면 지원 폼입니다.

사이드바를 역할에 따라 늘렸다 줄였다 하지 않는 이유는, 운영진 모드를 껐다 켤 때마다
사이드바가 흔들리면 어디에 있었는지 잃어버리기 때문입니다.

스레드 방은 목록에서 더블클릭하면 별도 창으로 뜹니다. 스레드를 보면서 다른 일을 하는 상황이
흔한데 3컬럼 하나로는 그게 안 됩니다. 창을 떼면 됩니다.

읽음 통계와 지원서 목록은 `Table`을 씁니다. 정렬과 다중 선택이 공짜로 따라옵니다.
메뉴바에는 새 공지(⌘N), 새로고침(⌘R), 검색(⌘F)을 겁니다. 새 공지는 권한이 없으면 비활성입니다.

## 4. 기능 범위

| 도메인 | 챌린저 기본 | 추가로 열리는 것 | 무엇으로 판정하나 |
|---|---|---|---|
| 공지 | 목록·상세 열람, 읽음 처리 | 작성, 대상 지정, 읽음 통계 | `ManagementTeam` + 운영진 모드 |
| 스레드 | 참여, 대화, 나가기, 신고 | 초대, 강퇴, 역할 변경 | 방장 여부 (서버 리소스 권한) |
| 매칭 | 차수 확인, 지원, 결과 확인 | 프로젝트 생성(Plan 파트), 폼 관리·심사·팀 확정(PO), 차수 개설(지부장 이상) | 파트 + 프로젝트 capability + `ManagementTeam` |

1차에서 빼는 것은 이렇습니다.

- **리크루팅 도메인** — 웹에 코드는 있지만 배포되지 않았습니다. 서버 상태가 확정되면 봅니다
- **FoundationModels 기반 기능** — 공지 AI 초안, 스레드 자동 분류. 없어도 앱이 돌아갑니다

매칭 공고 등록은 4단계에 넣습니다. 공고를 올리는 사람과 지원서를 심사하는 사람이 같은 PO라
심사만 넣으면 그 사람이 맥과 웹을 오가게 됩니다. 차수 개설도 같이 넣되 순위는 뒤입니다.
쓰는 사람이 지부장 이상으로 좁고 한 기수에 몇 번 없는 작업입니다. 대가는 폼 길이입니다.
필드가 많고 검증 규칙이 붙어서 4단계가 눈에 띄게 무거워지는데, 이건 감수합니다.

## 5. 공유 패키지 — UMCNetworkKit

iOS 레포와 겹치는 네트워크 배관을 처음부터 별도 레포의 SPM 패키지로 뺍니다.
복사본으로 시작했다가 나중에 추출하는 방법도 있지만 두 앱이 동시에 자라는 동안
복사본이 서로 갈라지는 쪽이 더 비쌉니다. 0단계에서 한 번 아프고 끝내는 편을 택했습니다.

SPM 원격 의존성은 **레포 루트의 `Package.swift`만** 인식합니다. iOS 레포 안에 `Packages/` 폴더를
만들어 참조하는 방식은 동작하지 않습니다. 그래서 별도 레포가 사실상 강제입니다.

### 패키지 구성

레포 이름은 아직 정하지 않았습니다. 아래에서는 `umc-product-swift-core`로 적어 두었습니다.

```
umc-product-swift-core/
├── Package.swift              ← 루트. 여기만 원격에서 보인다
└── Sources/UMCNetworkKit/
    ├── Base/       APIResponse, BaseTargetType, NetworkEnvironment
    ├── Client/     NetworkClient, MoyaNetworkAdapter, DefaultAuthenticationPolicy,
    │               TokenPair, TokenStoreProtocol, TokenRefreshServiceImpl
    ├── Realtime/   StompFrame, StompConnection
    ├── Identity/   ManagementTeam
    └── Error/      NetworkError, RepositoryError, ErrorSeverity
```

`platforms: [.iOS(.v26), .macOS(.v26)]`, 외부 의존성은 Moya 하나입니다.

`ManagementTeam`을 넣은 건 두 앱이 같은 권한 판정을 해야 하기 때문입니다. 서버 `roleType`
문자열과 레벨 표가 어긋나면 한쪽 앱에서만 버튼이 보이는 사고가 납니다. 이 파일은 189줄에
`import Foundation`뿐이라 그대로 옮겨집니다.

### 안 넣는 것

`Core/Network` 아래에 있어도 패키지로 가지 않는 폴더가 있습니다.

- `Auth/` — 소셜 로그인 매니저. 12개월 커밋 6건으로 이 폴더가 가장 자주 바뀝니다
- `Member/`, `Authorization/` — `CoreDomain`에 의존합니다. 도메인을 끌고 오면 패키지가 아니라 앱이 됩니다
- `Storage/`, `DI/AuthSystemFactory` — 앱마다 다르게 씁니다

`UserSessionManager`도 패키지에 넣지 않습니다. `@Observable`이라 화면 계층과 붙어 있고
운영진 모드 토글의 의미가 두 앱에서 같으리라는 보장이 없습니다. macOS에서는 새로 만들되
`ManagementTeam` 판정 로직은 패키지 것을 씁니다.

DTO와 도메인 모델, 화면 코드도 전부 각 앱에서 따로 갑니다.

### 끊어야 할 연결 세 군데

공유 대상 파일 중 다섯 개가 `UMCFoundation`을 import합니다. 실제로 쓰는 심볼은 넷뿐이고
전부 끊어낼 수 있습니다.

| 지금 | 왜 문제인가 | 바꿀 것 |
|---|---|---|
| `NetworkConfig` → `Config.API.baseURL` | `Config`가 `Bundle.main.infoDictionary`를 읽고, 없으면 `fatalError`. 패키지가 앱 번들 구조를 알면 안 됩니다 | `NetworkEnvironment(baseURL:defaultHeaders:)`를 앱 시작 시 한 번 주입 |
| `NetworkClient.swift:81` → `AppStorageKey.clearSessionScopedValues()` | 패키지가 앱의 UserDefaults 키를 압니다 | `SessionResetting` 프로토콜을 주입받아 호출 |
| `NetworkError`·`RepositoryError`가 `UMCFoundation`에 있음 | 패키지가 `UMCFoundation`을 import하면 Alert·AppFlow·Location까지 딸려옵니다 | 에러 타입 셋을 패키지로 이동 |

세 번째가 제일 큽니다. iOS 레포에서 이 타입들을 이름으로 쓰는 파일이 `Core/Network` 바깥에 64개,
`ManagementTeam`을 쓰는 파일이 33개입니다. 백 개 가까운 파일에 import를 넣는 대신
`UMCFoundation`에 typealias 세 줄을 남깁니다.

```swift
public typealias NetworkError = UMCNetworkKit.NetworkError
public typealias RepositoryError = UMCNetworkKit.RepositoryError
public typealias ManagementTeam = UMCNetworkKit.ManagementTeam
```

`AppError`가 앞의 둘을 case로 감싸고 있으니 `UMCFoundation`이 패키지를 import하게 됩니다.
의존 방향이 뒤집히는 셈인데, 연결을 끊고 나면 패키지 쪽은 `UMCFoundation`을 더 이상 import하지 않으므로
순환은 생기지 않습니다. 대신 `UMCFoundation`이 더는 의존 그래프의 바닥이 아니게 됩니다.

### 버전과 인증

- 태그 `v0.x.y`를 발행하고 `exact:`로 핀을 겁니다
- `branch: "develop"` 핀은 금지합니다. 어제 되던 빌드가 오늘 깨집니다
- 개발 중에는 Xcode에 로컬 패키지를 끌어다 원격 참조를 덮어써도 됩니다. 다만 PR 전에 되돌려야 하고
  `Package.resolved`가 로컬 경로를 가리키면 CI가 막습니다
- 프라이빗 레포이므로 사람은 SSH 키, CI는 deploy key를 등록합니다

### 0단계 작업 순서

0단계는 macOS 화면을 한 장도 만들지 않습니다. iOS 앱이 멀쩡한 채로 패키지를 물게 만드는 것까지가 끝입니다.

1. 패키지 레포 생성. `Base`/`Client`/`Realtime`, `ManagementTeam`, 에러 타입 셋을 옮기고
   위의 연결 셋을 끊습니다. 테스트도 함께 옮깁니다 — `APIResponseTests`, `NetworkClientTests`,
   `TokenPairTests`, `DefaultAuthenticationPolicyTests`, `StompFrameTests`, `StompConnectionTests`,
   `Tests/Support/`. `swift test`가 macOS에서 통과하는지 여기서 확인합니다
2. `v0.1.0` 태그 발행
3. iOS 레포: 옮긴 파일을 지우고 `Tuist/Package.swift`에 패키지를 추가합니다.
   `Core/Network/Project.swift`의 의존성에 `.external(name: "UMCNetworkKit")`를 넣고,
   `UMCFoundation`에 typealias 세 줄, 앱 부트스트랩에 `NetworkEnvironment`와 `SessionResetting` 주입을 붙입니다
4. iOS 전체 빌드와 테스트가 통과한 뒤에 머지합니다
5. macOS 레포에서 같은 패키지를 참조합니다

3번이 iOS 레포를 건드리는 PR이라 리뷰가 붙습니다. macOS 작업을 시작하기 전에 이게 머지되어 있어야 합니다.

## 6. 앱 아키텍처

템플릿의 Clean Architecture를 그대로 씁니다.

```
View ←→ ViewModel(@Observable) → UseCase(Protocol) → Repository → DataSource
                                     ↑ DIContainer 주입
```

모듈 구성은 이렇습니다.

```
UMCDesk (app, .macOS)
Core/       Foundation · DesignSystem · UIComponents · DI
Features/   Auth · Notice · Community · Matching
```

로그인은 iOS와 같은 경로입니다. 카카오 SDK가 macOS를 지원하는 게 확인됐으니 우회 로그인을 만들 일은
없습니다. 다만 `Auth/`는 패키지에 넣지 않으므로 SDK 의존성은 macOS 레포의 `Tuist/Package.swift`에
따로 추가하고 로그인 매니저도 따로 만듭니다.

`Matching`은 iOS에 없는 신규 피처입니다. 웹 v2와 같은 서버라 토큰도 그대로 씁니다.
`BaseTargetType`은 `baseURL`을 호스트 루트로만 두고 Router가 전체 path를 들고 있습니다.
프로젝트 API는 전부 `/api/v1/projects` 아래라 iOS Router와 prefix가 같습니다. 매칭 차수만
`/api/v1/project/matching-rounds`로 단수형이라 여기서 오타를 내기 쉽습니다.

권한 게이팅은 화면마다 흩어 두지 않습니다. `UserSessionManager` 상당물을 `Core/Foundation`에 두고
ViewModel이 그걸 관찰해 버튼 노출 여부를 결정합니다. 기수별 파트 목록도 여기서 같이 들고
있습니다. 다만 매칭 화면의 버튼은 세션이 아니라 `projects/permissions` 응답을 봅니다.
세션은 지원 자격까지, 그 뒤부터는 서버 capability입니다.

### 템플릿에서 고쳐야 할 것

`Project+Core.swift`의 `coreProject`는 `destinations` 파라미터가 이미 열려 있어 그대로 쓸 수 있습니다.
문제는 `Project+Feature.swift`입니다. Domain 레이어만 `domainDestinations`로 열려 있고
Data와 Presentation은 `.iOS`가 박혀 있습니다(62·76·108·122행). 세 레이어 모두 파라미터로 열어야 합니다.

Presentation은 두 앱이 공유하지 않습니다. macOS 공지 목록은 `Table` 정렬 키가 붙는데 iOS는 그럴 일이 없고
스레드 방은 아예 별도 창입니다. 배관은 같아도 배관에 실려 오는 물건은 다르게 생겼습니다.

## 7. 데이터 흐름과 실시간

STOMP 커넥션은 앱 생애에 하나입니다. 창이 몇 개든 하나입니다. actor로 격리하고
각 화면은 `threadId`로 필터링해서 자기 이벤트만 받습니다. iOS의
`CommunityThreadRealtimeClient`가 이미 이 구조입니다.

맥에서 새로 생기는 문제는 잠자기입니다. 노트북 덮개를 닫으면 커넥션이 끊기고, 열면 재연결됩니다.
STOMP는 끊긴 동안 놓친 이벤트를 다시 주지 않으므로 재연결 직후 REST로 메시지를 한 번 채워 넣어야 합니다.
iOS에서도 같은 처리를 하지만 맥은 이 상황이 훨씬 자주 옵니다.

매칭 심사의 합격·불합격 판정은 낙관적 업데이트를 하지 않습니다. 화면에 먼저 반영했다가
서버가 거절하면 되돌려야 하는데, 심사 결과는 되돌리는 사이에 심사자가 다음 지원자로 넘어가 버립니다.
서버 응답을 확인하고 반영합니다.

역할이 바뀌는 경우도 있습니다. 임기가 끝나 권한이 빠지거나 새로 붙는 상황인데,
앱을 켜 둔 채로 바뀌면 화면과 실제 권한이 어긋납니다. 서버가 403을 주면
`UserSessionManager`를 다시 동기화하고 화면을 갱신합니다.

## 8. 에러 처리

세 갈래를 그대로 씁니다.

- **Loadable** — 화면 안 인라인 상태. 목록 로딩, 검증 실패
- **ErrorHandler** — 흐름을 끊는 전역 Alert. 세션 만료, 권한 없음
- **AlertPrompt** — 확인·취소 다이얼로그. 지원서 반려처럼 되돌리기 어려운 작업

맥에서 정해야 할 건 하나입니다. 창이 여러 개일 때 전역 Alert이 어디에 뜨는가.
활성 창 기준으로 띄웁니다. 백그라운드 창에서 발생한 오류라도 사용자가 보고 있는 창에 뜨는 편이 낫습니다.

## 9. 테스트

패키지 테스트는 iOS와 macOS 양쪽에서 돌아야 합니다. 패키지 레포 CI에서 `swift test`로 macOS를 확인하고
iOS는 앱 레포의 Tuist 테스트가 커버합니다. 옮긴 테스트 중 `KeychainTokenStoreTests`는
entitlements가 필요해서 그대로는 안 돌아갑니다 — 이건 앱 레포에 남깁니다.

앱 테스트는 UseCase와 Repository 위주입니다. 권한 분기는 테스트를 붙입니다.
역할별로 어떤 기능이 보여야 하는지가 이 앱에서 제일 틀리기 쉬운 부분입니다.
축이 둘이라 더 그렇습니다. 레벨은 challenger인데 파트가 Plan인 계정이 대표적인 함정입니다.

## 10. 배포

App Store에 올리지 않고 공증 DMG로 나갑니다. 샌드박스가 강제되지 않는 대신
Developer ID 서명과 `notarytool` 공증이 필요하고, CI에서 서명하려면 인증서와 앱 암호를
시크릿으로 등록해야 합니다. 5단계에서 이 파이프라인을 만듭니다.

자동 업데이트 프레임워크는 넣지 않습니다. 앱을 켤 때 최신 버전을 확인해 알림만 띄우고
다운로드는 링크로 넘깁니다. Sparkle은 배포가 잦아져서 손이 아파질 때 붙이면 됩니다.

## 11. 로드맵

| 단계 | 내용 | 끝났다고 볼 기준 |
|---|---|---|
| 0 | SPM 패키지 추출 + iOS 마이그레이션 | iOS 앱이 패키지를 물고 전체 테스트 통과 |
| 1 | 템플릿 셋업, 로그인, 역할·파트 동기화, 공지 열람 | 챌린저 계정으로 로그인해 공지를 읽는다 |
| 2 | 스레드 목록·방·별도 창 | 스레드 방을 떼어 놓고 대화한다 |
| 3 | 운영진 모드, 공지 작성·대상 지정·읽음 통계 | 맥에서 쓴 공지가 iOS 앱에 뜬다 |
| 4 | 매칭 공고 등록·차수 개설·지원·심사·팀 확정 | PO가 맥에서 공고를 올리고, 챌린저가 지원해 팀이 확정된다 |
| 5 | 메뉴바·단축키·창 상태 복원·서명·공증 | 공증 DMG로 설치된다 |

챌린저 기능을 앞에 뒀습니다. 1·2단계만 끝나도 챌린저에게는 쓸 만한 앱이 되고
운영 기능은 그 위에 얹힙니다. 반대로 하면 3단계까지 가야 아무도 쓸 수 있는 게 없습니다.

## 12. 확인이 필요한 것

- **패키지 레포 이름.** 정해지면 문서와 0단계 1번의 `umc-product-swift-core`를 바꿉니다
- **`projects/permissions`의 실제 응답.** capability 필드 구성은 컨트롤러에서 확인했지만
  프로젝트 목록 화면에서 id를 어느 시점에 모아 한 번에 던질지는 화면을 그리면서 정해야 합니다
- **Developer ID 인증서와 공증용 Apple 계정을 누가 들고 있는지.** 5단계 전에는 필요합니다

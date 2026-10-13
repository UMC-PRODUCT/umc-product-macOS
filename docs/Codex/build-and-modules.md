# Build & Run + Tuist 모듈 구조

> 빌드 명령과 모듈 의존성의 기준은 `UMCDesk/`의 매니페스트와 Makefile이다.
> 프로젝트 규약은 [AGENTS.md](../../AGENTS.md)를 따른다.

- 작성자: 제옹(euijjang97)
- 확인일: 2026-10-13

## 빌드 진입점

저장소 루트 Makefile이 `UMCDesk/Makefile`로 위임한다. 아래 명령은 루트에서 실행한다.
Tuist 호출은 `mise exec --`를 거치며 `UMCDesk/mise.toml`의 `4.208.0`을 사용한다.

```bash
brew install mise      # mise가 없는 환경에서 최초 1회
make bootstrap         # mise trust + 고정 Tuist 설치
make install           # SPM 의존성 설치
make generate          # UMCDesk/UMCDesk.xcworkspace 생성
make open              # 워크스페이스 열기, 없으면 먼저 생성
make doctor            # mise·Tuist·Xcode 확인
make build CODE_SIGNING_ALLOWED=NO
make test CODE_SIGNING_ALLOWED=NO
make test SCHEME=AuthPresentation CODE_SIGNING_ALLOWED=NO
```

`build`·`test`는 기존 워크스페이스를 사용한다. 매니페스트·의존성·생성 환경값을 바꿨으면
먼저 `make install` 또는 `make generate`를 실행한다. 자세한 타겟은
[Makefile 가이드](../../UMCDesk/MAKEFILE_GUIDE.md)를 참고한다.

| 설정 | 현재 값 | 근거 |
|------|---------|------|
| 플랫폼·최소 버전 | macOS 26.0 | `Settings+Recommended.swift` |
| Swift | 6.0, strict concurrency complete | `Settings+Recommended.swift` |
| 앱 이름 / 타겟 | UMC Desk / UMCDesk | `Project.swift` |
| Bundle ID | `com.umc.product.macos` | `Project.swift` |
| 앱 버전 | `0.0.1` | `MARKETING_VERSION` |
| 빌드 번호 | `TUIST_BUILD_NUMBER`, 없으면 `1` | `CURRENT_PROJECT_VERSION` |
| 기본 빌드 설정 | Debug, `platform=macOS` | `UMCDesk/Makefile` |
| 로컬 DerivedData | `UMCDesk/.local-derived-data` | `UMCDesk/Makefile` |

## 실제 모듈 구성

```text
UMCDesk/
├── Project.swift / Workspace.swift / Tuist.swift
├── Makefile / mise.toml
├── Tuist/
│   ├── Package.swift / Package.resolved
│   └── ProjectDescriptionHelpers/
│       ├── Project+Core.swift
│       ├── Project+Feature.swift
│       └── Settings+Recommended.swift
├── UMCDesk/Sources/
│   ├── App/UMCDeskApp.swift
│   └── Composition/AppDependencies.swift
├── Core/
│   ├── Foundation/       # 타겟 이름 UMCFoundation
│   ├── Domain/           # 사용자 역할·세션
│   ├── Network/          # Aquila·Moya 어댑터, 토큰 갱신·Keychain
│   ├── DI/               # 등록·캐시·앱 수명 인스턴스
│   ├── Routing/          # Router 구현 전 기반 타겟
│   ├── DesignSystem/     # 토큰·폰트·리소스
│   └── UIComponents/     # UMCCheckboxStyle
├── Features/
│   ├── Auth/             # 화면·폼·디자인 프리뷰, API 연결 전
│   ├── Home/             # 아래 6개 Feature는 계층별 기반 타겟
│   ├── Notice/
│   ├── Activity/
│   ├── Community/
│   ├── Matching/
│   └── ProjectWorkspace/
├── Secrets/              # 빌드 설정과 로컬 override 안내
└── ci_scripts/ci_post_clone.sh
```

현재 앱은 `AuthView`를 표시한다. Window 기본 크기는 1440×960, 최소 크기는 1040×720이다.
Widget·Watch 앱 타겟은 없다. 프로젝트 파일은 생성물이므로 직접 수정하지 않고 매니페스트를 고친다.

### 의존성 방향

`featureProject`는 Feature마다 Domain·Data·Presentation 세 개의 macOS static framework를 만든다.

| 타겟 | 기본 의존성 | 소스 경로 |
|------|-------------|-----------|
| `{Name}Domain` | UMCFoundation, CoreDomain | `Domain/Sources/**` |
| `{Name}Data` | 해당 Domain, CoreNetwork | `Data/Sources/**` |
| `{Name}Presentation` | 해당 Domain, CoreRouting, CoreDesignSystem, CoreUIComponents | `Presentation/Sources/**` |

Data 구현체는 앱의 composition root에서 Domain Protocol에 연결한다. Presentation에서 Data를
직접 import하지 않는다. 타겟 간 공개 타입의 프로퍼티와 초기화에는 `public`을 명시한다.
Core에는 여러 Feature가 공유하는 기반 기능만 두고 Feature 전용 구현은 해당 Data에 둔다.
도메인 소유권을 새로 정할 때는 단일 소유자·재사용 범위·예외를 관련 설계 문서에 기록한다.

Core Bundle ID는 `com.umc.product.macos.core.{suffix}`, Feature는
`com.umc.product.macos.feature.{name}.{layer}`다. 두 헬퍼 모두 `.macOS`와 공통 최소 버전을
사용한다. `coreProject`의 `resources`, `featureProject`의 `dataResources`·
`presentationResources`에 런타임 자산을 등록한다. 실제 Auth 이미지와 디자인 시스템 폰트·색상은
각 모듈의 리소스 번들에서 `Bundle.module`로 읽는다.

### 패키지

직접 의존성은 Aquila 한 개이며 revision
`c167df60acf91bd5827c67e4ec083ec902b0f65b`에 고정돼 있다.
`CoreNetwork`는 `Aquila`, `AquilaMoya`, `Moya` 제품을 사용한다.
`Package.resolved`에는 Moya 15.0.3, Alamofire 5.12.2, ReactiveSwift 6.7.0,
RxSwift 6.10.2가 함께 기록돼 있다. Kingfisher·소셜 로그인 SDK는 현재 매니페스트에 없다.

## 테스트와 CI

| 명령 | 실행 범위 |
|------|-----------|
| `make test` | UMCDeskTests, CoreDITests, CoreDesignSystemTests, CoreNetworkTests |
| `make test-network` | CoreNetwork 스킴 |
| `make test SCHEME=AuthPresentation` | AuthPresentationTests, 앱 기본 스킴과 별도 |
| `make test-dmg` | Python 자동화 스크립트 테스트 |

`.github/workflows/tuist-ci.yml`은 main·develop push/PR에서 자동화 스크립트, 네트워크,
앱·Core 테스트와 Release 빌드를 실행한다. 이어서 프리배포 설정을 재생성해 Release 디자인
시스템 테스트와 빌드를 확인한다. AuthPresentationTests는 현재 이 workflow에 별도 단계가 없다.

## 프리배포와 패키징

`prerelease/{앱버전}/{양의 빌드번호}`를 승인·병합된 `origin/develop`에서 만들고 푸시한다.
별도 prerelease 대상 PR은 만들지 않는다. `MARKETING_VERSION`과 브랜치 버전은 같아야 한다.

```bash
make generate TUIST_PRERELEASE=1 TUIST_BUILD_NUMBER=2
make build CONFIGURATION=Release CODE_SIGNING_ALLOWED=NO
```

`TUIST_PRERELEASE=1`은 **프로젝트 생성 시** `UMC_PRERELEASE` 컴파일 조건을 추가한다.
일반 Release로 되돌릴 때도 `make generate TUIST_PRERELEASE=0`이 필요하다. 이 예시의 빌드 번호는
로컬 검증용이며 실제 배포에서는 중복되지 않는 번호를 확인한다.

Cloud post-clone 스크립트는 prerelease 이름·버전을 검사하고 브랜치의 빌드 번호로 프로젝트를
생성한다. GitHub의 `publish-cloud-dmg.yml`은 같은 브랜치·commit의 공증된 Cloud 앱을 기다려
서명·공증 DMG를 만들고 GitHub prerelease를 발행한다. 실행 환경과 필요한 설정은
[Xcode Cloud 안내](../../tools/xcode-cloud/README.md)를 참고한다. 문서의 workflow 설명만으로
현재 Cloud 설정·인증서·실행 성공을 단정하지 않는다.

`make dmg-test`는 로컬 확인용 DMG, `make dmg-release TUIST_BUILD_NUMBER=...`는 로컬
Developer ID 서명·공증 DMG 경로다. 앱 entitlement는 현재 sandbox와 outbound network만
포함한다. Keychain 저장소는 앱의 기본 access group을 쓰며 공유 extension 그룹은 없다.

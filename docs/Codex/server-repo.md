# 서버 레포 참고 가이드

**레포**: [UMC-PRODUCT/umc-product-server](https://github.com/UMC-PRODUCT/umc-product-server)
Java Spring 서버의 Controller·DTO·Domain 코드를 API 계약의 근거로 확인한다.

- 작성자: 제옹(euijjang97)
- 확인일: 2026-10-13
- 확인 기준: 기본 브랜치 `main`, 커밋
  [`f74b9bbd`](https://github.com/UMC-PRODUCT/umc-product-server/commit/f74b9bbd7f6af65df9d797206482c71d4d27dacf)

아래는 이 커밋에서 확인한 참고 경로다. 기능을 붙일 때 대상 브랜치·최신 Controller·DTO를
다시 확인한다. 이 macOS 앱은 공통 토큰 갱신 transport가 있으며 Feature API 연결은 후속 작업이다.

> **읽기 전용이다.** 서버 레포에 커밋·PR·이슈를 만들지 않는다.
> 메인테이너가 명시적으로 지시한 경우만 예외다.

## 언제 여나

| 상황 | 먼저 볼 곳 |
|---|---|
| 엔드포인트·요청/응답 필드 확인 | `{도메인}/adapter/in/web/*Controller.java` 와 같은 폴더의 `dto/` |
| FE 연동 스펙이 이미 정리돼 있나 | `docs/guides/*_FE_API_가이드.md`, `docs/guides/*-client-contract.md` |
| 권한 규칙 (누가 무엇을 할 수 있나) | `docs/guides/프로젝트_권한_정책.md`, `authorization/` 패키지 |
| 에러 코드와 메시지 | `docs/guides/에러_코드_목록.md` (`.json` 은 기계 판독용) |
| 왜 이렇게 설계했나 | `docs/adr/NNN-*.md` |
| macOS DTO와 실제 응답이 어긋남 | 해당 도메인 Controller → `dto/` → Response record 순서로 따라간다 |

## 조회 방법

클론하지 않는다. `gh` CLI 로 필요한 파일만 읽는다.

```bash
R=UMC-PRODUCT/umc-product-server

# 폴더 목록
gh api "repos/$R/contents/docs/guides" --jq '.[].name'

# 파일 내용
gh api "repos/$R/contents/{경로}" --jq '.content' | base64 -d

# 파일명을 모를 때 — 코드 검색
gh api -X GET search/code -f q='ChallengerPart repo:UMC-PRODUCT/umc-product-server' --jq '.items[].path'
```

## 도메인 패키지

`src/main/java/com/umc/product/{도메인}/`에서 기능별 패키지를 찾는다. 앱 연동 시 우선 확인할 곳은 다음과 같다.

| 앱 기능 | 서버 패키지 | 비고 |
|---|---|---|
| 공지 | `notice` | Command / Query / Content / VoteResponse 로 컨트롤러가 나뉘어 있다 |
| 스레드 | `community` | 연동 스펙은 `docs/guides/community-thread-client-contract.md` |
| 프로젝트 매칭 | `project` | 매칭 차수·지원서·지원 폼·권한 capability 가 모두 여기 |
| 로그인·토큰 | `authentication` | |
| 역할·권한 판정 | `authorization` | `SubjectAttributes`, Casbin 연동 |
| 회원·챌린저 | `member`, `challenger` | 파트·기수·지부 정보 |

각 도메인은 `adapter/in/web`(컨트롤러·DTO) · `application`(유스케이스) · `domain`(엔티티·enum) 순으로 본다.
필드명·타입·nullable 여부를 확인할 때는 항상 `domain` 의 enum/record 원본까지 내려간다.

## 확인된 규약

**아래 확인한 Controller 경로는 `/api/v1/`로 시작한다.** macOS의 `BaseTargetType`은
AquilaMoya 별칭이며 앱은 BASE_URL로 NetworkEnvironment를 만든다. 새 Router에서 API prefix를
중복하거나 빠뜨리지 않도록 서버의 전체 path와 baseURL 결합 결과를 확인한다. 토큰 갱신은
`TokenAuthenticationController`의 `POST /api/v1/auth/token/renew`와 클라이언트 구현을 대조했다.

단수·복수가 섞여 있는 자리가 있다. 프로젝트는 `/api/v1/projects` 인데 매칭 차수는
`/api/v1/project/matching-rounds` 로 **단수형**이다. 이런 곳은 추측하지 말고 컨트롤러의
`@RequestMapping` 을 직접 확인한다.

**파트는 기수별이다.** `ChallengerPart`는 10종이다. 공통 PLAN·DESIGN, 레거시
WEB·ANDROID·IOS·NODEJS·SPRINGBOOT·ADMIN, 신규 WEB_PRODUCT_ENGINEER·
MOBILE_PRODUCT_ENGINEER로 구분한다. `SubjectAttributes.GisuChallengerInfo`에 기수·지부·
part·챌린저가 들어가므로 회원의 파트를 전역 스칼라 하나로 고정하지 않는다. 신규 파트의
infra 허용 여부도 enum의 `canHaveInfra()`에서 확인한다.

**권한 판정은 클라이언트에서 다시 구현하지 않는다.** 프로젝트 화면은 서버가 화면 분기용으로 열어 둔
capability API 를 쓴다.

```
GET /api/v1/projects/permissions?ids=1,2,3
```

프로젝트 id를 최대 100개까지 넘기면 `projects` 배열이 돌아온다. 각 can* 필드는 boolean
자체가 아니라 `{ allowed, reasonCode, reason }` capability 객체다. 예를 들어
`applicationForm.canCreate.allowed`·`application.canDecide.allowed`·`partQuota.canEdit.allowed`로
판정한다. 권한이 없으면 이 capability의 allowed가 false이며 이유 코드·메시지를 함께 받을 수 있다.

리소스 단위 권한이 필요한 다른 지점(스레드 방장 기능 등)은
`GET /api/v1/authorization/resource-permission`을 확인한다. 같은 Controller에는
`POST /api/v1/authorization/resource-permissions/batch`도 있다. query·Body·응답 계약은
각 DTO를 읽고 결정한다.

## 하지 않을 것

- **스펙 추측 금지.** 필드명·타입·nullable 여부는 컨트롤러/DTO 실제 코드로 확인한 뒤
  Response DTO 에 반영한다 (절대 규칙 #2·#3 과 함께 적용).
- 서버 레포의 `CLAUDE.md`·`AGENTS.md`·`.agents/` 는 서버팀 규약이다. 이 레포 규약과 섞지 않는다.
- 서버 코드를 이 레포로 복사해 오지 않는다. 필요한 것은 스펙이지 구현이 아니다.


## 이번 확인의 직접 근거

- [ProjectPermissionController](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/project/adapter/in/web/ProjectPermissionController.java): 경로·최대 100개·false capability 정책
- [ProjectPermissionsResponse](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/project/adapter/in/web/dto/response/ProjectPermissionsResponse.java) / [ProjectPermissionCapabilityInfo](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/project/application/port/in/query/dto/ProjectPermissionCapabilityInfo.java): capability 응답 구조
- [ChallengerPart](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/common/domain/enums/ChallengerPart.java) / [SubjectAttributes](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/authorization/domain/SubjectAttributes.java): 파트·기수별 상태
- [TokenAuthenticationController](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/authentication/adapter/in/web/TokenAuthenticationController.java): 토큰 갱신 경로
- [ProjectMatchingRoundController](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/project/adapter/in/web/ProjectMatchingRoundController.java) / [ResourcePermissionController](https://github.com/UMC-PRODUCT/umc-product-server/blob/f74b9bbd7f6af65df9d797206482c71d4d27dacf/src/main/java/com/umc/product/authorization/adapter/in/web/ResourcePermissionController.java): 매칭·권한 경로

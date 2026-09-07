# 서버 레포 참고 가이드

**레포**: [UMC-PRODUCT/umc-product-server](https://github.com/UMC-PRODUCT/umc-product-server)
Spring Boot + Gradle(Kotlin DSL), 헥사고날(포트-어댑터) 구조.

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
| iOS DTO 와 실제 응답이 어긋남 | 해당 도메인 Controller → `dto/` → Response record 순서로 따라간다 |

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

`src/main/java/com/umc/product/{도메인}/` 아래에 30여 개가 있다. 맥·iOS 앱과 맞닿는 것은 이렇다.

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

**경로는 전부 `/api/v1/` 로 시작한다.** iOS 의 `BaseTargetType` 은 `baseURL` 을 호스트 루트로만 두고
Router 가 전체 path 를 들고 있으므로 서버 경로를 그대로 적으면 된다.

단수·복수가 섞여 있는 자리가 있다. 프로젝트는 `/api/v1/projects` 인데 매칭 차수는
`/api/v1/project/matching-rounds` 로 **단수형**이다. 이런 곳은 추측하지 말고 컨트롤러의
`@RequestMapping` 을 직접 확인한다.

**파트는 기수별이다.** `ChallengerPart` 는 8종(`PLAN`·`DESIGN`·`WEB`·`ANDROID`·`IOS`·`NODEJS`·
`SPRINGBOOT`·`ADMIN`)이고 JSON 필드명은 `part` 다. 다만 `SubjectAttributes` 가 회원 하나에
`GisuChallengerInfo` 리스트를 물고 있어서 기수마다 파트가 다를 수 있다. 전역 스칼라로 잡으면 안 된다.

**권한 판정은 클라이언트에서 다시 구현하지 않는다.** 프로젝트 화면은 서버가 화면 분기용으로 열어 둔
capability API 를 쓴다.

```
GET /api/v1/projects/permissions?ids=1,2,3
```

프로젝트 id 를 최대 100개까지 넘기면 프로젝트마다 boolean 묶음이 돌아온다
(`applicationForm.canCreate`, `application.canDecide`, `partQuota.canEdit`, `member`, `statistics` 등).
권한이 없어도 에러가 아니라 false 가 온다.

리소스 단위 권한이 필요한 다른 지점(스레드 방장 기능 등)은
`GET /api/v1/authorization/resource-permission` 을 쓴다.

## 하지 않을 것

- **스펙 추측 금지.** 필드명·타입·nullable 여부는 컨트롤러/DTO 실제 코드로 확인한 뒤
  Response DTO 에 반영한다 (절대 규칙 #2·#3 과 함께 적용).
- 서버 레포의 `CLAUDE.md`·`AGENTS.md`·`.agents/` 는 서버팀 규약이다. 이 레포 규약과 섞지 않는다.
- 서버 코드를 이 레포로 복사해 오지 않는다. 필요한 것은 스펙이지 구현이 아니다.

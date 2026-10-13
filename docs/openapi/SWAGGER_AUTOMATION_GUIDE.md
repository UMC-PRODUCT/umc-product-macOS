# OpenAPI 도구 현황과 사용 범위

작성자: 제옹(euijjang97)
확인일: 2026-10-13

`tools/openapi/`에는 엔드포인트 목록 비교 도구와 예전 프로젝트 구조용 스캐폴드 생성기가 있습니다. 현재 UMC Desk의 Tuist 모듈에 API를 자동 연결하는 도구는 아닙니다. 이 문서는 저장소에 있는 스크립트의 실제 동작과 수동 보정 범위를 설명합니다.

## 엔드포인트 목록 비교

`jq`를 설치하고 이전·새 OpenAPI JSON을 준비한 뒤 저장소 루트에서 실행합니다.

```sh
tools/openapi/diff_openapi_endpoints.sh ./openapi-prev.json ./openapi.json
```

스크립트는 `GET`·`POST`·`PUT`·`PATCH`·`DELETE`의 메서드, 경로, `operationId`를 정렬해 추가·삭제 목록을 출력합니다. 같은 경로의 `operationId`가 바뀌어도 추가·삭제로 표시됩니다. 요청·응답 스키마, 필드 타입, nullable, 권한 변경까지 비교하지는 않습니다.

## 스캐폴드 생성기의 현재 제한

`generate_endpoint_scaffold.sh`는 엔드포인트 하나를 골라 API·DTO·Repository·UseCase·Swift Testing 초안과 메타데이터를 생성합니다. 아래는 기존 도구의 호출 형식이며 실행하면 현재 앱 구조 밖에 파일이 생깁니다.

```sh
tools/openapi/generate_endpoint_scaffold.sh \
  --spec ./openapi.json \
  --feature Home \
  --path /api/v1/notices/recent \
  --method get
```

현재 생성 위치는 스크립트에 고정된 `AppName/AppName/Features/<Feature>/Data/Generated/`입니다. `UMCDesk/Features/`로 자동 배치되지 않으며 Tuist 타깃에도 포함되지 않습니다. 예시 엔드포인트는 호출 형식을 보여주기 위한 것으로, 실제 서버 지원을 보장하지 않습니다.

템플릿에는 다음 수동 보정이 필요합니다.

- `Config.baseURL`, `@testable import AppName`과 접근 제어를 실제 모듈 기준으로 바꿉니다.
- API·DTO·Repository 구현은 `Data/Sources/`, Domain 모델·Protocol·UseCase는 `Domain/Sources/`, 테스트는 해당 레이어의 `Tests/`로 나눕니다.
- Request 필드와 응답 필드·타입을 채우고 임시 `String` 도메인 매핑과 `"TODO"` 반환을 제거합니다.
- Response DTO의 synthesized Codable을 custom `init(from:)`·`encode(to:)`로 바꾸고 정수 호환 디코딩 규약을 적용합니다.
- 앱의 `DIContainer`에 구현체를 등록하고 ViewModel의 액션·`Loadable` 상태와 연결합니다.
- 생성한 테스트를 실제 모듈과 동작에 맞추고 테스트 타깃을 구성합니다.

생성기는 요청 본문의 JSON `$ref`와 `200` 응답의 JSON `$ref`를 메타데이터로 읽습니다. `$ref`의 필드를 풀어 DTO를 작성하거나 `201`, `204`, 오류 응답, 페이지네이션, 인증·권한을 구현하지 않습니다. 기존 이름의 출력 파일이 있으면 덮어쓸 수 있으므로 생성 결과는 초안으로 검토합니다.

## UMC Desk에 API를 붙일 때

먼저 [서버 조회 가이드](../Codex/server-repo.md)에 따라 실제 서버 Controller·DTO·권한 규칙과 capability API를 확인합니다. OpenAPI와 서버 코드가 다르면 필드·nullable·권한을 추측해서 채우지 않습니다. 화면이 있다는 사실도 서버 연동 완료를 뜻하지 않습니다. 현재 Auth 화면은 로컬 UI 상태로 동작합니다.

구현은 [Network Router 규약](../Codex/network-router.md), [Response DTO 디코딩 규약](../Codex/response-dto-decoding.md), [아키텍처](../Codex/architecture.md)를 기준으로 진행합니다. 스캐폴드 생성기를 현재 모듈 구조로 고치는 작업과 개별 API 연결은 별도 구현 작업으로 다룹니다.

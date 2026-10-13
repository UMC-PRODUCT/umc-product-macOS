# Network Router와 인증 transport

> API 경로·메서드·encoding은 Router, 파라미터 직렬화는 DTO가 맡는다.
> 프로젝트 규약은 [AGENTS.md](../../AGENTS.md)를 따른다.

- 작성자: 제옹(euijjang97)
- 확인일: 2026-10-13

## 현재 네트워크 구성

`CoreNetwork`는 Aquila 기반 actor `NetworkClient`와 `MoyaNetworkAdapter`를 제공한다.
`NetworkTypes.swift`의 `NetworkEnvironment`, `TokenStore`, `TokenPair`, 인증 정책·세션 초기화
Protocol은 Aquila 별칭이고, `BaseTargetType`·`NetworkAdapterError`는 AquilaMoya 별칭이다.

`AppDependencies`가 앱 설정의 BASE_URL과 공유 Keychain 저장소로 클라이언트를 만들고 DI에
등록한다. Feature Data는 이 어댑터를 사용하도록 구성하며 현재 Feature별 Router·Repository
구현은 없다. `CoreRouting`은 화면 전환용 모듈로 네트워크 Router와 역할이 다르다.

| 구성 | 구현 책임 |
|------|-----------|
| `NetworkClient` | Aquila 요청·인증·재시도 위임, 앱 NetworkError 매핑 |
| `MoyaNetworkAdapter` | Moya Target 요청, 인증 우회 요청, 앱 오류 매핑 |
| `AuthSystemFactory` | transport와 토큰 갱신 서비스 조립 |
| `TokenRefreshServiceImpl` | `POST /api/v1/auth/token/renew`, refreshToken Body, APIResponse 해제 |
| `KeychainTokenStore` | 앱 기본 Keychain에 토큰 저장·삭제 |
| `SessionResetHandler` | 세션 상태·세션 범위 DI 캐시 초기화 콜백 |

갱신 실패 중 401·403은 `tokenRefreshFailed`로 매핑하고 일시적인 URL 오류는 transient 오류로
구분한다. 요청·갱신·로그아웃 동작의 범위는 `Core/Network/Tests`에서 검증한다. 이 기반 구현이
Auth 화면의 실제 로그인·가입 연동 완료를 뜻하지는 않는다.

공통 응답은 `APIResponse<T: Codable>`다. `success`를 `isSuccess`로 매핑하고 code·message·
result를 읽는다. `unwrap()`은 실패 응답과 필요한 result 누락을 오류로 만들며 `EmptyResult`는
result 없는 성공을 허용한다. 데이터가 필요 없으면 `validateSuccess()`로 성공 여부만 검사한다.

## Router 작성 규칙

새 엔드포인트는 `Features/{Feature}/Data/Sources/Router/`에 둔다. 계약은
[서버 가이드](server-repo.md)에 따라 실제 Controller·DTO에서 확인한다.

1. `task`에 파라미터 인라인 딕셔너리를 만들지 않는다.
2. Body는 Encodable Request DTO와 `.requestJSONEncodable(body)`를 사용한다.
3. Query는 DTO의 `toParameters`와 `URLEncoding.queryString`으로 직렬화한다.
4. Path 변수는 case associated value로 받아 path에서만 쓴다. 단일 path 변수만 있으면 DTO는 불필요하다.
5. DTO 필드명·nullable·배열 encoding·인증 필요 여부는 엔드포인트 계약으로 확인한다.

아래는 구조 예시이며 현재 제공되는 서버 API나 구현 타입이 아니다.

```swift
struct ItemListQuery {
    let cursor: String?

    var toParameters: [String: Any] {
        var parameters: [String: Any] = [:]
        if let cursor { parameters["cursor"] = cursor }
        return parameters
    }
}

struct CreateItemRequestDTO: Encodable {
    let title: String
}

// Router의 task switch 안
case .list(let query):
    return .requestParameters(
        parameters: query.toParameters,
        encoding: URLEncoding.queryString
    )
case .create(let body):
    return .requestJSONEncodable(body)
```

Request DTO는 `Data/Sources/DTO/Request/`, Response DTO는 `Data/Sources/DTO/Response/`에 둔다.
Body·Query에서 같은 필드를 중복 직렬화하지 않는다. 기존 Router를 옮기는 작업은 기능 변경과
구분해 검증하며, 응답 디코딩은 [Response DTO 가이드](response-dto-decoding.md)를 따른다.

## 설정과 로그

`APIConfig.baseURL()`은 앱 Info.plist의 BASE_URL을 읽는다. 로컬 설정 방법은
[Secrets 안내](../../UMCDesk/Secrets/README.md)를 참고한다. 값·토큰·개인 키를 문서나 로그에
복사하지 않는다. `NetworkClient.logger`는 authorizationCode, verificationCode, password류
민감 필드를 redaction 대상으로 추가한다. 새 인증 필드가 생기면 로그 마스킹 대상도 확인한다.

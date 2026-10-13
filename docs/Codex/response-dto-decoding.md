# Response DTO Decoding

> 서버 wire 타입은 엔드포인트별 Controller·DTO·직렬화 설정에서 확인한다.
> 프로젝트 규약은 [AGENTS.md](../../AGENTS.md)를 따른다.

- 작성자: 제옹(euijjang97)
- 확인일: 2026-10-13

## 타입과 디코딩 원칙

서버 응답의 숫자 식별자는 String 형태를 받을 수 있다. 이 계약을 따르는 필드는 Response DTO·
Domain Model·Repository Protocol까지 String으로 유지하고 연산할 때만 숫자로 바꾼다.
모든 서버 필드가 같은 wire 타입이라고 추정하지 않는다.

Response DTO는 custom `init(from:)`와 `encode(to:)`를 작성한다. Request/Encodable DTO는
이 규칙의 대상이 아니며 서버 요청 계약에 맞게 Int를 사용할 수 있다. 현재 `APIResponse`와
토큰 갱신의 `TokenResult`에 수동 Codable 구현이 있다. Feature별 응답 DTO는 아직 없다.

공통 헬퍼는 이미 `Core/Foundation/Sources/KeyedDecodingContainer+FlexibleNumber.swift`에
있다. `import UMCFoundation` 후 사용하며 파일마다 private 헬퍼를 복사하지 않는다.

| 헬퍼 | 동작 |
|------|------|
| `decodeFlexibleString(forKey:)` | String → Int → Double 순으로 String 변환, 실패 throw |
| `decodeFlexibleStringIfPresent(forKey:)` | 누락·null은 nil, 잘못된 값은 throw |
| `decodeFlexibleStringOrNil(forKey:)` / `OrEmpty` | 실패를 nil / 빈 문자열로 흡수 |
| `decodeFlexibleStringArray(forKey:)` | `[String]` 또는 `[Int]`, 실패하면 빈 배열 |
| `decodeFirstNonEmptyString(forKeys:)` | 여러 키에서 공백 제거 후 첫 비어 있지 않은 문자열 |
| `decodeIntFlexible(forKey:)` / `IfPresent` | Int → String → Double, 잘못된 값은 throw |
| `decodeDoubleFlexible(forKey:)` / `IfPresent` | Double·Int·숫자 문자열 허용, 잘못된 값은 throw |
| `decodeBoolFlexibleIfPresent(forKey:)` | Bool·숫자·true/false/1/0 문자열, 해석 불가는 nil |

Double을 String·Int로 바꿀 때 소수점은 0 방향으로 절삭한다. 정수 범위에 들어오지 않는 값은
오류다. 식별자나 필수 값에는 실패를 숨기는 `OrNil`·`OrEmpty`를 임의로 적용하지 않는다.

## 작성 예시

아래는 String 식별자를 가진 DTO의 구조 예시다. 필드의 실제 계약은 서버에서 확인한다.

```swift
import Foundation
import UMCFoundation

struct ItemResponseDTO: Codable {
    let itemID: String
    let title: String

    private enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemID = try container.decodeFlexibleString(forKey: .itemID)
        title = try container.decode(String.self, forKey: .title)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(itemID, forKey: .itemID)
        try container.encode(title, forKey: .title)
    }
}
```

Int가 필요한 계약상의 숫자 필드도 `decode(Int.self)`를 직접 쓰지 않고
`decodeIntFlexible`·`decodeIntFlexibleIfPresent`를 사용한다. String·Int·Double의 `IfPresent`
헬퍼는 누락·null만 nil로 처리하고 잘못된 값은 throw한다. `decodeBoolFlexibleIfPresent`는
해석할 수 없는 값도 nil로 반환한다.

## 리뷰 기준

- Response DTO의 custom decode·encode와 CodingKeys를 확인한다.
- 식별자의 타입이 DTO·Domain·Repository에서 같은지 확인한다.
- 누락·null·잘못된 타입을 서로 구분하고 서버 계약에 맞게 처리한다.
- String·JSON Number와 범위 밖 값 등 실제 위험한 입력을 테스트한다.
- Request DTO 예외와 `APIResponse.unwrap()`·`validateSuccess()` 선택을 확인한다.

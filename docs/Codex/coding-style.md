# Swift 코딩 스타일 + 네이밍 규칙

> 코드 스타일, 식별자 네이밍 규칙 상세 레퍼런스.
> 핵심 요약은 `AGENTS.md` 참고.

- **들여쓰기**: 4 spaces (탭 금지)
- **줄 길이**: 최대 99자
- **접근 제어자**: 외부 불필요 상태는 `private` 필수
- **상수**: View 내부 전용은 `fileprivate enum Constants`

- 작성자: 제옹(euijjang97)

## 네이밍 규칙

식별자(상수·변수·프로퍼티·함수·case·타입)는 **무엇인지·왜 존재하는지**를 이름만으로 읽을 수 있어야 합니다.

### 원칙

1. **의미 없는 숫자 접미사 금지** — `text1`, `text2`, `value1`, `item2`, `section3` 처럼 카운터로 구분된 이름 사용 금지.
   같은 섹션 안의 여러 값이라도 각각 자기 역할을 드러내는 이름을 부여한다.
2. **연속 인덱스가 본질인 경우만 예외** — 1부터 N까지의 순서 자체가 의미인 경우 (예: `step1`, `step2`, `phase1`). 이외에는 모두 도메인 어휘로 이름 짓는다.
3. **컬렉션이면 컬렉션으로** — 여러 값이 *같은 종류의 데이터* 라면 `[Type]` 배열 또는 `enum` + 매핑을 쓰고, `xxx1`/`xxx2`로 펼치지 않는다.
4. **약어 금지(도메인 표준 제외)** — `usr`, `cnt`, `tmp` 대신 `user`, `count`, `temporary`. 단 `id`, `URL`, `API` 등 도메인 표준 약어는 허용.
5. **타입을 이름에 박지 않기** — `userArray`, `nameString` 대신 `users`, `name`. 단 의미 충돌이 있을 때만 한정사 부여 (예: `loginIdInput` vs `loginId`).

### ❌ 안티패턴

```swift
fileprivate enum Constants {
    static let supportText1: String = "이용 중 불편사항이 있으신가요?"
    static let supportText2: String = "고객센터 운영시간 09:00 - 18:00"

    static let title1: String = "로그인"
    static let title2: String = "회원가입"

    static let btn1Color: Color = UMCColor.Semantic.textBrandDefault
    static let btn2Color: Color = UMCColor.Semantic.textDisabled
}
```

> 카운터만으로는 어떤 값이 어떤 역할인지 알 수 없다. 리뷰어가 본문(`Text(Constants.supportText2)`)을 봐도 무엇이 표시되는지 파악하려면 정의로 점프해야 한다.

### ✅ 권장 패턴

```swift
fileprivate enum Constants {
    static let supportInquiryPrompt: String = "이용 중 불편사항이 있으신가요?"
    static let supportOperatingHours: String = "고객센터 운영시간 09:00 - 18:00"

    static let loginScreenTitle: String = "로그인"
    static let signUpScreenTitle: String = "회원가입"

    static let primaryActionColor: Color = UMCColor.Semantic.textBrandDefault
    static let disabledActionColor: Color = UMCColor.Semantic.textDisabled
}
```

> 호출부(`Text(Constants.supportInquiryPrompt)`)만 봐도 "지원 문의 안내 문구"가 표시된다는 것이 드러난다.

## MARK 구분

```swift
// MARK: - Property
// MARK: - Body
// MARK: - Function
```

## 파일 헤더와 토큰 이름

소스 파일 작성자는 `euijjang97`, 문서·위키 작성자는 `제옹(euijjang97)`로 표기한다.
새 Swift 파일 헤더는 `//  Created by euijjang97 on {날짜}.`, 스크립트·Makefile·workflow는
같은 내용을 `#` 주석으로 쓴다.

`UMCSpacing.value16`·`UMCRadius.value8`·색상 단계의 `teal500`은 디자인 토큰의 값·단계를
명시하는 이름이다. 역할이 없는 임의 숫자 접미사와 구분한다. View에서 색상을 고를 때는
`UMCColor.Semantic`의 역할 이름을 우선하고 화면 배경에는 `UMCColor.Custom`을 사용한다.

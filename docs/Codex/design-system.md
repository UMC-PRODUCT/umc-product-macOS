# 디자인 시스템 + 성능 최적화

> 기준 Figma는 [UMC Mac OS](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS)다.
> 이 문서의 구현 값은 2026-10-13 저장소 기준이며 최신 Figma Variables를 다시 읽었다는 뜻은 아니다.
> 규약은 [AGENTS.md](../../AGENTS.md), API 참고 자료는 [Apple 인덱스](apple-frameworks/INDEX.md)를 따른다.

- 작성자: 제옹(euijjang97)

## 토큰과 리소스

구현 위치는 `UMCDesk/Core/DesignSystem/`이다. `UMCColor`, `UMCSpacing`, `UMCRadius`,
`UMCTypography`를 사용한다. 이전 템플릿의 DefaultConstant·DefaultSpacing·AppFont는 없다.

| 토큰 | 구현 값 |
|------|---------|
| `UMCSpacing.value*` | 4, 8, 12, 16, 20, 24, 32, 40, 64pt |
| `UMCRadius.value*` | 4, 6, 8, 12, 16, 24pt |
| `UMCRadius.full` | 9999pt |
| `UMCColor.Primitives` | Teal·TealGrey 등 기본 팔레트 |
| `UMCColor.Semantic` | 텍스트·아이콘·배경·표면·테두리·상태·태그 역할 |
| `UMCColor.Custom` | backgroundDefault, backgroundAppShell, backgroundSurface |

색상 리소스는 `Resources/UMCColors.xcassets`에 있다. Primitive는 대부분 Semantic에서
참조하며 일부 Semantic과 Custom은 독립 asset이다. asset의 Light·Dark appearance를 함께
유지한다. 화면 배경에는 Custom/Background를 사용한다.

Figma 동기화 작업에서는 `UMC Color`의 Light·Dark 값뿐 아니라 노드의 `explicitVariableModes`와
모드 상속을 확인한다. Primitive도 모드마다 바뀔 수 있으므로 고정 색상의 외부 브랜드에 바로
쓰지 않는다. 인증 `Login/Left Panel`은 화면이 Dark여도 Light를 유지한다. 실제 AuthView도
브랜드 패널에 `.environment(\.colorScheme, .light)`를 적용한다.

## Typography

Pretendard Regular·Bold를 리소스 번들에 포함하고 프로세스당 한 번 등록한다.
`.umcTypography(_:)`는 폰트·정확한 줄높이·자간과 사용자 글자 크기 배율을 적용한다.
폰트만 필요할 때는 `UMCTypography.font`를 사용한다.

| 계열 | 크기 | 줄높이 배율 | 자간 |
|------|------|-------------|------|
| largeTitle1 Regular·Bold | 36pt | 1.5 | -2% |
| largeTitle2 Regular·Bold | 32pt | 1.5 | -2% |
| largeTitle3 Regular·Bold | 26pt | 1.5 | -2% |
| title1 Regular·Bold | 22pt | 1.3 | -2% |
| title2 Regular·Bold | 20pt | 1.3 | -1% |
| title3 Regular·Bold | 16pt | 1.4 | -1% |
| headline Regular·Bold | 14pt | 1.4 | 0 |
| bodyRegular·calloutRegular | 12pt | 1.4 | 0 |
| subheadlineRegular | 11pt | 1.4 | 0 |
| footnoteRegular·captionRegular | 10pt | 1.4 | 0 |

총 19개 스타일이다. Debug·프리배포의 타이포 조정은 `UMCTypographyPreview` 환경값을 통해
비교하며 기본 토큰 값을 덮어쓰지 않는다. `TUIST_PRERELEASE=1`로 **프로젝트를 생성**하면
Release에서도 `UMC_PRERELEASE` 분기가 포함된다. 일반 Release에는 이 도구가 없다.

## 공용 체크박스와 Feature 컴포넌트

현재 `CoreUIComponents`의 실제 공용 스타일은 `UMCCheckboxStyle`이다.
AuthButtonStyle·입력·브랜드 패널 등은 AuthPresentation 전용이다. ArticleTextField·Badge·
MainButton 등의 이전 템플릿 컴포넌트를 구현된 공용 API로 취급하지 않는다.

```swift
Toggle("동의", isOn: $agrees)
    .toggleStyle(UMCCheckboxStyle())
```

앱 루트에는 기본 ToggleStyle이 설정돼 있다. 독립 Preview에도 같은 스타일을 적용한다.
체크 상태는 SF Symbol `.replace.magic(fallback: .replace)`로 전환하며 Reduce Motion에서는
애니메이션을 끈다. 실제 Toggle의 accessibilityRepresentation을 유지해 키보드·VoiceOver
체크 상태가 보존되도록 한다. Feature마다 체크박스 스타일을 중복 구현하지 않는다.

## Liquid Glass와 모션

이 앱의 최소 버전은 macOS 26.0이다. 현재 인증 화면의 카드·입력은 토큰 기반 표면·테두리로
구현돼 있다. Glass를 새로 적용할 때는 기능·플랫폼 가용성과 배경 대비를 먼저 확인한다.

| API | 선택 기준 |
|-----|-----------|
| `.regular` | 일반적인 Glass 요소 |
| `.regular.interactive()` | 사용자 조작에 반응하는 요소 |
| `.clear` | 풍부한 배경 위에서 대비를 확보할 수 있는 경우 |
| `.glass` / `.glassProminent` | 시스템 Glass 버튼 스타일이 적합한 경우 |
| `GlassEffectContainer` / `glassEffectID` | 여러 Glass 요소의 결합·전환이 필요한 경우 |

자세한 API는 [SwiftUI Liquid Glass 가이드](apple-frameworks/SwiftUI-Implementing-Liquid-Glass-Design.md)와
[AppKit 가이드](apple-frameworks/AppKit-Implementing-Liquid-Glass-Design.md)를 참고한다.
측정하지 않은 성능 개선 비율을 보장하지 않는다. 인증 화면 전환과 표시 애니메이션은
`AuthMotion`에서 Reduce Motion을 반영한다.

## 렌더링 검토

관찰 범위와 View 소유권을 먼저 줄이고 측정 결과에 따라 최적화한다. 데이터 목록에는 안정적인
identity를 사용하며 임의의 `.id()` 변경으로 상태를 계속 초기화하지 않는다.
List·Table·Lazy 컨테이너는 화면 요구와 데이터 규모에 맞게 선택하고, row마다 조건으로
개수가 바뀌거나 여러 View가 생성되는 구조는 비용을 확인한다. Equatable·Container/Presenter
분리는 필요한 경계에만 적용한다. 자세한 규칙은 Apple `swiftui-specialist` reference를 읽는다.

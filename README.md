<div align="center">

# {{프로젝트 이름}}

**"{{한 줄 슬로건}}"**

{{한 줄 소개 — 이 앱이 누구의 어떤 문제를 푸는지}}

[![Release](https://img.shields.io/github/v/release/YOUR-ORG/YOUR-REPO?label=release&color=blue)](https://github.com/YOUR-ORG/YOUR-REPO/releases)
[![Swift](https://img.shields.io/badge/Swift-6.3-orange.svg)]()
[![Xcode](https://img.shields.io/badge/Xcode-26.2-1575F9.svg)]()
[![iOS](https://img.shields.io/badge/iOS-26.0+-black.svg)]()
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Modular-2ea44f.svg)]()

</div>

---

## 📖 소개

{{해결하려는 문제와 사용자가 얻는 경험을 2~3줄로.}}

**Killer Features**

- 🔔 **{{기능 1}}** — {{한 줄 설명}}
- 📱 **{{기능 2}}** — {{한 줄 설명}}
- 📍 **{{기능 3}}** — {{한 줄 설명}}

## 🛠️ 기술 스택

<div align="center">
<img src="{{기술 스택 이미지 URL}}" width="100%" alt="기술 스택">
</div>

## 🏝️ 섬 사람들

이 레포는 작은 섬입니다. 땅을 넓히는 사람이 있고 그 땅이 물에 잠기지 않게 지키는 사람이 있습니다.

<div align="center">

| <img src="https://github.com/user-attachments/assets/2cfb0092-9998-4dbf-b094-267f81863c69" width="240" alt="땅주"> | <img src="https://github.com/user-attachments/assets/144c1a20-d0ce-4a49-bb3d-d0bc83af01ec" width="240" alt="섬 지킴이"> |
|:---:|:---:|
| **🪧 땅주** | **🛡️ 섬 지킴이** |
| 제옹한테 권한을 준 사람 | 주인님 없는 땅에서 섬을 단단하게 만들고 있는 중 |
| 땅만 주고 도망감 | 땅 위에 강한 도시를 만드는 중 |
|  | [@euijjang97](https://github.com/euijjang97) |

</div>

> 땅주는 돌아오지 않을거에요..! ^^

> 기수별 팀원 구성(사진·역할·GitHub)은 [Wiki › Team](https://github.com/UMC-PRODUCT/umc-product-macOS/wiki/Team)에서,
> 신규 기능·운영 기록은 [Wiki › Release History](https://github.com/UMC-PRODUCT/umc-product-macOS/wiki/Release-History)에서 확인하세요.

## 📚 개발 문서

아키텍처·코딩 컨벤션·빌드 방법 등 상세 가이드는 `docs/claude/` 에 있습니다.
팀 규모가 커지면 [Wiki](https://github.com/YOUR-ORG/YOUR-REPO/wiki) 로 이관하고 아래 표의 링크만 바꾸세요.

| 주제 | 문서 |
|------|------|
| 🏗️ 아키텍처 | [architecture.md](docs/claude/architecture.md) |
| 📐 절대 규칙 & 코딩 컨벤션 | [CLAUDE.md](CLAUDE.md) · [coding-style.md](docs/claude/coding-style.md) |
| ⚠️ 에러 처리 | [architecture.md › 에러 처리](docs/claude/architecture.md) |
| 🌐 네트워크 & DTO 디코딩 | [network-router.md](docs/claude/network-router.md) · [response-dto-decoding.md](docs/claude/response-dto-decoding.md) |
| 🎨 디자인 시스템 | [design-system.md](docs/claude/design-system.md) |
| 🧱 모듈 구조 (Tuist) | [build-and-modules.md](docs/claude/build-and-modules.md) |
| ⚙️ 빌드 & 실행 | [AppName/MAKEFILE_GUIDE.md](AppName/MAKEFILE_GUIDE.md) |
| 🔀 Git 워크플로우 | [git-workflow.md](docs/claude/git-workflow.md) |
| 🔍 PR 리뷰 | [pr-review.md](docs/claude/pr-review.md) |
| 🍎 Apple 프레임워크 · 스킬팩 | [apple-frameworks/INDEX.md](docs/claude/apple-frameworks/INDEX.md) |
| 🛰️ OpenAPI 스캐폴딩 | [SWAGGER_AUTOMATION_GUIDE.md](docs/openapi/SWAGGER_AUTOMATION_GUIDE.md) |

> 신규 합류자는 **빌드 & 실행** → **아키텍처** → **절대 규칙** 순서로 시작하세요.

## 🔑 시크릿 설정

- `Secrets.xcconfig`(`BASE_URL`, `KAKAO_KEY` 등)와 `GoogleService-Info.plist`는 **팀 내부 채널**에서 수령합니다.
- 실제 키·설정 파일은 원격 저장소에 커밋하지 않습니다.
- 상세 절차: [AppName/Secrets/README.md](AppName/Secrets/README.md)

```bash
cd AppName
make bootstrap                                       # mise + tuist 설치 (최초 1회)
cp Secrets/Secrets.xcconfig.template Secrets/Secrets.xcconfig
make open                                            # generate + Xcode 열기
```

---

<div align="center">

**Made with ❤️ by {{팀 이름}}**

</div>

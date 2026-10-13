# UMC Desk 문서 안내

확인일: 2026-10-13
작성자: 제옹(euijjang97)

저장소 문서는 현재 코드와 함께 관리합니다. 앱은 macOS 26 이상을 대상으로 하며 Auth UI와 디자인 시스템, 네트워크·DI 기반, 공증 DMG 배포 도구를 갖추고 있습니다. Auth의 실제 API 연결과 나머지 서비스 Feature는 구현 전입니다. 화면 미리보기나 배포 자동화 코드의 존재를 서버 연동·출시 완료의 근거로 사용하지 않습니다.

## 개발과 규약

| 문서 | 내용 |
| --- | --- |
| [AGENTS.md](../AGENTS.md) | 저장소 공통 규칙과 상세 문서 진입점 |
| [Makefile 안내](../UMCDesk/MAKEFILE_GUIDE.md) | 최초 설치, 빌드·테스트, 미리보기, DMG, 정리 명령 |
| [환경 설정](../UMCDesk/Secrets/README.md) | `.invalid` 기본값과 로컬 API 설정 |
| [빌드와 모듈](Codex/build-and-modules.md) | Tuist 프로젝트·Feature·Core 구성 |
| [아키텍처](Codex/architecture.md) | 계층 경계, 상태·DI·에러 처리 |
| [디자인 시스템](Codex/design-system.md) | Figma 기준, Light/Dark 토큰, 공통 UI |
| [코딩 스타일](Codex/coding-style.md) | 네이밍·접근 제어·파일 규약 |
| [Network Router](Codex/network-router.md) | API·Query·Body 구성 |
| [Response DTO](Codex/response-dto-decoding.md) | 호환 디코딩과 응답 타입 규약 |
| [Git Workflow](Codex/git-workflow.md) | 이슈·브랜치·커밋·PR·배포 규칙 |
| [PR 리뷰](Codex/pr-review.md) | 리뷰 범위와 확인 기준 |

## API·배포·레퍼런스

| 문서 | 내용 |
| --- | --- |
| [서버 조회 가이드](Codex/server-repo.md) | 실제 서버 스펙·권한·협업 확인 경로 |
| [플랫폼 책임 범위 복사본](Codex/platform-domain-ownership.md) | 공통 엔진과 목적팀의 경계. 최신 원문 여부는 본문 기준일 확인 |
| [OpenAPI 도구 현황](openapi/SWAGGER_AUTOMATION_GUIDE.md) | 엔드포인트 비교와 기존 스캐폴드의 제한 |
| [공증 DMG 배포 설계](specs/배포_Xcode%20Cloud와%20공증%20DMG%20및%20설치%20사이트_설계.md) | 구현된 Cloud·Actions 배포 흐름과 외부 사이트 경계 |
| [Cloud 운영 안내](../tools/xcode-cloud/README.md) | 비밀값·산출물 검증·게시·복구 |
| [Apple 프레임워크·스킬팩](Codex/apple-frameworks/INDEX.md) | Apple API와 SwiftUI 참조 자료 |

디자인 기준은 [UMC Mac OS Figma](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS)입니다. 기획·PRD·설계는 `docs/specs/`, 구현 계획은 `docs/plans/`, 서버 전달용 명세는 `docs/server/`에 둡니다. 문서를 추가할 때는 해당 디렉터리와 규약을 따르고 검토 중인 로컬 초안의 존재를 공식 게시나 승인으로 해석하지 않습니다.

[프로젝트 위키](https://github.com/UMC-PRODUCT/umc-product-macOS/wiki)는 위 문서와 현재 구현을 주제별로 안내합니다. 구현 상태가 바뀌면 코드와 저장소 문서를 먼저 맞추고 위키의 안내도 함께 갱신합니다.

# macOS 스레드 설계와 구현 현황

- 작성자: 제옹(euijjang97)
- 작성일: 2026-11-28
- 디자인 기준일: 2026-11-22. UMC Mac OS 하이파이 12개 그룹의 결정 사항을 기록했다. [Figma 섹션](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=911-19226) · [Light](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=1113-23307) · [Dark](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=1113-23308)
- 구현 확인일: 2026-11-28. macOS 개발 브랜치와 서버 기본 브랜치의 소스를 대조했다. 실제 배포 버전과 화면 검수는 별도다. [macOS 기준 커밋](https://github.com/UMC-PRODUCT/umc-product-macOS/commit/1d69052160f97137b9e221dcd24bc06b6e7def57) · [서버 기준 커밋](https://github.com/UMC-PRODUCT/umc-product-server/commit/ea582a17c74cabfd6f7daeddd8336ae85369d8f2)

## 2026-11-28 작업 반영

스레드 도구 안에서도 목록과 같은 검색어를 편집한다. 한글 조합 중 Return은 편집기가 처리하고, 확정 뒤 Return·아래 방향키는 결과 선택에 사용한다. [탭별 패널 가이드](../Codex/tool-panels.md)

## 화면별 기준

| 화면 | 디자인 결정 | macOS 구현과 남은 차이 |
|---|---|---|
| 새 스레드·편집 | 제목과 소개에 집중한다. 생성 기본값은 자유와 기본 말풍선 아이콘이다. | 생성 폼은 기본값 `FREE`·💬를 채우고 아이콘·카테고리도 직접 바꿀 수 있다. 편집 폼은 제목·소개만 제공한다. 제목은 필수이며 최대 80자, 소개는 최대 500자다(유니코드 스칼라 기준). |
| 목록·검색 | 방 아이콘을 생략하고 제목, 작은 읽지 않은 수, 고정 여부로 구분한다. 고정·일반 그룹은 개별로 접는다. 검색은 전용 행에 둔다. | 제목·소개 검색과 ⌘F, 작은 수 배지는 구현돼 있다. 현재 행은 방 아이콘을 그리며, 검색어가 없고 고정 항목이 있을 때 ‘고정’·‘전체’로 나눈다. 그룹별 접기 상태는 구현돼 있지 않다. |
| 대화·창 | 앱 공통 사이드바와 창 제목 막대를 따른다. 선택·강조에는 Light·Dark의 녹색 의미 토큰을 쓴다. 입력창 뒤 넓은 배경판을 없애고 입력 컨트롤에 Glass를 적용한다. 대화 공간을 확보하도록 아이콘·제목·참여자 수를 상단 도구 모음으로 옮긴다. 대화 옵션과 메시지 작업은 macOS 메뉴로 제공한다. | 목록·상세 분할, 별도 대화 창, 시스템 메뉴, 메시지 반응과 Glass 입력창이 구현돼 있다. 투명도 감소 설정에서는 불투명 배경으로 대체한다. 필터·생성은 창 제목 막대의 스레드 도구에서 열지만, 아이콘·제목·참여자 수는 아직 대화 본문 헤더에 남아 있다. |
| 메시지·사진 | 답장·멘션·반응을 지원한다. 사진은 한 번에 최대 4장이며 한 장이라도 있으면 전송 전 확인한다. 취소하면 글과 첨부를 살리고, 전송 실패 시 같은 메시지를 다시 보낼 수 있어야 한다. | 작성 내용·답장·첨부를 초안으로 복원하고, 전송 중·실패 상태를 대화에 표시한다. 사진 확인을 취소하면 초안으로 돌아간다. 지원 기기에서는 최근 대화나 읽지 않은 메시지를 기기에서 요약한다. |
| 참여자·초대 | 참여자 목록에서 초대로 이어진다. 본인은 초대 후보와 관리 대상에서 제외한다. 타인의 프로필은 읽기 전용으로 연다. | 참여자 검색·초대·프로필·차단 및 메시지 신고 화면이 있다. 초대 후보는 서버 조회 결과를 사용하고 관리 선택에서는 현재 회원 ID를 확인한다. |
| 일괄 관리·이탈 | 내보내기 전에 대상과 인원을 확인한다. 취소하면 목록을 유지한다. 일부만 실패하면 성공·실패 대상을 나누고 실패한 사람만 재시도한다. | 역할별 메뉴와 대상별 처리 결과가 있다. 개설자는 위임 후 나가며, 강퇴 대상에게는 대화 대신 내보내짐 확인 경로를 제공한다. |

관련 구현은 [목록·생성](../../UMCDesk/Features/Community/Presentation/Sources/CommunityPresentation.swift), [대화·전송 확인](../../UMCDesk/Features/Community/Presentation/Sources/ThreadConversationView.swift), [초안·전송 복구](../../UMCDesk/Features/Community/Presentation/Sources/ThreadConversationModel.swift), [대화 창·옵션](../../UMCDesk/Features/Community/Presentation/Sources/ThreadWindowContent.swift), [참여자 관리](../../UMCDesk/Features/Community/Presentation/Sources/ThreadManagementPeopleView.swift), [프로필·신고](../../UMCDesk/Features/Community/Presentation/Sources/ThreadManagementProfileView.swift)에서 확인한다.

세부 시안은 [프로필](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=1124-12272), [전송 복구](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=1124-10739), [답장 메뉴](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=1124-11133), [나가기](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/UMC-Mac-OS?node-id=1124-17112)에서 확인한다.

## 스레드 도구와 대화 옵션

창 제목 막대의 **스레드 도구**에는 제목·소개 검색, 스레드 만들기, 분류·참여 상태 필터, 전체 스레드가 있다. 이 도구는 방을 선택하기 전에도 열 수 있다. **대화 옵션**은 현재 방에서 수행할 작업을 담는다.

| 사용자 상태 | 대화 옵션과 참여자 관리 |
|---|---|
| 비참여자 | 공유할 상세 정보가 있으면 공유 메뉴를 연다. |
| 참여자 | 공유, 참여자 보기, 고정·고정 해제, 알림 끄기·켜기, 나가기를 제공한다. |
| 관리자 | 참여자 기능에 초대·스레드 편집·삭제·내보내기를 더한다. |
| 개설자 | 관리자 기능에 관리자 지정·해제와 개설자 위임을 더한다. 나가려면 먼저 위임한다. |

메시지의 답장·작업 메뉴를 열었다 취소하면 기존 입력 초안을 보존한다. 강퇴 확인 요청(ACK)이 실패하면 행을 유지하고 실패를 알린다. 확인 화면을 다시 열어 재시도할 수 있어야 하며, 성공한 뒤 목록과 열린 창을 정리한다. [확인 요청 처리](../../UMCDesk/Features/Community/Presentation/Sources/ThreadManagementView.swift)

## 열람과 관리 권한

- 11월 22일 시안에서 비참여자 열람 화면을 정리했다. 서버가 허용하는 범위는 다음과 같다. 로그인한 비참여자와 나간 회원(`LEFT`)은 상세·참여자·기존 메시지를 조회할 수 있다. 실시간 이벤트 수신과 보내기·답장·멘션·반응·읽음 처리·메시지 신고는 현재 참여자(`ACTIVE`)에게 열린다. macOS는 읽기 전용 대화에 참여자 전용 안내를 표시한다. 참여자 목록 메뉴는 현재 참여 상태에서만 노출한다. [서버 계약 §7](https://github.com/UMC-PRODUCT/umc-product-server/blob/ea582a17c74cabfd6f7daeddd8336ae85369d8f2/docs/guides/community-thread-client-contract.md)
- 강퇴된 회원(`KICKED`)은 대화를 열거나 재초대될 수 없다. 나간 회원은 다시 초대할 수 있다. 강퇴 확인 화면은 접근 차단을 유지한 채 목록과 창을 정리해야 한다. [조회 서비스](https://github.com/UMC-PRODUCT/umc-product-server/blob/ea582a17c74cabfd6f7daeddd8336ae85369d8f2/monolith/src/main/java/com/umc/product/community/application/service/query/CommunityThreadQueryService.java)
- 개설자와 관리자는 초대·내보내기·스레드 편집·삭제를 수행할 수 있다. 관리자 지정·해제와 개설자 위임은 개설자만 수행한다. 개설자는 강퇴할 수 없고 위임하면 기존 개설자는 관리자가 된다. 일괄 작업도 대상별 권한을 그대로 적용한다. [멤버십 서비스](https://github.com/UMC-PRODUCT/umc-product-server/blob/ea582a17c74cabfd6f7daeddd8336ae85369d8f2/monolith/src/main/java/com/umc/product/community/application/service/command/CommunityThreadMembershipCommandService.java) · [생성·편집·삭제 서비스](https://github.com/UMC-PRODUCT/umc-product-server/blob/ea582a17c74cabfd6f7daeddd8336ae85369d8f2/monolith/src/main/java/com/umc/product/community/application/service/command/CommunityThreadLifecycleCommandService.java)

## 개선 이력과 회귀 확인

| 기준 | 반영한 결정·확인할 동작 |
|---|---|
| 2026-11-22 하이파이 | Light·Dark 기준 화면과 목록·대화·참여자 관리 결정을 확정했다. 원본 링크는 문서 상단에 있다. |
| macOS 후속 반영 | [선택 색상·Liquid Glass](https://github.com/UMC-PRODUCT/umc-product-macOS/pull/130), [입력창·메시지 반응 배치](https://github.com/UMC-PRODUCT/umc-product-macOS/pull/132), [필터의 시스템 선택 표시](https://github.com/UMC-PRODUCT/umc-product-macOS/pull/147), [창 제목 막대의 탭 도구](https://github.com/UMC-PRODUCT/umc-product-macOS/pull/170)를 반영했다. |
| macOS 로컬 검수 | **보기 → 데이터 미리보기 → 스레드**에서 ‘데이터 있음’과 ‘빈 상태’를 번갈아 열어 목록·상세·미선택 상태를 확인한다. [#195](https://github.com/UMC-PRODUCT/umc-product-macOS/pull/195) |
| iOS 병합 사례 · 메시지 | ACK 수신 후 메시지가 보이지 않으면 REST로 복구한다. 입력 중에도 메시지 메뉴가 가려지지 않아야 한다. [#1693](https://github.com/UMC-PRODUCT/umc-product-iOS/pull/1693) · [#1698](https://github.com/UMC-PRODUCT/umc-product-iOS/pull/1698) |
| iOS 병합 사례 · 회원·이탈 | 타인 프로필은 읽기 전용이다. 나가기 취소 후 방이 남고, 본인은 초대 검색에서 빠지며, 강퇴 확인 후에는 방이 사라진다. [#1694](https://github.com/UMC-PRODUCT/umc-product-iOS/pull/1694) · [#1696](https://github.com/UMC-PRODUCT/umc-product-iOS/pull/1696) · [#1697](https://github.com/UMC-PRODUCT/umc-product-iOS/pull/1697) · [#1699](https://github.com/UMC-PRODUCT/umc-product-iOS/pull/1699) |

스레드를 개선할 때마다 해당 화면이나 권한 항목을 최신 상태로 고치고, 이력에 날짜·변경점·근거를 추가한다. 디자인만 바뀐 경우에는 macOS에 남은 차이를 적고, 구현이나 검수가 끝나면 그 근거와 확인일을 갱신한다.

# 문의 채널 Figma 원본 재현 설계

- 작성일: 2026-11-27
- 작성자: 제옹(euijjang97)
- 대상: UMC Desk · macOS · 1단계 원본 재현
- 현재 구현 기준: `origin/develop` [df02419ecab81b9e4d99aace288db045723e2898](https://github.com/UMC-PRODUCT/umc-product-macOS/tree/df02419ecab81b9e4d99aace288db045723e2898)
- 검토 상태: 동일 문서 커밋에 대한 독립 원본 대조 결과는 [문서 이슈](https://github.com/UMC-PRODUCT/umc-product-macOS/issues/189)에 연결된 PR에서 관리한다.

## 원본 선정과 읽는 법

사용자는 FAQ에서 답을 찾고, 해결되지 않은 문제를 UMC PRODUCT에 접수하고, 자기 문의의 답변을 확인한다. 운영 화면에서는 접수 건을 배정하고 답변하며 반복 질문을 공개 FAQ로 편집한다. Figma 레일의 선택 이름은 **문의**, 현재 Mac 창과 메뉴 이름은 **고객센터**다. 스레드는 별도 창이다.

2026-11-27 KST에 공식 파일의 [Hi-fi 페이지](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=605-9566)에서 [06 · 문의 · Hi-fi](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18962)를 열었다. 이 섹션 안에 [Light](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18963)와 [Dark](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18964) 각각 17개의 같은 이름·크기의 화면이 있고 검색 결과·팀 선택·운영 메뉴까지 이어진다. 이 34개가 시각 검수 대상이다. [기존 서버 명세](../server/문의_앱%20문의%20채널과%20서버%20연동%20범위_서버명세.md)가 참조하는 [Mid-fi](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=335-845)와 [서버 협의 페이지](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1073-9771)는 기획 이력이다.

Figma 노드 링크는 현재 파일을 연다. 조회 응답에 불변 revision ID가 없어 파일 버전은 미확인이다. 원본 근거는 전체 34개 렌더, 표시 레이어의 좌표·오토레이아웃·서체·페인트·컴포넌트·프로토타입 반응, 변수의 모드별 값이다. 시안의 이름·시각·인원수·파일·메시지는 예시 데이터다. 문구를 복제하는 시각 검수와 실서비스에서 데이터를 공급하는 조건을 구별한다.

## 화면 지도

아래 Light와 Dark는 같은 행의 서로 다른 원본이다. 화면 이동은 프로토타입 반응과 상태 문구를 기준으로 읽는다. 예를 들어 Q3는 새 창이나 작성 시트가 아니라 Workspace의 내용을 교체하고, Q3 위 **받는 팀 선택**만 모달로 열린다.

| 원본 화면 | Light | Dark | 진입 후 보이는 상태와 다음 행동 |
| --- | --- | --- | --- |
| Q1 · 많이 묻는 질문 | [1100:18965](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18965) | [1100:20882](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20882) | 순위 → Q4, 문의 → Q3, 검색 → 검색어 선택, 내 문의 → Q1-empty |
| Q1-admin · 문의 관리 | [1100:19133](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19133) | [1100:21050](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21050) | 전체·내 담당·미배정·미분류, 첫 행 → Q5, FAQ → Q6 |
| Q1-empty · 내 문의 | [1100:19387](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19387) | [1100:21304](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21304) | 답변 찾아보기 → Q1, 문의하기 → Q3 |
| Q2 · 진행 중 문의 | [1100:19489](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19489) | [1100:21406](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21406) | 진행 중 대화, 답변 입력, 내 문의로 → Q1-empty |
| Q2-closed · 종료 문의 | [1100:19623](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19623) | [1100:21540](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21540) | 종료 기록과 입력 유지, 전송 → Q2 |
| Q3 · 문의 등록 | [1100:19748](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19748) | [1100:21665](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21665) | 추천 답변 → Q4, 팀 선택, 취소 → Q1, 전송 조건 충족 → Q2 |
| Q4 · FAQ 상세 | [1100:19926](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19926) | [1100:21843](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21843) | 해결 응답, 담당자에게 문의하기 → Q3, 복귀 분기 |
| Q5 · 운영 문의 상세 | [1100:20041](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20041) | [1100:21958](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21958) | 문의자 발신과 운영 답변, 배정·라벨·종료·대표 질문 |
| Q6 · FAQ 관리 | [1100:20225](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20225) | [1100:22142](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22142) | 초안·발행·보관, 대표 질문 선택, 공개용 편집 |
| 문의 도구 · 사용자 · 펼침 | [1100:20370](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20370) | [1100:22287](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22287) | Q1 위 도구 팝오버, 닫기·검색·새 문의·바로가기 |
| 문의 도구 · UMC PRODUCT · 펼침 | [1100:20539](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20539) | [1100:22456](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22456) | Q1-admin 위 운영 도구 팝오버, FAQ·목록·선택 문의 |
| Q3 · 받는 팀 선택 · 열린 상태 | [1102:9857](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9857) | [1102:10080](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10080) | Q3 위 딤과 두 열 선택창, 선택/취소 → Q3 |
| Q5 · 담당자 선택 · 열린 상태 | [1102:10303](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10303) | [1102:10553](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10553) | Q5의 처리 정보 위 담당자 메뉴, 선택/취소 → Q5 |
| Q5 · 라벨 편집 · 열린 상태 | [1102:10803](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10803) | [1102:11051](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-11051) | Q5의 처리 정보 위 체크 목록, 적용/취소 → Q5 |
| Q1-search · 검색어 선택 | [1112:19842](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19842) | [1112:20223](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20223) | 출석·과제 → 결과, 영수증 → 빈 결과 |
| Q1-search · 검색 결과 | [1112:19949](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19949) | [1112:20330](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20330) | 두 결과 → Q4, 다시 검색 → 검색어 선택 |
| Q1-search · 검색 결과 없음 | [1112:20116](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20116) | [1112:20497](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20497) | 다시 검색 → 검색어 선택, 문의하기 → Q3 |

## 창과 본문

부록의 좌표는 **직계 부모 원점 기준**이다. 루트 캔버스는 1440×960, 작업면은 (52,40)에서 1376×908, 레일은 (4,40)에서 44×908이다. 레이어 순서는 작업면 → 현재 선택된 실제 App Shell → 40 높이의 네이티브 타이틀바 표시 순이다. 팀 선택 모달은 작업면 위, 레일·타이틀바 아래에 있다. 구형 56 너비 탐색 레일은 숨김이다. 프레임 바깥의 섹션 간 여백은 창 안에 넣지 않는다.

Q1의 Workspace에는 1376×44 상단 도구 행, 1348×1 분리선, (0,45)의 1376×851 Content가 있다. Content의 좌우 패딩 40, 상하 24, 세로 간격 16과 실제 Header 너비 1282를 함께 보존한다. 단순히 부모 너비에서 80을 뺀 값으로 본문을 늘리면 14만큼 달라진다. Q1 순위 898 + 간격 24 + 도움 360, Q1-admin 표 960 + 간격 24 + 보조 298, Q5 대화 898 + 간격 24 + 처리 정보 360, Q6 목록 330 + 간격 24 + 편집 928을 각각 대조한다.

Q2에서는 대화 카드 안쪽 24, 타임라인 세로 간격 20, 수신 아바타 32와 본문 사이 12, 말풍선 너비 660·안쪽 14다. 문의자 시점의 내 메시지는 오른쪽, 담당자 메시지는 왼쪽이다. Q5에서는 문의자의 메시지가 왼쪽으로 바뀐다. Q3는 898 너비의 작성 영역과 360 너비의 추천 답변을 나란히 둔다. 받는 팀 모달은 (312,186.5), 816×587, 두 열 네 줄이다. Q5 담당자와 라벨은 **오른쪽 처리 정보 내부**의 각기 다른 위치에서 펼쳐진다. 기본 창 전체를 어둡게 덮는 Q3와 구별한다.

재현 구현에서는 1 Figma 단위를 macOS 논리 1 pt로 대응시키는 것을 전제로 삼는다. 이는 참조 크기에서의 매핑이며 실제 창을 측정한 결과가 아니다. 현행 최상위 뷰의 일괄 padding 32도 원본 Content의 가로 40·세로 24와 다르다. 현재 고객센터 단독 창 기본값은 980×720, SupportView의 하한은 560×420이다. 데이터 미리보기의 1040×720에서도 참조 캔버스보다 너비 400, 높이 240이 작다. 고정된 좌우 분할을 그대로 넣으면 내용이 맞지 않는다. 좁은 창에서의 재배치와 글자 배율은 이 원본의 수용 조건 밖이다.

## 현재 앱의 접근과 보존할 동작

경로는 모두 위 기준 SHA의 파일과 행이다. Figma의 사용자·UMC PRODUCT 표시는 역할별 화면 예시다. 실제 계정에 운영 capability를 부여하는 조건은 이 코드에서 확인되지 않는다. 아래 로컬 예시를 서비스 권한 판단에 쓰지 않는다.

| 원본 요구 | 현재 구현과 근거 | 재현 매핑과 기능 경계 |
| --- | --- | --- |
| 레일의 문의, 사용자·운영 도구 | [UMCDeskApp.swift 95](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/UMCDeskApp.swift#L95), [메뉴 545](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/UMCDeskApp.swift#L545), [미리보기 212](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/DataPreviewWindow.swift#L212). 일반 모드는 독립 창, 미리보기는 세션의 support 선택. [스레드 109](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/UMCDeskApp.swift#L109)는 별도 WindowGroup | 공통 창 장식의 중복 렌더를 피한다. 원본 레일 선택·도구 배치는 표시 대상이며 실제 계정용 운영 진입은 별도 계약이 필요하다. |
| Q1 FAQ, 검색, 기간 순위, 카테고리 | [SupportView 107](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L107), [검색·정렬 149](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L149), [도움 패널 233](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L233). 일반 창은 내장 appGuide, 로컬 예시는 발행 FAQ도 합산. 검색·카테고리가 비고 기간별 인원이 있을 때 순위 표시 | 원본의 5행·갱신 시각·선택 탭은 표시 명세. 운영 통계와 새 순위 조회는 실제 공급 필요. 시안의 검색은 예시 검색어 두 개를 고르는 분기, 앱은 자유 검색이다. |
| Q1-empty · Q2 내 문의와 답변 | [일반 상태 112](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L112), [목록 41](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportInquiryPreview.swift#L41), [대화 35](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportTicketDetail.swift#L35). 일반 창은 ‘문의 접수 준비 중’. 미리보기는 소유한 문의만 사용자 목록에 포함 | 예시가 0건인 상태와 서비스 준비 중 상태를 구별한다. 전송·첨부·실시간 수신은 표시 재현만으로 제공할 수 없다. |
| Q2 종료·재문의, Q5 첫 답변 | [전송 44](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportFixture.swift#L44), [입력 52](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportTicketDetail.swift#L52). 공백 차단, 종료 건은 소유한 문의자의 메시지로 재개. 담당자 답변 시 진행 중. 로컬 응답은 마지막 reply ID로 하단 스크롤 | 원본 순서와 메시지 방향에 매핑하고 로컬 상태·identity를 유지한다. 실제 발신자·수신 순서·읽음·실패 재시도 계약은 별도 확인. |
| Q3 등록, 받는 팀, 첨부·추천 FAQ | [시트 98](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L98), [작성 224](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportInquiryPreview.swift#L224), [생성 124](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportFixture.swift#L124). 로컬은 460 너비 시트, 제목·내용 필수, 팀 두 종류. 새 UUID 선택 | 원본은 제목 필드 없이 분류·팀·내용·첨부·추천 FAQ가 있는 본문이다. 팀 여덟 선택지·50MB 안내는 원본 문구다. 계정용 분류·접수·첨부 전송을 구현했다고 표시하지 않는다. |
| Q4 FAQ 상세·본문·답변 정보 | [상세 165](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L165). 목록 복귀, 제목, 선택 가능한 답변 제공 | 원본 우측 답변 정보·검증 조직·해결 응답·작성 중 복귀는 별도 표시 및 흐름. 실제 해결 응답 기록은 별도 확인. |
| Q1-admin 목록, Q5 담당·라벨·대표 질문·처리 이력 | [운영 노출 68](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L68), [운영 필터 161](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportInquiryPreview.swift#L161), [운영 정보 107](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportTicketDetail.swift#L107). fixture가 있을 때만 운영 탭. 담당자/라벨은 로컬 Picker | 시안의 복수 라벨 적용·배정 이력·대표 질문 연결과 앱의 단일 라벨은 다르다. 계정별 capability·영속 저장 계약을 충족한 뒤 활성화한다. |
| Q6 FAQ 초안·발행·보관 | [편집 54](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportFAQPreview.swift#L54), [검증·발행 60](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportFixture.swift#L60). Table에서 편집 시트, 공개 스냅숏과 수정본 분리 | 원본은 좌측 선택과 우측 편집의 동시 표시. 로컬에서도 검증을 거쳐 발행하고 보관하면 공개 스냅숏을 내린다. 실서비스 발행·보관 권한과 적용 범위는 미확인. |

앱의 실제 서비스 연동 여부는 위 호출 지점에 한정해 판단했다. [실시간 큐·발신자 이슈](https://github.com/UMC-PRODUCT/umc-product-macOS/issues/157)와 [배정·라벨·FAQ·인기 순위 연동 이슈](https://github.com/UMC-PRODUCT/umc-product-macOS/issues/171)는 별도 작업이다.

### 같은 고객센터로 이어지는 앱 진입점

| 출발점 | 코드 근거 | 현재 동작 |
| --- | --- | --- |
| 로그인 화면의 고객센터 링크 | [AuthSupportButton](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Auth/Presentation/Sources/Views/AuthLoginViews.swift#L216) | 창 ID로 고객센터를 연다. |
| 오프라인·로그인 실패 | [오프라인](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Auth/Presentation/Sources/Views/AuthStatusViews.swift#L99) · [로그인 실패](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Auth/Presentation/Sources/Views/AuthStatusViews.swift#L109) | 재확인과 별도인 고객센터 버튼으로 같은 창을 연다. |
| 설정 레일 및 앱 정보 | [레일 도움말](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Settings/Presentation/Sources/SettingsView.swift#L265) · [앱 정보의 열기](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Settings/Presentation/Sources/Views/SettingsAboutView.swift#L103) | 설정의 openWindow로 같은 목적지에 진입한다. |
| 프로필·활동 코드 오류 | [프로필 안내](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Settings/Presentation/Sources/Views/SettingsProfileView.swift#L49) · [활동 코드 오류](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/Features/Settings/Presentation/Sources/Views/SettingsProfileDialogs.swift#L275) | 오류에서 담당 운영진에게 문의를 누르면 대화상자를 먼저 닫고 같은 목적지를 연다. |

### 입력과 상태의 경계

- **원본 동작**. Q3 ‘문의 보내기’는 받는 팀 선택 여부를 검사한다. 미선택이면 선택창을 열고, 선택했으면 접수·답변 대기 변수를 설정한 뒤 Q2로 이동한다. ‘어느 팀인지 모르겠어요’도 실제 선택지다. Q4 ‘목록으로’는 작성 중 답변 열람 변수에 따라 Q3 또는 Q1로 복귀한다.
- **운영 처리**. Q5의 ‘내가 맡기’는 담당·이력 변수, ‘라벨 편집’의 각 행은 임시 선택을 바꾼다. ‘적용’에서 세 값을 반영하고 닫는다. 담당자 선택은 선택과 함께 닫힌다. Q2-closed의 전송은 진행 화면으로 돌아간다. Q6은 저장·발행·보관을 구분한다. 부록은 버튼별 실제 연결을 기록한다.
- **원본에 보이는 상태**. 빈 내 문의, 검색 결과 없음, 접수/진행 중/종료, 답변 대기, 미배정, FAQ 초안/발행/보관과 수정 중 기존 발행본 공개가 있다. 최초 목록 로딩, 통신 실패·재시도, 접근 거절, 업로드 중·실패를 위한 별도 프레임은 34개에 없다. 34개 참조 프레임 중 별도 좁은 폭·IME·VoiceOver 화면은 없다. 호버·포커스와 입력 조합의 컴포넌트 수준 반응은 전체 마스터를 검증하기 전까지 미확인이다. ‘Esc’ 표기는 실제 trigger 정보와 구분한다.
- **현재 코드에서 보존**. FAQ 검색 Return/↓로 결과에 포커스, Table Return으로 상세, Escape로 목록 복귀, 문의 본문 텍스트 선택, 빈 메시지 전송 차단, 종료 운영 건의 읽기 전용 표시가 있다. [FAQ 검색·포커스](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportView.swift#L188), [목록 Return](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportInquiryPreview.swift#L216), [말풍선 접근성](https://github.com/UMC-PRODUCT/umc-product-macOS/blob/df02419ecab81b9e4d99aace288db045723e2898/UMCDesk/UMCDesk/Sources/App/SupportTicketDetail.swift#L89). IME 조합 중 Return, 화면 낭독 순서, 실패 후 포커스는 실제 앱에서 별도 검증해야 한다.

## 색과 모드 상속

문의 섹션의 explicitVariableModes는 비어 있다. Q1 루트의 반경은 20이고 넘치는 콘텐츠를 자른다. 두 하위 섹션은 UMC Color(701:2261)를 각각 Light(701:0), Dark(746:0)로 지정한다. 34개 프레임은 각 섹션과 같은 UMC Color 모드를 다시 명시하며 87:2 컬렉션에도 Light 쪽 87:0, Dark 쪽 115:0을 지정한다. 자식의 명시적 값이 없으면 상위 모드를 따른다. Q1 Light 기본 CTA와 App Shell에도 701:0이 직접 지정돼 있다. Dark 자식까지 조회한 11개 화면 모두 App Shell은 Light로 강제된다. [Dark Q1-admin 레일](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9962)을 기준으로 확인한다. [Dark 검색어 선택의 출석·과제 버튼](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20294)도 Light 강제이며 stroke 2다. 바로 옆 영수증 버튼은 Dark 명시와 원격 단일 모드 fill을 함께 쓴다. 프레임 이름만 보고 모든 자식을 Dark로 바꾸면 두 버튼 모두 달라진다. 이름이 같은 원격 Color(단일 Mode 1)와 로컬 UMC Color는 별도 컬렉션이다. 단일 모드 색에 임의 Dark 변환을 적용하지 않는다. 문의 시안 인터랙션(401:5819)의 Light/와 Dark/는 변수명 접두사이고 모드는 401:0 하나다. 인기 문의 순위(1112:20782)도 1112:0 단일 모드다. 구 87:2의 explicit 값은 resolved 목록에 나타나지 않아 구컬렉션 값의 적용 여부는 미확인이다. 실사용 UMC Color 28종의 양 모드 56개 값은 기준 코드의 색 자산 및 semantic→primitive 매핑과 소스 표현 정밀도 내에서 일치했다. 별도 예외인 [영수증](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20295)의 원격 Neutral-Inverse/Strong-600 → TealGrey-600은 단일 모드 6:0에서 RGB(0.376200, 0.383800, 0.383293), α=1이다. 현행 TealGrey-600 Dark는 (0.572549, 0.596078, 0.596078), α=1이다. 이 슬롯에는 원격 모드의 원본값을 유지해야 한다. [현행 TealGrey-600 색 자산](../../UMCDesk/Core/DesignSystem/Resources/UMCColors.xcassets/Primitives/Grey/TealGrey-600.colorset/Contents.json)

Q1 순위 행은 디자인 컨텍스트에서 아래 변 1단위 선이 확인된다.

| 첫 사용 노드 | 원본 컬렉션 / 변수 | Light 해석 | Dark 해석 |
| --- | --- | --- | --- |
| [1100:18965](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18965) | UMC Color / Custom/Background/Default | #FFFFFF | #171919 |
| [1100:19009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19009) | UMC Color / Custom/Background/Surface-White | #FFFFFF | #1D2020 |
| [1100:19009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19009) | UMC Color / Semantic/Border/Neutral/Weaker-100 | TealGrey-100 → #EFF0F0 | TealGrey-100 → #1D2020 |
| [1100:19018](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19018) | UMC Color / Custom/Background/Surface-Grey(Weaker) | #FBFCFC | #1D2020 |
| [1100:19021](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19021) | UMC Color / Semantic/Text/Neutral-Default | TealGrey-900 → #0F1010 | TealGrey-900 → #F2F5F5 |
| [1100:19027](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19027) | UMC Color / Semantic/Text/Neutral-Medium-600 | TealGrey-600 → #606262 | TealGrey-600 → #929898 |
| [1100:19028](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19028) | UMC Color / Semantic/Fill/Primary-Inverse/Stronger-600 | Teal-600 → #02746C | Teal-600 → #62CCC4 |
| [I1100:19028;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19028;879-20081) | UMC Color / Semantic/Text/Inverse | White → #FFFFFF | White → #000000 |
| [1100:19030](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19030) | UMC Color / Semantic/Fill/Primary/Medium-100 | Teal-100 → #DDF4F1 | Teal-100 → #0D3B37 |
| [I1100:19030;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19030;879-20075) | UMC Color / Semantic/Text/Brand-Default | Teal-600 → #02746C | Teal-600 → #62CCC4 |
| [1100:19031](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19031) | UMC Color / Semantic/Fill/Neutral/Weaker-50 | TealGrey-50 → #FBFCFC | TealGrey-50 → #0F1010 |
| [1102:9763](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9763) | UMC Color / Semantic/Fill/Neutral/Medium-100 | TealGrey-100 → #EFF0F0 | TealGrey-100 → #1D2020 |
| [I1102:9763;924:18602](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9763;924-18602) | UMC Color / Primitives/Grey/TealGrey-500 | #7E7F7F | #6C7272 |
| [1100:19052](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19052) | UMC Color / Custom/Background/Surface-Grey(Weak) | #EFF0F0 | #383B3B |
| [1101:9476](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9476) | UMC Color / Primitives/Grey/TealGrey-900 | #0F1010 | #F2F5F5 |
| [I1101:9476;758:14002;758:13652](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14002;758-13652) | UMC Color / Primitives/Teal/Teal-50 | #F4FBFA | #082624 |
| [I1101:9476;758:14008](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14008) | UMC Color / Semantic/Fill/Primary-Inverse/Stronger-Hover(Pressed) | Teal-800 → #01423D | Teal-800 → #A7E6E1 |
| [I1101:9476;758:14009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14009) | UMC Color / Semantic/Border/Neutral/Stronger-600 | TealGrey-600 → #606262 | TealGrey-600 → #929898 |
| [1101:9498](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9498) | UMC Color / Custom/Background/App Shell | #0F1010 | #0F1010 |
| [1101:9503](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9503) | UMC Color / Custom/Background/Text-White | #FFFFFF | #FFFFFF |
| [1100:19230](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19230) | UMC Color / Primitives/Teal/Teal-100 | #DDF4F1 | #0D3B37 |
| [1102:9739](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9739) | UMC Color / Semantic/Border/Neutral/Weak-200 | TealGrey-200 → #E2E3E3 | TealGrey-200 → #292C2C |
| [I1102:9739;970:16603](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9739;970-16603) | UMC Color / Primitives/Grey/TealGrey-700 | #3F4141 | #B5BBBB |
| [1100:19821](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19821) | UMC Color / Semantic/Border/Neutral/Medium-300 | TealGrey-300 → #CCCCCC | TealGrey-300 → #383B3B |
| [1102:9979](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9979) | UMC Color / Custom/Background/Dimmed | #0F1010 / 20% | #000000 / 40% |
| [1112:19913](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19913) | UMC Color / Primitives/Teal/Teal-500 | #008A80 | #45BDB4 |
| [1112:19914](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19914) | Color / Semantic/Fill/Neutral-Inverse/Strong-600 | TealGrey-600 → #606262 | TealGrey-600 → #606262 |
| [1100:21133](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21133) | UMC Color / Semantic/Text/Neutral-Strong-800 | TealGrey-800 → #282A2A | TealGrey-800 → #D4DADA |
| [1100:21476](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21476) | UMC Color / Semantic/Fill/Neutral/Strong-200 | TealGrey-200 → #E2E3E3 | TealGrey-200 → #292C2C |

Custom/Background/Default, Surface-White, Surface-Grey(Weaker), Surface-Grey(Weak)는 앱에서 각각 backgroundDefault, backgroundSurfaceWhite, backgroundSurfaceGreyWeaker, backgroundSurfaceGreyWeak 자산을 찾는다. 배경과 표면의 이름이 비슷해도 위 색상표의 두 모드를 따로 대조한다. 의미색은 별칭의 종착점과 앱 Asset Catalog의 양 모드가 일치할 때만 대응시킨다. [UMCColor.swift](../../UMCDesk/Core/DesignSystem/Sources/UMCColor.swift)

### Light와 Dark가 서로 다른 변수를 쓰는 면

회수한 Dark 11개 화면의 가시 레이어를 대응 Light 트리와 순서·이름·치수로 대조했다. 다음 슬롯은 같은 변수를 모드만 바꾸어 쓰지 않는다. 실제 색상값은 위 표에서 각 모드 열을 읽는다.

| 슬롯 | Light 노드 | Light 바인딩 | Dark 노드 | Dark 바인딩 |
| --- | --- | --- | --- | --- |
| 문의 내용 | [1100:19216](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19216) | Semantic/Text/Neutral-Medium-600 | [1100:21133](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21133) | Semantic/Text/Neutral-Strong-800 |
| 상태 | [1100:19217](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19217) | Semantic/Text/Neutral-Medium-600 | [1100:21134](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21134) | Semantic/Text/Neutral-Strong-800 |
| 담당자 | [1100:19218](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19218) | Semantic/Text/Neutral-Medium-600 | [1100:21135](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21135) | Semantic/Text/Neutral-Strong-800 |
| 라벨 | [1100:19219](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19219) | Semantic/Text/Neutral-Medium-600 | [1100:21136](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21136) | Semantic/Text/Neutral-Strong-800 |
| 접수일 | [1100:19220](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19220) | Semantic/Text/Neutral-Medium-600 | [1100:21137](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21137) | Semantic/Text/Neutral-Strong-800 |
| 대화 | [1100:19559](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19559) | Custom/Background/Surface-Grey(Weak) | [1100:21476](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21476) | Semantic/Fill/Neutral/Strong-200 |
| 대화 | [1100:19691](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19691) | Custom/Background/Surface-Grey(Weak) | [1100:21608](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21608) | Semantic/Fill/Neutral/Strong-200 |
| 내용과 첨부 자료는 UMC PRODUCT에 전달돼요. | [1100:19828](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19828) | Semantic/Text/Neutral-Medium-600 | [1100:21745](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21745) | Semantic/Text/Neutral-Strong-800 |
| 운영 대화 | [1100:20111](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20111) | Custom/Background/Surface-Grey(Weak) | [1100:22028](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22028) | Semantic/Fill/Neutral/Strong-200 |
| 운영 대화 | [1102:10374](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10374) | Custom/Background/Surface-Grey(Weak) | [1102:10624](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10624) | Semantic/Fill/Neutral/Strong-200 |
| 운영 대화 | [1102:10874](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10874) | Custom/Background/Surface-Grey(Weak) | [1102:11122](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-11122) | Semantic/Fill/Neutral/Strong-200 |

## 컴포넌트와 에셋

| 마스터 / variant | 컴포넌트 계열 | 사용 예시 | 인스턴스 크기 |
| --- | --- | --- | --- |
| [Size=Sm, Color=Primary, State=Default, Style=Fill, Icon Position=None, Icon Only=False](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=879-20080) | Button | [Action/문의하기](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19028) | 144×40 |
| [Size=Md, Color=Neutral, State=Default, Style=Fill, Icon Position=None, Icon Only=False](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=879-20074) | Button | [Action/많이 묻는 질문](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19030) | 160×48 |
| [State=Default, Type=Rectangle](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=924-18599) | Search Bar | [Search Bar](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9763) | 1142×40 |
| [Selection=문의](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=758-13998) | Side Bar/App Shell | [App Shell · 문의](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9476) | 44×908 |
| [Selection=Unselected](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=758-13653) | Icon/Side Bar | [Icon/Side Bar](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14002) | 44×44 |
| [Selection=Selected](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=758-13639) | Icon/Side Bar | [Icon/Side Bar](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14008) | 44×44 |
| [Img](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=758-13802) | Component (추가하면서 분류 정리 예정) | [Img](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14009) | 44×44 |
| [Mode=Light,Active=True](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=610-14303) | Window Controls/Standard | [Window Controls](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9499) | 60×14 |
| [Style=Weak, Size=Sm, Color=Brand](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=879-21409) | Tag/Basic | [Tag/Basic](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9723) | 96×28 |
| [Message input](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=970-16791) | Component (추가하면서 분류 정리 예정) | [Message input](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9739) | 1234×104 |
| [Size=Md, Color=Primary, State=Default, Style=Fill, Icon Position=None, Icon Only=False](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=879-20070) | Button | [Action/출석·과제](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19913) | 144×48 |

Q1의 검색 glyph는 magnifyingglass, 레일은 위부터 house, megaphone, calendar.badge.checkmark, text.bubble, square.grid.2x2, person.2, questionmark.circle다. 마지막 문의만 Selected다. 레일 하단 Img는 프로필 이미지 채움이고, 대화의 ‘운’·‘유’는 이니셜이다. 첨부 예시 오류 화면.png는 파일명 텍스트로 표시한다. 타이틀바의 뒤/앞 화살표와 문의 도구 그래픽은 디자인 컨텍스트의 별도 벡터 슬롯이다. 코드로 쓸 SF Symbol 이름이 확인된 항목만 Image(systemName:)으로 매핑하고 나머지 벡터는 원본 내보내기와 크기를 대조한다. Q1의 프로필 슬롯은 44×44 원형 object-cover이며 1단위 테두리가 있다. 도구 팝오버는 바깥 클릭과 keyCode 27(Escape)으로 닫힌다. 전체 캡처는 검수 근거로 보관한다.

## 서체와 문구

| 사양 | 서체·weight | 크기 / 행높이 / 자간 | 실제 사용 |
| --- | --- | --- | --- |
| T1 | Noto Sans KR Medium | 14 / 20 / 0% | [문의 도구](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19021) |
| T2 | Noto Sans KR Bold | 28 / 40 / 0% | [문의](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19026) |
| T3 | Noto Sans KR Regular | 14 / 21 / 0% | [서비스 이용 중 궁금한 점은 답변을 찾거나 UMC PRODUCT에](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19027) |
| T4 | Noto Sans KR Medium | 13 / 20 / -1% | [문의하기](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19028;879-20081) |
| T5 | Noto Sans KR Medium | 13 / 20 / -2% | [많이 묻는 질문](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19030;879-20075) |
| T6 | SF Pro Regular | 14 / AUTO / 0 | [SF Symbol glyph](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9763;924-18602) |
| T7 | Noto Sans KR Regular | 14 / 140% / -1% | [궁금한 내용을 검색하세요](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9763;924-18603) |
| T8 | Noto Sans KR Bold | 22 / 33 / 0% | [실시간 인기 문의](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19038) |
| T9 | Noto Sans KR Medium | 13 / 20 / 0% | [최근 24시간](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19042) |
| T10 | Noto Sans KR Regular | 13 / 20 / 0% | [마지막 갱신 14:32](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19043) |
| T11 | Noto Sans KR Bold | 18 / 27 / 0% | [1](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19046) |
| T12 | Noto Sans KR Medium | 17 / 26 / 0% | [출석 기록이 실제와 다르게 보여요](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19048) |
| T13 | Noto Sans KR Medium | 14 / 21 / 0% | [28명 문의](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19050) |
| T14 | Noto Sans KR Bold | 16 / 24 / 0% | [아직 해결되지 않았나요?](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19091) |
| T15 | Noto Sans KR Medium | 12 / 18 / 0% | [새 순위가 있어요. 읽던 목록은 그대로 유지했어요.](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19095) |
| T16 | SF Pro Medium | 16 / AUTO / 0 | [SF Symbol glyph](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1101-9476;758-14002;758-13652) |
| T17 | Noto Sans KR Medium | 16 / 24 / 0% | [출석 기록이 실제와 다르게 보여요](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19225) |
| T18 | Noto Sans KR Medium | 12 / AUTO / 0% | [출석 오류](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19231) |
| T19 | Noto Sans KR Regular | 15 / 23 / 0% | [많이 묻는 질문에서 먼저 답을 찾거나 문의를 남겨주세요.](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19456) |
| T20 | Noto Sans KR Regular | 12 / 140% / 0% | [진행 중](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9723;879-21410) |
| T21 | Noto Sans KR Regular | 13 / AUTO / 0% | [Learning & Activity](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19558) |
| T22 | Noto Sans KR Regular | 15 / 24 / 0% | [앱에서 출석 기록이 실제와 다르게 표시돼요. 새로고침해도 같아서 ](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19566) |
| T23 | Noto Sans KR Bold | 12 / 18 / 0% | [운](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19569) |
| T24 | SF Pro Regular | 16 / AUTO / 0 | [SF Symbol glyph](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9739;970-16603) |
| T25 | SF Pro Medium | 12 / AUTO / 0 | [SF Symbol glyph](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9739;970-16817) |
| T26 | Noto Sans KR Regular | 14 / AUTO / 0% | [받는 팀 선택](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19822) |
| T27 | Noto Sans KR Regular | 12 / AUTO / 0% | [문의와 가까운 팀을 선택해 주세요. 잘 모르겠다면 UMC PROD](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19824) |
| T28 | Noto Sans KR Regular | 16 / 24 / 0% | [앱에서 출석 기록이 실제와 다르게 표시돼요. 새로고침해도 같아서 ](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19827) |
| T29 | Noto Sans KR Medium | 15 / 23 / 0% | [출석 기록이 실제와 다르게 보여요](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20297) |
| T30 | Noto Sans KR Medium | 18 / 27 / 0% | [출석 기록이 실제와 다르게 보여요](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20314) |
| T31 | Noto Sans KR Bold | 16 / 145% / 0% | [문의 도구](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20505) |
| T32 | Noto Sans KR Regular | 12 / 145% / 0% | [답을 찾아보고 내 문의를 이어가세요.](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20508) |
| T33 | Noto Sans KR Regular | 13 / 145% / 0% | [도움말 검색](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20511) |
| T34 | Noto Sans KR Medium | 11 / 145% / 0% | [⌘F](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20512) |
| T35 | Noto Sans KR Medium | 12 / 145% / 0% | [도움말과 내 문의](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20516) |
| T36 | Noto Sans KR Medium | 13 / 145% / 0% | [많이 묻는 질문](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20518) |
| T37 | Noto Sans KR Regular | 11 / 145% / 0% | [상단 도구 버튼으로 다시 열 수 있어요](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20524) |
| T38 | Noto Sans KR Bold | 20 / AUTO / 0% | [어느 팀에 문의할까요?](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9982) |
| T39 | Noto Sans KR Medium | 14 / AUTO / 0% | [취소](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9984) |
| T40 | Noto Sans KR Bold | 14 / 21 / 0% | [담당자 선택](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10432) |
| T41 | Noto Sans KR Regular | 13 / 19 / 0% | [출석 오류](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10942) |
| T42 | Pretendard Variable Regular | 18 / 140% / -1% | [출석·과제](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-19913;879-20071) |
| T43 | Pretendard Variable Medium | 17 / 140% / -2% | [영수증](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-19914;879-20075) |

행높이·자간의 %는 글자 크기 기준이며 부동소수점 표기 오차는 정수 %로 정리했다. 단위 표시 없는 수치는 Figma 단위다. 위 T 번호는 이 문서에서 같은 측정값을 다시 찾기 위한 키다. 원본에는 Noto Sans KR, SF Pro, Pretendard Variable이 함께 쓰인다. 앱의 .umcTypography는 사용자 글꼴·배율 설정을 받으므로 이름이 유사한 토큰만으로 원본과 같다고 판정할 수 없다. 부록 문구의 명시적 개행은 줄바꿈으로 표시한다. 자동 줄바꿈은 표기된 너비와 서체로 대조한다. [UMCTypography.swift](../../UMCDesk/Core/DesignSystem/Sources/UMCTypography.swift)

## 수용 검수와 2단계 인계

| 검수 | 통과 기준 |
| --- | --- |
| 원본 대조 | 34개 지정 프레임을 각 1440×960에서 같은 모드·예시값으로 나란히 확인한다. 숨김 레일, 펼침 오버레이, 검색 결과 0건/2건, 종료·재문의, FAQ 편집의 공개 상태를 각각 선택한다. |
| 배치·타입 | 작업면 원점, 각 열 너비, 버튼 순서, 폼과 팝오버의 안쪽 여백, 반경·선·그림자, 문구와 줄바꿈을 대조한다. 첨부 슬롯·이니셜·프로필·SF Symbol을 각각 식별하고 아래 표의 노드로 불일치 원인을 기록한다. 임의 픽셀 오차를 합격 기준으로 두지 않는다. |
| 테마·입력 | Light/Dark를 별도 기준 이미지로 대조한다. 선택·비활성·숨김·가시성 변수를 확인한다. 연결된 trigger, 조건문 결과, 복귀 목적지가 대응하고 전송 가능 상태가 현재 데이터 경계와 일치해야 한다. |
| 정적 검증과 실기 검증 | 문서 단계에서는 링크·현행 파일/행·Figma ID·프레임 인벤토리·토큰 alias를 확인한다. 실제 구현 후 창별 캡처·대화 입력·포커스·VoiceOver 및 서비스 권한은 별도 수용 검증 대상이다. |
| 단계 완료 | 리뷰어가 같은 Git head의 원본 추적표를 대조한다. 필수 지적을 반영하면 새 head를 넘기고, 최종 통과 SHA를 PR 검토 기록과 2단계 문서에 고정한다. 원본 수정 이력은 별도 커밋으로 추적한다. |

## 화면별 측정 부록

각 항목은 **보이는 순서**를 따른다. 세부 표는 같은 모양의 공통 셸과 앞서 나온 동일 레이어를 한 번만 기록한다. 위치는 부모 기준 x,y(소수점 둘째 자리까지)이고 크기는 w×h다. H/V는 수평·수직 오토레이아웃, 패딩은 좌·우·상·하, 정렬은 주축/교차축 순서다. 문구 표는 TEXT 레이어의 name 대신 characters를 따른다. [1100:19573](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19573)은 앱 버전·오류 화면을 요청한다. [1100:19999](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19999)의 실제 FAQ 문구는 표시·동기화 오류와 출석 인정·학사 판단의 경계를 명시한다. 텍스트 표의 WIDTH_AND_HEIGHT는 양축 자동, HEIGHT는 고정 너비에서 높이 자동, NONE은 고정이다. DISABLED는 말줄임 해제다. 별도 행 제한이 없으면 —로 둔다.

### Q1 · 많이 묻는 질문

순위 → Q4, 문의 → Q3, 검색 → 검색어 선택, 내 문의 → Q1-empty. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18965) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20882)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19009) | Workspace | 52,40 · 1376×908 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/FIXED | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19010](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19010) | 공통 상단 탐색 · 이전 / 앞으로 | 0,0 · 1376×44 | H 12 / 16,24,6,6 / MIN,CENTER · FILL/FIXED | — |
| [1100:19017](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19017) | 상단 여유 공간 | 16,21.5 · 1241×1 | H 0 / 0,0,0,0 / MIN,MIN · FILL/FIXED | clip |
| [1100:19018](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19018) | 탭 도구 모음 열기 · 문의 도구 | 1269,4 · 83×36 | H 6 / 0,0,0,0 / CENTER,CENTER · HUG/FIXED | r8 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1100:19019](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19019) | 공지 도구 아이콘 | 1,8 · 20×20 | — · FIXED/FIXED | clip |
| [1100:19020](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19020) | Vector | 2.5,2.5 · 15×15 | — · FIXED/FIXED | 선 1.3333333730697632 727575@1 |
| [1100:19022](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19022) | Divider | 0,44 · 1348×1 | H 0 / 0,0,0,0 / MIN,MIN · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19023](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19023) | Content | 0,45 · 1376×851 | V 16 / 40,40,24,24 / MIN,MIN · FIXED/FIXED | clip · 면 Custom/Background/Surface-White |
| [1100:19024](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19024) | Header | 40,24 · 1282×65 | H 16 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19025](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19025) | Heading | 0,0 · 1122×65 | V 4 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19028](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19028) | Action/문의하기 | 1138,12.5 · 144×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:19029](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19029) | Navigation | 40,105 · 272×48 | H 8 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19030](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19030) | Action/많이 묻는 질문 | 0,0 · 160×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19031](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19031) | Action/내 문의 | 168,0 · 104×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19032](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19032) | FAQ 검색 | 40,169 · 1282×52 | H 12 / 16,16,8,8 / MIN,CENTER · FIXED/FIXED | r12 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1102:9763](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9763) | Search Bar | 16,6 · 1142×40 | H 0 / 16,16,12,12 / MIN,CENTER · FILL/FIXED | r12 · 면 Semantic/Fill/Neutral/Medium-100 |
| [1100:19034](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19034) | Action/검색 | 1170,2 · 96×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19035](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19035) | FAQ 탐색 | 40,237 · 1282×526 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19036](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19036) | 실시간 인기 문의 | 0,0 · 898×526 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19037](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19037) | Rank Header | 0,0 · 898×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19039](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19039) | Action/최근 24시간 | 660,0 · 126×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19040](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19040) | Action/최근 7일 | 798,0 · 100×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19041](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19041) | Rank Meta | 0,56 · 898×36 | H 12 / 0,0,8,8 / SPACE_BETWEEN,CENTER · FIXED/HUG | clip |
| [1100:19044](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19044) | Rank 1 | 0,100 · 898×73.2 | H 20 / 0,0,6,6 / MIN,CENTER · FIXED/FILL | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |
| [1100:19045](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19045) | 순위 | 0,16.6 · 40×40 | V 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r8 · clip · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19047](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19047) | 질문 | 60,12.6 · 662×48 | V 2 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19051](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19051) | Rank 2 | 0,181.2 · 898×73.2 | H 20 / 0,0,6,6 / MIN,CENTER · FIXED/FILL | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |
| [1100:19052](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19052) | 순위 | 0,16.6 · 40×40 | V 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r8 · clip · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:19058](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19058) | Rank 3 | 0,262.4 · 898×73.2 | H 20 / 0,0,6,6 / MIN,CENTER · FIXED/FILL | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |
| [1100:19065](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19065) | Rank 4 | 0,343.6 · 898×73.2 | H 20 / 0,0,6,6 / MIN,CENTER · FIXED/FILL | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |
| [1100:19072](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19072) | Rank 5 | 0,424.8 · 898×73.2 | H 20 / 0,0,6,6 / MIN,CENTER · FIXED/FILL | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |
| [1100:19080](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19080) | 답변 탐색 | 922,0 · 360×526 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:19083](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19083) | Categories | 24,104 · 312×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19084](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19084) | Action/출석·과제 | 0,0 · 150×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19085](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19085) | Action/계정·로그인 | 162,0 · 150×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19086](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19086) | Categories | 24,168 · 312×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19087](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19087) | Action/프로젝트·매칭 | 0,0 · 150×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19088](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19088) | Action/활동 증명 | 162,0 · 150×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19090](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19090) | Divider | 24,232 · 312×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19093](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19093) | Action/문의하기 | 24,347 · 144×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:19094](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19094) | 순위 갱신 안내 | 40,779 · 1282×48 | H 12 / 12,12,8,8 / MIN,CENTER · FIXED/FIXED | r12 · clip · 면 Custom/Background/Surface-Grey(Weaker) |
| [1100:19096](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19096) | Action/새 순위 보기 | 1106,0 · 132×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1101:9476](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9476) | App Shell · 문의 | 4,40 · 44×908 | V 20 / 4,4,0,16 / SPACE_BETWEEN,CENTER · FIXED/FIXED | 면 Primitives/Grey/TealGrey-900 |
| [1101:9498](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9498) | App shell · native titlebar · 40pt preview | 0,0 · 1440×40 | H 12 / 12,0,0,0 / MIN,CENTER · FIXED/FIXED | clip · 면 Custom/Background/App Shell |
| [1101:9499](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9499) | Window Controls | 12,13 · 60×14 | H 9 / 0,0,0,0 / CENTER,CENTER · HUG/HUG | — |
| [1101:9500](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9500) | Native navigation · 32 + 4 + 32 | 84,0 · 68×40 | H 4 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1101:9501](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9501) | 이전 · 이동 기록 없음 | 0,4 · 32×32 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r10 · clip |
| [1101:9502](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9502) | 아이콘 · back | 5,5 · 22×22 | — · FIXED/FIXED | clip |
| [1101:9503](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9503) | Vector | 7.5,4 · 7×14 | — · FIXED/FIXED | 선 1.7999999523162842 Custom/Background/Text-White |
| [1101:9504](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9504) | 앞으로 · 이동 기록 없음 | 36,4 · 32×32 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r10 · clip |
| [1101:9505](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1101-9505) | 아이콘 · forward | 5,5 · 22×22 | — · FIXED/FIXED | clip |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19021](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19021) | 문의 도구 | T1 | 55×20 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19026](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19026) | 문의 | T2 | 1122×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19027](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19027) | 서비스 이용 중 궁금한 점은 답변을 찾거나 UMC PRODUCT에 문의해 주세요. | T3 | 1122×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19028;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19028;879-20081) | 문의하기 | T4 | 112×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19030;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19030;879-20075) | 많이 묻는 질문 | T5 | 128×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19031;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19031;879-20075) | 내 문의 | T5 | 72×20 | HEIGHT / DISABLED / — / CENTER |
| [I1102:9763;924:18603](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9763;924-18603) | 궁금한 내용을 검색하세요 | T7 | 147×20 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [I1100:19034;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19034;879-20075) | 검색 | T5 | 64×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19038](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19038) | 실시간 인기 문의 | T8 | 648×33 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19039;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19039;879-20075) | ✓ 최근 24시간 | T5 | 94×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19040;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19040;879-20075) | 최근 7일 | T5 | 68×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19042](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19042) | 최근 24시간 | T9 | 430×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19043](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19043) | 마지막 갱신 14:32 | T10 | 456×20 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19046](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19046) | 1 | T11 | 40×27 | HEIGHT / DISABLED / — / CENTER |
| [1100:19048](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19048) | 출석 기록이 실제와 다르게 보여요 | T12 | 662×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19049](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19049) | 출석·과제 · UMC 서비스 | T10 | 662×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19050](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19050) | 28명 문의 | T13 | 156×21 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19053](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19053) | 2 | T11 | 40×27 | HEIGHT / DISABLED / — / CENTER |
| [1100:19055](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19055) | 앱에 로그인이 안 돼요 | T12 | 662×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19056](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19056) | 계정·로그인 · UMC 서비스 | T10 | 662×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19057](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19057) | 21명 문의 | T13 | 156×21 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19060](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19060) | 3 | T11 | 40×27 | HEIGHT / DISABLED / — / CENTER |
| [1100:19062](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19062) | 과제 파일이 업로드되지 않아요 | T12 | 662×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19064](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19064) | 16명 문의 | T13 | 156×21 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19067](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19067) | 4 | T11 | 40×27 | HEIGHT / DISABLED / — / CENTER |
| [1100:19069](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19069) | 프로젝트 지원이 저장되지 않아요 | T12 | 662×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19070](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19070) | 프로젝트·매칭 · UMC 서비스 | T10 | 662×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19071](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19071) | 11명 문의 | T13 | 156×21 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19074](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19074) | 5 | T11 | 40×27 | HEIGHT / DISABLED / — / CENTER |
| [1100:19076](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19076) | 활동 증명서가 열리지 않아요 | T12 | 662×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19077](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19077) | 수료·활동 증명 · UMC 서비스 | T10 | 662×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19078](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19078) | 7명 문의 | T13 | 156×21 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19079](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19079) | 같은 사람의 반복 접수는 한 번만 집계해요. | T10 | 898×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19081) | 카테고리별 답변 | T11 | 312×27 | HEIGHT / DISABLED / — / LEFT |
| [1100:19082](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19082) | UMC PRODUCT가 확인한 서비스 이용 답변을 보여요. | T3 | 312×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19084;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19084;879-20075) | 출석·과제 | T5 | 118×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19085;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19085;879-20075) | 계정·로그인 | T5 | 118×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19087;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19087;879-20075) | 프로젝트·매칭 | T5 | 118×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19088;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19088;879-20075) | 활동 증명 | T5 | 118×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19091](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19091) | 아직 해결되지 않았나요? | T14 | 312×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19092](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19092) | 해결되지 않은 문제는 UMC PRODUCT 담당자가 도와드려요. | T3 | 312×42 | HEIGHT / DISABLED / — / LEFT |
| [1100:19095](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19095) | 새 순위가 있어요. 읽던 목록은 그대로 유지했어요. | T15 | 1082×18 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19096;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19096;879-20075) | 새 순위 보기 | T5 | 100×20 | HEIGHT / DISABLED / — / CENTER |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:19018](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19018) | 탭 도구 모음 열기 · 문의 도구 | 클릭 | tools/inquiry ← NOT |
| [1100:19028](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19028) | Action/문의하기 | 클릭 | FAQ에서 문의 ← False · 작성 중 답변 열람 ← False · 작성 문의 FAQ q ← 출석 기록이 실제와 다르게 보여요 · 작성 문의 FAQ meta ← 출석·과제 · UMC 서비스 · 작성 문의 FAQ intro ← 활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요. · 작성 문의 FAQ steps ← 1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.<br><br>2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.<br><br>3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요. · 작성 문의 FAQ warning ← UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요. · 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자 · 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT · 작성 문의 FAQ related ← 관련 안내<br>출석 화면 오류 안내 · 작성 문의 카테고리 ← 출석·과제 · 작성 문의 내용 ← 앱에서 출석 기록이 실제와 다르게 표시돼요.<br>새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다. · 작성 문의 첨부 ← 오류 화면.png  ·  첨부 변경 · 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원 · 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · Q3 · 문의 등록 |
| [1100:19031](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19031) | Action/내 문의 | 클릭 | Q1-empty · 내 문의 |
| [1102:9763](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9763) | Search Bar | 클릭 | Q1-search · 검색어 선택 |
| [1100:19034](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19034) | Action/검색 | 클릭 | Q1-search · 검색어 선택 |
| [1100:19039](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19039) | Action/최근 24시간 | 클릭 | 기간 ← 최근 24시간 · 24시간 선택 표시 ← ✓ 최근 24시간 · 7일 선택 표시 ← 최근 7일 · 문의자 1 ← 28명 문의 · 문의자 2 ← 21명 문의 · 문의자 3 ← 16명 문의 · 문의자 4 ← 11명 문의 · 문의자 5 ← 7명 문의 · 갱신 문의자/로그인 ← 34명 문의 · 갱신 문의자/출석 ← 30명 문의 |
| [1100:19040](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19040) | Action/최근 7일 | 클릭 | 기간 ← 최근 7일 · 24시간 선택 표시 ← 최근 24시간 · 7일 선택 표시 ← ✓ 최근 7일 · 문의자 1 ← 126명 문의 · 문의자 2 ← 93명 문의 · 문의자 3 ← 74명 문의 · 문의자 4 ← 42명 문의 · 문의자 5 ← 29명 문의 · 갱신 문의자/로그인 ← 138명 문의 · 갱신 문의자/출석 ← 128명 문의 |
| [1100:19044](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19044) | Rank 1 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19051](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19051) | Rank 2 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19058](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19058) | Rank 3 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19065](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19065) | Rank 4 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19072](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19072) | Rank 5 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19084](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19084) | Action/출석·과제 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19085](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19085) | Action/계정·로그인 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19087](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19087) | Action/프로젝트·매칭 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19088](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19088) | Action/활동 증명 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:19096](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19096) | Action/새 순위 보기 | 클릭 | 기존 순위 ← False · 갱신 순위 ← True · 갱신 시각 ← 마지막 갱신 14:33 · 새 순위 안내 표시 ← False |

</details>

### Q1-admin · 문의 관리

전체·내 담당·미배정·미분류, 첫 행 → Q5, FAQ → Q6. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19133) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21050)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19185](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19185) | 상단 여유 공간 | 16,21.5 · 1212×1 | H 0 / 0,0,0,0 / MIN,MIN · FILL/FIXED | clip |
| [1100:19186](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19186) | 탭 도구 모음 열기 · 문의 관리 도구 | 1240,4 · 112×36 | H 6 / 0,0,0,0 / CENTER,CENTER · HUG/FIXED | r8 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1100:19193](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19193) | Heading | 0,0 · 1118×65 | V 4 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19196](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19196) | Action/FAQ 관리 | 1134,12.5 · 148×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:19197](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19197) | 운영 목록 보기 | 40,105 · 376×48 | H 8 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19198](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19198) | Action/전체 5 | 0,0 · 112×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19199](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19199) | Action/내 담당 2 | 120,0 · 124×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19200](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19200) | Action/미배정 3 | 252,0 · 124×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19201](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19201) | 문의 필터 | 40,169 · 712×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19202](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19202) | Dropdown / 상태 전체 | 0,6 · 160×36 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | — |
| [1100:19203](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19203) | Action/상태 전체  ▾ | 0,-6 · 160×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FILL/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19204](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19204) | SF Symbol / chevron.down | 133.82,15.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Default |
| [1100:19205](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19205) | Dropdown / 카테고리 전체 | 172,6 · 204×36 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | — |
| [1100:19206](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19206) | Action/카테고리 전체  ▾ | 0,-6 · 204×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FILL/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19207](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19207) | SF Symbol / chevron.down | 177.82,15.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Default |
| [1100:19208](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19208) | Dropdown / 라벨 전체 | 388,6 · 160×36 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | — |
| [1100:19209](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19209) | Action/라벨 전체  ▾ | 0,-6 · 160×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FILL/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19211](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19211) | Action/미분류 문의 | 560,0 · 152×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19212](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19212) | UMC PRODUCT 전용 공간 | 40,233 · 1282×594 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19213](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19213) | 문의 표 | 0,0 · 960×594 | V 12 / 0,0,0,0 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19215](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19215) | Table Header | 0,45 · 960×40 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r6 · clip · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:19221](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19221) | Divider | 0,97 · 960×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19222](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19222) | 전체 문의 목록 | 0,110 · 960×425 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19223](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19223) | Inquiry/출석 기록이 실제와 다르게 보여요 | 0,0 · 960×84 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1100:19224](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19224) | 문의 요약 | 0,18 · 340×48 | V 4 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19229](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19229) | 라벨 · 운영 목록 | 572,32 · 218×20 | H 6 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1100:19230](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19230) | 라벨/출석 오류 | 0,0 · 63×20 | H 0 / 8,8,3,3 / MIN,CENTER · HUG/HUG | r6 · clip · 면 Primitives/Teal/Teal-100 |
| [1100:19232](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19232) | 라벨/정보 확인 | 69,0 · 63×20 | H 0 / 8,8,3,3 / MIN,CENTER · HUG/HUG | r6 · clip · 면 Primitives/Teal/Teal-100 |
| [1100:19238](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19238) | Divider | 0,84 · 960×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19239](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19239) | Inquiry/앱에 로그인이 안 돼요 | 0,85 · 960×84 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1100:19247](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19247) | Divider | 0,169 · 960×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19248](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19248) | Inquiry/과제 파일이 업로드되지 않아요 | 0,170 · 960×84 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1100:19256](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19256) | Divider | 0,254 · 960×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19257](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19257) | Inquiry/프로젝트 지원이 저장되지 않아요 | 0,255 · 960×84 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1100:19265](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19265) | Divider | 0,339 · 960×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19266](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19266) | Inquiry/활동 증명서가 열리지 않아요 | 0,340 · 960×84 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | clip |
| [1100:19274](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19274) | Divider | 0,424 · 960×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:19346](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19346) | Flexible space | 0,547 · 1×15 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19348](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19348) | 답변 준비 필요 | 984,0 · 298×594 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19353](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19353) | Flexible space | 24,243 · 1×263 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19354](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19354) | Action/FAQ 초안 작성 | 24,522 · 250×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19189](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19189) | 문의 관리 도구 | T1 | 84×20 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19194](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19194) | 문의 관리 | T2 | 1118×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19195](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19195) | UMC PRODUCT 전용 · 서비스에 접수된 문의를 관리하세요. | T3 | 1118×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19196;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19196;879-20081) | FAQ 관리 | T4 | 116×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19198;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19198;879-20075) | 전체 5 | T5 | 80×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19199;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19199;879-20075) | 내 담당 2 | T5 | 92×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19200;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19200;879-20075) | 미배정 3 | T5 | 92×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19203;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19203;879-20075) | 상태 전체 | T5 | 128×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19206;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19206;879-20075) | 카테고리 전체 | T5 | 172×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19209;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19209;879-20075) | 라벨 전체 | T5 | 128×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19211;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19211;879-20075) | 미분류 문의 | T5 | 120×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19214](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19214) | 접수된 문의 | T8 | 960×33 | HEIGHT / DISABLED / — / LEFT |
| [1100:19216](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19216) | 문의 내용 | T9 | 340×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19217](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19217) | 상태 | T9 | 80×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19218](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19218) | 담당자 | T9 | 116×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19219](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19219) | 라벨 | T9 | 218×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19220](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19220) | 접수일 | T9 | 158×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19225](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19225) | 출석 기록이 실제와 다르게 보여요 | T17 | 340×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19226](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19226) | 출석·과제 · Learning & Activity | T10 | 340×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19227](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19227) | 접수 | T13 | 80×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19228](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19228) | 미배정 | T13 | 116×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19231](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19231) | 출석 오류 | T18 | 47×14 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19233](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19233) | 정보 확인 | T18 | 47×14 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19237](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19237) | 오늘 14:20 | T10 | 158×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19241](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19241) | 앱에 로그인이 안 돼요 | T17 | 340×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19242](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19242) | 계정·로그인 · Platform | T10 | 340×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19243](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19243) | 진행 중 | T13 | 80×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19244](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19244) | 이지원 | T13 | 116×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19245](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19245) | 로그인 | T10 | 218×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19246](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19246) | 오늘 13:42 | T10 | 158×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19250](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19250) | 과제 파일이 업로드되지 않아요 | T17 | 340×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19254](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19254) | 정보 확인 | T10 | 218×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19255](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19255) | 오늘 12:11 | T10 | 158×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19259](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19259) | 프로젝트 지원이 저장되지 않아요 | T17 | 340×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19260](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19260) | 프로젝트·매칭 · Learning & Activity | T10 | 340×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19263](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19263) | 기능 요청 | T10 | 218×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19264](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19264) | 어제 | T10 | 158×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19268](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19268) | 활동 증명서가 열리지 않아요 | T17 | 340×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19269](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19269) | 수료·활동 증명 · Learning & Activity | T10 | 340×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19347](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19347) | UMC PRODUCT 구성원만 문의를 조회·배정·처리할 수 있어요. | T10 | 960×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19349](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19349) | 답변 준비 필요 | T11 | 250×27 | HEIGHT / DISABLED / — / LEFT |
| [1100:19350](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19350) | 문의는 늘고 있지만 아직 발행 답변이 없는 질문이에요. | T10 | 250×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19351](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19351) | 알림이 오지 않아요<br>최근 24시간 · 6명 문의 | T17 | 250×48 | HEIGHT / DISABLED / — / LEFT |
| [1100:19352](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19352) | PRODUCT 내부 집계<br>공개 인기 순위에는 표시하지 않아요. | T10 | 250×40 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19354;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19354;879-20075) | FAQ 초안 작성 | T5 | 218×20 | HEIGHT / DISABLED / — / CENTER |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:19186](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19186) | 탭 도구 모음 열기 · 문의 관리 도구 | 클릭 | tools/inquiry_ops ← NOT |
| [1100:19196](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19196) | Action/FAQ 관리 | 클릭 | Q6 · FAQ 관리 |
| [1100:19198](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19198) | Action/전체 5 | 클릭 | 운영 전체 목록 ← True · 내 담당 목록 ← False · 미배정 목록 ← False · 미분류 목록 ← False |
| [1100:19199](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19199) | Action/내 담당 2 | 클릭 | 운영 전체 목록 ← False · 내 담당 목록 ← True · 미배정 목록 ← False · 미분류 목록 ← False |
| [1100:19200](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19200) | Action/미배정 3 | 클릭 | 운영 전체 목록 ← False · 내 담당 목록 ← False · 미배정 목록 ← True · 미분류 목록 ← False |
| [1100:19211](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19211) | Action/미분류 문의 | 클릭 | 운영 전체 목록 ← False · 내 담당 목록 ← False · 미배정 목록 ← False · 미분류 목록 ← True |
| [1100:19223](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19223) | Inquiry/출석 기록이 실제와 다르게 보여요 | 클릭 | Q5 · 운영 문의 상세 |
| [1100:19354](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19354) | Action/FAQ 초안 작성 | 클릭 | FAQ 목록 상태 ← 초안 · FAQ 초안 선택 표시 ← ✓ 초안 · FAQ 발행 선택 표시 ← 발행 · FAQ 보관 선택 표시 ← 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 선택 질문 ← 알림이 오지 않아요 · FAQ 편집 질문 ← 알림이 오지 않아요 · FAQ 편집 답변 ← 기기의 알림 권한과 앱의 알림 설정을 확인해 주세요.<br>계속 알림이 오지 않으면 앱 버전과 발생 시각을 UMC PRODUCT에 알려주세요. · FAQ 편집 별칭 ← 별칭 · 알림 누락, 푸시 오류 · FAQ 편집 적용 범위 ← UMC 서비스 사용자 · FAQ 편집 카테고리 ← 알림 · FAQ 편집 검증 조직 ← 종료일 · 지정 안 함    검증 조직 · UMC PRODUCT · FAQ 편집 표시 ← True · FAQ 선택 안내 표시 ← False · 조건 충족 → FAQ 발행 상태 ← 수정 중 · 기존 발행본 공개, FAQ 저장 안내 ← 검증 전까지 기존 발행본이 공개돼요. · 조건 그 외 → FAQ 발행 상태 ← 초안 · 미공개, FAQ 저장 안내 ← 초안은 검증 후 발행하기 전까지 공개되지 않아요. · Q6 · FAQ 관리 |

</details>

### Q1-empty · 내 문의

답변 찾아보기 → Q1, 문의하기 → Q3. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19387) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21304)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19452](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19452) | Action/많이 묻는 질문 | 0,0 · 160×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19453](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19453) | Action/내 문의 | 168,0 · 104×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19454](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19454) | 내 문의 없음 | 40,169 · 1282×658 | V 16 / 40,40,40,40 / CENTER,CENTER · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19457](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19457) | Actions | 473,352.5 · 336×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19458](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19458) | Action/답변 찾아보기 | 0,0 · 180×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19459](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19459) | Action/문의하기 | 192,4 · 144×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19448](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19448) | 내 문의 | T2 | 1122×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19449](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19449) | 내가 남긴 문의의 처리 상태와 답변을 확인하세요. | T3 | 1122×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19455](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19455) | 아직 등록한 문의가 없어요 | T2 | 900×40 | HEIGHT / DISABLED / — / CENTER |
| [1100:19456](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19456) | 많이 묻는 질문에서 먼저 답을 찾거나 문의를 남겨주세요. | T19 | 900×23 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19458;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19458;879-20075) | 답변 찾아보기 | T5 | 148×20 | HEIGHT / DISABLED / — / CENTER |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:19452](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19452) | Action/많이 묻는 질문 | 클릭 | Q1 · 많이 묻는 질문 |
| [1100:19458](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19458) | Action/답변 찾아보기 | 클릭 | Q1 · 많이 묻는 질문 |

</details>

### Q2 · 진행 중 문의

진행 중 대화, 답변 입력, 내 문의로 → Q1-empty. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19489) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21406)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19552](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19552) | Action/내 문의로 | 1134,8.5 · 148×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19553](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19553) | 문의 정보 | 40,105 · 1282×28 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:19554](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19554) | Badge/진행 중 | 0,0 · 96×28 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1102:9723](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9723) | Tag/Basic | 0,0 · 96×28 | H 0 / 6,6,0,0 / CENTER,CENTER · FIXED/FIXED | r6 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19556](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19556) | 접수한 문의 / 받는 팀 | 108,4 · 166×20 | H 4 / 0,0,0,0 / MIN,MIN · HUG/HUG | clip |
| [1100:19559](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19559) | 대화 | 40,149 · 1282×678 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:19560](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19560) | Message timeline | 24,24 · 1234×482 | V 20 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip · VERTICAL |
| [1100:19561](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19561) | 사용자 메시지 정렬 | 0,0 · 1234×104 | H 0 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19562](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19562) | Right alignment | 0,0 · 574×1 | V 0 / 0,0,0,0 / MIN,MIN · FILL/FIXED | clip |
| [1100:19563](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19563) | 사용자 메시지 | 574,0 · 660×104 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | r16 · clip |
| [1100:19565](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19565) | Message bubble | 0,28 · 660×76 | V 0 / 14,14,14,14 / MIN,MIN · FIXED/HUG | r16 · clip · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19567](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19567) | Incoming message | 0,124 · 1234×80 | H 12 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19568](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19568) | Avatar / 운 | 0,0 · 32×32 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r12 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19570](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19570) | UMC PRODUCT 메시지 | 44,0 · 660×80 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | r16 · clip |
| [1100:19572](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19572) | Message bubble | 0,28 · 660×52 | V 0 / 14,14,14,14 / MIN,MIN · FIXED/HUG | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19583](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19583) | 메시지 입력 | 24,522 · 1234×132 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19584](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19584) | 채팅 입력 필드 | 0,0 · 1234×104 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/FIXED | r16 |
| [1102:9739](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9739) | Message input | 0,0 · 1234×104 | V 0 / 16,16,16,16 / CENTER,CENTER · FIXED/FIXED | r16 · 선 1 Semantic/Border/Neutral/Weak-200 · 면 Custom/Background/Surface-White |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19550](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19550) | 출석 기록이 실제와 다르게 보여요 | T2 | 1118×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19551](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19551) | 출석·과제 · UMC 서비스 | T3 | 1118×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19552;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19552;879-20075) | 내 문의로 | T5 | 116×20 | HEIGHT / DISABLED / — / CENTER |
| [I1102:9723;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9723;879-21410) | 진행 중 | T20 | 36×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [1100:19557](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19557) | 받는 팀 · | T10 | 49×20 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19558](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19558) | Learning & Activity | T21 | 113×16 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19564](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19564) | 나 · 14:20 | T9 | 660×20 | HEIGHT / DISABLED / — / RIGHT |
| [1100:19566](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19566) | 앱에서 출석 기록이 실제와 다르게 표시돼요.<br>새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다. | T22 | 632×48 | HEIGHT / DISABLED / — / LEFT |
| [1100:19569](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19569) | 운 | T23 | 14×18 | HEIGHT / DISABLED / — / LEFT |
| [1100:19571](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19571) | 이지원 · UMC PRODUCT 담당자 · 14:24 | T9 | 660×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19573](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19573) | 확인해 볼게요. 사용 중인 앱 버전과 오류가 나타난 화면을 보내주실 수 있나요? | T22 | 632×24 | HEIGHT / DISABLED / — / LEFT |
| [I1102:9739;970:16602](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9739;970-16602) | UMC PRODUCT 담당자에게 메시지 보내기 | T7 | 1200×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19597](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19597) | UMC PRODUCT 담당자에게 메시지를 보내세요. | T9 | 1234×20 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:19552](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19552) | Action/내 문의로 | 클릭 | Q1-empty · 내 문의 |
| [I1102:9739;970:16816](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9739;970-16816) | Icon/Circle(32px) | 클릭 | 재문의 메시지 표시 ← True |

</details>

### Q2-closed · 종료 문의

종료 기록과 입력 유지, 전송 → Q2. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19623) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21540)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19688](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19688) | Badge/종료 | 0,0 · 96×28 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1100:19693](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19693) | 사용자 메시지 정렬 | 0,0 · 1234×80 | H 0 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19695](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19695) | 사용자 메시지 | 574,0 · 660×80 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | r16 · clip |
| [1100:19697](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19697) | Message bubble | 0,28 · 660×52 | V 0 / 14,14,14,14 / MIN,MIN · FIXED/HUG | r16 · clip · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19699](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19699) | Incoming message | 0,100 · 1234×80 | H 12 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19684](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19684) | 출석 화면 오류 문의 | T2 | 1118×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19685](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19685) | 출석·과제 · 2026.09.30 접수 | T3 | 1118×21 | HEIGHT / DISABLED / — / LEFT |
| [I1102:9725;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9725;879-21410) | 종료 | T20 | 23×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [1100:19690](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19690) | 받는 팀 · Learning & Activity | T10 | 1174×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19698](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19698) | 앱의 출석 화면이 잘못 표시돼요. 새로고침해도 같아서 확인 부탁드립니다. | T22 | 632×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19705](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19705) | 출석 화면의 동기화 오류를 수정했어요. 앱을 새로고침한 뒤 활동 메뉴에서 다시 확인해 주세요. | T22 | 632×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19722](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19722) | 메시지를 보내면 문의가 다시 열려요 | T9 | 1234×20 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [I1102:9747;970:16816](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9747;970-16816) | Icon/Circle(32px) | 클릭 | 문의 팀 및 처리/문의 접수 상태 ← 진행 중 · 문의 팀 및 처리/문의 답변 있음 ← True · 문의 팀 및 처리/문의 답변 대기 ← False · 문의 팀 및 처리/문의 받는 팀 / 접수됨 ← Learning & Activity · 작성 문의 FAQ q ← 출석 기록이 실제와 다르게 보여요 · 작성 문의 FAQ meta ← 출석·과제 · UMC 서비스 · 작성 문의 FAQ intro ← 활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요. · 작성 문의 FAQ steps ← 1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.<br><br>2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.<br><br>3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요. · 작성 문의 FAQ warning ← UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요. · 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자 · 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT · 작성 문의 FAQ related ← 관련 안내<br>출석 화면 오류 안내 · 작성 문의 카테고리 ← 출석·과제 · 작성 문의 내용 ← 앱에서 출석 기록이 실제와 다르게 표시돼요.<br>새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다. · 작성 문의 첨부 ← 오류 화면.png  ·  첨부 변경 · 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원 · 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · 사용자 대화 답변 ← 출석 화면의 동기화 오류를 수정했어요. 앱을 새로고침한 뒤 활동 메뉴에서 다시 확인해 주세요. · 재문의 메시지 표시 ← True · Q2 · 진행 중 문의 |

</details>

### Q3 · 문의 등록

추천 답변 → Q4, 팀 선택, 취소 → Q1, 전송 조건 충족 → Q2. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19748) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21665)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19808](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19808) | Heading | 0,0 · 1282×65 | V 4 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19811](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19811) | 등록 폼과 추천 답변 | 40,105 · 1282×722 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19812](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19812) | 문의 작성 | 0,0 · 898×722 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19813](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19813) | 문의 분류 및 받는 팀 | 24,24 · 850×69 | H 20 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1100:19814](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19814) | 문의 종류 | 0,0 · 300×69 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:19816](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19816) | Dropdown / 출석·과제 | 0,29 · 300×40 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | — |
| [1100:19817](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19817) | Action/출석·과제  ▾ | 0,-4 · 300×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FILL/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19818](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19818) | SF Symbol / chevron.down | 273.82,17.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Default |
| [1100:19819](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19819) | 받는 팀 | 320,0 · 530×69 | V 8 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1100:19821](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19821) | 받는 팀 선택 버튼 | 0,29 · 530×40 | H 12 / 12,12,0,0 / SPACE_BETWEEN,CENTER · FILL/FIXED | r8 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1100:19823](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19823) | SF Symbol / chevron.down | 506.82,17.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Medium-600 |
| [1100:19826](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19826) | 내용 입력 · 작성 중 | 24,176 · 850×321 | V 12 / 16,16,16,16 / MIN,MIN · FIXED/FILL | r10 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:19830](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19830) | Action/오류 화면.png  ·  첨부 변경 | 24,550 · 360×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19832](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19832) | Form Actions | 24,650 · 850×48 | H 12 / 0,0,0,0 / MAX,CENTER · FIXED/HUG | clip |
| [1100:19833](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19833) | Action alignment | 0,23.5 · 542×1 | V 0 / 0,0,0,0 / MIN,MIN · FILL/FIXED | clip |
| [1100:19834](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19834) | Action/취소 | 554,0 · 112×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19835](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19835) | Action/문의 보내기 | 678,4 · 172×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:19836](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19836) | 관련 FAQ | 922,0 · 360×270 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/HUG | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19840](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19840) | Action/답변 확인하기 | 24,142 · 312×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19809](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19809) | 문의하기 | T2 | 1282×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19810](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19810) | 서비스 이용 중 겪은 문제를 알려주시면 UMC PRODUCT가 확인해 드려요. | T3 | 1282×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19815](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19815) | 카테고리 | T13 | 300×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19817;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19817;879-20075) | 출석·과제 | T5 | 268×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19820](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19820) | 받는 팀 | T13 | 42×21 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19822](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19822) | 받는 팀 선택 | T26 | 71×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1100:19824](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19824) | 문의와 가까운 팀을 선택해 주세요. 잘 모르겠다면 UMC PRODUCT에서 확인해 드려요. | T27 | 850×14 | HEIGHT / DISABLED / — / LEFT |
| [1100:19825](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19825) | 문의 내용 | T13 | 850×21 | HEIGHT / DISABLED / — / LEFT |
| [1100:19827](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19827) | 앱에서 출석 기록이 실제와 다르게 표시돼요.<br>새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다. | T28 | 818×48 | HEIGHT / DISABLED / — / LEFT |
| [1100:19828](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19828) | 내용과 첨부 자료는 UMC PRODUCT에 전달돼요. | T10 | 818×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19829](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19829) | 첨부 | T13 | 850×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19830;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19830;879-20075) | 오류 화면.png  ·  첨부 변경 | T5 | 328×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19831](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19831) | 이미지·문서, 최대 50MB | T10 | 850×20 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19834;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19834;879-20075) | 취소 | T5 | 80×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:19835;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19835;879-20081) | 문의 보내기 | T4 | 140×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19837](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19837) | 먼저 확인해 보세요 | T14 | 312×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:19838](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19838) | 출석 기록이 실제와 다르게 보여요 | T12 | 312×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19839](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19839) | 검증된 답변 · UMC PRODUCT | T10 | 312×20 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19840;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19840;879-20075) | 답변 확인하기 | T5 | 280×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:19845](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19845) | 답변을 읽지 않아도 문의를 보낼 수 있어요. 작성하던 내용과 첨부는 유지돼요. | T10 | 312×40 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:19821](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19821) | 받는 팀 선택 버튼 | 클릭 | 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← True |
| [1100:19834](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19834) | Action/취소 | 클릭 | Q1 · 많이 묻는 질문 |
| [1100:19835](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19835) | Action/문의 보내기 | 클릭 | 조건 충족 → 문의 팀 및 처리/문의 받는 팀 / 접수됨 ← 문의 팀 및 처리/접수 팀 선택값, 문의 팀 및 처리/문의 접수 상태 ← 접수, 문의 팀 및 처리/문의 답변 있음 ← False, 문의 팀 및 처리/문의 답변 대기 ← True, 재문의 메시지 표시 ← False, Q2 · 진행 중 문의 · 조건 그 외 → 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← True |
| [1100:19840](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19840) | Action/답변 확인하기 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |

</details>

### Q4 · FAQ 상세

해결 응답, 담당자에게 문의하기 → Q3, 복귀 분기. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19926) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21843)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:19989](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19989) | Action/목록으로 | 1134,8.5 · 148×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:19990](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19990) | FAQ Detail | 40,105 · 1282×722 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:19991](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19991) | 검증된 답변 | 0,0 · 902×722 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:19992](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19992) | Badge/검증된 답변 | 24,24 · 144×32 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1102:9727](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9727) | Tag/Basic | 0,0 · 144×32 | H 0 / 6,6,0,0 / CENTER,CENTER · FIXED/FIXED | r6 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:19996](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19996) | Divider | 24,164 · 854×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:20000](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20000) | Flexible space | 24,396 · 1×238 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:20001](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20001) | FAQ Actions | 24,650 · 854×48 | H 12 / 0,0,0,0 / MAX,CENTER · FIXED/HUG | clip |
| [1100:20002](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20002) | Action/해결됐어요 | 466,0 · 156×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20003](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20003) | Action/담당자에게 문의하기 | 634,4 · 220×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:20005](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20005) | 답변 정보 | 926,0 · 356×722 | V 24 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:20010](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20010) | Divider | 24,273 · 308×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:20012](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20012) | Flexible space | 24,364 · 1×250 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:19987](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19987) | 자주 묻는 질문 | T2 | 1118×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19988](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19988) | UMC PRODUCT가 확인한 서비스 이용 답변을 확인하세요. | T3 | 1118×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:19989;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-19989;879-20075) | 목록으로 | T5 | 116×20 | HEIGHT / DISABLED / — / CENTER |
| [I1102:9727;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9727;879-21410) | 검증된 답변 | T20 | 58×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [1100:19994](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19994) | 출석 기록이 실제와 다르게 보여요 | T2 | 854×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:19995](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19995) | 출석·과제 · UMC 서비스 | T10 | 854×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:19997](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19997) | 활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요. | T12 | 854×26 | HEIGHT / DISABLED / — / LEFT |
| [1100:19998](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19998) | 1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.<br><br>2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.<br><br>3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요. | T28 | 854×120 | HEIGHT / DISABLED / — / LEFT |
| [1100:19999](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19999) | UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요. | T3 | 854×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20002;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20002;879-20075) | 해결됐어요 | T5 | 124×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20003;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20003;879-20081) | 담당자에게 문의하기 | T4 | 188×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20006](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20006) | 답변 정보 | T11 | 308×27 | HEIGHT / DISABLED / — / LEFT |
| [1100:20007](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20007) | 적용 대상<br>UMC 서비스 사용자 | T13 | 308×42 | HEIGHT / DISABLED / — / LEFT |
| [1100:20008](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20008) | 검증한 조직<br>UMC PRODUCT | T3 | 308×42 | HEIGHT / DISABLED / — / LEFT |
| [1100:20009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20009) | 수정일<br>2026.09.30 | T3 | 308×42 | HEIGHT / DISABLED / — / LEFT |
| [1100:20011](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20011) | 관련 안내<br>출석 화면 오류 안내 | T3 | 308×42 | HEIGHT / DISABLED / — / LEFT |
| [1100:20013](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20013) | UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요. | T10 | 308×60 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:19989](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19989) | Action/목록으로 | 클릭 | 조건 충족 → Q3 · 문의 등록 · 조건 그 외 → Q1 · 많이 묻는 질문 |
| [1100:20002](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20002) | Action/해결됐어요 | 클릭 | 해결 응답 ← True |
| [1100:20003](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20003) | Action/담당자에게 문의하기 | 클릭 | 조건 충족 → 문의 참고 답변 ← 출석 기록이 실제와 다르게 보여요, 문의 참고 답변 표시 ← 참고한 답변 · 출석 기록이 실제와 다르게 보여요, FAQ에서 문의 ← True, 작성 문의 FAQ q ← 출석 기록이 실제와 다르게 보여요, 작성 문의 FAQ meta ← 출석·과제 · UMC 서비스, 작성 문의 FAQ intro ← 활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요., 작성 문의 FAQ steps ← 1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.<br><br>2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.<br><br>3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요., 작성 문의 FAQ warning ← UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요., 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자, 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT, 작성 문의 FAQ related ← 관련 안내<br>출석 화면 오류 안내, 작성 문의 카테고리 ← 출석·과제, 작성 문의 내용 ← 앱에서 출석 기록이 실제와 다르게 표시돼요.<br>새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다., 작성 문의 첨부 ← 오류 화면.png  ·  첨부 변경, 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원, 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · 조건 충족 → 문의 참고 답변 ← 출석 기록이 실제와 다르게 보여요, 문의 참고 답변 표시 ← 참고한 답변 · 출석 기록이 실제와 다르게 보여요, FAQ에서 문의 ← True · 조건 충족 → 문의 참고 답변 ← 앱에 로그인이 안 돼요, 문의 참고 답변 표시 ← 참고한 답변 · 앱에 로그인이 안 돼요, FAQ에서 문의 ← True, 작성 문의 FAQ q ← 앱에 로그인이 안 돼요, 작성 문의 FAQ meta ← 계정·로그인 · UMC 서비스, 작성 문의 FAQ intro ← 로그인이 어려우면 계정 정보와 네트워크 연결을 먼저 확인해 주세요., 작성 문의 FAQ steps ← 1. 가입할 때 사용한 계정으로 로그인했는지 확인해 주세요.<br><br>2. 네트워크 연결을 확인하고 앱을 다시 실행해 주세요.<br><br>3. 문제가 계속되면 오류 화면과 발생 시각을 함께 문의해 주세요., 작성 문의 FAQ warning ← 비밀번호나 인증 코드는 문의에 첨부하지 마세요., 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자, 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT, 작성 문의 FAQ related ← 관련 안내<br>계정 및 로그인 안내, 작성 문의 카테고리 ← 계정·로그인, 작성 문의 내용 ← 가입한 계정으로 로그인할 수 없어요.<br>오류가 발생한 시각과 화면을 확인해 주세요., 작성 문의 첨부 ← 파일 첨부, 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원, 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · 조건 충족 → 문의 참고 답변 ← 앱에 로그인이 안 돼요, 문의 참고 답변 표시 ← 참고한 답변 · 앱에 로그인이 안 돼요, FAQ에서 문의 ← True · 조건 충족 → 문의 참고 답변 ← 과제 파일이 업로드되지 않아요, 문의 참고 답변 표시 ← 참고한 답변 · 과제 파일이 업로드되지 않아요, FAQ에서 문의 ← True, 작성 문의 FAQ q ← 과제 파일이 업로드되지 않아요, 작성 문의 FAQ meta ← 출석·과제 · UMC 서비스, 작성 문의 FAQ intro ← 과제 파일을 올릴 수 없다면 파일 형식·용량과 네트워크 상태를 확인해 주세요., 작성 문의 FAQ steps ← 1. 파일 형식·용량과 네트워크 상태를 확인해 주세요.<br><br>2. 앱을 새로고침하고 업로드를 다시 시도해 주세요.<br><br>3. 계속 실패하면 오류 화면과 발생 시각을 UMC PRODUCT에 알려주세요., 작성 문의 FAQ warning ← UMC PRODUCT는 업로드 오류를 확인해 드려요. 제출 기한 연장이나 인정 여부는 처리하지 않아요., 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자, 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT, 작성 문의 FAQ related ← 관련 안내<br>과제 제출 안내, 작성 문의 카테고리 ← 출석·과제, 작성 문의 내용 ← 과제 파일을 올리면 오류가 나요.<br>파일 형식과 오류 화면을 함께 보내드립니다., 작성 문의 첨부 ← 파일 첨부, 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원, 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · 조건 충족 → 문의 참고 답변 ← 과제 파일이 업로드되지 않아요, 문의 참고 답변 표시 ← 참고한 답변 · 과제 파일이 업로드되지 않아요, FAQ에서 문의 ← True · 조건 충족 → 문의 참고 답변 ← 프로젝트 지원이 저장되지 않아요, 문의 참고 답변 표시 ← 참고한 답변 · 프로젝트 지원이 저장되지 않아요, FAQ에서 문의 ← True, 작성 문의 FAQ q ← 프로젝트 지원이 저장되지 않아요, 작성 문의 FAQ meta ← 프로젝트·매칭 · UMC 서비스, 작성 문의 FAQ intro ← 지원 내용이 저장되지 않으면 네트워크 상태와 입력 항목을 확인해 주세요., 작성 문의 FAQ steps ← 1. 필수 입력 항목과 네트워크 상태를 확인해 주세요.<br><br>2. 작성한 내용을 보관한 뒤 저장을 다시 시도해 주세요.<br><br>3. 문제가 계속되면 오류 화면과 발생 시각을 UMC PRODUCT에 알려주세요., 작성 문의 FAQ warning ← 지원 저장 오류를 확인해 드려요. 선발 결과나 매칭 변경은 처리하지 않아요., 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자, 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT, 작성 문의 FAQ related ← 관련 안내<br>프로젝트 지원 안내, 작성 문의 카테고리 ← 프로젝트·매칭, 작성 문의 내용 ← 프로젝트 지원서를 저장하면 오류가 나요.<br>저장 시각과 오류 화면을 함께 보내드립니다., 작성 문의 첨부 ← 파일 첨부, 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원, 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · 조건 충족 → 문의 참고 답변 ← 프로젝트 지원이 저장되지 않아요, 문의 참고 답변 표시 ← 참고한 답변 · 프로젝트 지원이 저장되지 않아요, FAQ에서 문의 ← True · 조건 충족 → 문의 참고 답변 ← 활동 증명서가 열리지 않아요, 문의 참고 답변 표시 ← 참고한 답변 · 활동 증명서가 열리지 않아요, FAQ에서 문의 ← True, 작성 문의 FAQ q ← 활동 증명서가 열리지 않아요, 작성 문의 FAQ meta ← 수료·활동 증명 · UMC 서비스, 작성 문의 FAQ intro ← 활동 증명서가 열리지 않으면 앱을 새로고침하고 다시 열어주세요., 작성 문의 FAQ steps ← 1. 네트워크 연결과 앱 버전을 확인해 주세요.<br><br>2. 활동 증명 메뉴를 새로고침하고 다시 열어주세요.<br><br>3. 계속 열리지 않으면 오류 화면을 UMC PRODUCT에 알려주세요., 작성 문의 FAQ warning ← UMC PRODUCT는 증명서 조회·다운로드 오류를 확인해 드려요. 수료 여부를 결정하지 않아요., 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자, 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT, 작성 문의 FAQ related ← 관련 안내<br>활동 증명 발급 안내, 작성 문의 카테고리 ← 수료·활동 증명, 작성 문의 내용 ← 활동 증명서 화면이 열리지 않아요.<br>앱 버전과 오류 화면을 함께 보내드립니다., 작성 문의 첨부 ← 파일 첨부, 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원, 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · 조건 충족 → 문의 참고 답변 ← 활동 증명서가 열리지 않아요, 문의 참고 답변 표시 ← 참고한 답변 · 활동 증명서가 열리지 않아요, FAQ에서 문의 ← True · Q3 · 문의 등록 |

</details>

### Q5 · 운영 문의 상세

문의자 발신과 운영 답변, 배정·라벨·종료·대표 질문. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20041) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21958)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:20104](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20104) | Action/문의 관리로 | 1134,8.5 · 148×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20105](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20105) | 운영 문의 상태 | 40,105 · 1282×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:20106](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20106) | Badge/접수 | 0,10 · 96×28 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1100:20109](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20109) | Action/문의 종료 | 1134,0 · 148×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20110](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20110) | 대화와 운영 정보 | 40,169 · 1282×658 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:20111](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20111) | 운영 대화 | 0,0 · 898×658 | V 16 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:20112](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20112) | Message timeline | 24,24 · 850×462 | V 20 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip · VERTICAL |
| [1100:20115](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20115) | Incoming message | 0,0 · 850×108 | H 12 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:20116](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20116) | Avatar / 유 | 0,0 · 32×32 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r12 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:20118](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20118) | 문의한 메시지 | 44,0 · 660×108 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | r16 · clip |
| [1100:20129](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20129) | 운영 답변 입력 | 24,502 · 850×132 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | clip |
| [1100:20130](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20130) | 채팅 입력 필드 | 0,0 · 850×104 | V 8 / 0,0,0,0 / MIN,MIN · FIXED/FIXED | r16 |
| [1102:9755](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9755) | Message input | 0,0 · 850×104 | V 0 / 16,16,16,16 / CENTER,CENTER · FIXED/FIXED | r16 · 선 1 Semantic/Border/Neutral/Weak-200 · 면 Custom/Background/Surface-White |
| [1100:20144](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20144) | 처리 정보 | 922,0 · 360×658 | V 12 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:20147](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20147) | Action/미배정  ▾ | 24,95 · 312×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20148](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20148) | Action/내가 맡기 | 24,155 · 140×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20150](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20150) | 라벨 | 24,247 · 312×32 | H 8 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:20151](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20151) | Badge/출석 오류 | 0,0 · 96×32 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1102:9731](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9731) | Tag/Basic | 0,0 · 96×32 | H 0 / 6,6,0,0 / CENTER,CENTER · FIXED/FIXED | r6 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:20153](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20153) | Badge/정보 확인 | 104,0 · 96×32 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1100:20157](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20157) | Action/라벨 편집 | 24,291 · 140×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20160](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20160) | Action/대표 질문 연결 | 24,416 · 180×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20161](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20161) | Divider | 24,476 · 312×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:20195](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20195) | 담당자 메뉴 펼치기 | 306,108.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Medium-600 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:20103](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20103) | 김유엠 · UMC 서비스 · 오늘 14:20 접수 | T3 | 1118×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20104;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20104;879-20075) | 문의 관리로 | T5 | 116×20 | HEIGHT / DISABLED / — / CENTER |
| [I1102:9729;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9729;879-21410) | 접수 | T20 | 23×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [1100:20108](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20108) | 받는 팀 · Learning & Activity | T10 | 1014×20 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20109;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20109;879-20075) | 문의 종료 | T5 | 116×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20117](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20117) | 유 | T23 | 14×18 | HEIGHT / DISABLED / — / LEFT |
| [1100:20119](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20119) | 김유엠 · 14:20 | T9 | 660×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20121](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20121) | 앱에서 출석 기록이 실제와 다르게 표시돼요. 새로고침해도 같아서 오류 화면을 보내드립니다. | T22 | 632×24 | HEIGHT / DISABLED / — / LEFT |
| [1100:20122](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20122) | 첨부 · 오류 화면.png | T10 | 660×20 | HEIGHT / DISABLED / — / LEFT |
| [I1102:9755;970:16602](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9755;970-16602) | 문의자에게 답변 보내기 | T7 | 816×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20143](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20143) | 첫 답변을 보내면 진행 중으로 바뀌어요. 종료 후 새 메시지로 다시 열 수 있어요. | T10 | 850×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20145](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20145) | 처리 정보 | T11 | 312×27 | HEIGHT / DISABLED / — / LEFT |
| [1100:20146](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20146) | 담당자 | T9 | 312×20 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20147;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20147;879-20075) | 미배정 | T5 | 280×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20148;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20148;879-20075) | 내가 맡기 | T5 | 108×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20149](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20149) | 라벨 · PRODUCT 내부용 | T9 | 312×20 | HEIGHT / DISABLED / — / LEFT |
| [I1102:9731;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9731;879-21410) | 출석 오류 | T20 | 47×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [I1102:9733;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9733;879-21410) | 정보 확인 | T20 | 47×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [I1100:20157;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20157;879-20075) | 라벨 편집 | T5 | 108×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20158](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20158) | 대표 질문 | T9 | 312×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20159](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20159) | 미분류 | T13 | 312×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20160;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20160;879-20075) | 대표 질문 연결 | T5 | 148×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20162](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20162) | 담당자 변경 이력 | T9 | 312×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20163](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20163) | 14:20 문의 접수 · 담당자 미배정 | T10 | 312×20 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:20104](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20104) | Action/문의 관리로 | 클릭 | Q1-admin · 문의 관리 |
| [1100:20109](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20109) | Action/문의 종료 | 클릭 | 운영 문의 상태 ← 종료 |
| [I1102:9755;970:16816](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9755;970-16816) | Icon/Circle(32px) | 클릭 | 운영 문의 상태 ← 진행 중 · 답변 보냄 ← True |
| [1100:20147](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20147) | Action/미배정  ▾ | 클릭 | 담당자 선택 열림 ← True · 라벨 선택 열림 ← False · 대표 질문 선택 열림 ← False |
| [1100:20148](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20148) | Action/내가 맡기 | 클릭 | 담당자 ← 이지원 · 배정 이력 ← 방금 · 이지원이 담당자를 이지원으로 변경 · 담당자 선택 열림 ← False |
| [1100:20157](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20157) | Action/라벨 편집 | 클릭 | 문의 팀 및 처리/라벨 편집 초안 1 ← 라벨 출석 오류 · 문의 팀 및 처리/라벨 편집 초안 2 ← 라벨 정보 확인 · 문의 팀 및 처리/라벨 편집 초안 3 ← 라벨 기능 요청 · 담당자 선택 열림 ← False · 라벨 선택 열림 ← True · 대표 질문 선택 열림 ← False |
| [1100:20160](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20160) | Action/대표 질문 연결 | 클릭 | 담당자 선택 열림 ← False · 라벨 선택 열림 ← False · 대표 질문 선택 열림 ← True |
| [1100:20195](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20195) | 담당자 메뉴 펼치기 | 클릭 | 담당자 선택 열림 ← True · 라벨 선택 열림 ← False · 대표 질문 선택 열림 ← False |

</details>

### Q6 · FAQ 관리

초안·발행·보관, 대표 질문 선택, 공개용 편집. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20225) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22142)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:20289](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20289) | FAQ 상태 필터 | 40,105 · 344×48 | H 8 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:20290](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20290) | Action/초안 | 0,0 · 112×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20291](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20291) | Action/발행 | 120,0 · 112×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20292](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20292) | Action/보관 | 240,0 · 104×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20293](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20293) | FAQ 관리 작업 공간 | 40,169 · 1282×658 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:20294](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20294) | FAQ 목록 | 0,0 · 330×658 | V 12 / 20,20,20,20 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:20296](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20296) | FAQ record/출석 기록이 실제와 다르게 보여요 | 20,59 · 290×83 | V 8 / 16,16,16,16 / MIN,MIN · FIXED/HUG | r10 · clip · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:20299](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20299) | FAQ record/앱에 로그인이 안 돼요 | 20,154 · 290×83 | V 8 / 16,16,16,16 / MIN,MIN · FIXED/HUG | r10 · clip |
| [1100:20308](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20308) | FAQ 편집 영역 | 354,0 · 928×658 | V 0 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1100:20309](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20309) | 공개용 FAQ 편집 | 0,0 · 928×658 | V 12 / 24,24,24,24 / MIN,MIN · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1100:20310](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20310) | Badge/수정 중 · 기존 발행본 공개 | 24,24 · 288×32 | H 0 / 0,0,0,0 / MIN,CENTER · FIXED/FIXED | r8 · clip |
| [1102:9737](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9737) | Tag/Basic | 0,0 · 288×32 | H 0 / 6,6,0,0 / CENTER,CENTER · FIXED/FIXED | r6 · 면 Semantic/Fill/Primary/Medium-100 |
| [1100:20313](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20313) | Question Input | 24,100 · 880×64 | V 8 / 16,16,16,16 / MIN,MIN · FIXED/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:20317](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20317) | Answer Input | 24,240 · 880×173 | V 8 / 16,16,16,16 / MIN,MIN · FIXED/FILL | r10 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weak) |
| [1100:20319](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20319) | 적용 범위 | 24,425 · 880×40 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1100:20320](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20320) | Dropdown / UMC 서비스 사용자 | 0,0 · 360×40 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | — |
| [1100:20321](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20321) | Action/UMC 서비스 사용자  ▾ | 0,-4 · 360×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FILL/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20322](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20322) | SF Symbol / chevron.down | 333.82,17.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Default |
| [1100:20323](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20323) | Dropdown / 출석·과제 | 372,0 · 260×40 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | — |
| [1100:20324](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20324) | Action/출석·과제  ▾ | 0,-4 · 260×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FILL/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20325](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20325) | SF Symbol / chevron.down | 233.82,17.13 · 10.18×5.73 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Default |
| [1100:20327](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20327) | Divider | 24,509 · 880×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:20330](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20330) | FAQ Publish Actions | 24,586 · 880×48 | H 12 / 0,0,0,0 / MAX,CENTER · FIXED/HUG | clip |
| [1100:20331](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20331) | Action alignment | 0,23.5 · 396×1 | V 0 / 0,0,0,0 / MIN,MIN · FILL/FIXED | clip |
| [1100:20332](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20332) | Action/초안 저장 | 408,0 · 156×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1100:20333](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20333) | Action/검증 후 발행 | 576,4 · 180×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:20334](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20334) | Action/보관 | 768,0 · 112×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:20286](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20286) | FAQ 관리 | T2 | 1118×40 | HEIGHT / DISABLED / — / LEFT |
| [1100:20287](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20287) | 문의에서 반복되는 질문을 공개용 답변으로 정리하고 검증하세요. | T3 | 1118×21 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20290;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20290;879-20075) | 초안 | T5 | 80×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20291;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20291;879-20075) | ✓ 발행 | T5 | 80×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20292;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20292;879-20075) | 보관 | T5 | 72×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20295](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20295) | 대표 질문 | T11 | 290×27 | HEIGHT / DISABLED / — / LEFT |
| [1100:20297](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20297) | 출석 기록이 실제와 다르게 보여요 | T29 | 258×23 | HEIGHT / DISABLED / — / LEFT |
| [1100:20298](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20298) | 발행 | T9 | 258×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20300](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20300) | 앱에 로그인이 안 돼요 | T29 | 258×23 | HEIGHT / DISABLED / — / LEFT |
| [I1102:9737;879:21410](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-9737;879-21410) | 수정 중 · 기존 발행본 공개 | T20 | 131×17 | WIDTH_AND_HEIGHT / DISABLED / — / CENTER |
| [1100:20312](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20312) | 공개용 질문 | T9 | 880×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20314](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20314) | 출석 기록이 실제와 다르게 보여요 | T30 | 848×27 | HEIGHT / DISABLED / — / LEFT |
| [1100:20315](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20315) | 별칭 · 출석 오류, 출석 정정, 결석 표시 | T10 | 880×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20316](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20316) | 공개용 답변 | T9 | 880×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20318](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20318) | 활동 메뉴를 새로고침하고 출석 상태를 확인해 주세요.<br>계속 잘못 표시되면 앱 버전·발생 시각·오류 화면을 UMC PRODUCT에 알려주세요. | T28 | 848×48 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20321;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20321;879-20075) | UMC 서비스 사용자 | T5 | 328×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20324;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20324;879-20075) | 출석·과제 | T5 | 228×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20326](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20326) | 종료일 · 지정 안 함    검증 조직 · UMC PRODUCT | T10 | 880×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20328](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20328) | 검증 확인 · 개인정보 없음 / 적용 범위 확인 / 답변 정확성 확인 | T9 | 880×20 | HEIGHT / DISABLED / — / LEFT |
| [1100:20329](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20329) | 검증 전까지 기존 발행본이 공개돼요. | T9 | 880×20 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20332;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20332;879-20075) | 초안 저장 | T5 | 124×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20333;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20333;879-20081) | 검증 후 발행 | T4 | 148×20 | HEIGHT / DISABLED / — / CENTER |
| [I1100:20334;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20334;879-20075) | 보관 | T5 | 80×20 | HEIGHT / DISABLED / — / CENTER |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:20290](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20290) | Action/초안 | 클릭 | FAQ 목록 상태 ← 초안 · FAQ 초안 선택 표시 ← ✓ 초안 · FAQ 발행 선택 표시 ← 발행 · FAQ 보관 선택 표시 ← 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 편집 표시 ← False · FAQ 선택 안내 표시 ← True |
| [1100:20291](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20291) | Action/발행 | 클릭 | FAQ 목록 상태 ← 발행 · FAQ 초안 선택 표시 ← 초안 · FAQ 발행 선택 표시 ← ✓ 발행 · FAQ 보관 선택 표시 ← 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 편집 표시 ← False · FAQ 선택 안내 표시 ← True |
| [1100:20292](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20292) | Action/보관 | 클릭 | FAQ 목록 상태 ← 보관 · FAQ 초안 선택 표시 ← 초안 · FAQ 발행 선택 표시 ← 발행 · FAQ 보관 선택 표시 ← ✓ 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 편집 표시 ← False · FAQ 선택 안내 표시 ← True |
| [1100:20296](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20296) | FAQ record/출석 기록이 실제와 다르게 보여요 | 클릭 | FAQ 선택 질문 ← 출석 기록이 실제와 다르게 보여요 · FAQ 편집 질문 ← 출석 기록이 실제와 다르게 보여요 · FAQ 편집 답변 ← 활동 메뉴를 새로고침하고 출석 상태를 확인해 주세요.<br>계속 잘못 표시되면 앱 버전·발생 시각·오류 화면을 UMC PRODUCT에 알려주세요. · FAQ 편집 별칭 ← 별칭 · 출석 오류, 출석 정정, 결석 표시 · FAQ 편집 적용 범위 ← UMC 서비스 사용자 · FAQ 편집 카테고리 ← 출석·과제 · FAQ 편집 검증 조직 ← 종료일 · 지정 안 함    검증 조직 · UMC PRODUCT · FAQ 편집 표시 ← True · FAQ 선택 안내 표시 ← False · 조건 충족 → FAQ 발행 상태 ← 수정 중 · 기존 발행본 공개, FAQ 저장 안내 ← 검증 전까지 기존 발행본이 공개돼요. · 조건 충족 → FAQ 발행 상태 ← 초안 · 미공개, FAQ 저장 안내 ← 초안은 검증 후 발행하기 전까지 공개되지 않아요. · 조건 충족 → FAQ 발행 상태 ← 보관 · 공개 제외, FAQ 저장 안내 ← 보관한 답변은 공개·추천·순위에서 제외돼요. |
| [1100:20299](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20299) | FAQ record/앱에 로그인이 안 돼요 | 클릭 | FAQ 선택 질문 ← 앱에 로그인이 안 돼요 · FAQ 편집 질문 ← 앱에 로그인이 안 돼요 · FAQ 편집 답변 ← 로그인이 어려우면 계정 정보와 네트워크 연결을 먼저 확인해 주세요.<br>비밀번호나 인증 코드는 문의에 첨부하지 마세요. · FAQ 편집 별칭 ← 별칭 · 로그인 실패, 계정 오류 · FAQ 편집 적용 범위 ← UMC 서비스 사용자 · FAQ 편집 카테고리 ← 계정·로그인 · FAQ 편집 검증 조직 ← 종료일 · 지정 안 함    검증 조직 · UMC PRODUCT · FAQ 편집 표시 ← True · FAQ 선택 안내 표시 ← False · 조건 충족 → FAQ 발행 상태 ← 수정 중 · 기존 발행본 공개, FAQ 저장 안내 ← 검증 전까지 기존 발행본이 공개돼요. · 조건 충족 → FAQ 발행 상태 ← 초안 · 미공개, FAQ 저장 안내 ← 초안은 검증 후 발행하기 전까지 공개되지 않아요. · 조건 충족 → FAQ 발행 상태 ← 보관 · 공개 제외, FAQ 저장 안내 ← 보관한 답변은 공개·추천·순위에서 제외돼요. |
| [1100:20332](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20332) | Action/초안 저장 | 클릭 | 조건 충족 → FAQ 저장 안내 ← 초안을 저장했어요. 기존 발행본은 계속 공개돼요. · 조건 그 외 → FAQ 저장 안내 ← 초안을 저장했어요. 검증 후 발행할 수 있어요. |
| [1100:20333](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20333) | Action/검증 후 발행 | 클릭 | 조건 충족 → FAQ 레코드 상태 출석 기록이 실제와 다르게 보여요 ← 발행 · 조건 충족 → FAQ 레코드 상태 앱에 로그인이 안 돼요 ← 발행 · 조건 충족 → FAQ 레코드 상태 알림이 오지 않아요 ← 발행 · 조건 충족 → FAQ 레코드 상태 이전 버전의 로그인 오류 안내 ← 발행 · FAQ 목록 상태 ← 발행 · FAQ 초안 선택 표시 ← 초안 · FAQ 발행 선택 표시 ← ✓ 발행 · FAQ 보관 선택 표시 ← 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 발행 상태 ← 발행 · 새 검증본 공개 · FAQ 저장 안내 ← 검증된 새 답변을 발행했어요. |
| [1100:20334](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20334) | Action/보관 | 클릭 | 조건 충족 → FAQ 레코드 상태 출석 기록이 실제와 다르게 보여요 ← 보관 · 조건 충족 → FAQ 레코드 상태 앱에 로그인이 안 돼요 ← 보관 · 조건 충족 → FAQ 레코드 상태 알림이 오지 않아요 ← 보관 · 조건 충족 → FAQ 레코드 상태 이전 버전의 로그인 오류 안내 ← 보관 · FAQ 목록 상태 ← 보관 · FAQ 초안 선택 표시 ← 초안 · FAQ 발행 선택 표시 ← 발행 · FAQ 보관 선택 표시 ← ✓ 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 발행 상태 ← 보관 · 공개 제외 · FAQ 저장 안내 ← 공개·검색·추천·순위에서 제외했어요. |

</details>

### 문의 도구 · 사용자 · 펼침

Q1 위 도구 팝오버, 닫기·검색·새 문의·바로가기. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20370) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22287)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:20502](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20502) | 탭 도구 모음 · 바깥 클릭 닫기 | 0,52 · 1348×884 | — · FIXED/FIXED | 면 ffffff@0.0010000000474974513 |
| [1100:20503](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20503) | 탭 도구 모음 · inquiry | 938,63 · 390×371 | V 14 / 20,20,20,20 / MIN,MIN · FIXED/HUG | r16 · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White · 그림자 #000000 / 13%, offset (0,8), blur 24, spread 0, NORMAL, showShadowBehindNode=true |
| [1100:20504](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20504) | 도구 제목과 닫기 | 20,20 · 348×32 | H 8 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | — |
| [1100:20506](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20506) | 도구 모음 닫기 · Esc | 316,0 · 32×32 | H 0 / 8,8,8,8 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1100:20507](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20507) | 닫기 | 8,8 · 16×16 | — · FIXED/FIXED | 선 1.600000023841858 Semantic/Text/Neutral-Medium-600 |
| [1100:20509](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20509) | 검색 · 도움말 검색 | 20,97 · 348×40 | H 10 / 12,12,12,12 / MIN,CENTER · FIXED/FIXED | r8 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1100:20510](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20510) | 검색 | 12,12 · 16×16 | — · FIXED/FIXED | 선 1.600000023841858 Semantic/Text/Neutral-Medium-600 |
| [1100:20513](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20513) | 동작 · 새 문의 작성 | 20,151 · 348×40 | H 0 / 16,16,4,4 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:20514](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20514) | 도구 구분선 | 20,205 · 348×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:20515](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20515) | 도구 그룹 · 도움말과 내 문의 | 20,220 · 348×101 | V 2 / 0,0,0,0 / MIN,MIN · FIXED/HUG | — |
| [1100:20517](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20517) | 도구 작업 · 많이 묻는 질문 | 0,19 · 348×40 | H 12 / 12,12,12,12 / MIN,CENTER · FIXED/FIXED | r8 |
| [1100:20519](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20519) | SF Symbol / chevron.right | 322,14.91 · 5.73×10.17 | — · FIXED/FIXED | 면 Semantic/Text/Neutral-Medium-600 |
| [1100:20520](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20520) | 도구 작업 · 내 문의 현황 | 0,61 · 348×40 | H 12 / 12,12,12,12 / MIN,CENTER · FIXED/FIXED | r8 |
| [1100:20523](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20523) | 도구 단축키 | 20,335 · 348×16 | H 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | — |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:20505](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20505) | 문의 도구 | T31 | 308×23 | HEIGHT / DISABLED / — / LEFT |
| [1100:20508](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20508) | 답을 찾아보고 내 문의를 이어가세요. | T32 | 348×17 | HEIGHT / DISABLED / — / LEFT |
| [1100:20511](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20511) | 도움말 검색 | T33 | 254×19 | HEIGHT / DISABLED / — / LEFT |
| [1100:20512](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20512) | ⌘F | T34 | 18×16 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [I1100:20513;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20513;879-20081) | 새 문의 작성 | T4 | 316×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20516](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20516) | 도움말과 내 문의 | T35 | 348×17 | HEIGHT / DISABLED / — / LEFT |
| [1100:20518](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20518) | 많이 묻는 질문 | T36 | 298×19 | HEIGHT / DISABLED / — / LEFT |
| [1100:20521](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20521) | 내 문의 현황 | T36 | 298×19 | HEIGHT / DISABLED / — / LEFT |
| [1100:20524](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20524) | 상단 도구 버튼으로 다시 열 수 있어요 | T37 | 296×16 | HEIGHT / DISABLED / — / LEFT |
| [1100:20525](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20525) | Esc | T34 | 18×16 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:20423](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20423) | 탭 도구 모음 열기 · 문의 도구 | 클릭 | 문의 도구 펼침 예시/사용자 ← NOT |
| [1100:20433](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20433) | Action/문의하기 | 클릭 | tools/inquiry ← False · FAQ에서 문의 ← False · 작성 중 답변 열람 ← False · 작성 문의 FAQ q ← 출석 기록이 실제와 다르게 보여요 · 작성 문의 FAQ meta ← 출석·과제 · UMC 서비스 · 작성 문의 FAQ intro ← 활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요. · 작성 문의 FAQ steps ← 1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.<br><br>2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.<br><br>3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요. · 작성 문의 FAQ warning ← UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요. · 작성 문의 FAQ scope ← 적용 대상<br>UMC 서비스 사용자 · 작성 문의 FAQ org ← 검증한 조직<br>UMC PRODUCT · 작성 문의 FAQ related ← 관련 안내<br>출석 화면 오류 안내 · 작성 문의 카테고리 ← 출석·과제 · 작성 문의 내용 ← 앱에서 출석 기록이 실제와 다르게 표시돼요.<br>새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다. · 작성 문의 첨부 ← 오류 화면.png  ·  첨부 변경 · 작성 문의 담당 조직 ← 담당 조직  UMC PRODUCT    ·    담당자  이지원 · 작성 문의 추천 조직 ← 검증된 답변 · UMC PRODUCT · Q3 · 문의 등록 |
| [1100:20436](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20436) | Action/내 문의 | 클릭 | tools/inquiry ← False · Q1-empty · 내 문의 |
| [1100:20439](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20439) | Action/검색 | 클릭 | tools/inquiry ← False · Q1-search · 검색어 선택 |
| [1100:20449](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20449) | Rank 1 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20456](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20456) | Rank 2 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20463](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20463) | Rank 3 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20470](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20470) | Rank 4 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20477](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20477) | Rank 5 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20489](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20489) | Action/출석·과제 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20490](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20490) | Action/계정·로그인 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20492](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20492) | Action/프로젝트·매칭 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20493](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20493) | Action/활동 증명 | 클릭 | 선택한 질문의 공개 FAQ 내용 설정 → Q4 · FAQ 상세 |
| [1100:20502](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20502) | 탭 도구 모음 · 바깥 클릭 닫기 | 클릭 | 문의 도구 펼침 예시/사용자 ← False |
| [1100:20503](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20503) | 탭 도구 모음 · inquiry | {'type': 'ON_KEY_DOWN', 'device': 'KEYBOARD', 'keyCodes': [27]} | 문의 도구 펼침 예시/사용자 ← False |
| [1100:20506](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20506) | 도구 모음 닫기 · Esc | 클릭 | 문의 도구 펼침 예시/사용자 ← False |
| [1100:20509](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20509) | 검색 · 도움말 검색 | 클릭 | tools/inquiry ← False · Q1-search · 검색어 선택 |
| [1100:20513](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20513) | 동작 · 새 문의 작성 | 클릭 | tools/inquiry ← False · 문의 도구 펼침 예시/사용자 ← False · Q3 · 문의 등록 |
| [1100:20517](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20517) | 도구 작업 · 많이 묻는 질문 | 클릭 | tools/inquiry ← False · 문의 도구 펼침 예시/사용자 ← False · Q1 · 많이 묻는 질문 |
| [1100:20520](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20520) | 도구 작업 · 내 문의 현황 | 클릭 | tools/inquiry ← False · 문의 도구 펼침 예시/사용자 ← False · Q1-empty · 내 문의 |

</details>

### 문의 도구 · UMC PRODUCT · 펼침

Q1-admin 위 운영 도구 팝오버, FAQ·목록·선택 문의. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20539) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22456)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1100:20762](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20762) | 탭 도구 모음 · inquiry_ops | 938,63 · 390×359 | V 14 / 20,20,20,20 / MIN,MIN · FIXED/HUG | r16 · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White · 그림자 #000000 / 13%, offset (0,8), blur 24, spread 0, NORMAL, showShadowBehindNode=true |
| [1100:20768](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20768) | 동작 · FAQ 작성 · 관리 | 20,97 · 348×40 | H 0 / 16,16,4,4 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1100:20769](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20769) | 도구 구분선 | 20,151 · 348×1 | — · FIXED/FIXED | 면 Semantic/Border/Neutral/Weaker-100 |
| [1100:20770](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20770) | 도구 그룹 · UMC PRODUCT 전용 | 20,166 · 348×143 | V 2 / 0,0,0,0 / MIN,MIN · FIXED/HUG | — |
| [1100:20772](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20772) | 도구 작업 · 문의 관리 목록 | 0,19 · 348×40 | H 12 / 12,12,12,12 / MIN,CENTER · FIXED/FIXED | r8 |
| [1100:20775](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20775) | 도구 작업 · 선택한 문의 확인 | 0,61 · 348×40 | H 12 / 12,12,12,12 / MIN,CENTER · FIXED/FIXED | r8 |
| [1100:20778](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20778) | 도구 작업 · 많이 묻는 질문 보기 | 0,103 · 348×40 | H 12 / 12,12,12,12 / MIN,CENTER · FIXED/FIXED | r8 |
| [1100:20781](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20781) | 도구 단축키 | 20,323 · 348×16 | H 8 / 0,0,0,0 / MIN,MIN · FIXED/HUG | — |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1100:20764](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20764) | 문의 관리 도구 | T31 | 308×23 | HEIGHT / DISABLED / — / LEFT |
| [1100:20767](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20767) | UMC PRODUCT 구성원만 사용할 수 있는 관리 도구예요. | T32 | 348×17 | HEIGHT / DISABLED / — / LEFT |
| [I1100:20768;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1100-20768;879-20081) | FAQ 작성 · 관리 | T4 | 316×20 | HEIGHT / DISABLED / — / CENTER |
| [1100:20771](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20771) | UMC PRODUCT 전용 | T35 | 348×17 | HEIGHT / DISABLED / — / LEFT |
| [1100:20773](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20773) | 문의 관리 목록 | T36 | 298×19 | HEIGHT / DISABLED / — / LEFT |
| [1100:20776](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20776) | 선택한 문의 확인 | T36 | 298×19 | HEIGHT / DISABLED / — / LEFT |
| [1100:20779](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20779) | 많이 묻는 질문 보기 | T36 | 298×19 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1100:20592](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20592) | 탭 도구 모음 열기 · 문의 관리 도구 | 클릭 | 문의 도구 펼침 예시/PRODUCT ← NOT |
| [1100:20602](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20602) | Action/FAQ 관리 | 클릭 | tools/inquiry_ops ← False · Q6 · FAQ 관리 |
| [1100:20629](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20629) | Inquiry/출석 기록이 실제와 다르게 보여요 | 클릭 | tools/inquiry_ops ← False · Q5 · 운영 문의 상세 |
| [1100:20760](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20760) | Action/FAQ 초안 작성 | 클릭 | tools/inquiry_ops ← False · FAQ 목록 상태 ← 초안 · FAQ 초안 선택 표시 ← ✓ 초안 · FAQ 발행 선택 표시 ← 발행 · FAQ 보관 선택 표시 ← 보관 · 조건 충족 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← True · 조건 그 외 → FAQ 레코드 표시 출석 기록이 실제와 다르게 보여요 ← False · 조건 충족 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← True · 조건 그 외 → FAQ 레코드 표시 앱에 로그인이 안 돼요 ← False · 조건 충족 → FAQ 레코드 표시 알림이 오지 않아요 ← True · 조건 그 외 → FAQ 레코드 표시 알림이 오지 않아요 ← False · 조건 충족 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← True · 조건 그 외 → FAQ 레코드 표시 이전 버전의 로그인 오류 안내 ← False · FAQ 선택 질문 ← 알림이 오지 않아요 · FAQ 편집 질문 ← 알림이 오지 않아요 · FAQ 편집 답변 ← 기기의 알림 권한과 앱의 알림 설정을 확인해 주세요.<br>계속 알림이 오지 않으면 앱 버전과 발생 시각을 UMC PRODUCT에 알려주세요. · FAQ 편집 별칭 ← 별칭 · 알림 누락, 푸시 오류 · FAQ 편집 적용 범위 ← UMC 서비스 사용자 · FAQ 편집 카테고리 ← 알림 · FAQ 편집 검증 조직 ← 종료일 · 지정 안 함    검증 조직 · UMC PRODUCT · FAQ 편집 표시 ← True · FAQ 선택 안내 표시 ← False · 조건 충족 → FAQ 발행 상태 ← 수정 중 · 기존 발행본 공개, FAQ 저장 안내 ← 검증 전까지 기존 발행본이 공개돼요. · 조건 그 외 → FAQ 발행 상태 ← 초안 · 미공개, FAQ 저장 안내 ← 초안은 검증 후 발행하기 전까지 공개되지 않아요. · Q6 · FAQ 관리 |
| [1100:20761](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20761) | 탭 도구 모음 · 바깥 클릭 닫기 | 클릭 | 문의 도구 펼침 예시/PRODUCT ← False |
| [1100:20762](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20762) | 탭 도구 모음 · inquiry_ops | {'type': 'ON_KEY_DOWN', 'device': 'KEYBOARD', 'keyCodes': [27]} | 문의 도구 펼침 예시/PRODUCT ← False |
| [1100:20765](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20765) | 도구 모음 닫기 · Esc | 클릭 | 문의 도구 펼침 예시/PRODUCT ← False |
| [1100:20768](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20768) | 동작 · FAQ 작성 · 관리 | 클릭 | tools/inquiry_ops ← False · 문의 도구 펼침 예시/PRODUCT ← False · Q6 · FAQ 관리 |
| [1100:20772](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20772) | 도구 작업 · 문의 관리 목록 | 클릭 | tools/inquiry_ops ← False · 문의 도구 펼침 예시/PRODUCT ← False · Q1-admin · 문의 관리 |
| [1100:20775](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20775) | 도구 작업 · 선택한 문의 확인 | 클릭 | tools/inquiry_ops ← False · 문의 도구 펼침 예시/PRODUCT ← False · Q5 · 운영 문의 상세 |
| [1100:20778](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20778) | 도구 작업 · 많이 묻는 질문 보기 | 클릭 | tools/inquiry_ops ← False · 문의 도구 펼침 예시/PRODUCT ← False · Q1 · 많이 묻는 질문 |

</details>

### Q3 · 받는 팀 선택 · 열린 상태

Q3 위 딤과 두 열 선택창, 선택/취소 → Q3. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9857) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10080)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1102:9979](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9979) | 받는 팀 선택 / 모달 | 0,0 · 1440×960 | V 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | clip · 면 Custom/Background/Dimmed |
| [1102:9980](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9980) | 받는 팀 선택 | 312,186.5 · 816×587 | V 20 / 24,24,24,24 / MIN,MIN · FIXED/HUG | r16 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-White |
| [1102:9981](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9981) | 선택창 제목 | 25,25 · 766×37 | H 0 / 0,0,0,0 / SPACE_BETWEEN,CENTER · FILL/HUG | clip |
| [1102:9983](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9983) | 취소 | 716,0 · 50×37 | H 0 / 12,12,10,10 / MIN,MIN · HUG/HUG | clip |
| [1102:9986](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9986) | 팀 선택 행 1 | 25,118 · 766×96 | H 12 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1102:9987](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9987) | Brand & Growth | 0,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:9988](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9988) | 팀 이름 및 선택 상태 | 15,15 · 347×17 | H 0 / 0,0,0,0 / SPACE_BETWEEN,CENTER · FILL/HUG | clip |
| [1102:9992](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9992) | Learning & Activity | 389,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:9997](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9997) | 팀 선택 행 2 | 25,234 · 766×96 | H 12 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1102:9998](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9998) | Community & Connection | 0,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10003](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10003) | Operations Enablement | 389,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10008](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10008) | 팀 선택 행 3 | 25,350 · 766×96 | H 12 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1102:10009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10009) | Platform | 0,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10014](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10014) | Design Platform | 389,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10019](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10019) | 팀 선택 행 4 | 25,466 · 766×96 | H 12 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1102:10020](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10020) | Infrastructure | 0,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10025](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10025) | 어느 팀인지 모르겠어요 | 389,0 · 377×96 | V 8 / 14,14,14,14 / MIN,MIN · FILL/FIXED | r10 · clip · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-Grey(Weaker) |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1102:9982](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9982) | 어느 팀에 문의할까요? | T38 | 185×24 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:9984](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9984) | 취소 | T39 | 26×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:9985](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9985) | 문의와 가까운 팀을 하나 선택하면 문의 작성 화면에 반영돼요. | T21 | 326×16 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:9989](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9989) | Brand & Growth | T39 | 107×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:9991](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9991) | 모집·선발, 공식 홈페이지, 테크 블로그 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:9994](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9994) | Learning & Activity | T39 | 125×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:9996](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9996) | 워크북·미션, 활동 참여, 출석·수료, UPMS | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:10000](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10000) | Community & Connection | T39 | 172×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10002](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10002) | 커뮤니티·Connect, 프로필·전자명함, 채팅 이용 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:10005](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10005) | Operations Enablement | T39 | 159×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10007](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10007) | 기수·조직·역할 관리, 공지, 출석·운영 승인 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:10011](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10011) | Platform | T39 | 59×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10013](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10013) | 로그인·인증, 알림·채팅 전달 오류, 공통 폼 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:10016](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10016) | Design Platform | T39 | 108×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10018](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10018) | 디자인 시스템, Figma 라이브러리·토큰 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:10022](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10022) | Infrastructure | T39 | 93×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10024](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10024) | 배포·실행 환경, 장애·모니터링 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |
| [1102:10027](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10027) | 어느 팀인지 모르겠어요 | T39 | 136×17 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10029](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10029) | UMC PRODUCT에서 담당 팀을 확인해요 | T27 | 350×14 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1102:9979](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9979) | 받는 팀 선택 / 모달 | {'type': 'ON_KEY_DOWN', 'device': 'KEYBOARD', 'keyCodes': [27]} | 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:9983](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9983) | 취소 | 클릭 | 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:9987](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9987) | Brand & Growth | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Brand & Growth · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Brand & Growth · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:9992](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9992) | Learning & Activity | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Learning & Activity · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Learning & Activity · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:9998](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9998) | Community & Connection | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Community & Connection · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Community & Connection · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:10003](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10003) | Operations Enablement | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Operations Enablement · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Operations Enablement · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:10009](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10009) | Platform | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Platform · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Platform · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:10014](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10014) | Design Platform | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Design Platform · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Design Platform · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:10020](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10020) | Infrastructure | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← Infrastructure · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← Infrastructure · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← False · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |
| [1102:10025](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10025) | 어느 팀인지 모르겠어요 | 클릭 | 문의 팀 및 처리/접수 팀 선택값 ← 담당 팀 확인 중 · 문의 팀 및 처리/문의 받는 팀 / 작성 중 ← 어느 팀인지 모르겠어요 · 문의 팀 및 처리/문의 받는 팀 / 선택 완료 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택 Brand & Growth ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Learning & Activity ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Community & Connection ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Operations Enablement ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Design Platform ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 Infrastructure ← False · 문의 팀 및 처리/문의 받는 팀 / 선택 어느 팀인지 모르겠어요 ← True · 문의 팀 및 처리/문의 받는 팀 / 선택창 열림 ← False · Q3 · 문의 등록 |

</details>

### Q5 · 담당자 선택 · 열린 상태

Q5의 처리 정보 위 담당자 메뉴, 선택/취소 → Q5. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10303) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10553)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1102:10431](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10431) | Menu/담당자 | 24,143 · 312×293 | V 8 / 16,16,16,16 / MIN,MIN · FIXED/HUG | r12 · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-White |
| [1102:10434](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10434) | Action/이지원 | 16,73 · 80×48 | H 0 / 16,16,2,2 / CENTER,CENTER · HUG/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1102:10435](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10435) | Action/김지원 | 16,129 · 80×48 | H 0 / 16,16,2,2 / CENTER,CENTER · HUG/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1102:10436](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10436) | Action/미배정 | 16,185 · 82×48 | H 0 / 16,16,2,2 / CENTER,CENTER · HUG/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1102:10437](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10437) | 담당자 메뉴 취소 | 16,241 · 280×36 | H 0 / 0,0,8,8 / CENTER,CENTER · FILL/FIXED | clip |
| [1102:10487](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10487) | App shell · native titlebar · 40pt preview | 4,0 · 1440×40 | H 12 / 12,0,0,0 / MIN,CENTER · FIXED/FIXED | clip · 면 Custom/Background/App Shell |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1102:10432](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10432) | 담당자 선택 | T40 | 280×21 | HEIGHT / DISABLED / — / LEFT |
| [1102:10433](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10433) | 문의 관리 권한이 있는 UMC PRODUCT 구성원 | T10 | 280×20 | HEIGHT / DISABLED / — / LEFT |
| [I1102:10434;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-10434;879-20075) | 이지원 | T5 | 48×20 | HEIGHT / DISABLED / — / CENTER |
| [I1102:10435;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-10435;879-20075) | 김지원 | T5 | 48×20 | HEIGHT / DISABLED / — / CENTER |
| [I1102:10436;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-10436;879-20075) | 배정 해제 | T5 | 50×20 | HEIGHT / DISABLED / — / CENTER |
| [1102:10438](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10438) | 취소 | T21 | 24×16 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1102:10412](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10412) | Action/내가 맡기 | 클릭 | 담당자 ← 이지원 · 배정 이력 ← 방금 · 이지원이 담당자를 이지원으로 변경 · 담당자 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10424](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10424) | Action/라벨 편집 | 클릭 | 문의 팀 및 처리/라벨 편집 초안 1 ← 라벨 출석 오류 · 문의 팀 및 처리/라벨 편집 초안 2 ← 라벨 정보 확인 · 문의 팀 및 처리/라벨 편집 초안 3 ← 라벨 기능 요청 · 담당자 선택 열림 ← False · 라벨 선택 열림 ← True · 대표 질문 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10427](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10427) | Action/대표 질문 연결 | 클릭 | 담당자 선택 열림 ← False · 라벨 선택 열림 ← False · 대표 질문 선택 열림 ← True · Q5 · 운영 문의 상세 |
| [1102:10431](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10431) | Menu/담당자 | {'type': 'ON_KEY_DOWN', 'device': 'KEYBOARD', 'keyCodes': [27]} | 담당자 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10434](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10434) | Action/이지원 | 클릭 | 담당자 ← 이지원 · 배정 이력 ← 방금 · 이지원이 담당자를 이지원으로 변경 · 담당자 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10435](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10435) | Action/김지원 | 클릭 | 담당자 ← 김지원 · 배정 이력 ← 방금 · 이지원이 담당자를 김지원으로 변경 · 담당자 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10436](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10436) | Action/미배정 | 클릭 | 담당자 ← 미배정 · 배정 이력 ← 방금 · 이지원이 담당자를 미배정으로 변경 · 담당자 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10437](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10437) | 담당자 메뉴 취소 | 클릭 | 담당자 선택 열림 ← False · Q5 · 운영 문의 상세 |

</details>

### Q5 · 라벨 편집 · 열린 상태

Q5의 처리 정보 위 체크 목록, 적용/취소 → Q5. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10803) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-11051)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1102:10939](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10939) | Menu/라벨 | 24,323 · 312×313 | V 8 / 16,16,16,16 / MIN,MIN · FIXED/HUG | r12 · 선 1 Semantic/Border/Neutral/Medium-300 · 면 Custom/Background/Surface-White |
| [1102:10941](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10941) | 선택/출석 오류 | 16,45 · 280×36 | H 12 / 8,8,8,8 / MIN,CENTER · FILL/HUG | r12 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10943](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10943) | 선택 표시 영역 | 252,8 · 20×20 | H 0 / 0,0,0,0 / CENTER,CENTER · FIXED/FIXED | r4 · clip · 선 1 Semantic/Text/Neutral-Medium-600 |
| [1102:10945](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10945) | 선택/정보 확인 | 16,89 · 280×36 | H 12 / 8,8,8,8 / MIN,CENTER · FILL/HUG | r12 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10949](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10949) | 선택/기능 요청 | 16,133 · 280×36 | H 12 / 8,8,8,8 / MIN,CENTER · FILL/HUG | r12 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-Grey(Weaker) |
| [1102:10953](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10953) | Action/적용 | 16,177 · 80×48 | H 0 / 16,16,2,2 / CENTER,CENTER · HUG/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1102:10955](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10955) | 라벨 편집 취소 | 16,261 · 280×36 | H 0 / 0,0,8,8 / CENTER,CENTER · FILL/FIXED | clip |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1102:10940](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10940) | 라벨 선택 · 복수 선택 가능 | T40 | 280×21 | HEIGHT / DISABLED / — / LEFT |
| [1102:10942](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10942) | 출석 오류 | T41 | 232×19 | HEIGHT / DISABLED / — / LEFT |
| [1102:10944](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10944) | ✓ | T13 | 10×21 | WIDTH_AND_HEIGHT / DISABLED / — / LEFT |
| [1102:10946](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10946) | 정보 확인 | T41 | 232×19 | HEIGHT / DISABLED / — / LEFT |
| [1102:10950](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10950) | 기능 요청 | T41 | 232×19 | HEIGHT / DISABLED / — / LEFT |
| [I1102:10953;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1102-10953;879-20075) | 적용 | T5 | 48×20 | HEIGHT / DISABLED / — / CENTER |
| [1102:10954](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10954) | 라벨은 UMC PRODUCT 내부에서만 보여요. | T10 | 280×20 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1102:10911](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10911) | Action/미배정  ▾ | 클릭 | 담당자 선택 열림 ← True · 라벨 선택 열림 ← False · 대표 질문 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10939](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10939) | Menu/라벨 | {'type': 'ON_KEY_DOWN', 'device': 'KEYBOARD', 'keyCodes': [27]} | 라벨 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10941](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10941) | 선택/출석 오류 | 클릭 | 문의 팀 및 처리/라벨 편집 초안 1 ← NOT |
| [1102:10945](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10945) | 선택/정보 확인 | 클릭 | 문의 팀 및 처리/라벨 편집 초안 2 ← NOT |
| [1102:10949](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10949) | 선택/기능 요청 | 클릭 | 문의 팀 및 처리/라벨 편집 초안 3 ← NOT |
| [1102:10953](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10953) | Action/적용 | 클릭 | 라벨 출석 오류 ← 문의 팀 및 처리/라벨 편집 초안 1 · 라벨 정보 확인 ← 문의 팀 및 처리/라벨 편집 초안 2 · 라벨 기능 요청 ← 문의 팀 및 처리/라벨 편집 초안 3 · 라벨 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10955](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10955) | 라벨 편집 취소 | 클릭 | 라벨 선택 열림 ← False · Q5 · 운영 문의 상세 |
| [1102:10962](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10962) | 담당자 메뉴 펼치기 | 클릭 | 담당자 선택 열림 ← True · 라벨 선택 열림 ← False · 대표 질문 선택 열림 ← False · Q5 · 운영 문의 상세 |

</details>

### Q1-search · 검색어 선택

출석·과제 → 결과, 영수증 → 빈 결과. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19842) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20223)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1112:19905](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19905) | Action/많이 묻는 질문 | 1138,12.5 · 144×40 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Primary-Inverse/Stronger-600 |
| [1112:19909](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19909) | 검색어 예시 | 40,105 · 1282×722 | V 16 / 40,40,40,40 / CENTER,CENTER · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1112:19912](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19912) | Actions | 473,384.5 · 336×48 | H 12 / 0,0,0,0 / MIN,CENTER · FIXED/HUG | clip |
| [1112:19913](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19913) | Action/출석·과제 | 0,0 · 144×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Primitives/Teal/Teal-500 |
| [1112:19914](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19914) | Action/영수증 | 156,0 · 144×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 면 Semantic/Fill/Neutral-Inverse/Strong-600 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1112:19903](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19903) | FAQ 검색 | T2 | 1122×40 | HEIGHT / DISABLED / — / LEFT |
| [1112:19904](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19904) | 서비스 이용 중 궁금한 내용을 찾아보세요. | T3 | 1122×21 | HEIGHT / DISABLED / — / LEFT |
| [I1112:19905;879:20081](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-19905;879-20081) | 많이 묻는 질문 | T4 | 112×20 | HEIGHT / DISABLED / — / CENTER |
| [1112:19910](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19910) | 어떤 내용을 찾으시나요? | T2 | 900×40 | HEIGHT / DISABLED / — / CENTER |
| [1112:19911](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19911) | 예시 검색어를 선택해 FAQ를 찾아보세요. | T19 | 900×23 | HEIGHT / DISABLED / — / CENTER |
| [I1112:19913;879:20071](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-19913;879-20071) | 출석·과제 | T42 | 148×20 | HEIGHT / DISABLED / — / CENTER |
| [I1112:19914;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-19914;879-20075) | 영수증 | T43 | 112×20 | HEIGHT / DISABLED / — / CENTER |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1112:19913](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19913) | Action/출석·과제 | 클릭 | Q1-search · 검색 결과 |
| [1112:19914](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19914) | Action/영수증 | 클릭 | Q1-search · 검색 결과 없음 |

</details>

### Q1-search · 검색 결과

두 결과 → Q4, 다시 검색 → 검색어 선택. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-19949) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20330)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1112:20020](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20020) | FAQ 탐색 | 40,105 · 1282×722 | H 24 / 0,0,0,0 / MIN,MIN · FIXED/FILL | clip |
| [1112:20021](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20021) | 검색 결과 | 0,0 · 1282×722 | V 8 / 0,0,0,0 / MIN,MIN · FILL/FILL | clip |
| [1112:20022](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20022) | Rank Header | 0,0 · 1282×48 | H 12 / 0,0,0,0 / MIN,CENTER · FILL/HUG | clip |
| [1112:20024](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20024) | Action/다시 검색 | 1156,0 · 126×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |
| [1112:20029](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20029) | 검색 결과 · 출석 기록이 실제와 다르게 보여요 | 0,56 · 1282×80 | H 20 / 16,16,6,6 / MIN,CENTER · FILL/FIXED | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |
| [1112:20032](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20032) | 질문 | 16,16 · 1074×48 | V 2 / 0,0,0,0 / MIN,MIN · FILL/HUG | clip |
| [1112:20043](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20043) | 검색 결과 · 과제 파일이 업로드되지 않아요 | 0,144 · 1282×80 | H 20 / 16,16,6,6 / MIN,CENTER · FILL/FIXED | clip · 선 개별 변(통합 굵기 미확인) Semantic/Border/Neutral/Weaker-100 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1112:20011](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20011) | 검색어 · 출석·과제 | T3 | 1122×21 | HEIGHT / DISABLED / — / LEFT |
| [1112:20023](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20023) | 검색 결과 2건 | T8 | 1144×33 | HEIGHT / DISABLED / — / LEFT |
| [I1112:20024;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-20024;879-20075) | 다시 검색 | T5 | 94×20 | HEIGHT / DISABLED / — / CENTER |
| [1112:20033](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20033) | 출석 기록이 실제와 다르게 보여요 | T12 | 1074×26 | HEIGHT / DISABLED / — / LEFT |
| [1112:20034](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20034) | 출석·과제 · UMC 서비스 | T10 | 1074×20 | HEIGHT / DISABLED / — / LEFT |
| [1112:20035](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20035) | 답변 보기 | T13 | 156×21 | HEIGHT / DISABLED / — / RIGHT |
| [1112:20047](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20047) | 과제 파일이 업로드되지 않아요 | T12 | 1074×26 | HEIGHT / DISABLED / — / LEFT |

</details>

<details><summary>프로토타입 반응</summary>

| 노드 | 요소 | 트리거 | 결과·변수 |
| --- | --- | --- | --- |
| [1112:20024](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20024) | Action/다시 검색 | 클릭 | Q1-search · 검색어 선택 |
| [1112:20029](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20029) | 검색 결과 · 출석 기록이 실제와 다르게 보여요 | 클릭 | 공개 FAQ q ← 출석 기록이 실제와 다르게 보여요 · 공개 FAQ meta ← 출석·과제 · UMC 서비스 · 공개 FAQ intro ← 활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요. · 공개 FAQ steps ← 1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.<br><br>2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.<br><br>3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요. · 공개 FAQ warning ← UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요. · 공개 FAQ scope ← 적용 대상<br>UMC 서비스 사용자 · 공개 FAQ org ← 검증한 조직<br>UMC PRODUCT · 공개 FAQ related ← 관련 안내<br>출석 화면 오류 안내 · 작성 중 답변 열람 ← False · 해결 응답 ← False · Q4 · FAQ 상세 |
| [1112:20043](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20043) | 검색 결과 · 과제 파일이 업로드되지 않아요 | 클릭 | 공개 FAQ q ← 과제 파일이 업로드되지 않아요 · 공개 FAQ meta ← 출석·과제 · UMC 서비스 · 공개 FAQ intro ← 과제 파일을 올릴 수 없다면 파일 형식·용량과 네트워크 상태를 확인해 주세요. · 공개 FAQ steps ← 1. 파일 형식·용량과 네트워크 상태를 확인해 주세요.<br><br>2. 앱을 새로고침하고 업로드를 다시 시도해 주세요.<br><br>3. 계속 실패하면 오류 화면과 발생 시각을 UMC PRODUCT에 알려주세요. · 공개 FAQ warning ← UMC PRODUCT는 업로드 오류를 확인해 드려요. 제출 기한 연장이나 인정 여부는 처리하지 않아요. · 공개 FAQ scope ← 적용 대상<br>UMC 서비스 사용자 · 공개 FAQ org ← 검증한 조직<br>UMC PRODUCT · 공개 FAQ related ← 관련 안내<br>과제 제출 안내 · 작성 중 답변 열람 ← False · 해결 응답 ← False · Q4 · FAQ 상세 |

</details>

### Q1-search · 검색 결과 없음

다시 검색 → 검색어 선택, 문의하기 → Q3. [Light 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20116) · [Dark 원본](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20497)

<details><summary>배치·표면</summary>

| 노드 | 레이어 | 위치 · 크기 | 방향·간격 / 패딩 / 정렬 · 가로/세로 크기 | 표면 |
| --- | --- | --- | --- | --- |
| [1112:20183](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20183) | 검색 결과 없음 | 40,105 · 1282×722 | V 16 / 40,40,40,40 / CENTER,CENTER · FIXED/FILL | r16 · clip · 선 1 Semantic/Border/Neutral/Weaker-100 · 면 Custom/Background/Surface-White |
| [1112:20187](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20187) | Action/다시 검색 | 0,0 · 180×48 | H 0 / 16,16,2,2 / CENTER,CENTER · FIXED/FIXED | r8 · 선 2 Semantic/Border/Neutral/Weaker-100 · 면 Semantic/Fill/Neutral/Weaker-50 |

</details>

<details><summary>표시 문구</summary>

| 노드 | 원문 | 서체 | 크기 | 자동 크기 / 말줄임 / 최대 줄 / 정렬 |
| --- | --- | --- | --- | --- |
| [1112:20178](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20178) | 검색어 · 영수증 | T3 | 1122×21 | HEIGHT / DISABLED / — / LEFT |
| [1112:20184](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20184) | ‘영수증’에 대한 검색 결과가 없어요 | T2 | 900×40 | HEIGHT / DISABLED / — / CENTER |
| [1112:20185](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20185) | 다른 검색어로 찾아보거나 UMC PRODUCT에 문의해 주세요. | T19 | 900×23 | HEIGHT / DISABLED / — / CENTER |
| [I1112:20187;879:20075](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=I1112-20187;879-20075) | 다시 검색 | T5 | 148×20 | HEIGHT / DISABLED / — / CENTER |

</details>

### 기본 렌더에서 숨겨진 레이어

같은 이름은 최초 노드를 표시한다. 변수 토글로 드러나는 상태와 구형 레일·대체 입력처럼 기본 화면에서 그리지 않는 레이어가 함께 있다. 숨김 자체는 버튼이 비활성이라는 근거가 아니다.

| 기본 렌더에서 숨김 | 대표 노드 |
| --- | --- |
| 아이콘 탐색 레일 | [1100:18966](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-18966) |
| 이전 · 이동 기록 없음 | [1100:19011](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19011) |
| 앞으로 · 이동 기록 없음 | [1100:19014](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19014) |
| 질문이나 궁금한 내용을 검색하세요 | [1100:19033](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19033) |
| Rank 1 · 갱신 | [1112:20787](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20787) |
| Rank 2 · 갱신 | [1112:20794](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1112-20794) |
| Flexible space | [1100:19089](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19089) |
| 탭 도구 모음 · 바깥 클릭 닫기 | [1100:19097](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19097) |
| 탭 도구 모음 · inquiry | [1100:19098](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19098) |
| 라벨/기능 요청 | [1100:19234](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19234) |
| 출석 오류 · 정보 확인 | [1100:19236](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19236) |
| 내 담당 문의 목록 | [1100:19275](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19275) |
| 미배정 문의 목록 | [1100:19294](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19294) |
| 미분류 문의 목록 | [1100:19329](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19329) |
| 탭 도구 모음 · inquiry_ops | [1100:19356](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19356) |
| 진행 중 | [1100:19555](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19555) |
| 답변 대기 안내 | [1100:19574](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19574) |
| Divider | [1100:19575](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19575) |
| 참고한 답변 · 출석 기록이 실제와 다르게 보여요 | [1100:19576](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19576) |
| 재문의한 메시지 정렬 | [1100:19577](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19577) |
| 메시지 입력 안내 | [1100:19585](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19585) |
| Composer actions | [1100:19587](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19587) |
| 종료 | [1100:19689](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19689) |
| 참고한 답변 | [1100:19841](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19841) |
| 받는 팀 선택 / 모달 | [1100:19870](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19870) |
| 검증된 답변 | [1100:19993](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19993) |
| ✓ 해결 응답을 기록했어요. 문의가 새로 등록되지는 않아요. | [1100:20004](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20004) |
| 접수 | [1100:20107](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20107) |
| 문의 내용 | [1100:20113](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20113) |
| 보낸 답변 정렬 | [1100:20123](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20123) |
| 출석 오류 | [1100:20152](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20152) |
| 정보 확인 | [1100:20154](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20154) |
| Badge/기능 요청 | [1100:20155](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20155) |
| Menu/담당자 | [1100:20164](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20164) |
| Menu/라벨 | [1100:20172](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20172) |
| Menu/대표 질문 | [1100:20190](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20190) |
| FAQ record/알림이 오지 않아요 | [1100:20302](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20302) |
| FAQ record/이전 버전의 로그인 오류 안내 | [1100:20305](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20305) |
| 수정 중 · 기존 발행본 공개 | [1100:20311](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20311) |
| FAQ 선택 안내 | [1100:20335](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20335) |
| 현재 선택 | [1102:9990](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-9990) |
| ✓ | [1102:10952](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10952) |

### 조회 범위와 남은 확인

34개 전체 렌더와 두 모드의 프레임 지정은 확인했다. 위 레이어별 상세 수치는 Light 17개 기준이다. Q5 담당자 선택 프레임의 타이틀바는 Light [1102:10487](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10487)의 x=4, Dark [1102:10737](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10737)의 x=0으로 다르다. Dark의 Q1·Q4·Q6·두 도구 펼침·팀 선택 여섯 화면은 공식 도구의 응답량·플랜 한도 때문에 전체 자식 속성의 일괄 교차 검증이 남아 있다. 나머지 11개의 Dark 트리는 회수했다. 일부 텍스트 스타일 이름·개별 constraints와 모든 숨김 레이어의 자식·원격 마스터 내부 모드도 미확인이다. 이들은 **조회 미확인**이며, 최초 로딩 전용 프레임처럼 **원본에서 독립 상태가 정의되지 않은 경우**와 구별한다. 후속 설계의 기준 SHA는 독립 검토가 통과한 뒤 기록한다.

#### Dark 상세 대조가 남은 여섯 화면

독립 조회와 보존 렌더에서 여섯 화면의 존재·순서·1440×960 루트, Workspace 1376×908, App Shell 44×908, 타이틀바 1440×40, UMC Color 746:0을 확인했다. 팀 선택의 전체 오버레이 1440×960과 두 열도 확인했다. 다음 열의 속성은 렌더만으로 값이나 상속 경로를 복원할 수 없어 원본 보강이 필요하다.

| 화면 | Dark frame | 최소 자식 노드 | 원본이 필요한 속성과 재현 영향 |
| --- | --- | --- | --- |
| Q1 FAQ | [1100:20882](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20882) | [1100:20926](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20926) | 검색·순위·도움 영역의 폭/패딩, 폰트·페인트·내부 강제 모드. 레일 1101:9928의 내부 상속 |
| Q4 FAQ 상세 | [1100:21843](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21843) | [1100:21887](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21887) | 본문과 답변 정보·하단 액션의 열 너비, 서체·색·모드와 긴 문구의 clip |
| Q6 FAQ 관리 | [1100:22142](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22142) | [1100:22186](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22186) | 대표 질문 목록·편집 열·공개 상태의 크기, 서체·색·모드 |
| 사용자 도구 펼침 | [1100:22287](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22287) | [1100:22331](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22331) | 도구 팝오버의 원점·너비·패딩·서체·페인트·그림자·강제 모드와 뒤쪽 Q1 |
| 운영 도구 펼침 | [1100:22456](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22456) | [1100:22500](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-22500) | 운영 도구 팝오버의 같은 속성, 배경 운영 표와의 중첩·상속 |
| 받는 팀 선택 | [1102:10080](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10080) | [1102:10202](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1102-10202) | 화면 전체 딤의 불투명도, 대화상자 효과·두 열 여덟 선택지의 bounds·폰트·색·모드 |

#### 동작 뒤에 나타나는 기존 상태

| 시점 | Light / Dark 레이어 | 확인한 동작과 바인딩 | 원본 보강 범위 |
| --- | --- | --- | --- |
| Q3 접수 → Q2 답변 대기 | [1100:19574](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19574) / [1100:21491](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21491) | 두 모드 모두 팀 선택 후 전송하면 답변 대기 변수를 true로 설정하고 Q2로 이동한다. Light 1077:10030과 Dark 1077:10269의 기본값은 false다. Light 안내의 visibility 연결은 확인했다. Dark 안내의 실제 visibility 연결은 미확인이다. | 참 상태에서 안내가 차지하는 위치·크기·실제 문구·서체·색과 타임라인 밀림 |
| Q4 해결 응답 | [1100:20004](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-20004) / [1100:21921](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21921) | 양쪽 안내의 visibility는 Light 401:5824 / Dark 401:6212에 연결돼 있고 기본값은 false다. Light ‘해결됐어요’의 클릭이 401:5824를 true로 설정한다. Dark 버튼의 클릭 반응은 미확인이다. 레이어 이름은 ‘✓ 해결 응답을 기록했어요. 문의가 새로 등록되지는 않아요.’다. | 표시 시 characters·줄바꿈·색·폰트와 하단 액션 간격 |
| Q4에서 Q3 작성으로 진입 | [1100:19841](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-19841) / [1100:21758](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1100-21758) | ‘FAQ에서 문의’ 변수로 참고한 답변을 드러낸다. Light 레이어의 가시성 바인딩은 401:5822, 기본값 false다. Dark 401:6210의 기본값 false와 숨김 레이어의 존재를 확인했고, 해당 레이어와 변수의 직접 연결은 미확인이다. | 참고 답변 자식·배치·색·타이포와 입력 영역 높이 변화 |

위 상태는 이미 원본에 정의되어 있다. 가시성 전환 후의 렌더 또는 부모와 자식의 전체 속성이 확보돼야 숨김 상태의 재현을 판정할 수 있다. 독립 검토에서 일반 배치·크기 270행과 표시 문구·타이포 264행은 보존된 노드값과 일치했다. 위 두 범위의 원본 보강은 1단계 완료 조건으로 남는다.

독립 조사에서 확인한 사용 변수 142개 중 111개는 ID·이름을 값 응답과 대조했다. 아래 31개는 사용 ID와 이름까지만 확인했다. 레이어의 실제 수치와 Variables의 valuesByMode·alias 최종값은 서로 다른 근거다. 이 목록의 이름에서 정의값을 역산하지 않는다.

<details><summary>값 응답이 없는 변수 31개</summary>

| 사용 변수 ID | Figma 변수 이름 |
| --- | --- |
| `VariableID:123:6815` | Spacing/16 |
| `VariableID:123:6812` | Spacing/4 |
| `VariableID:123:6813` | Spacing/8 |
| `VariableID:72fdfb742d40b1750dee13820c4af8410e00415a/2860:106` | Typography/Base/FontWeight/Medium |
| `VariableID:123:6814` | Spacing/12 |
| `VariableID:612:17032` | Radius/12 |
| `VariableID:123:6817` | Spacing/24 |
| `VariableID:612:17031` | Radius/8 |
| `VariableID:3ef7f6e3e7db2b9e7de1321ba9229531dd00a85d/4311:72` | Mode |
| `VariableID:123:6819` | Spacing/40 |
| `VariableID:4f4098ebf2175fb4f25682799a336040a3e08a99/2860:209` | Spacing/Semantic/Padding/Padding 6 |
| `VariableID:d0a0eb63f55135cabd2806e402f173914b2453fc/2860:605` | Spacing/Semantic/Padding/Padding 0 |
| `VariableID:612:17030` | Radius/6 |
| `VariableID:123:6816` | Spacing/20 |
| `VariableID:612:17033` | Radius/16 |
| `VariableID:409:3211` | Light/대표 질문 |
| `VariableID:ae02948c7f89f269323de7f3622375789cba8a85/2860:57` | Spacing/Semantic/Padding/Padding 16 |
| `VariableID:a40be7b7525d8cf7d01ba4f54d83aadc9fc68a6d/2860:153` | Typography/Base/FontFamily/Brand |
| `VariableID:401:6208` | Dark/기간 |
| `VariableID:401:6209` | Dark/갱신 시각 |
| `VariableID:1112:20785` | Dark/기존 순위 |
| `VariableID:401:6246` | Dark/문의자 1 |
| `VariableID:401:6254` | Dark/문의자 2 |
| `VariableID:401:6262` | Dark/문의자 3 |
| `VariableID:401:6270` | Dark/문의자 4 |
| `VariableID:401:6278` | Dark/문의자 5 |
| `VariableID:428:2927` | Dark/새 순위 안내 표시 |
| `VariableID:1077:10185` | Dark/문의 팀 및 처리/문의 받는 팀 / 작성 중 |
| `VariableID:409:3780` | Dark/대표 질문 |
| `VariableID:527:10594` | Dark/문의 도구 펼침 예시/사용자 |
| `VariableID:527:10850` | Dark/문의 도구 펼침 예시/PRODUCT |

</details>

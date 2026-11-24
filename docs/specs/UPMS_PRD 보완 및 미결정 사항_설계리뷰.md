# UPMS PRD 구현 대조 및 근거 확인

작성일: 2026-11-16
작성자: 제옹(euijjang97)
상태: 확인한 구현·문서의 대조 기록 — 신규 정책 제안과 사용자 결정 질문을 제외했다.

## 1. 검토 범위와 원칙

1차 범위인 **프로젝트 등록 → 디자이너 지원 → 선발 → 랜덤·수동 배정 → 결과 공개**를 다룬다.
개발자 매칭 산식, 팀 구성 이후 업무 관리, 신규 외부 연동은 범위 밖이다.

**운영 웹의 기존 동작을 존중하되, 서버가 지원하는 범위 안에서는 Mac에도 기능을 제공할 수 있다.
웹에 노출되지 않았다는 이유만으로 Mac 제공 범위에서 제외하지 않는다.**
PRD·Figma·웹은 기존 흐름과 차이를 확인하는 참고 자료이며, 서로 다르더라도 서버 계약으로
확인된 기능은 권한·기간·정원·데이터 변경 규칙을 그대로 유지해 Mac에 반영할 수 있다.
서버보다 넓은 권한을 부여하거나 시간 검사를 우회하는 것은 포함하지 않는다.

근거가 없으면 미확인으로 남기며 신규 정책·기능을 만들지 않는다.
7절의 출처 차이는 Mac 제공을 일괄 차단하거나 사용자에게 정책 결정을 요구하는 목록이 아니다.
8절은 기존 서버 기능의 Mac 적용 가능 범위와 기술 제약을 분리한 기록이다.

- PRD: [UPMS PRD](https://app.notion.com/p/makeus-challenge/UPMS-PRD-419b57f4596b80ee8426c4554e65e68d) 1~11장, 작성일 2026-11-15. 원문을 수정하지 않았다.
- 서버: 기본 브랜치 `main`의 [60fdadd2](https://github.com/UMC-PRODUCT/umc-product-server/commit/60fdadd2cb0ef7c8a252cc1903859af56ba7b015). 2026-11-16에 SHA가 동일함을 재확인했다. 앞선 확인에서 Service·Domain·권한·Repository·DTO·관련 테스트 소스를 대조했다. 기본 브랜치를 운영 배포 버전으로 간주하지 않는다.
- 과거 기록: `맥 앱 매칭 개선` 채팅(`01a0f08c-f508-7712-bbf5-7c59123484b7`)의 10월 말 작업 요약과 사용자 제공 운영 협의 기록. 이전 `develop c0c34fa2` 확인과 현재 대조의 기준은 다르다. 과거 설명을 현재 승인·구현의 근거로 승격하지 않는다.
- UPMS 웹: 조직 저장소 설명·README에서 전용 저장소 **`umc-product-web-activity`**를 확인했다. 기본 브랜치 `develop`의 [cded27e6][web-commit]에서 일정 계산·삭제 메뉴와 요청·배정 기간과 capability·정원 편집·지원서 열람·폼 저장 경로를 읽었다. [README][web-readme]의 브랜치 설명도 배포 완료 증거로 해석하지 않는다.
- 통합 웹 비교: `umc-product-web-v2` 기본 브랜치 `develop`의 [51b03fb5][v2-commit]. README와 기존 프로젝트 매칭 기간 판정 함수를 표적 조회했다. 전용 웹과 동일 배포물이라고 간주하거나 구 저장소 전체가 폐기됐다고 단정하지 않는다.
- Figma: 2026-11-16 공식 도구로 웹 파일 `mgDK3eBgoDYfARQEmtcoxQ`의 [현재 전체 플로우][figma-current], [명단 프레임][figma-status], 관련 화면 텍스트와 댓글을 읽었다. 별도 `구 플로우` 페이지(`14967:611481`)와 구분했다. 현재 페이지에도 서로 다른 시기의 문구·댓글이 있어 **현재 파일에 존재한다는 사실을 승인·배포 완료로 해석하지 않는다.** macOS 파일 `kM8a1siXgusAVRRgyUZ15U`는 이번 웹 정책 대조의 근거로 사용하지 않았다.
- 조회 범위: 조직 저장소 목록에서 관련 저장소를 식별한 뒤 위 경로만 읽었다. 다른 저장소·Figma 전체 페이지·모든 댓글의 전수 검토는 아니다. 웹 Figma 디자인과 댓글은 수정하지 않았다. 이후 Mac Figma 반영 범위는 10절에 별도로 기록했다.

## 2. 이전 정리와 현재 근거의 차이

| 항목 | 이전 정리 또는 현재 PRD | 이번에 확인한 사실 |
|---|---|---|
| 지부장 합불 결정 | 이전 정리는 판정 불가, 현재 PRD는 소속 지부 매칭 기간 중 가능 | 현재 서버 판정 권한은 프로젝트 기수·지부장도 포함한다. 시간은 차수 도메인이 별도로 검사한다. |
| 학교 회장·부회장 지원자 목록 | 이전 정리는 개인 목록 금지, 현재 PRD는 소속 지부 목록 가능·본문 불가 | 현재 서버는 같은 지부 학교 운영진의 목록을 허용하며 상세 권한은 별도다. 세부 범위 차이는 7절에 기록했다. |
| 랜덤 일정 | 이전 정리는 11/19, 현재 PRD는 11/18 20:00~11/19 00:00 | 서버 실행 조건은 3차 실제 공개 완료다. PRD의 3차 발표 시각은 22시다. |
| 역할 겸임 | 이전 정리는 역할 전환을 확정안처럼 기술, 현재 PRD는 미정 | 확인한 서버는 전체 역할·소유권을 검사한다. 전용 웹에는 어드민·챌린저 겸직자의 Admin/Challenger View 전환 옵션이 있다. 이는 서버의 선택 역할 전환 계약을 뜻하지 않는다. [웹 옵션][web-access] |
| 폼·결과 보존 | 이전 정리는 제출 당시 질문·답변 보존, 현재 PRD는 세부 보존 미정 | 질문 단위 보존에는 구현 근거가 있으나 섹션 답변 삭제와 과거 합격 상태 변경 경로도 있다. 3절에 범위를 기록했다. |
| 대기 최종 처리 | 현재 PRD는 미정 | 서버는 발표 대상 중 미선발 대기를 REJECTED로 종결한다. |
| 공통 일정 재저장·기수 UI | 이전 정리에 지부 일정 덮어쓰기·기수 선택 UI 없음이 있음 | 이번 표적 코드 조회에서 해당 UI·재저장 동작의 최신 근거를 다시 확인하지 않았다. |
| 동일 학교 배정 | 이전 정리는 가능하면 회피 | 서버는 동일 학교 인원이 적은 프로젝트·지원자를 우선한다. 절대 금지 조건이 아니다. |

이전 협의의 프로젝트 카드·Notion 링크·문항 구성, PM:DE:PE 비율, 개발자 일정과 문의 채널은
과거 기록이다. 이번 남은 근거 대조를 위해 새 요구사항으로 옮기거나 현재 적용 정책으로 확정하지 않는다.

## 3. 서버 코드로 답이 확인된 항목

다음 15개 항목은 확인한 커밋의 동작이다. 대기 종결·PM 지정·시간 경계·랜덤 모집단 등
이미 코드로 답한 내용은 사용자 결정 항목으로 남기지 않는다.
소스 링크는 동일 커밋에 고정했으며, 테스트는 내용을 확인했을 뿐 실행하지 않았다.

| 항목 | 코드로 확인한 답 | 근거 |
|---|---|---|
| U-03 최소 선발·대기 처리 | 프로젝트·파트별 **잔여 TO**와 해당 차수의 판정 대상 지원자로 계산한다. TO가 0이면 추가 최소 선발 0, 지원자 0~1명도 의무 0, 여석이 있고 2명 이상이면 최소 1명이다. 기존 합격 유지 후 대기 → 불합격 순으로 보충하며 각 풀 안에서 동일 학교 인원이 적은 지원자를 우선한다. 발표 대상 프로젝트에서 선발되지 않은 대기는 **REJECTED**로 종결한다. DRAFT·CANCELLED는 발표 대상에서 제외한다. | [디자이너 최소치][designer], [선발 정책][decision], [공개 처리][publication], [공개 테스트][publication-test] |
| U-04 랜덤 대상 | 지원서 제출 이력이 없어도 **해당 기수·매칭 지부의 ACTIVE DESIGN 챌린저**이면 후보가 된다. ACTIVE·PENDING_PUBLICATION 배정자는 제외한다. 매칭 지부 이동을 반영하고 후보 순서를 섞은 뒤 같은 학교가 적은 프로젝트의 잔여 TO에 배정한다. 자리 부족자는 미배정으로 남는다. 별도의 “UPMS 참가 취소” 동의 상태를 이 후보 선정 경로에서 검사하지 않는다. | [랜덤 후보·배정][random] |
| U-07 직접 등록 PM | 생성 요청의 `productOwnerMemberId`를 생략하면 요청자 본인으로 정한다. 어느 경우든 해당 기수의 PLAN 챌린저여야 한다. 어드민이 다른 사람을 지정하면 역할·기수·지부 범위도 검사한다. 작성자와 담당 PM은 별도로 저장하므로 **소유자 없는 직접 등록은 현재 흐름에 없다.** | [생성 요청][create-request], [생성 검증][create] |
| U-07 역할 겸임·기수 | 별도 “선택 역할”을 전달하는 흐름이 아니라 회원이 가진 역할 전체와 프로젝트 소유권을 검사한다. 판정은 담당 PM 또는 해당 기수 총괄단 또는 해당 기수·지부장으로 OR 판정하며 SUPER_ADMIN은 전역이다. 관리 목록은 중앙 조회·지부 관리·본인 프로젝트를 조합한다. 다만 모든 조회 경로가 단순 권한 합집합인 것은 아니다(4절). | [판정 권한][decide-access], [전역/기수 권한][authority], [관리 목록][management-scope] |
| U-07 소속·파트 기준 | 지원 생성 시 프로젝트 기수의 현재 챌린저 파트와 매칭 지부를 검사하고, 제출 시 매칭 지부를 재검사한다. 수동 배정은 같은 기수의 현재 ACTIVE 신분·현재 파트·매칭 지부를 검사한다. 이전 지원 당시 소속·파트를 영구 고정한 모델로 해석하면 안 된다. | [지원 생성][apply-create], [제출][apply-submit], [수동 후보 검증][manual-candidate] |
| U-08 폼 수정 가능 시점 | DRAFT·PENDING_REVIEW에서 편집 가능하고 IN_PROGRESS는 해당 지부에 열린 지원 차수가 없을 때 가능하다. 따라서 **지원 시작 후 영구 잠금이 아니라 지원 기간만 잠금**이다. 판정 기간·차수 사이는 수정 가능한 경우가 있다. | [폼 편집 가드][form-guard], [열린 지원 차수 조회][form-edit] |
| U-08 질문·답변 보존 범위 | IN_PROGRESS의 질문 유형·제목·설명·필수 여부 변경은 질문을 fork한다. 질문 제거는 비활성화하고 답변의 questionId로 구버전 질문을 조회한다. 그러나 **섹션 삭제는 확인 플래그가 true이면 제출 답변도 삭제**한다. 질문 메타가 그대로이고 선택지만 바뀌면 기존 선택지를 직접 수정·삭제한다. 섹션 제목·정책도 갱신하므로 “제출 당시 폼 전체 스냅샷 보존”이라고 쓸 수 없다. | [질문 fork][form-fork], [상세의 구버전 조회][detail], [섹션 삭제][section-delete], [선택지 직접 변경][option-change], [삭제 확인 테스트][form-test] |
| U-08 지원 수정·복구 | 제출본은 지원 기간에 필수 답변 검증 후 답변 전체 상태를 갱신하며 재제출 없이 SUBMITTED를 유지한다. 초안 수정은 같은 기간 가드가 없지만 최종 제출은 열린 지원 차수여야 한다. 생성 중복 요청은 기존 초안 반환이 아니라 서비스에서 중복 오류를 반환한다. | [초안 생성 가드][apply-create], [초안·제출본 수정][apply-update], [제출 가드][apply-submit] |
| U-06 시각 경계 | 지원은 `startsAt ≤ now ≤ endsAt`, 합불 판정은 `endsAt < now ≤ decisionDeadline`, 자동 선발은 `decisionDeadline < now`. 랜덤 이후 수동 조정은 `startsAt ≤ now < endsAt`이며 랜덤 실행 완료·미공개 조건도 필요하다. 서버 시각 기준이고 구간마다 끝점 포함이 다르다. | [차수 도메인][round-time], [수동 기간 정책][adjustment] |
| U-01 공개 완료 | 예정 시각 도달 + 자동 선발 완료 + 아직 미공개일 때 공개한다. 공개 트랜잭션이 끝나 `resultPublishedAt`이 기록돼야 공개로 판정하며, 3차 공개 후 랜덤 작업을 예약한다. 이미 처리한 공개는 재처리하지 않는다. 예정 시각 없는 레거시 차수는 결정 마감 경과로 공개 여부를 판단하는 별도 동작이다. | [차수 공개 판정][round-time], [공개 서비스][publication] |
| U-05 수동 초과 배정 | 랜덤 실행 완료 후 같은 매칭 유형의 미공개 조정 기간에만 TO 검사를 생략한다. 일반 차수는 배정 인원 + 미반영 합격자를 고려해 정원을 검사한다. 조정 중에도 ACTIVE 신분·파트·지부·중복 배정 검사는 유지한다. 이 경로에 별도 초과 인원 상한은 없다. | [수동 배정][manual], [조정 기간][adjustment], [초과 배정 테스트][manual-test] |
| U-05 최종 TO 반영 | 랜덤 최종 공개에서 해제 예약을 먼저 제거하고 신규 배정을 ACTIVE로 만든 후 같은 유형의 실제 활동 인원까지 TO를 늘린다. 기존 TO는 줄이지 않으며 TO가 없던 파트는 생성할 수 있다. PM·다른 매칭 유형은 대상이 아니다. | [공개 순서][publication], [TO 동기화][quota-publication], [유형·상한 테스트][quota-test] |
| 삭제·지원 내역 | 프로젝트 삭제는 해당 지부의 열린 지원 차수가 있으면 금지한다. 그 외엔 상태 무관 삭제 가능하며 담당 PM 또는 범위 내 운영진 권한이 필요하다. 해당 프로젝트·지원서·팀원·정원·폼·응답·답변을 제거한다. 지원서 JPQL DELETE와 통합 테스트의 엔티티 부재 검증까지 확인했으므로 **단순 숨김이나 철회와 다르다.** 다른 프로젝트 배정은 유지한다. 감사 이벤트의 존재가 삭제된 답변 보존을 뜻하지 않는다. | [삭제 서비스][deletion], [삭제 기간][delete-guard], [답변·폼 제거][delete-form], [물리삭제 통합 테스트][deletion-test] |
| 삭제 후 재지원 | 해당 프로젝트의 합격 근거·배정이 없어져 다시 미배정자가 될 수 있다. 그러나 새 지원은 여전히 열린 차수여야 한다. **삭제 직후 마감된 차수에 특별 재지원할 수 있는 예외는 확인한 생성·제출 경로에 없다.** 후속 차수 지원·랜덤·수동 배정은 각각의 조건을 따라야 한다. | [삭제 후 미배정 테스트][deletion-test], [지원 기간 검사][apply-create] |
| U-02 과거 발표와 현재 배정 | 공개 명단은 현재 ACTIVE 팀원과 배정 차수를 조회한다. 일반 수동 해제는 연결된 합격 지원서를 REJECTED로 바꾸고 팀원 행을 삭제하지만 답변은 유지한다. 최종 조정의 기존 ACTIVE 해제는 예약했다가 최종 공개 시 반영한다. **현재 조회 계약은 불변의 과거 발표 스냅샷이 아니다.** | [공개 명단 조회][roster], [수동 해제][manual], [지원서 변경·답변 보존 테스트][release-test] |

## 4. 구현 계약에서 확인한 차이

다음은 기존 코드와 응답의 기술 제약이다. Mac 적용 시 그대로 고려하며 새 서버 정책을 요구하지 않는다.

1. **판정 capability와 시간 검사:** `application.canDecide.allowed`는 프로젝트 상태·역할을 검사하고, 차수의 판정 가능 시간은 실제 요청의 도메인 검증에서 검사한다. [capability 구현][capability]
2. **예정 시각과 실제 공개 완료:** `ProjectMatchingRoundResponse`와 Info는 `resultPublishAt`·`autoDecisionExecutedAt`을 담지만 `resultPublishedAt`은 담지 않는다. 도메인은 실제 공개 완료 시각으로 공개 여부를 판단한다. 확인한 공개 현황 응답도 완료 필드 없이 명단을 제공한다. 전용 웹은 `resultPublishAt` 예정 시각으로 결과 공개 여부를 계산하며, 실제 변경 요청은 서버 capability와 도메인 검증을 추가로 거친다. 예정 시각 도달을 서버 공개 트랜잭션 완료 증거로 볼 수 없다. [웹 공개 판단][web-period], [배정 요청 가드][web-assign] [응답 DTO][round-response], [공개 도메인][round-time]
3. **겸직 scope 우선순위:** 목록 resolver는 PM/보조 PM 분기를 SUPER_ADMIN·총괄단보다 먼저 적용하고 상세의 지원 중 허용 여부도 이 scope를 사용한다. 따라서 총괄+PM 겸직자는 담당 프로젝트에서 지원 중 상세가 막힐 수 있다. 의도된 우선순위의 공식 설명은 이번 근거에서 미확인이다. [scope 분기][list-scope], [상세 시간][detail]
4. **초안 중복 응답 설명:** 컨트롤러 설명은 기존 초안 반환으로 기술하지만 서비스는 동일 초안에 중복 오류를 반환한다. 이 차이를 확인했으며 별도 복구 흐름을 새 요구사항으로 정하지 않는다. [생성 검사][apply-create]

## 5. 운영 상태와 확인 한계

PRD는 11/10 출시 예정과 이후 차수 일정을 기술한다. 실제 출시·QA 완료, 운영 배포 버전,
현재 진행 차수, 운영 DB의 역할·TO·예약 시간은 이번에 확인하지 않았다.
코드에 구현이 있다는 사실과 운영 환경에서 해당 구현이 적용됐다는 사실은 구분한다.

FR-01~23별 전체 구현 완료 여부와 KPI 측정 결과도 이번 확인 대상이 아니다.
측정 산식·목표값·추적 기능을 새로 제안하거나 완료로 표시하지 않는다.

## 6. 기존 책임 범위 참고 자료

[Handbook README](https://github.com/UMC-PRODUCT/umc-product-handbook/blob/main/README.md)와
[Ownership Registry](https://github.com/UMC-PRODUCT/umc-product-handbook/blob/main/ownership-registry.md)는 앞선 검토에서 2026-11-16 조회했다.
Learning & Activity에 UPMS 제품 경험이 포함되며 기존 담당으로 조이가 기록돼 있다.
다만 Purpose Acting Lead 임기 종료가 11/08로 명시돼 있어 현시점 담당 연장·후임은 이 문서로 확정하지 않는다.
박박지현·이방토의 UPMS 지원 기록도 세부 범위·기간의 수락이나 현재 착수를 뜻하지 않는다.

플랫폼 책임 경계는 [저장된 가이드](../Codex/platform-domain-ownership.md)의 2026-10-10 복사본을 참고했다.
최신 Notion 본문은 확인하지 않았다. 이 자료들은 기존 책임 범위의 참고일 뿐,
사용자에게 새 정책을 결정하거나 동료에게 변경을 요청할 의무를 부여하지 않는다.
외부 연락·작업 요청은 하지 않았다.

## 7. PRD·서버·전용 웹·Figma 대조

아래는 사용자 결정 질문이 아니라 **동일 항목의 출처별 사실**이다.
`일치`는 확인한 부분의 일치이고, `아직 상충`은 현재 문구·구현이 다르다는 뜻이다.
어느 자료가 낡았거나 최종 승인됐는지는 변경 이력·승인 근거 없이 단정하지 않는다.
출처 간 차이가 있어도 서버 지원이 확인되면 8절의 제약 안에서 Mac에 제공할 수 있다.

| 항목 | PRD·과거 기록 | 서버 | 전용 웹 코드 | 현재 Figma·댓글 | 대조 상태 |
|---|---|---|---|---|---|
| 랜덤 실행 순서 | PRD: 3차 결과 11/18 22시, 랜덤 11/18 20시~11/19 00시 | 3차 실제 공개 완료 후 랜덤 실행·예약. [가드][random-guard] | 시작일 기준 7일째 00~20시를 `RANDOM_MATCHING`의 **운영진 조정 기간**으로 저장한다. 11/13 시작을 대입하면 11/19 00~20시다. 자동 랜덤 실행 시각과 별개다. [계산][web-schedule], [요청][web-schedule-request] | 현재 전체 플로우의 조회한 텍스트에서 20:00·22:00을 명시한 운영표는 찾지 못했다. 웹 코드의 “피그마 운영표” 주석만으로 원본 확인을 대신하지 않는다. | **아직 상충:** PRD의 발표 전 20시 자동 랜덤 시작은 서버 조건과 맞지 않는다. 웹 API 구간이 수동 조정 기간이라는 의미는 코드로 해소됐다. |
| 프로젝트 삭제 기간 | PRD: 어드민 삭제는 등록·매칭 기간, PM 기간 미정 | 열린 지원 차수만 차단하고 그 밖에는 상태 무관 삭제 가능. [기간][delete-guard], [권한][delete-access] | PM·허용 운영진 삭제 메뉴는 `isApplicationPeriod`일 때만 비활성. 확인 핸들러는 DELETE 요청을 실행한다. 다만 상단 설명은 “팀 매칭 진행 중 수정 및 삭제 불가”다. [메뉴][web-delete], [기간·요청][web-projects] | 삭제 모달은 복구 불가를 안내하지만 확인한 노드에 삭제 허용 기간은 없다. [삭제 모달][figma-delete] | **부분 일치·아직 상충:** 웹 실행 조건은 서버와 일치한다. PRD의 운영진 기간 설명 및 웹 상단 설명은 실제 조건과 다르다. Figma는 기간 근거 미확인. |
| 수동 배정 기간·공개 | PRD는 랜덤 이후 수동 기간을 설명 | 일반 1~3차에도 허용 구간이 있고 즉시 ACTIVE. 최종 조정은 발표 대기. [기간][adjustment], [배정][manual] | 1차 시작~판정 마감, 직전 발표 예정 시각~다음 판정 마감, 랜덤 조정 구간을 검사한다. 배정 핸들러는 이 기간과 서버 `canAssign`을 모두 확인한다. [기간][web-period], [핸들러][web-assign] | 툴팁은 “매칭 차수나 마감 기한과 관계없이 … 언제든 … 변경 사항은 즉시 반영”이라고 적혀 있다. [툴팁][figma-manual] | **아직 상충:** 웹·서버에는 기간 제한이 있으며 최종 조정도 즉시 공개되지 않는다. PRD에는 일반 차수 수동 배정 범위가 빠져 있다. 툴팁 변경·승인 이력은 미확인. |
| TO 잠금·최종 증가 | PRD: 전체 매칭 시작 후 TO 변경 불가 | 설정 잠금과 별개로 최종 공개 시 실제 활동 인원까지 TO 자동 증가. [동기화][quota-publication] | TO 편집은 서버 열별 `canEdit`을 확인한다. 수동 배정 화면은 조정 기간에 `canAddOverQuota`를 허용하며 실제 배정은 capability로 다시 검사한다. [정원][web-quota], [초과 배정][web-overquota] | 조회한 현재 플로우에서 최종 공개 TO 자동 증가를 설명한 주석은 확인하지 못했다. | **구현 간 일치·PRD 설명 차이:** 정원 설정 잠금과 조정 중 초과 배정이 공존한다. 자동 증가가 PRD 잠금의 명시적 예외라는 공식 문구는 미확인. |
| 지원서 열람 역할·기간 | PRD: 회장·부회장 목록, 마스터·지부장·담당 PM의 매칭 기간 본문 열람 | 같은 지부 학교 파트장·기타 운영진 목록, 보조 PM 상세도 허용. 총괄단은 지원 중 상세 가능, 지원 종료 후 상세 종료 가드 없음. [범위][list-scope], [상세][detail-access], [시간][detail] | 중앙·학교 운영진은 목록만, 상세는 제한한다. Admin/PM 상세 클릭에는 `isModalLocked`를 적용해 지원 기간 또는 진행 판정 차수가 없으면 잠근다. 역할 메뉴의 존재만으로 서버 권한을 추정하지 않았다. [역할][web-access], [시간 가드][web-read-period], [Admin 클릭][web-admin-read], [PM 클릭][web-pm-read] | 엄예빈의 10/8 KST(UTC 10/7) 댓글은 종료 차수도 지원서를 재열람하되 상태 변경만 비활성이라고 명시한다. 스레드 답글은 판정 기간과 결과 시트 공개를 분리한다. [댓글][figma-read-comment] | **아직 상충:** 서버·댓글의 종료 후 열람과 웹의 전역 모달 잠금이 다르다. 학교 운영진 세부 범위·보조 PM·총괄단 지원 중 열람도 PRD에 충분히 기술되지 않았다. |
| 폼·과거 결과 보존 | PRD 세부 보존 미정. 과거 정리는 제출 당시 질문·답변 보존으로 요약 | 질문 fork·구버전 조회는 있으나 확인 플래그에 따른 섹션 답변 삭제와 수동 해제 시 기존 합격 상태 변경도 존재한다. [폼][section-delete], [해제][manual] | 확인한 폼 저장 빌더는 기존 섹션·질문 ID를 보내지만 `confirmDeleteAnsweredSections`를 보내지 않는다. 따라서 서버의 삭제 확인 플래그를 이 UI가 사용한다고 볼 수 없다. [폼 요청][web-form], [저장][web-form-save] | 과거 지원서 재열람 댓글은 있으나 전체 폼·발표 결과의 불변 스냅샷이나 답변 삭제 확인 절차 근거는 조회 범위에서 미확인이다. [댓글][figma-read-comment] | **구현 범위 확인·정책 미확인:** PRD 위반으로 단정할 내용은 아니다. 질문 단위 보존을 전체 이력 보존으로 확대하지 않는다. |

Figma 댓글 근거는 `14661:33868`에 연결된 스레드 `1957113058`이다.
엄예빈의 원문(2026-10-08 02:21 KST, UTC 10/7 17:21), 같은 작성자의 공개 시각 분리 답글,
이예원의 실시간 결과 반영 오류 확인 요청 답글을 읽었다. 조회 시 **미해결** 상태였다.
따라서 과거 기획 의도를 보여주는 근거로 기록하며 현재 승인 완료로 표시하지 않는다.

통합 웹 `web-v2`의 기존 [기간 판정][v2-period]은 차수의 `startsAt`~`endsAt` 포함 구간을 검사한다.
이 함수만으로 현재 전용 웹의 삭제·열람 권한을 대체하거나 여섯 불일치를 해소하지 않았다.

## 8. Mac 반영 가능한 기존 서버 기능

아래는 새 정책이나 일괄 구현 지시가 아니라 **현재 서버 계약으로 제공 가능한 범위**다.
웹 제공 여부는 앞서 읽은 `web-activity` 커밋의 코드 기준이며 운영 배포 여부와 다르다.
Mac의 현재 화면·DTO 구현 완료 여부는 이번에 조사하지 않았다.
경로의 `{projectId}`·`{applicationId}`는 서버 리소스 식별자다.

| 기능 | 실제 API·서비스 근거 | 현재 웹 제공 여부 | Mac에서 제공 가능한 내용 | 유지할 서버 제약 | 적용 전 기술 확인 |
|---|---|---|---|---|---|
| 지원 종료 후 본문 재열람 | `GET /api/v1/projects/{projectId}/applications/{applicationId}`. [컨트롤러][application-detail-api], [상세 서비스][detail] | Admin·PM 클릭은 지원 기간 또는 진행 판정 차수가 없으면 잠긴다. [웹 가드][web-read-period] | 서버가 허용한 종료 차수의 지원서·답변·첨부 재열람. 웹의 전역 모달 잠금을 동일하게 적용할 필요는 없다. | 본인·프로젝트 PM/보조 PM·허용 운영진의 READ 권한. DRAFT는 본인만. 일반 PM/보조 PM 등은 해당 지원 종료 후이며 총괄단 지원 중 조회는 scope 검사 적용. | 상세 API의 403/404, 본인 조회의 공개 전 `status=null`, 질문별 구버전·첨부 응답을 처리한다. 판정 버튼은 조회 가능 여부와 별도로 제어한다. |
| 보조 PM의 지원자 목록·상세 | 위 상세 API와 `GET /api/v1/projects/{projectId}/applications`. [목록·상세 API][application-list-api], [scope][list-scope], [상세 권한][detail-access] | 목록에 보조 PM 이름을 붙이는 코드는 있으나 **보조 PM 본인의 진입·열람 흐름 전체는 미확인**. | 서버가 인정한 보조 PM에게 담당 프로젝트 지원자 조회를 제공할 수 있다. | 서버의 ACTIVE PLAN 보조 PM 조건·기수·프로젝트 scope·열람 시점 적용. 보조 PM이라는 이유로 합불 판정 권한까지 부여하지 않는다. | 역할 이름만으로 권한을 복제하지 않고 실제 목록·상세 권한을 사용한다. 총괄+PM 겸직의 scope 우선순위도 4절 제약을 따른다. |
| 일반 1~3차 수동 배정·해제 | `GET /api/v1/projects/admin/{projectId}/members/candidates`, 같은 members 경로 `POST`, `DELETE /{memberId}`. [API][manual-api], [서비스][manual] | 제공됨. 역할·기간 및 서버 capability를 함께 검사한다. [웹 핸들러][web-assign] | 허용 운영진의 후보 조회·수동 배정·해제. 랜덤 이후에만 제공하는 것으로 제한할 필요는 없다. | 총괄단/허용 지부장 등 서버 권한, 차수별 허용 구간, ACTIVE·현재 파트·매칭 지부·중복·정원 검사. 일반 배정은 즉시 ACTIVE이고 해제는 연결 합격 상태를 변경한다. | 후보 API 결과와 `canAssign`/`canUnassign`, 실제 요청의 409 사유를 처리한다. 일반 정원은 미반영 합격자도 포함한다. |
| 최종 조정의 TO 초과 배정·공개 반영 | 위 수동 매칭 API와 [최종 공개][publication], [TO 동기화][quota-publication] | 조정 기간에 초과 배정 UI를 허용한다. [웹 조건][web-overquota] | 서버가 허용하는 최종 조정·취소를 제공하고, 서버가 공개한 뒤 바뀐 명단·TO를 다시 표시할 수 있다. | 랜덤 실행 완료·같은 유형의 미공개 조정 기간에만 정원 검사 예외. 다른 후보 검사는 유지한다. 최종 공개 시 TO는 필요한 만큼 증가하며 줄지 않는다. | 배정·해제 예약과 현재 공개 명단을 혼동하지 않는다. Mac이 TO를 선제 수정하거나 새 초과 상한을 만들지 않는다. 공개 작업 수동 실행 버튼을 추가하는 근거로 사용하지 않는다. |
| 지원 폼 수정·질문 단위 보존 | `PUT /api/v1/projects/{projectId}/application-form`. [API][form-api], [편집 조건][form-guard], [질문 fork][form-fork] | 폼 저장 제공됨. 기존 섹션·질문 ID를 요청한다. [웹 저장][web-form-save] | 허용 시점에 문항 편집·저장하고 상세 응답에 포함된 구버전 질문·답변을 표시할 수 있다. | PROJECT EDIT 권한. DRAFT/PENDING_REVIEW 또는 IN_PROGRESS 중 열린 지원 차수가 없는 경우. 질문 변경·옵션·섹션 처리는 서버의 실제 보존 범위를 따른다. | PUT은 전체 상태이므로 생략 항목의 제거 의미와 기존 ID를 유지한다. 전체 폼·결과가 불변 스냅샷인 것처럼 표시하지 않는다. |
| 답변이 있는 섹션의 확인 후 삭제 | 위 폼 PUT의 `confirmDeleteAnsweredSections`. [요청 DTO][form-request], [삭제 처리][section-delete] | 확인한 웹 요청 빌더는 이 플래그를 보내지 않는다. [빌더][web-form] | 서버가 제공하는 경고·확인 후 섹션과 해당 답변을 삭제하는 기존 절차를 Mac에 제공할 수 있다. | 플래그 생략/false이면 답변 있는 섹션 제거를 `409 PROJECT-0026`으로 거절. 서버가 전달한 섹션명·답변자 수와 답변 삭제 영향을 확인한 뒤 true로 재요청한다. 기존 EDIT·기간 검사도 유지한다. | 자동으로 true를 붙이거나 오류 뒤 무확인 재시도하지 않는다. 실제 사용자 확인과 명시적 재요청을 연결하며 추가 보존 정책을 만들지 않는다. |
| 지원 초안 저장·제출본 수정 | `POST /api/v1/projects/{projectId}/applications`, `PUT /{projectId}/applications/{applicationId}`, `POST /{projectId}/applications/{applicationId}/submit`. [API][application-write-api], [수정 서비스][apply-update] | 이번 표적 조회로 초안·제출본 편집 흐름 전체는 미확인. | 기존 지원 초안 저장·다시 열기·최종 제출과 지원 기간 내 제출본 수정 제공 가능. 제출본 수정은 재제출 없이 SUBMITTED를 유지한다. | 본인 권한·기수·현재 파트·매칭 지부·차수 중복 검사. 초안 수정의 기간 조건과 최종 제출/제출본 수정의 열린 지원 기간 조건을 구분한다. | 초안 중복 생성은 기존 초안을 반환하지 않고 오류를 낸다. 기존 내 지원 조회와 applicationId를 사용하며 전체 답변 갱신·필수 답변 검증을 처리한다. |

공통 적용 제약은 다음과 같다.

- 서버 capability를 사용하되 `canDecide`만으로 시간까지 허용됐다고 판단하지 않는다. 실제 차수 시간과 요청 결과를 함께 처리한다.
- `resultPublishAt`은 예정 시각이다. 확인한 차수 DTO에는 실제 `resultPublishedAt`이 없으므로 예정 시각 도달만으로 공개 성공을 확정하지 않는다. 기존 공개 명단·본인 상세의 서버 응답 범위에서 표시한다.
- 전지부 운영 범위, 기수·소속·파트 기준, 겸직 scope는 3·4절의 서버 계약을 그대로 따른다. Mac 화면 전환으로 서버 권한이 확대되지 않는다.
- 추가 확인한 `POST /api/v1/project/matching-rounds/{matchingRoundId}/auto-decide`는 기존 자동 선발의 수동 실행 API다. 최고관리자·해당 기수 총괄단·해당 기수/지부 지부장만 실행할 수 있으며, 1~3차는 결정 마감 이후, 랜덤은 3차 실제 공개 이후만 허용한다. 이미 실행된 차수는 no-op이다. 기존 Mac 실행 화면은 이 조건을 유지하며, 임의 실행이나 최종 공개 버튼으로 확대하지 않는다. [컨트롤러][auto-decide-api]
- 위 항목은 서버 코드 지원 확인이다. 실제 연동 전 배포된 API 계약·인증 응답·오류 및 Mac DTO 매핑을 확인해야 하며, 이는 신규 정책 결정 요청이 아닌 기술 검증이다.

## 9. 이번 수정·검증 범위

- 유지: 서버에서 확인한 15개 동작과 동일 커밋의 파일·줄 근거.
- 추가: 서버 지원 범위에서 Mac 제공이 가능하다는 적용 기준, 기존 서버 기능 7개와 웹 제공 여부·필수 제약·연동 전 기술 확인. 폼 확인 삭제 요청 DTO와 지원·조회·수동 매칭 컨트롤러를 추가 대조했다. 서버 main SHA는 동일했다.
- 미확인: 운영 배포·DB·예약 실행, Figma 문구의 최종 승인·변경 이력, 조회하지 않은 페이지·코드 경로. 테스트 소스·코드를 읽었으며 빌드·실행 테스트는 하지 않았다.
- 이 로컬 문서와 아래 Mac Figma를 수정했다. 서버·웹·Mac 앱 코드·Notion·웹 Figma·이슈·PR은 변경하지 않았다. 신규 서버 정책과 사용자 결정 질문은 추가하지 않았다.


## 10. Mac Figma 반영 결과 — 2026-11-16

기존 [매칭 섹션](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=335-844)의 화면·컴포넌트를 재사용했다. 관련 Light/Dark 화면을 수정하고, 빠진 상태 3쌍과 작은 확인·처리 오버레이 4쌍을 추가했다. 기존 전체 화면을 중복 재생성하지 않았다.

| 반영 범위 | 실제 변경 | 대표 노드 |
|---|---|---|
| 명단·수동 조정 | 일반 1~3차의 즉시 배정과 최종 조정의 공개 대기를 분리했다. 최종 구간의 TO 초과 예외·공개 시 TO 증가를 안내하고, 단일 재배정 요청으로 오해할 진입 버튼은 숨겼다. | [최종 조정 Light](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1003-9621), [Dark](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1003-10318), [일반 차수](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1021-9864) |
| 지원서 열람·판정 | 지원 종료 후 열람과 판정 마감 잠금을 분리했다. 보조 PM 읽기 전용 상태는 판정 연결을 제거하고 소유자 운영 도구 진입도 숨겼다. | [보조 PM 열람](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1021-9674) |
| 초안·제출본 | 지원 기간 내 제출본 수정과 SUBMITTED 유지 문구를 반영했다. 기존 제출 내역의 수정 진입, 저장·취소 복귀를 연결했다. | [제출본 수정](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1021-9514) |
| 폼 편집 | 열린 지원 기간 기준 잠금과 답변 있는 섹션 삭제 확인을 반영했다. 서버 경고 이후 확인/취소 및 삭제 요청 중 상태를 연결했다. 자동 확인·무확인 재시도를 넣지 않았다. | [폼 편집](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=380-5129), [삭제 확인](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1021-10042) |
| 시각 개선 | 기존 42건·70명·36명 통계의 계층을 강화하고 차수 칩·모집 상태 pill·정원 막대를 컴포넌트로 재사용했다. 4/5·3/5·5/5는 같은 90px 트랙에서 72·54·90px로 표시한다. 선택 행·지원자 정보·타임라인의 대비와 여백을 정돈했다. | 위 명단 Light/Dark |

검증은 대표 화면 캡처와 노드·프로토타입 속성 조회로 수행했다. `UMC Color`의 Light/Dark 명시 모드와 상속, 배경·텍스트 변수 연결, 확인/취소·수정 복귀·판정 잠금을 확인했다. Sol UI 리뷰의 최종 차수 표시·탭 선택·재배정 진입·파괴적 확인 색상·제출본 수정 문구 지적을 반영했다. 정원 막대 길이와 Dark KPI 대비도 캡처로 재검증했다. 의도된 세로 스크롤 영역을 제외한 확인 대상 오버플로우를 보정했다.

추가 글 잘림 검증: 매칭 섹션의 표시 텍스트 4,423개를 조사했다. 말줄임·최대 줄 제한은 없었으며, 고정 높이 578개(중복을 합친 161종)를 자동 높이로 측정했다. 필요한 높이가 부족한 버튼 6개는 너비를 132px로 넓혔고, 결과 제목·안내 16개는 자동 높이로 바꿨다. 글씨 크기는 유지했다. 수정 후 텍스트가 직접 부모의 클리핑 경계를 넘는 항목은 0개였으며 공개 명단·삭제 모달 캡처에서 버튼과 긴 안내를 확인했다. 1440×960 화면 크기를 유지했다.

추가 정보 시각화: [지원자 심사](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=125-8727)와 [차수 운영 타임라인](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=380-4892)의 Light/Dark 4개 화면을 보완했다. 심사 분포는 기존 대기 8·합격 3·불합격 1을 합한 12명만 분모로 사용한다. 모바일 1/2·웹 1/2는 각각 별도 정원 막대로 표시하며 심사 분포와 합산하지 않는다. 일정은 기존 예시 날짜를 유지하고 지원 시작 → 지원 마감 → 판정 마감 → 마감 이후 자동 처리 → 공개 예정 순서로 표현했다. 번호·연결선은 시간 순서이며 실제 완료율이 아니다. 실제 공개 완료나 랜덤 실행 시각을 추정하지 않았다. 이름·학교·답변은 텍스트를 유지했다. 42건·70명·36명은 공통 분모의 비율로 만들지 않았다. 분포 막대 274.67/103/34.33px(총 412px), 파트별 91/182px 및 4개 화면의 텍스트 경계 초과 0개를 확인하고 Light/Dark 캡처로 검증했다. 수치·날짜는 기존 시안 예시이며 현재 운영 데이터가 아니다.

한계: 실제 서버 요청·배포·예약 작업과 전체 프로토타입 클릭 실행은 검증하지 않았다. 삭제 요청 중 화면은 서버 응답을 흉내 내어 자동 성공시키지 않는다. 화면의 숫자는 기존 시안 예시이며 실제 집계가 아니다. Figma에서 Pretendard를 사용할 수 없어 기존 Noto Sans KR을 유지했다. 앱 구현과 런타임 접근성 검증은 이번 변경에 포함하지 않았다.

### 전체 매칭 화면군 재점검

2026-11-16에 `335:844` 아래 1440×960 화면 **104개(52개 Light/Dark 쌍)**와 부속 오버레이의 텍스트를 조사했다. 전체 화면의 `UMC Color` 명시 모드를 기존 Light/Dark 구분에 맞췄다. 이번 후속 점검에서 시각 표현을 보정한 화면은 32개이며 제출 확인 문구 2개를 추가 보정했다. 화면·페이지를 새로 복제하지 않았고 기존 심사 요약/정원 블록을 재사용했다.

| 화면군 | 판정·실제 반영 |
|---|---|
| 프로젝트 탐색·검색·상세·팀 구성 | 기존 채움/빈자리 슬롯과 숫자가 정원을 충분히 보여 주므로 유지. 탐색 일정의 넘치는 막대 폭을 카드 너비에 맞추고 예정 단계의 잔여 1px 채움을 숨겼다. |
| 일정 설정·잠금·운영 타임라인 | 기존 날짜 표·읽기 전용 상태·5단계 흐름이 충분해 유지. 실제 공개 완료와 예정 시각을 혼동하는 새 진행률은 만들지 않았다. |
| 심사·판정 확인·저장 중·시작 전·종료·접근 제한·보조 PM | 기본 심사에 적용한 분포/정원 블록을 누락된 변형 12개에 동일하게 반영. 기존 숨김 상태·판정 잠금·연결을 유지했다. 모든 심사 분모를 `선발 1 / TO 2`로 명확히 표시했다. 접근 제한 화면에서 숨겨진 정보는 새로 노출하지 않았다. |
| 내 지원·초안·제출본·결과 | 작성/제출 완료와 공개 예정을 구분하고, 예정 단계에 완료 채움을 표시하지 않았다. 기존 작성 완료율·제출본 수정 상태는 유지. 지원 기간 내 제출본 수정 가능 문구와 제출 확인의 공개 예정 시각을 기존 서버 계약·같은 시안 일정에 맞췄다. |
| 등록·폼·TO 설정 | 초안 → 검토 대기 → 공개의 연결선을 추가. 필수 질문 수·입력 필드·파트별 정원 조절은 기존 표현이 충분해 유지하고, 입력값을 별도 새 통계로 합산하지 않았다. |
| 자동 선발·발표 대기 | 확인된 처리 완료 단계는 체크, 아직 확정되지 않은 미선발 처리와 공개는 `대기`·`예정`으로 구분. 자동 처리 완료를 최종 발표 완료로 표시하지 않았다. |
| 공개 현황·통계·명단·일반/최종 조정 | 기존 명단 막대·차수 칩·상태 표시는 유지. 기존 막대 18개의 길이를 표시된 분수 기준으로 검증·보정한 뒤, 서버 유형 범위와 맞지 않는 차수 예시 6개(Light/Dark)는 숨겼다. 학교·프로젝트 막대는 유지했다. 예: 학교 28/40은 411.6/588px, 프로젝트 4/12는 196/588px. |
| 배정/해제·삭제·완료·중단·권한/오류 안내 | 대상·영향·사유를 읽는 것이 우선이므로 텍스트와 확인/취소를 유지. 가짜 전후 인원·추천·예측·성공률을 추가하지 않았다. |

최종 텍스트 검사: 섹션 내 표시 텍스트 **4,483개**, 고정 높이 **556개(중복 제외 154종)**를 확인했다. 고정 높이를 실제 자동 높이와 비교한 부족 항목 0개, 직접 부모 클리핑 경계 초과 0개, 말줄임·최대 줄 제한 0개였다. 이는 현재 시안 문자열에 대한 검사이며 임의 길이의 실제 데이터까지 보장하지 않는다. 글씨 크기를 줄이지 않았다. 대표 탐색·심사 종료·자동 처리·내 지원·등록·통계의 Light/Dark 캡처를 생성했고, Sol 리뷰의 완료 화면 문구·정원 분모·예정 막대 지적을 반영했다.

통계는 추가로 서버 컨트롤러·DTO·서비스·조회 Repository까지 확인했다. `GET /api/v1/projects/statistics/matchings`는 선택된 한 매칭 유형의 차수별·학교별·프로젝트별 집계를 제공한다. 학교는 누적 매칭 인원/대상 총원, 차수는 해당 차수 매칭 인원/이전 차수 매칭을 제외한 가능 인원, 프로젝트는 차수별 인원을 제공한다. 따라서 기존 학교 예시 28/40·22/35·17/25와 그 합 67/100·67%, 프로젝트 1·2차 표의 형태는 지원된다. 상단 분모 이름도 차수 잔여 인원과 혼동하지 않도록 `매칭 대상 총원`으로 맞췄다. 숫자는 시안 예시이며 실제 운영값은 아니다. 반면 배정 차수가 없는 팀원은 inner join 및 차수 필터에서 제외하므로 기존 `차수 미분류 5명`·지원서 없는 합류 설명·미분류 표 열은 숨겼다. 랜덤 배정도 assignedMatchingRound를 가지면 해당 차수로 집계되므로 지원서 유무로 미분류를 추정하지 않는다. 한 응답에 디자인/개발 차수를 섞었던 기존 3개 예시 막대도 숨기고 차수 정보 확인 중 상태로 바꿨다. 새 숫자나 차수별 결과를 만들지 않았다. 근거: [공개 통계 계약][stats-contract], [응답 필드][stats-response], [대상·유형 필터][stats-filter], [차수·학교 집계][stats-calculation], [실제 조회 조인][stats-query]. 통계 하단 표는 본문 `380:5827`/`394:3985`의 `VERTICAL` 스크롤 영역(뷰포트 828px, 내용 끝 869px)으로, 숨겨서 제거한 내용이 아니다. 실제 API 실행·전체 프로토타입 클릭 실행의 미검증 범위는 위와 같다.

### Hi-fi 전체 반영 및 버튼 세부 검증 — 2026-11-17

사용자가 지정한 `605:9566`은 `- Hi-fi` 페이지이며 기존 UPMS 화면은 없었다. [UPMS 하이파이 섹션](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1050-5661)에 기존 매칭 104개 화면(52개 Light·Dark 쌍), 확인 모달 8개, 노치·메뉴바 10개를 추가했다. 합계 122개 상태이며 원본 Mid-fi와 무관한 Hi-fi 화면은 보존했다. 탐색·일정·지원 작성·내 지원·공고와 폼·심사·팀 관리·명단과 조정·종료·공통 안내·추가 서버 지원 상태·노치를 모두 포함한다.

Hi-fi의 매칭 선택 앱 셸을 104개 화면에 적용하고, 상단 탐색·탭 표면·카드와 선택 영역·구분선·제목 계층을 정리했다. 기존 macOS 버튼의 크기·색·상태 의미에 맞춰 연결된 UPMS 버튼 2종을 만들었다. 원본 Hi-fi 버튼은 `Pretendard Variable`을 사용하지만 도구에서 해당 폰트 로딩이 실패해, 기존 매칭의 `Noto Sans KR`를 유지했다. 셸 아이콘은 기존 `SF Pro`를 재사용했다. 버튼 폰트를 줄이거나 문구를 삭제해서 맞추지 않았다. UMC 색상 바인딩과 실제 모드 해석 값을 동기화해 일부 화면의 검정 배경 렌더링도 수정했다.

- 가시 상단 툴바 102개: 좌우 12pt·아이콘과 라벨 간격 8pt. `매칭 운영 도구`도 실제 콘텐츠 폭에 맞게 넓혔다.
- 가시 공통 버튼 472개: 라벨 한 줄·좌우 여백 16pt 이상·수직 중앙 정렬. 줄바꿈, 라벨 및 버튼의 부모 경계 이탈 0건을 Sol UI 리뷰로 재확인했다.
- 숨김 상태까지 검사했다. 좌표가 오래된 재배정·처리 버튼 18개는 잠시 표시해 가운데 정렬과 한 줄 높이 21pt를 실측한 후 원래 숨김 상태로 복원했다. 숨김 상태에서 다시 읽는 좌표는 Figma가 재계산하지 않을 수 있으므로 표시 상태의 실측값을 기준으로 기록한다.
- 가시 텍스트 4,896개 중 고정 높이 786개를 실제 자동 높이와 대조했다. 안내문 24개의 1pt 부족을 높이 자동 확장으로 수정했다. 수정 후 검사 범위에서 텍스트 경계 이탈·truncation 0건이다. 확인 모달 버튼 행은 44pt로 확보하고 필요한 모달 높이도 늘렸다.
- 1440×960 화면 104개는 UMC Light 52개·Dark 52개로 명시했다. 심사·조정 양 모드와 탐색·노치·삭제 확인 캡처에서 대비·문구·버튼을 직접 확인했다. 기존 막대의 분모와 비율, 읽기 전용·공개 예정·처리 중 상태는 유지했다.

프로토타입 내부 반응 2,124개, 내부 목적지 106개를 확인했고 UPMS 내부 화면 전환의 Mid-fi 페이지 잔존은 0개다. 원본의 자기 화면 유지 연결 14개는 유지한다. UPMS 밖 프로젝트 작업 공간으로 가는 버튼 8개는 대응 Hi-fi 화면이 없어 **기존 목적지의 Figma 외부 URL 링크**로 보존했다. 따라서 내부 전환과 외부 링크를 합한 반응은 2,132개다. 버튼과 기존 기능 설명은 삭제하지 않았으며, 이 8개는 Hi-fi 안에서 연속 재생되는 전환이 아니다. 전체 프로토타입 클릭 실행, 실제 입력·서버 호출·실시간 갱신·macOS 실행은 이번 Figma 작업의 검증 범위가 아니다.

추가 캡처에서 확인한 정렬 문제도 같은 날 수정했다. 심사 범례 14개(양 모드·읽기 전용·보조 PM 등 변형)의 칩과 전체 인원 중심을 y=17pt로 통일하고, 범례와 분포 막대 사이를 8pt로 맞췄다. 명단 작업 행 18개는 버튼과 권한 안내를 y=20pt 중심으로 정렬했다. 일반·최종 조정 설명 4개는 본문 전체 폭 1,284pt·13pt 글자·20pt 행간의 자동 높이 영역으로 분리했다. 설명의 끝은 y=781pt로 부모 높이 826pt 안에 들어가며, 좌우 경계 이탈은 없다. `배정하기`·`배정 해제`·`재배정하기`·`불합격 판정`으로 52개 버튼 라벨을 완결형으로 바꿔 문자로 들어 있던 말줄임표를 제거했다. 실제 중심 좌표와 전체·확대 캡처를 함께 확인했으며 서버 동작이나 확인 대화상자 연결은 바꾸지 않았다.

대표 링크: [프로젝트 탐색](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1052-5661), [지원자 심사](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1053-9192), [최종 조정](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1053-11831), [노치 확장](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1053-25893), [답변 포함 삭제 확인](https://www.figma.com/design/kM8a1siXgusAVRRgyUZ15U/?node-id=1053-25137). 검증 캡처는 저장소 밖 `/tmp/upms-hifi-*.png`, 원본·대상 매핑은 `/tmp/upms-hifi-state.json`에 남겼다. 앱·서버 코드나 새로운 정책은 변경하지 않았다.

### 실제 앱 셸 구조 반영 — 2026-11-17

현재 앱의 Settings/MyPage 구현과 사용자 제공 실행 화면을 기준으로 UPMS Hi-fi 앱 화면 104개(양 모드 52쌍)의 공통 셸을 수정했다. UPMS 자체의 실행 화면이 구현됐다는 뜻은 아니다. 앱 코드와 공용 Figma 마스터는 변경하지 않았다. 확인 모달 8개는 독립 오버레이여서 자체 셸이 없고, 노치 10개는 데스크톱 모형이므로 이번 셸 수정 대상에서 제외했다.

| 실제 코드 근거 | Figma 반영 |
|---|---|
| `UMCDesk/Features/Settings/Presentation/Sources/SettingsView.swift:73` — 레일 44pt, 좌측 여백 4pt와 간격 4pt, 우측·하단 12pt, 콘텐츠 반경 16pt | 1440×960에서 콘텐츠 `(52,40,1376,908)`, 레일 `(4,40,44,908)`, 콘텐츠 반경16 |
| 같은 파일 `:157` — AppShell 배경의 windowToolbar, Dark toolbar 색상 체계 | Light·Dark 모두 검은 상단바에 창 제어와 탐색 버튼 배치. 본문은 각각 UMC Light·Dark 유지 |
| 같은 파일 `:353` — `.navigation`, 32pt 버튼 2개와 간격4pt, glyph16pt, 비활성 opacity0.3 | 뒤로·앞으로를 본문 툴바에서 상단바로 이동하고 chevron으로 표현. 기존 연결·활성 상태 유지 |
| 같은 파일 `:187` — 레일 항목44×44, glyph16pt, 프로필 이미지32pt·하단 여백16pt | 아이콘 행을 상단부터44pt 간격으로 배치. 프로필은 UPMS 로컬 복제 인스턴스로32pt 적용 |
| `UMCDesk/UMCDesk/Sources/App/UMCDeskApp.swift:48` — 기본1440×960, titleBar·unifiedCompact | 네이티브 상단바 높이는 코드 상수가 아니다. 제공된 실행 캡처를 참고한40pt 시안으로 표시 |

매칭 도구 등 UPMS 기능 액션은 기존 본문 상단에 유지했다. 설정 전용 271pt 카테고리 사이드바를 UPMS에 추가하지 않았다. 본문 폭은1,284pt 그대로이며 높이는826→828pt로 늘었다. 기존 내용·버튼·상태·시각화는 변경하지 않았다.

수정 전후104개 화면의 전체 텍스트 개수·문자열 해시와 프로토타입 노드·반응·목적지 해시가 모두 동일하다. 해당 화면 안의 반응을 가진 노드는2,088개이며, 반응 개수와는 다른 집계다. 최종 좌표는104개 모두 위 표와 일치했고 가시 본문 텍스트의 직접 부모 경계 이탈은0건이었다. Light·Dark 탐색, Dark 심사, Light 최종 조정 캡처를 직접 확인했다. 감사 기록은 `/tmp/upms-shell-preservation-audit.json`, 대표 캡처는 `/tmp/upms-app-shell-light.png`, `/tmp/upms-app-shell-dark.png`, `/tmp/upms-app-shell-review-dark.png`, `/tmp/upms-app-shell-adjust-light.png`다. 전체 프로토타입을 실제 클릭하며 재생하는 검증은 수행하지 않았다.

[auto-decide-api]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectMatchingRoundController.java#L126

[decision]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/policy/MatchingDecisionPolicy.java#L48
[publication]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectMatchingResultPublicationCommandService.java#L66
[publication-test]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/test/java/com/umc/product/project/application/service/command/ProjectMatchingResultPublicationCommandServiceTest.java#L82
[random]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectMatchingRoundFinalizationCommandService.java#L353
[random-guard]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectMatchingRoundFinalizationCommandService.java#L124
[create-request]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/dto/request/CreateDraftProjectRequest.java#L13
[create]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectCommandService.java#L96
[decide-access]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/access/ProjectApplicationDecisionPolicy.java#L26
[authority]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/authorization/domain/AuthoritySnapshot.java#L74
[management-scope]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/access/ProjectAccessScopeResolver.java#L118
[apply-create]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectApplicationCommandService.java#L95
[apply-submit]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectApplicationCommandService.java#L215
[apply-update]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectApplicationCommandService.java#L170
[manual-candidate]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectManualMatchingCommandService.java#L163
[form-guard]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/domain/Project.java#L224
[form-edit]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectApplicationFormCommandService.java#L95
[form-fork]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectApplicationFormCommandService.java#L413
[detail]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/query/ProjectApplicationQueryService.java#L98
[section-delete]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectApplicationFormCommandService.java#L308
[option-change]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/form/application/service/command/QuestionOptionCommandService.java#L68
[form-test]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/test/java/com/umc/product/project/application/service/command/ProjectApplicationFormCommandServiceTest.java#L486
[round-time]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/domain/ProjectMatchingRound.java#L292
[adjustment]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/policy/ProjectMatchingAdjustmentPolicy.java#L89
[manual]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectManualMatchingCommandService.java#L63
[manual-test]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/test/java/com/umc/product/project/application/service/command/ProjectManualMatchingIntegrationTest.java#L501
[quota-publication]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectMatchingQuotaPublicationService.java#L29
[quota-test]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/test/java/com/umc/product/project/application/service/command/ProjectMatchingQuotaPublicationServiceTest.java#L45
[deletion]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/command/ProjectDeletionCommandService.java#L63
[delete-guard]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/domain/Project.java#L277
[delete-form]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/form/application/service/command/FormCommandService.java#L114
[deletion-test]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/test/java/com/umc/product/project/application/service/command/ProjectDeletionIntegrationTest.java#L66
[roster]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/query/ProjectPublishedMembersQueryService.java#L74
[release-test]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/test/java/com/umc/product/project/application/service/command/ProjectManualMatchingIntegrationTest.java#L269
[delete-access]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/evaluator/ProjectPermissionEvaluator.java#L124
[list-scope]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/access/ProjectApplicationAccessScopeResolver.java#L65
[detail-access]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/evaluator/ProjectApplicationPermissionEvaluator.java#L88
[capability]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/query/ProjectPermissionQueryService.java#L386
[round-response]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/dto/response/ProjectMatchingRoundResponse.java#L9
[designer]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/policy/DesignerMatchingPolicy.java#L25

[web-readme]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/README.md#L1
[web-access]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/entities/session/lib/access.ts#L16
[web-schedule]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/features/matching-schedule/model/calculateSchedule.ts#L9
[web-schedule-request]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/features/matching-schedule/model/toMatchingRoundRequests.ts#L62
[web-delete]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/features/project-management/ui/ProjectManagementCard/ProjectManagementCard.tsx#L86
[web-projects]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/project-settings/-projects/ProjectsPage.tsx#L148
[web-period]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/team-matching/-status/useAssignablePeriod.ts#L25
[web-assign]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/team-matching/-status/MatchingStatusPage.tsx#L75
[web-quota]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/project-settings/-quota/QuotaPage.tsx#L159
[web-overquota]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/team-matching/-status/MatchingStatusPage.tsx#L186
[web-read-period]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/team-matching/-applications/useMatchingPeriodAccess.ts#L10
[web-admin-read]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/team-matching/-applications/AdminApplications.tsx#L282
[web-pm-read]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/routes/demo-day/team-matching/-applications/PmApplications.tsx#L230
[web-form]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/features/project-register/lib/toApplicationForm.ts#L109
[web-form-save]: https://github.com/UMC-PRODUCT/umc-product-web-activity/blob/cded27e6aca1a8114fe8a1e8ca587a8003fefedc/src/features/project-register/lib/saveProject.ts#L112
[web-commit]: https://github.com/UMC-PRODUCT/umc-product-web-activity/commit/cded27e6aca1a8114fe8a1e8ca587a8003fefedc
[v2-commit]: https://github.com/UMC-PRODUCT/umc-product-web-v2/commit/51b03fb54b2a72e4bf4cbc84730e827c41c7c823
[v2-period]: https://github.com/UMC-PRODUCT/umc-product-web-v2/blob/51b03fb54b2a72e4bf4cbc84730e827c41c7c823/src/features/project/new/model/matchingPeriod.ts#L5
[figma-current]: https://www.figma.com/design/mgDK3eBgoDYfARQEmtcoxQ/?node-id=14447-544993
[figma-status]: https://www.figma.com/design/mgDK3eBgoDYfARQEmtcoxQ/?node-id=14661-114712
[figma-manual]: https://www.figma.com/design/mgDK3eBgoDYfARQEmtcoxQ/?node-id=14661-116385
[figma-delete]: https://www.figma.com/design/mgDK3eBgoDYfARQEmtcoxQ/?node-id=14661-33187
[figma-read-comment]: https://www.figma.com/file/mgDK3eBgoDYfARQEmtcoxQ#1957113058
[application-detail-api]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectApplicationQueryController.java#L199
[application-list-api]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectApplicationQueryController.java#L143
[manual-api]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectManualMatchingController.java#L31
[form-api]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectApplicationFormController.java#L36
[form-request]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/dto/request/UpsertApplicationFormRequest.java#L23
[application-write-api]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectApplicationController.java#L47

[stats-contract]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/ProjectStatisticsQueryController.java#L87
[stats-response]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/in/web/dto/response/statistics/ProjectMatchingStatisticsResponse.java#L42
[stats-filter]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/query/ProjectStatisticsQueryService.java#L151
[stats-calculation]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/application/service/query/ProjectStatisticsQueryService.java#L566
[stats-query]: https://github.com/UMC-PRODUCT/umc-product-server/blob/60fdadd2cb0ef7c8a252cc1903859af56ba7b015/monolith/src/main/java/com/umc/product/project/adapter/out/persistence/ProjectStatisticsQueryRepository.java#L138

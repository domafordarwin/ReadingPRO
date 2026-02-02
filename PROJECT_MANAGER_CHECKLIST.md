# ✅ 프로젝트 매니저 실행 체크리스트

**목표**: ReadingPRO v2.0 문서 검토 프로세스를 체계적으로 관리하고 추진
**역할**: 프로젝트 매니저, 리더, 운영 담당자
**기간**: 2026-02-02 ~ 2026-02-18

---

## 📋 Week 1: 검토 프로세스 시작 (Feb 2-10)

### 월요일 (Feb 3) - 준비 및 공지

#### 아침 (09:00-10:00)
- [ ] **README.md 최종 확인**
  - [ ] "Document Review & Feedback Process" 섹션 포함 여부
  - [ ] 모든 문서 링크 작동 확인
  - [ ] 상태 표시 "ACTIVE - Document Review Phase" 확인

- [ ] **팀 리더 1:1 브리핑** (각 15분)
  - [ ] PO: PRD 검토 범위, 일정, 기대사항
  - [ ] 기술리더: TRD 검토 범위, 일정, 기대사항
  - [ ] DevOps: DEPLOYMENT_GUIDE 검토 범위, 일정, 기대사항
  - [ ] 구현팀 리더: MIGRATION_RUNBOOK 검토 범위, 일정, 기대사항

#### 오전 (10:00-11:00)
- [ ] **팀 전체 공지 미팅**
  - 참석: 전체 팀 (또는 각 팀 리더)
  - 자료: TEAM_COMMUNICATION_TEMPLATE.md 기반
  - 시간: 30분

  **공지 내용**:
  - 📌 일정: Feb 3-18 (4단계)
  - 📋 역할별 책임: 누가 어떤 문서를 언제까지 검토
  - 🎯 기대사항: 정성스러운 검토, 구체적인 피드백
  - 📚 시작 가이드: QUICK_REVIEW_SUMMARY.md 참조
  - 📢 질문 채널: Slack/GitHub Issues

#### 오후 (14:00-15:00)
- [ ] **각 역할별 담당자에게 문서 배포**
  - [ ] PO에게: PRD.md + QUICK_REVIEW_SUMMARY.md + REVIEW_GUIDE.md (PO 섹션)
  - [ ] 기술리더에게: TRD.md + QUICK_REVIEW_SUMMARY.md + REVIEW_GUIDE.md (기술리더 섹션)
  - [ ] 백엔드 개발자 1에게: API_SPECIFICATION.md + REVIEW_GUIDE.md
  - [ ] 백엔드 개발자 2에게: DATABASE_SCHEMA.md + REVIEW_GUIDE.md
  - [ ] 전체 개발자에게: DEVELOPER_GUIDE.md (참조용)
  - [ ] DevOps에게: DEPLOYMENT_GUIDE.md + REVIEW_GUIDE.md
  - [ ] 구현팀에게: MIGRATION_RUNBOOK.md + REVIEW_GUIDE.md

- [ ] **각 역할 리더 1:1 확인**
  - [ ] "문서 받으셨나요?"
  - [ ] "QUICK_REVIEW_SUMMARY.md 먼저 읽어주세요"
  - [ ] "질문이 있으면 언제든지 물어봐주세요"

#### 저녁 (16:00-17:00)
- [ ] **검토 추적 준비**
  - [ ] FEEDBACK_TRACKER.md 최신 버전 확인
  - [ ] 공유 드라이브/Confluence에 업로드 (Optional)
  - [ ] 각 역할별 섹션이 명확한지 확인
  - [ ] "검토 상태" 열 준비 (추적용)

---

### 화요일-금요일 (Feb 4-8) - 모니터링

#### 일일 체크인 (10:00)
- [ ] **Slack에서 검토 진행 상황 확인**
  - Q: 누가 검토를 시작했는가?
  - Q: 질문이나 이슈가 있는가?
  - Q: 막힘이 있는가?

#### 수요일 (Feb 6) - 진행 상황 점검
- [ ] **Mid-week 확인 (선택사항)**
  - [ ] PO/기술리더와 짧은 통화 (5분)
  - Q: 검토 진행 상황은?
  - Q: 추가 설명이 필요한 부분은?

#### 금요일 (Feb 8) - 주간 정리
- [ ] **주간 진행 상황 정리**
  - [ ] 검토 완료율 확인 (목표: 50% 이상)
  - [ ] 주요 피드백 선제적으로 정리
  - [ ] 미진행 역할 리더에게 알림

---

### 금요일 (Feb 10) - 검토 완료 확인

#### 오전 (09:00-10:00)
- [ ] **최종 확인 리마인더**
  - [ ] 모든 역할 리더에게 "내일 마감입니다" 알림
  - [ ] FEEDBACK_TRACKER.md에 피드백 작성하도록 당부

#### 오후 (14:00-16:00)
- [ ] **검토 완료 확인**
  - [ ] PO: PRD 검토 완료? → FEEDBACK_TRACKER.md에 기록됨?
  - [ ] 기술리더: TRD 검토 완료? → FEEDBACK_TRACKER.md에 기록됨?
  - [ ] 백엔드 개발 1: API 검토 완료? → FEEDBACK_TRACKER.md에 기록됨?
  - [ ] 백엔드 개발 2: DB 검토 완료? → FEEDBACK_TRACKER.md에 기록됨?
  - [ ] DevOps: DEPLOYMENT_GUIDE 검토 완료? → FEEDBACK_TRACKER.md에 기록됨?
  - [ ] 구현팀: MIGRATION_RUNBOOK 검토 완료? → FEEDBACK_TRACKER.md에 기록됨?

- [ ] **미진행 항목 마무리**
  - 아직 미완료: [역할명] → 개인 통화
  - 오늘 중 반드시 완료 당부
  - 늦으면 월요일까지 연장 가능 (1-2일만)

#### 저녁 (16:00-17:00)
- [ ] **검토 결과 정리**
  - [ ] FEEDBACK_TRACKER.md 수집 완료
  - [ ] 정리가 필요한 피드백 정리
  - [ ] P0/P1/P2 우선순위 1차 파악

---

## 📋 Week 2: 피드백 통합 (Feb 11-12)

### 월요일 (Feb 11) - 피드백 통합 미팅

#### 오전 (09:00-10:00)
- [ ] **미팅 준비**
  - [ ] 참석자: 모든 역할 리더 + 아키텍트
  - [ ] 장소: 회의실 또는 온라인
  - [ ] 시간: 1.5-2시간

#### 오전/오후 (10:00-15:00)
- [ ] **피드백 통합 미팅 진행**
  - [ ] **1단계 (30분): 피드백 검토**
    - FEEDBACK_TRACKER.md의 모든 P0 항목 검토
    - 각 항목별로:
      - 현재 상태 확인
      - 해결 우선순위 확인
      - 상충 해결 (동일 항목에 대한 다른 의견)

  - [ ] **2단계 (30분): P1 항목 검토**
    - 비슷한 주제끼리 그룹화
    - 우선순위 순서 정하기
    - 담당자/담당 문서 배정

  - [ ] **3단계 (15분): P2 항목 검토**
    - 빠른 검토 (의견 충돌 없는지 확인)
    - 장기 과제로 등록

  - [ ] **4단계 (15분): 수정 계획 수립**
    - P0: 누가 Feb 13-14에 수정할 것인가?
    - P1: 누가 Feb 15-17에 수정할 것인가?
    - P2: 나중에 처리할 것임을 확인

#### 오후 (15:00-16:00)
- [ ] **미팅 결과 정리**
  - [ ] FEEDBACK_TRACKER.md "피드백 통합" 섹션 업데이트
  - [ ] 각 문서별 수정 담당자 명시
  - [ ] 예상 완료 날짜 기록

#### 저녁 (16:00-17:00)
- [ ] **전체 팀 공지**
  - [ ] Slack/Email로 피드백 통합 결과 공지
  - [ ] P0/P1/P2 구분된 수정 계획 공유
  - [ ] "Feb 13부터 수정 시작합니다" 알림

---

### 화요일 (Feb 12) - 최종 정리

- [ ] **수정 가능성 재확인**
  - [ ] P0 항목이 정말 즉시 수정 가능한가?
  - [ ] 아키텍트/리더와 수정 방안 재논의 (필요시)
  - [ ] 리소스/시간 재확인

- [ ] **수정 계획 문서화**
  - [ ] FEEDBACK_TRACKER.md의 "P0 - 즉시 수정 필요" 섹션 완성
  - [ ] 각 항목: 현재 상태 → 개선안 → 수정 방법
  - [ ] 담당자 및 완료 예상 일자 명시

---

## 📋 Week 3: 문서 수정 (Feb 13-17)

### 월요일 (Feb 13) - P0 수정 시작

#### 오전 (09:00-10:00)
- [ ] **P0 항목 배정**
  - [ ] 각 담당자에게 직접 할당 (메시지)
  - [ ] PRD P0 → PO에게
  - [ ] TRD P0 → 기술리더에게
  - [ ] API P0 → 백엔드 개발 1에게
  - [ ] DB P0 → 백엔드 개발 2에게
  - [ ] DEPLOY P0 → DevOps에게
  - [ ] MIGRATE P0 → 구현팀에게

#### 오전/오후 (10:00-17:00)
- [ ] **P0 수정 모니터링**
  - 10:30: "시작하셨나요?" 확인
  - 13:00: 점심 후 진행 상황 확인
  - 16:00: "오늘 완료 가능한가?" 확인

#### 저녁 (16:00-17:00)
- [ ] **P0 수정 완료 체크**
  - [ ] Git에 commit되었는가?
  - [ ] FEEDBACK_TRACKER.md에 "완료" 표시
  - [ ] 수정 내용 간단히 정리

---

### 화요일-목요일 (Feb 14-16) - P1 수정

#### 08:00-09:00 (일일 스탠드업)
- [ ] **진행 상황 확인**
  - [ ] P0 항목 모두 완료되었나?
  - [ ] P1 수정 시작되었나?
  - [ ] 막힘이 있는가?

#### 일일 모니터링
- [ ] P1 수정 진행 상황 확인
- [ ] 질문/이슈 해결 지원
- [ ] 완료된 항목 체크

#### 저녁 (16:00-17:00)
- [ ] **일일 정리**
  - [ ] 완료된 P1 항목 정리
  - [ ] FEEDBACK_TRACKER.md 업데이트
  - [ ] 남은 P1 항목 상태 확인

---

### 금요일 (Feb 17) - 수정 완료 확인

#### 오전 (09:00-11:00)
- [ ] **최종 검토**
  - [ ] 모든 P0, P1 항목 완료되었나?
  - [ ] Git commits 확인
  - [ ] FEEDBACK_TRACKER.md 최신화

#### 오후 (14:00-15:00)
- [ ] **문서 최종 상태 확인**
  - [ ] 7개 문서 모두 최신 버전인가?
  - [ ] 링크 작동하는가?
  - [ ] README.md에 "Document Review & Feedback Process" 섹션은?

#### 저녁 (15:00-16:00)
- [ ] **역할별 리더 최종 검토 요청**
  - [ ] PO에게: "PRD 최종 검토 가능한가?"
  - [ ] 기술리더에게: "TRD 최종 검토 가능한가?"
  - [ ] DevOps에게: "DEPLOYMENT_GUIDE 최종 검토 가능한가?"
  - [ ] 구현팀에게: "MIGRATION_RUNBOOK 최종 검토 가능한가?"

---

## 📋 Week 4: 최종 승인 (Feb 18)

### 월요일 (Feb 18) - 최종 승인

#### 오전 (09:00-10:00)
- [ ] **각 역할별 승인 수집**
  - [ ] PO: PRD 최종 승인? (Yes/No/Minor changes)
  - [ ] 기술리더: TRD 최종 승인?
  - [ ] 백엔드 개발 리더: API + DB 최종 승인?
  - [ ] DevOps: DEPLOYMENT_GUIDE 최종 승인?
  - [ ] 구현팀: MIGRATION_RUNBOOK 최종 승인?

#### 오전 (10:00-12:00)
- [ ] **승인 결과 정리**
  - [ ] FEEDBACK_TRACKER.md "최종 검토 결과" 섹션 완성
  - [ ] 모든 리더의 승인 의견 기록
  - [ ] 주요 변경사항 요약

#### 오후 (14:00-15:00)
- [ ] **최종 공지 미팅** (선택사항)
  - [ ] 전체 팀에게 검토 완료 결과 공지
  - [ ] 다음 단계 안내: Phase 1 마이그레이션 (Feb 19)
  - [ ] 감사의 말씀

#### 저녁 (15:00-16:00)
- [ ] **구현 준비**
  - [ ] MIGRATION_RUNBOOK.md 최종 버전 확인
  - [ ] Phase 1 관련 팀원 (DB, 백엔드) 호출
  - [ ] "내일 오전 10시에 Phase 1 Kickoff" 예약

#### 저녁 (16:00-17:00)
- [ ] **최종 정리**
  - [ ] FEEDBACK_TRACKER.md 완성도 100% 확인
  - [ ] Git 최신 커밋 확인
  - [ ] README.md에 "Document Review Complete" 표시 (선택)

---

## 🎯 Success Metrics

### 검토 완료 기준

- [x] **모든 문서 검토 완료**
  - [ ] PRD 검토 완료 (PO)
  - [ ] TRD 검토 완료 (기술리더)
  - [ ] API_SPECIFICATION 검토 완료 (백엔드 1)
  - [ ] DATABASE_SCHEMA 검토 완료 (백엔드 2)
  - [ ] DEVELOPER_GUIDE 검토 완료 (전체 개발자)
  - [ ] DEPLOYMENT_GUIDE 검토 완료 (DevOps)
  - [ ] MIGRATION_RUNBOOK 검토 완료 (구현팀)

- [x] **피드백 우선순위화**
  - [ ] P0 항목 100% 식별 및 해결
  - [ ] P1 항목 80% 이상 해결
  - [ ] P2 항목 검토됨

- [x] **문서 수정 완료**
  - [ ] P0 항목 모두 수정됨 (Feb 14까지)
  - [ ] P1 항목 모두 수정됨 (Feb 17까지)
  - [ ] 수정사항이 Git에 커밋됨

- [x] **최종 승인**
  - [ ] 모든 역할별 리더의 승인 획득
  - [ ] FEEDBACK_TRACKER.md 완성

---

## 📊 추적용 템플릿

### Daily Stand-up (매일 10:00)

```
## ReadingPRO v2.0 문서 검토 진행 상황

### 검토 진행 (Feb 3-10)
- [ ] PO (PRD): □□□□□ (50%)
- [ ] Tech Lead (TRD): □□□□□ (50%)
- [ ] Backend Dev 1 (API): □□□□□ (50%)
- [ ] Backend Dev 2 (DB): □□□□□ (50%)
- [ ] All Devs (Dev Guide): □□□□□ (50%)
- [ ] DevOps (Deploy): □□□□□ (50%)
- [ ] Impl Team (Migration): □□□□□ (50%)

### 질문/이슈
- Q: 누가 질문을 했는가?
- Answer: [답변 또는 리더 배정]

### 예상 문제
- [예상 문제 및 대응책]

### 다음 24시간 계획
- [다음 24시간 주요 액션 아이템]
```

---

## 📞 긴급 연락처

| 역할 | 이름 | 연락처 | 담당 |
|------|------|--------|------|
| **PO** | [이름] | [Slack/Email] | PRD.md |
| **기술리더** | [이름] | [Slack/Email] | TRD.md |
| **DevOps** | [이름] | [Slack/Email] | DEPLOYMENT_GUIDE.md |
| **구현팀 리더** | [이름] | [Slack/Email] | MIGRATION_RUNBOOK.md |
| **프로젝트 매니저** | [본인] | [Slack/Email] | 전체 조율 |

---

## 🎓 팁 & 주의사항

✅ **해야 할 것**:
- 정기적으로 상황 파악하기
- 막힘이 있으면 즉시 해결 지원하기
- 긍정적 피드백도 함께 나누기
- 진행 상황 투명하게 공유하기

❌ **하면 안 되는 것**:
- 검토자에게 "빨리 끝내" 압박하기
- 피드백을 무시하거나 반박하기
- 일정을 임의로 변경하기
- 프로세스 단계를 건너뛰기

---

## 📌 중요 파일 링크

**매일 모니터링할 파일**:
- 👉 [FEEDBACK_TRACKER.md](FEEDBACK_TRACKER.md)
- 👉 [README.md](README.md) - Document Review 섹션

**팀에 공지할 파일**:
- 👉 [TEAM_COMMUNICATION_TEMPLATE.md](TEAM_COMMUNICATION_TEMPLATE.md)
- 👉 [QUICK_REVIEW_SUMMARY.md](docs/QUICK_REVIEW_SUMMARY.md)
- 👉 [REVIEW_GUIDE.md](REVIEW_GUIDE.md)

**검토 대상 7개 문서**:
- [docs/PRD.md](docs/PRD.md)
- [docs/TRD.md](docs/TRD.md)
- [docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)
- [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md)
- [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)
- [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
- [docs/MIGRATION_RUNBOOK.md](docs/MIGRATION_RUNBOOK.md)

---

**이 체크리스트를 따르면 ReadingPRO v2.0 문서 검토를 체계적이고 효율적으로 진행할 수 있습니다.**

**성공을 기원합니다! 🚀**

---

*마지막 업데이트: 2026-02-02*

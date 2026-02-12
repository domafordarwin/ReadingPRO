# Rails 8 Solid Trifecta 적용 보고서

> 작성일: 2026-02-13
> 작성자: Claude Opus 4.6
> 프로젝트: ReadingPRO (Railway 배포)

---

## 1. 개요

Rails 8의 **Solid Trifecta**(Solid Cache + Solid Queue + Solid Cable)를 ReadingPRO 프로젝트에 적용하여, Redis 등 외부 인프라 의존 없이 PostgreSQL만으로 캐싱과 백그라운드 잡 처리를 구현하였다.

### 적용 현황 요약

| 구성 요소 | 역할 | 적용 상태 | 비고 |
|-----------|------|-----------|------|
| **Solid Cache** | DB 기반 캐시 저장소 | ✅ 활성화 | Redis/Memcached 대체 |
| **Solid Queue** | DB 기반 백그라운드 잡 큐 | ✅ 활성화 | Sidekiq/Redis 대체 |
| **Solid Cable** | DB 기반 WebSocket pub/sub | ⬜ 미적용 | 실시간 기능 미사용으로 불필요 |

---

## 2. 변경 내역

### 커밋 목록 (4건)

| 커밋 | 설명 |
|------|------|
| `81acb01` | feat: Solid Cache 활성화 및 대시보드 캐시 최적화 |
| `ed416ad` | chore: Solid Cache 전역 max_age 60일 설정 |
| `a3fde6e` | feat: Solid Queue 활성화 (DB 기반 백그라운드 잡 큐) |
| `5530736` | chore: CLAUDE.md에 자동 커밋/푸시 규칙 추가 |

### 변경 파일 (7개, +63줄 / -23줄)

| 파일 | 변경 내용 |
|------|-----------|
| `config/environments/production.rb` | `:memory_store` → `:solid_cache_store`, `:async` → `:solid_queue` |
| `config/cache.yml` | `max_age: 60일` 활성화 |
| `config/puma.rb` | production에서 Solid Queue 플러그인 자동 실행 |
| `bin/docker-entrypoint` | `db:migrate` → `db:prepare` (cache/queue 테이블 자동 생성) |
| `app/controllers/researcher/dashboard_controller.rb` | 3곳에 `Rails.cache.fetch` 캐시 적용 |
| `app/services/cache_warmer_service.rb` | `invalidate_dashboard_caches` 메서드 추가 |
| `CLAUDE.md` | 자동 커밋/푸시 규칙 명시 |

---

## 3. Solid Cache 상세

### 3.1 이전 상태 (문제점)

- `config.cache_store = :memory_store` (인메모리)
- Railway 재배포 시 **모든 캐시 소멸**
- `CacheWarmerService`가 매 배포마다 처음부터 캐시를 재구축
- 첫 번째 방문자가 항상 느린 응답을 경험

### 3.2 변경 후

- `config.cache_store = :solid_cache_store` (PostgreSQL)
- 캐시가 `solid_cache_entries` 테이블에 **영구 저장**
- 재배포 후에도 캐시 유지 → 즉시 빠른 응답

### 3.3 캐시 전역 설정

```yaml
# config/cache.yml
default:
  store_options:
    max_age: 5,184,000초 (60일)  # 전역 만료 안전장치
    max_size: 256MB               # 최대 캐시 용량
    namespace: production          # 환경별 분리
```

### 3.4 캐시 포인트 현황

| 캐시 키 | TTL | 대상 데이터 | 무효화 시점 |
|---------|-----|------------|------------|
| `researcher/dashboard_stats` | 30분 | 대시보드 통계 (Item.count 등 4개 쿼리) | Item/Stimulus 변경 |
| `researcher/evaluation_stats` | 1시간 | 평가영역 통계 (4개 집계) | Item/Stimulus 변경 |
| `researcher/evaluation_indicators_list` | 1시간 | 평가 지표 드롭다운 목록 | Item/Stimulus 변경 |
| `researcher/sub_indicators_list` | 1시간 | 세부 지표 드롭다운 목록 | Item/Stimulus 변경 |
| `items_total_count_{filter}` | 1시간 | 문항 총 개수 (필터별) | — |
| `bundles_total_count_{filter}` | 1시간 | 모듈 총 개수 (필터별) | — |
| `item_types` / `item_statuses` / `item_difficulties` | 1일 | 필터 옵션 (enum 목록) | Item 변경 |
| `stimuli_total_count` / `stimuli_by_status` | 1일 | 지문 통계 | Stimulus 변경 |
| HTTP ETag (Item Bank) | 5분 | 브라우저 캐시 | — |

### 3.5 캐시 무효화 체계

```
Item 생성/수정/삭제
  └─ after_save/after_destroy → invalidate_item_caches
       ├─ item_types, item_statuses, item_difficulties 삭제
       └─ invalidate_dashboard_caches
            ├─ researcher/dashboard_stats 삭제
            ├─ researcher/evaluation_stats 삭제
            ├─ researcher/evaluation_indicators_list 삭제
            └─ researcher/sub_indicators_list 삭제

ReadingStimulus 생성/수정/삭제
  └─ after_save/after_destroy → invalidate_stimulus_caches
       ├─ stimuli_total_count, stimuli_by_status 삭제
       └─ invalidate_dashboard_caches (동일)
```

---

## 4. Solid Queue 상세

### 4.1 이전 상태 (문제점)

- `config.active_job.queue_adapter = :async` (인메모리)
- 서버 재시작 시 **대기 중인 잡 유실**
- 실패한 잡의 추적/재시도 불가
- 스케줄링된 반복 작업 불가

### 4.2 변경 후

- `config.active_job.queue_adapter = :solid_queue` (PostgreSQL)
- 잡이 `solid_queue_jobs` 테이블에 **영구 저장**
- 실패 시 `solid_queue_failed_executions`에 기록 → 디버깅 가능
- Puma 프로세스 내에서 인프로세스 실행 (별도 워커 불필요)

### 4.3 Puma 통합

```ruby
# config/puma.rb
plugin :solid_queue if ENV["RAILS_ENV"] == "production" || ENV["SOLID_QUEUE_IN_PUMA"]
```

Railway의 단일 컨테이너 환경에서 Puma 내부에 Solid Queue 수퍼바이저가 함께 실행된다.

### 4.4 Queue 설정

```yaml
# config/queue.yml
default:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 1 (JOB_CONCURRENCY 환경변수로 조정 가능)
      polling_interval: 0.1
```

### 4.5 등록된 백그라운드 잡

| 잡 | 큐 | 역할 |
|------|------|------|
| `PerformanceMetricRecorderJob` | `:performance` | 성능 메트릭 비동기 기록 |
| `AlertEvaluatorJob` | `:performance` | 성능 임계값 초과 시 알림 평가 |
| `MetricAggregatorJob` | `:low` | 시간별 메트릭 집계 + 오래된 데이터 정리 |

### 4.6 DB 테이블 (자동 생성)

`db/queue_schema.rb`에 정의된 10개 테이블:

| 테이블 | 역할 |
|--------|------|
| `solid_queue_jobs` | 잡 메타데이터 |
| `solid_queue_ready_executions` | 실행 대기 잡 |
| `solid_queue_scheduled_executions` | 예약된 잡 |
| `solid_queue_claimed_executions` | 워커가 가져간 잡 |
| `solid_queue_blocked_executions` | 동시성 제어로 블록된 잡 |
| `solid_queue_failed_executions` | 실패한 잡 (디버깅용) |
| `solid_queue_recurring_executions` | 반복 실행 잡 |
| `solid_queue_recurring_tasks` | 반복 작업 정의 |
| `solid_queue_processes` | 워커/디스패처 프로세스 |
| `solid_queue_semaphores` | 동시성 제어 세마포어 |
| `solid_queue_pauses` | 큐 일시정지 |

---

## 5. 인프라 변경: docker-entrypoint

### 이전

```bash
RAILS_LOG_LEVEL=warn ./bin/rails db:migrate
```

- `db/migrate` 디렉토리의 마이그레이션만 실행
- cache/queue/cable의 스키마 파일은 무시됨

### 이후

```bash
RAILS_LOG_LEVEL=warn ./bin/rails db:prepare
```

- primary DB: 마이그레이션 실행 (`db:migrate`)
- cache DB: `db/cache_schema.rb` 로드 → `solid_cache_entries` 테이블 생성
- queue DB: `db/queue_schema.rb` 로드 → `solid_queue_*` 테이블 10개 생성
- 이미 존재하는 테이블은 건너뜀 (멱등성 보장)

---

## 6. Solid Cable 미적용 사유

- 현재 ReadingPRO에 **실시간 WebSocket 기능 없음**
- Action Cable을 사용하는 뷰/컨트롤러가 없음
- 향후 실시간 알림, 라이브 채팅 등 기능 추가 시 활성화 가능
- 활성화 시 변경점: `cable.yml`의 adapter를 `solid_cable`로 변경

---

## 7. 효과 요약

### 비용 절감

| 항목 | 이전 | 이후 |
|------|------|------|
| Redis 인스턴스 | 불필요 (미사용) | 여전히 불필요 ✅ |
| 추가 워커 프로세스 | — | 불필요 (Puma 내장) |
| 인프라 복잡도 | PostgreSQL만 | PostgreSQL만 (변동 없음) |

### 안정성 향상

| 항목 | 이전 | 이후 |
|------|------|------|
| 캐시 재배포 시 | ❌ 소멸 | ✅ 유지 |
| 백그라운드 잡 재시작 시 | ❌ 유실 | ✅ 유지 |
| 실패 잡 추적 | ❌ 불가 | ✅ DB에 기록 |
| 잡 스케줄링 | ❌ 불가 | ✅ 반복/예약 실행 가능 |

### 성능 개선

| 항목 | 이전 | 이후 |
|------|------|------|
| 대시보드 첫 로드 | 매번 4개 COUNT 쿼리 | 캐시 히트 시 0개 쿼리 |
| 평가영역 통계 | 매번 복잡한 집계 | 1시간 캐시 |
| 문항등록 폼 옵션 | 매번 2개 쿼리 | 1시간 캐시 |

---

## 8. 배포 후 확인 방법

```bash
# Solid Cache 확인
railway run rails runner "puts SolidCache::Entry.count"

# Solid Queue 확인
railway run rails runner "puts SolidQueue::Job.count"

# 로그에서 Solid Queue 시작 확인
railway logs | grep -i "solid"
# 예상 출력: SolidQueue-x.x.x Supervisor started

# 캐시 동작 확인 (대시보드 2회 방문 후)
railway logs | grep "CacheWarmer"
```

---

## 9. 기타 변경

### CLAUDE.md 자동 커밋/푸시 규칙 추가

모든 코드 변경 작업 완료 후 Claude가 자동으로 `git commit + push`를 수행하도록 프로젝트 레벨 규칙을 명시하였다.

---

## 10. 향후 고려사항

1. **뷰 프래그먼트 캐싱**: `CacheHelper`가 이미 준비되어 있으나 뷰에서 미사용. 트래픽 증가 시 적용 검토
2. **Solid Cable**: 실시간 알림 기능 개발 시 활성화
3. **캐시 모니터링**: `SolidCache::Entry.count` / `byte_size` 합계로 캐시 사용량 추적
4. **잡 모니터링**: `SolidQueue::FailedExecution.count`로 실패 잡 추적, 관리자 대시보드에 표시 검토

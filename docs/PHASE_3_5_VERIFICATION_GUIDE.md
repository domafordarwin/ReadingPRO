# Phase 3.5: Production Monitoring Infrastructure - Verification Guide

**Date**: 2026-02-03
**Status**: Ready for End-to-End Testing
**Components**: 5 sub-phases completed (Foundation, Request Tracking, Web Vitals, Dashboard, Alerting)

---

## Verification Checklist

### Phase 3.5.1: Foundation - Persistent Metrics Storage ✅

#### Database Setup
- [ ] **Verify PerformanceMetric table exists**
  ```bash
  rails console
  > PerformanceMetric.table_exists?
  # Should return: true
  ```

- [ ] **Verify indexes are created**
  ```bash
  > PerformanceMetric.connection.indexes(:performance_metrics).map(&:name)
  # Should include: index_performance_metrics_metric_type_recorded_at
  #                 index_performance_metrics_endpoint_recorded_at
  ```

#### Model Validation
- [ ] **Test metric creation**
  ```bash
  rails console
  > metric = PerformanceMetric.create!(
      metric_type: 'page_load',
      endpoint: '/test',
      http_method: 'GET',
      value: 450.5,
      query_count: 3,
      recorded_at: Time.current
    )
  > PerformanceMetric.count  # Should increase
  > metric.persisted?  # Should be: true
  ```

- [ ] **Test metric_type validation**
  ```bash
  > PerformanceMetric.create(metric_type: 'invalid')
  # Should raise: ActiveRecord::RecordInvalid
  ```

- [ ] **Test scopes**
  ```bash
  > PerformanceMetric.by_type('page_load').count
  > PerformanceMetric.recent(1.hour).count
  ```

#### SolidQueue Setup
- [ ] **Verify SolidQueue is configured**
  ```bash
  > SolidQueue
  # Should be defined
  ```

- [ ] **Verify queue_name in jobs**
  ```bash
  > PerformanceMetricRecorderJob.new.queue_name
  # Should be: "performance"
  ```

---

### Phase 3.5.2: Request Performance Tracking ✅

#### Middleware Verification
- [ ] **Verify middleware is loaded**
  ```bash
  rails console
  > Rails.application.middleware.map(&:to_s).grep(/PerformanceMonitor/)
  # Should find: PerformanceMonitorMiddleware
  ```

- [ ] **Test request tracking**
  1. Start Rails server: `bin/rails server`
  2. Open browser: `http://localhost:3000`
  3. Visit any page (e.g., `/student` or `/admin`)
  4. Check logs for metric recording:
     ```bash
     tail -f log/development.log | grep "PerformanceMetric"
     # Should see: records being created
     ```

- [ ] **Verify metrics in database**
  ```bash
  rails console
  > PerformanceMetric.recent(5.minutes).by_type('page_load').count
  # Should be > 0 (if you visited pages recently)
  ```

#### Query Analysis Integration
- [ ] **Verify query_count is captured**
  ```bash
  > m = PerformanceMetric.by_type('page_load').recent(1.minute).first
  > m.query_count
  # Should be: integer >= 0
  ```

---

### Phase 3.5.3: Real User Monitoring (Web Vitals) ✅

#### Stimulus Setup Verification
- [ ] **Verify Stimulus is initialized**
  ```javascript
  // Open browser console on any page
  window.Stimulus
  // Should show: Application object
  ```

- [ ] **Verify web-vitals controller registered**
  ```javascript
  console.log(Stimulus.controllers)
  // Should include: "web-vitals"
  ```

#### Web Vitals Collection
- [ ] **Verify web-vitals library is loaded**
  1. Open browser DevTools Console
  2. Visit any page
  3. Check network tab: should see request to CDN for web-vitals library
  4. Check console: should see Web Vitals metrics being tracked

- [ ] **Check Web Vitals data in database**
  ```bash
  rails console
  > PerformanceMetric.where(metric_type: %w[fcp lcp cls inp ttfb]).recent(1.hour).count
  # Should be > 0 (if Web Vitals collection is working)
  ```

- [ ] **Test API endpoint directly**
  ```bash
  curl -X POST http://localhost:3000/api/metrics/web_vitals \
    -H "Content-Type: application/json" \
    -d '{
      "metric_name": "fcp",
      "value": 650,
      "id": "test-123",
      "rating": "good",
      "url": "/test"
    }'
  # Should return: 204 No Content
  ```

- [ ] **Verify metric appears in database**
  ```bash
  > PerformanceMetric.by_type('fcp').recent(1.minute).last.attributes
  # Should show: fcp metric with value ~650
  ```

---

### Phase 3.5.4: Monitoring Dashboard ✅

#### Dashboard Access
- [ ] **Verify admin dashboard loads**
  1. Login as admin
  2. Navigate to `/admin/system`
  3. Should see: Real-time metrics, Web Vitals, trends, alerts

#### Metrics Display
- [ ] **Verify real-time metrics display**
  - [ ] Page Load Time: Shows value in ms
  - [ ] Average Query Time: Shows value in ms
  - [ ] Cache Hit Rate: Shows percentage
  - [ ] Sample count: Shows # of metrics collected

- [ ] **Verify color coding works**
  - [ ] Green status (good): For metrics below green threshold
  - [ ] Yellow status (warning): For metrics between thresholds
  - [ ] Red status (critical): For metrics above thresholds

- [ ] **Verify Web Vitals section displays**
  - [ ] FCP (First Contentful Paint)
  - [ ] LCP (Largest Contentful Paint)
  - [ ] CLS (Cumulative Layout Shift)
  - [ ] INP (Interaction to Next Paint)
  - [ ] TTFB (Time to First Byte)

#### Trends Display
- [ ] **Verify hourly trends display**
  1. Dashboard should show 24-hour trends
  2. Each hour should show average metric value
  3. Should see historical pattern

#### Alert Detection
- [ ] **Verify alerts display**
  1. If metrics exceed thresholds, alerts should show
  2. Otherwise: "✅ 모든 지표가 정상입니다"

---

### Phase 3.5.5: Alerting & Data Retention ✅

#### Hourly Aggregates
- [ ] **Verify table exists**
  ```bash
  rails console
  > HourlyPerformanceAggregate.table_exists?
  # Should return: true
  ```

#### Alert Evaluator Job
- [ ] **Run alert evaluator manually**
  ```bash
  rails console
  > AlertEvaluatorJob.perform_now
  # Should complete without errors
  # Should log any alerts to Rails logger
  ```

- [ ] **Check log output**
  ```bash
  tail -f log/development.log | grep "AlertEvaluatorJob"
  # Should see: job execution messages
  ```

#### Metric Aggregator Job
- [ ] **Run aggregator manually**
  ```bash
  rails console
  > MetricAggregatorJob.perform_now
  # Should complete without errors
  ```

- [ ] **Verify aggregates were created**
  ```bash
  > HourlyPerformanceAggregate.count
  # Should be > 0
  ```

- [ ] **Check aggregated data**
  ```bash
  > agg = HourlyPerformanceAggregate.recent(1.hour).by_type('page_load').first
  > agg.attributes
  # Should show: avg_value, p95_value, p99_value, sample_count, etc.
  ```

#### Data Cleanup
- [ ] **Verify old data is cleaned up**
  ```bash
  # Create old data for testing
  rails console
  > old_metric = PerformanceMetric.create(
      metric_type: 'page_load',
      value: 100,
      recorded_at: 8.days.ago  # Older than 7 days
    )
  > old_agg = HourlyPerformanceAggregate.create(
      metric_type: 'page_load',
      hour: 95.days.ago,
      avg_value: 100,
      sample_count: 10
    )
  ```

  ```bash
  # Run cleanup
  > MetricAggregatorJob.perform_now

  # Verify old data is gone
  > PerformanceMetric.where('recorded_at < ?', 7.days.ago).count
  # Should be: 0
  > HourlyPerformanceAggregate.where('hour < ?', 90.days.ago).count
  # Should be: 0
  ```

---

## Integration Testing

### Scenario 1: Complete Request Flow
**Objective**: Verify end-to-end metric collection from request to dashboard

**Steps**:
1. Start Rails server: `bin/rails server`
2. Clear existing metrics (optional):
   ```bash
   rails console
   > PerformanceMetric.delete_all
   > HourlyPerformanceAggregate.delete_all
   ```
3. Visit any page as a user (e.g., student dashboard)
4. Wait 1-2 seconds for metrics to be queued
5. Check database for metrics:
   ```bash
   > PerformanceMetric.recent(1.minute).count
   # Should be: 1+
   ```
6. Visit admin dashboard: `/admin/system`
7. Verify metrics display in real-time

### Scenario 2: Alert Threshold Breach
**Objective**: Verify alert system detects performance degradation

**Steps**:
1. Create test metric that exceeds threshold:
   ```bash
   rails console
   > PerformanceMetric.create(
       metric_type: 'page_load',
       endpoint: '/test',
       value: 2500,  # Exceeds critical threshold of 2000ms
       recorded_at: 1.minute.ago
     )
   ```
2. Run alert evaluator:
   ```bash
   > AlertEvaluatorJob.perform_now
   ```
3. Check logs for alert:
   ```bash
   tail -f log/development.log | grep "ALERT"
   # Should see: critical alert for page_load
   ```

### Scenario 3: Web Vitals Collection
**Objective**: Verify browser metrics are collected

**Steps**:
1. Open browser DevTools
2. Visit any page
3. Check Network tab: confirm web-vitals library loaded
4. Wait 10+ seconds for Web Vitals to be collected
5. Check browser console for metric logging
6. Open Rails console:
   ```bash
   > PerformanceMetric.where(metric_type: %w[fcp lcp cls]).recent(5.minutes).count
   # Should be: 3+ (FCP, LCP, CLS)
   ```

### Scenario 4: Data Aggregation
**Objective**: Verify hourly aggregation and cleanup

**Steps**:
1. Create multiple test metrics:
   ```bash
   rails console
   > (1..100).each do |i|
       PerformanceMetric.create!(
         metric_type: 'page_load',
         value: 500 + rand(200),
         recorded_at: (1.hour.ago + i.seconds)
       )
     end
   ```
2. Verify raw metrics exist:
   ```bash
   > PerformanceMetric.count  # Should be: 100+
   ```
3. Run aggregator:
   ```bash
   > MetricAggregatorJob.perform_now
   ```
4. Verify aggregates created:
   ```bash
   > HourlyPerformanceAggregate.by_type('page_load').count
   # Should be: 1 (for previous hour)
   ```

---

## Performance Metrics

### Expected Overhead
- **Request Middleware**: < 2ms per request
- **Background Jobs**: Non-blocking, < 5ms to queue
- **Database Growth**: ~100 bytes per metric
- **Dashboard Query**: < 500ms for dashboard load

### Monitoring Thresholds (Default)
| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Page Load | ≤ 500ms | ≤ 1000ms | > 1000ms |
| Query Time | ≤ 100ms | ≤ 200ms | > 200ms |
| FCP | ≤ 700ms | ≤ 1200ms | > 1200ms |
| LCP | ≤ 900ms | ≤ 1500ms | > 1500ms |
| CLS | ≤ 0.1 | ≤ 0.25 | > 0.25 |

---

## Troubleshooting

### Metrics Not Appearing
- [ ] Check middleware is loaded: `Rails.application.middleware`
- [ ] Verify PerformanceMetric table exists: `PerformanceMetric.table_exists?`
- [ ] Check Rails logs for errors
- [ ] Ensure SolidQueue is running

### Web Vitals Not Collected
- [ ] Verify Stimulus is initialized: `window.Stimulus` in browser console
- [ ] Check that `data-controller="web-vitals"` on body tag
- [ ] Verify web-vitals library loads from CDN
- [ ] Check browser console for JavaScript errors

### Dashboard Not Displaying Data
- [ ] Verify metrics exist in database
- [ ] Check that helper methods are loaded
- [ ] Verify CSS classes are defined
- [ ] Check browser console for rendering errors

### Alerts Not Triggering
- [ ] Run `AlertEvaluatorJob.perform_now` manually
- [ ] Check if metrics exceed thresholds
- [ ] Verify Rails logger is configured
- [ ] Check log output for alert messages

---

## Post-Verification Steps

After all tests pass:
1. ✅ Generate Phase 3.5 Completion Report
2. ✅ Deploy to staging environment
3. ✅ Monitor for 24 hours
4. ✅ Deploy to production with alerts enabled
5. ✅ Monitor Phase 3.4 performance gains maintenance
6. ✅ Plan Phase 3.6 (Error Tracking Integration)

---

## Sign-Off

**Verification Started**: 2026-02-03
**Verification Completed**: ___________
**Verified By**: ___________
**Production Ready**: ☐ Yes ☐ No

---

## Next Steps

**Phase 3.6 Options** (tentative):
1. Error Tracking Integration (Sentry/Rollbar)
2. CI/CD Performance Gates
3. Custom Performance Dashboards
4. Anomaly Detection (ML-based)

**Recommendation**: Start with Error Tracking (high impact, 1-week effort)

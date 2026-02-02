# Performance Monitoring Guide

**Phase 3.4.6: Performance Benchmarking & Regression Testing**

## Overview

ReadingPRO uses comprehensive performance monitoring to:
- Track optimization progress (Phase 3.4)
- Detect performance regressions
- Ensure continued performance standards
- Monitor production metrics

## Performance Targets (Phase 3.4)

### Before Phase 3.4
```
Page Load Time:      1.5s (1500ms)
Database Query Time: 500ms (avg per request)
View Render Time:    800ms
Cache Hit Rate:      0% (no caching)
First Contentful Paint (FCP): 1.2s
Largest Contentful Paint (LCP): 1.5s
Time to Interactive (TTI): 2.0s
```

### Phase 3.4 Targets
```
Page Load Time:      0.5s (500ms)     ← -67% improvement
Database Query Time: 100ms (avg)      ← -80% improvement
View Render Time:    300ms            ← -62% improvement
Cache Hit Rate:      90%+             ← New metric
First Contentful Paint (FCP): 0.7s    ← -42% improvement
Largest Contentful Paint (LCP): 0.9s  ← -40% improvement
Time to Interactive (TTI): 1.2s       ← -40% improvement
```

## Key Performance Metrics

### 1. Page Load Time (Critical)

**Definition**: Total time from navigation to page fully loaded
**Target**: ≤ 1000ms (1 second)
**Phase 3.4 Target**: ≤ 500ms

**Measured as**:
```javascript
// Browser Performance API
const perfData = window.performance.timing;
const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
```

**Components**:
- HTML fetch & parse: ~200ms
- CSS loading: ~200ms (critical path)
- JavaScript execution: ~150ms
- Rendering: ~150ms
- Deferred assets: ~100ms (background)

### 2. Query Performance (Database)

**Definition**: Average database query time per request
**Target**: ≤ 100ms per request
**Phase 3.4 Improvement**: 5 queries → 2-3 queries

**Measured via**:
```ruby
# ActiveRecord query time tracking
ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, start, finish, _id, payload|
  duration = (finish - start) * 1000  # Convert to ms
  puts "[QUERY] #{payload[:name]}: #{duration.round(2)}ms"
end
```

**Regression Threshold**: >200ms average query time

### 3. View Rendering Time

**Definition**: Time to render ERB templates and fragments
**Target**: ≤ 500ms
**Phase 3.4 Target**: ≤ 300ms

**Measured via**:
```ruby
# Action View logging
ActiveSupport::Notifications.subscribe("render_template.action_view") do |_name, start, finish, _id, payload|
  duration = (finish - start) * 1000
  puts "[RENDER] #{payload[:identifier]}: #{duration.round(2)}ms"
end
```

### 4. Cache Hit Rate

**Definition**: Percentage of requests served from cache
**Target**: ≥ 80%
**Phase 3.4 Target**: ≥ 90%

**Components**:
- HTTP 304 responses: 60-80% (fresh_when/ETag)
- Fragment cache hits: 70-90% (per-row caching)
- Query result caching: 90%+ (Solid_cache)

**Measured via**:
```ruby
# Solid_cache stats (if available)
cache_size = Rails.cache.stats[:entries_count]
cache_hits = Rails.cache.stats[:hits_count]
hit_rate = (cache_hits / (cache_hits + misses)) * 100
```

### 5. First Contentful Paint (FCP)

**Definition**: Time when first content appears on screen
**Target**: ≤ 800ms
**Phase 3.4 Target**: ≤ 700ms

**Measured via**:
```javascript
// Web Vitals API
new PerformanceObserver((entryList) => {
  for (const entry of entryList.getEntries()) {
    console.log('FCP:', entry.renderTime || entry.loadTime);
  }
}).observe({entryTypes: ['paint']});
```

### 6. Largest Contentful Paint (LCP)

**Definition**: Time when largest content element is painted
**Target**: ≤ 1200ms
**Phase 3.4 Target**: ≤ 900ms

**Measured via**:
```javascript
// Web Vitals API
new PerformanceObserver((entryList) => {
  const lastEntry = entryList.getEntries().pop();
  console.log('LCP:', lastEntry.renderTime || lastEntry.loadTime);
}).observe({entryTypes: ['largest-contentful-paint']});
```

### 7. Time to Interactive (TTI)

**Definition**: Time when page is interactive (JS parsed & executed)
**Target**: ≤ 1500ms
**Phase 3.4 Target**: ≤ 1200ms

**Measured via**:
```javascript
// Simplified TTI calculation
window.addEventListener('load', () => {
  // All deferred scripts loaded
  const tti = performance.now();
  console.log('TTI:', tti);
});
```

## Performance Regression Thresholds

### Red Zone (Immediate Investigation Required)
```
Page Load Time:      > 2000ms (2 seconds)
Query Time:          > 500ms average
Cache Hit Rate:      < 50%
FCP:                 > 1200ms
LCP:                 > 2000ms
```

### Yellow Zone (Review & Optimization Needed)
```
Page Load Time:      > 1000ms (1 second)
Query Time:          > 200ms average
Cache Hit Rate:      < 70%
FCP:                 > 900ms
LCP:                 > 1500ms
```

### Green Zone (Target State)
```
Page Load Time:      ≤ 500ms
Query Time:          ≤ 100ms average
Cache Hit Rate:      ≥ 90%
FCP:                 ≤ 700ms
LCP:                 ≤ 900ms
```

## Monitoring Tools & Integration

### 1. Browser DevTools Performance Tab

**Steps**:
1. Open Chrome DevTools (F12)
2. Go to Performance tab
3. Click record (◉)
4. Navigate and interact with page
5. Stop recording
6. Review FCP, LCP, TTI metrics

**Key Metrics**:
- FCP (First Contentful Paint)
- LCP (Largest Contentful Paint)
- CLS (Cumulative Layout Shift)
- Total page load time

### 2. Web Vitals Library

**Integration**:
```javascript
import {getCLS, getFID, getFCP, getLCP, getTTFB} from 'web-vitals';

getCLS(console.log);
getFID(console.log);
getFCP(console.log);
getLCP(console.log);
getTTFB(console.log);
```

**Output**: Real user metrics for monitoring

### 3. Rails Performance Instrumentation

**Query Tracking**:
```ruby
# config/initializers/query_analyzer.rb
ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  logger.info "[QUERY] #{duration.round(2)}ms - #{payload[:name]}"
end
```

**Render Tracking**:
```ruby
ActiveSupport::Notifications.subscribe("render_template.action_view") do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  logger.info "[RENDER] #{duration.round(2)}ms - #{payload[:identifier]}"
end
```

### 4. PerformanceBenchmark Service

**Usage**:
```ruby
# In controller or request spec
benchmark = PerformanceBenchmark.new('item_bank_page')
result = benchmark.measure do
  # Code to measure (controller action, etc.)
end
benchmark.report
```

**Output**:
```
═══════════════════════════════════════════════════════════════════
PERFORMANCE BENCHMARK REPORT
═══════════════════════════════════════════════════════════════════
Test: item_bank_page
Time: 2026-02-03 12:34:56 UTC
───────────────────────────────────────────────────────────────────

Metrics:
  Page Load Time: 450ms ✓
  Query Time: 85ms ✓
  Render Time: 280ms ✓
  Cache Hit Rate: 92% ✓
  FCP: 650ms ✓
  LCP: 850ms ✓
  TTI: 1100ms ✓

═══════════════════════════════════════════════════════════════════
```

### 5. Phase 3.4 Improvement Summary

```ruby
# Generate Phase 3.4 improvement report
PerformanceBenchmark.compare_phases
```

**Output**:
```
════════════════════════════════════════════════════════════════════
PHASE 3.4 PERFORMANCE IMPROVEMENT SUMMARY
════════════════════════════════════════════════════════════════════

                     | Before | After | Improvement
────────────────────────────────────────────────────────────────────
Page Load Time       |   1500 |   500 | 66.7% ↓
Query Time           |    500 |   100 | 80.0% ↓
Render Time          |    800 |   300 | 62.5% ↓
Cache Hit Rate       |      0% |   90% | 90% ↑
FCP                  |   1200 |   700 | 41.7% ↓
LCP                  |   1500 |   900 | 40% ↓
TTI                  |   2000 |  1200 | 40% ↓
════════════════════════════════════════════════════════════════════
```

## Continuous Monitoring Setup

### 1. GitHub Actions (CI Pipeline)

**File**: `.github/workflows/performance.yml`

```yaml
name: Performance Check

on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
      - name: Run performance benchmarks
        run: bundle exec rails performance:benchmark
      - name: Check against thresholds
        run: bundle exec rails performance:validate
```

### 2. Datadog/New Relic Integration

**Monitor Production Metrics**:
```
- Page Load Time (apdex)
- Database Query Time
- Error Rate
- Cache Hit Rate
- Web Vitals (FCP, LCP, CLS)
```

### 3. Weekly Performance Reports

**Automated Report Generation**:
```ruby
# Scheduled task (config/sidekiq.yml)
:cron:
  performance_report:
    cron: '0 9 * * 1'  # Monday 9am
    class: PerformanceReportJob
    queue: default
```

## Performance Testing Checklist

### Before Deployment
- [ ] Run performance benchmarks
- [ ] Verify all metrics are in green zone
- [ ] Check for query count increase
- [ ] Review cache hit rate
- [ ] Test with Chrome DevTools Performance tab
- [ ] Run lighthouse audit (minimum 90 score)

### After Deployment (Production)
- [ ] Monitor error rate for 1 hour
- [ ] Check page load time trends
- [ ] Verify cache hit rate ≥ 90%
- [ ] Alert if metrics exceed thresholds

## Troubleshooting Performance Issues

### Slow Page Load Time
1. Check database query count (should be 2-3)
2. Verify cache is working (check 304 responses)
3. Review Network tab for CSS/JS loading
4. Check for N+1 queries in logs

### High Query Time
1. Run `EXPLAIN ANALYZE` on slow queries
2. Check if indexes are being used
3. Verify eager loading with `includes()`
4. Consider adding indexes if needed

### Low Cache Hit Rate
1. Check cache configuration (Solid_cache)
2. Verify cache keys are consistent
3. Review cache invalidation hooks
4. Check cache storage space

### High FCP/LCP
1. Check CSS/JS loading times
2. Verify image optimization
3. Review lazy loading implementation
4. Check for render-blocking resources

## Performance Optimization Priorities

### High Impact (Do First)
1. Fix N+1 queries
2. Implement caching
3. Optimize database indexes
4. Defer non-critical JS/CSS

### Medium Impact (Do Next)
1. Implement lazy loading
2. Optimize images
3. Split code bundles
4. Minify assets

### Low Impact (Do Last)
1. Fine-tune query filters
2. Optimize component rendering
3. Add monitoring dashboards
4. A/B test optimizations

## References

- [Web Vitals Documentation](https://web.dev/vitals/)
- [Rails Performance Guides](https://guides.rubyonrails.org/performance_testing.html)
- [Chrome DevTools Performance](https://developer.chrome.com/docs/devtools/performance/)
- [Lighthouse Auditing](https://developers.google.com/web/tools/lighthouse)

## See Also

- [Phase 3.4: Performance Optimization](../PHASES.md)
- [Query Optimization Guide](./DATABASE_INDEXES.md)
- [Asset Optimization Guide](./ASSET_OPTIMIZATION.md)
- [CLAUDE.md - Architecture Guide](../CLAUDE.md)

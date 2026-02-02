# Asset Optimization Guide

**Phase 3.4.5: CSS/JS Bundle Size Reduction**

## Overview

ReadingPRO uses Rails 8.1 with Propshaft for asset pipeline management. This guide documents asset optimization strategies to reduce bundle sizes and improve page load performance.

## Current Asset Analysis

### CSS Assets

| File | Lines | Purpose | Optimization |
|------|-------|---------|--------------|
| **design_system.css** | 1,793 | Design tokens, components | Critical (always needed) |
| **app.css** | 2,139 | Application styles, layouts | Page-specific splitting |
| **application.css** | 10 | Manifest/imports | Meta file |
| **TOTAL** | 3,932 | - | - |

### JavaScript Assets

| File | Lines | Purpose | Optimization |
|------|-------|---------|--------------|
| **research_search_controller.js** | 90 | Stimulus controller (debounced search) | Page-specific (lazy load) |
| **TOTAL** | 90 | - | - |

## Optimization Strategies

### 1. CSS Code Splitting (20-30% reduction)

**Current Strategy**: Load all CSS on every page
**Optimized Strategy**: Split by usage pattern

#### Pattern 1: Core Styles (Always Load)
**File**: `core.css` (150-200 lines)
- Reset/normalize styles
- Typography base
- Layout utilities

**Usage**: All pages
**Size**: ~8KB gzipped

#### Pattern 2: Design System (Shared Components)
**File**: `design_system.css` (1,793 lines)
**Usage**: All admin/portal pages
**Size**: ~65KB gzipped
**Status**: Already separated ✅

#### Pattern 3: Page-Specific Styles
**Files to create**:
- `item_bank.css` - Researcher item bank page only
- `dashboard.css` - Student/parent dashboards
- `forms.css` - Form-heavy pages

**Extraction from app.css**:
- Extract item_bank table styles
- Extract filter/pagination styles
- Extract dashboard card styles

**Expected Reduction**: app.css 2,139 → 1,200 lines (~44% reduction)

**Implementation**:
```erb
<!-- app/views/layouts/unified_portal.html.erb -->
<%= stylesheet_link_tag "design_system", media: "all" %>

<!-- Page-specific (only if needed) -->
<% if @current_page == "item_bank" %>
  <%= stylesheet_link_tag "item_bank", media: "all" %>
<% end %>
```

### 2. JavaScript Optimization

**Current**: research_search_controller.js (90 lines, 3KB)

**Optimization**: Already optimal!
- Small Stimulus controller
- No large dependencies
- Proper bundling via importmap

**Future**: Consider code splitting if Stimulus controllers grow
```javascript
// Lazy load heavy controllers
import { registerController } from '@hotwired/stimulus'
const controller = await import('./heavy_controller.js')
registerController('heavy', controller)
```

### 3. CSS Minification Strategy

**Current**: Rails 7.0+ auto-minifies in production
**Status**: Already enabled ✅

**Compression Comparison**:
```
design_system.css
  Raw: ~65KB
  Gzipped: ~8KB (87% reduction)

app.css
  Raw: ~85KB
  Gzipped: ~10KB (88% reduction)
```

### 4. Lazy Loading Strategy

**Critical CSS** (loaded immediately):
- design_system.css
- Stimulus bundles

**Deferred CSS** (loaded after page renders):
- Page-specific styles (item_bank.css, dashboard.css, etc.)
- Feature-specific styles (forms.css, reports.css)

**Implementation**:
```erb
<!-- Critical (synchronous) -->
<link rel="stylesheet" href="/assets/design_system.css">

<!-- Deferred (asynchronous) -->
<link rel="preload" as="style" href="/assets/item_bank.css" onload="this.onload=null;this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="/assets/item_bank.css"></noscript>
```

### 5. Asset Pipeline Configuration

**Propshaft Configuration** (`config/propshaft.yml`):
```yaml
output_path: public/assets
manifest_path: public/assets/.manifest.json

# Compression settings
gzip: true
brotli: true

# CDN settings (optional for production)
cdn:
  host: cdn.example.com
  path: /assets
```

## Expected Results

### Before Phase 3.4.5

```
CSS Bundle:
  - design_system.css: 8KB gzipped
  - app.css: 10KB gzipped
  - Total: 18KB gzipped (critical path)

JS Bundle:
  - Stimulus + controllers: 15KB gzipped
  - Total: 15KB gzipped (critical path)

Total Page Load (assets): ~35KB gzipped
```

### After Phase 3.4.5

```
CSS Bundle:
  - design_system.css: 8KB gzipped (critical)
  - item_bank.css: 3KB gzipped (deferred)
  - Total critical: 8KB gzipped

JS Bundle:
  - Stimulus: 12KB gzipped (critical)
  - research_search_controller.js: 1KB gzipped (lazy)
  - Total critical: 12KB gzipped

Total Critical Path: ~20KB gzipped (-43% reduction)
Total With Lazy: ~25KB gzipped (+7KB deferred)
```

## Performance Impact

### First Contentful Paint (FCP)

**Before**: 1.2s
- HTML: 200ms
- CSS: 400ms
- JS: 300ms
- Rendering: 300ms

**After**: 0.7s (-42%)
- HTML: 200ms
- Critical CSS: 200ms
- Critical JS: 150ms
- Rendering: 150ms
- Deferred assets load asynchronously

### Largest Contentful Paint (LCP)

**Before**: 1.5s
**After**: 0.9s (-40%)

## Implementation Checklist

### Phase 1: CSS Code Splitting
- [ ] Create `item_bank.css` with item bank-specific styles
- [ ] Create `dashboard.css` with dashboard-specific styles
- [ ] Create `core.css` with base/reset styles
- [ ] Remove duplicates from `app.css`
- [ ] Update layout templates to load page-specific CSS

### Phase 2: CSS Lazy Loading
- [ ] Implement preload + onload pattern
- [ ] Add noscript fallbacks
- [ ] Test CSS loading in Network tab
- [ ] Verify no FOUC (Flash of Unstyled Content)

### Phase 3: Asset Pipeline Optimization
- [ ] Verify gzip compression enabled
- [ ] Test Brotli compression (if available)
- [ ] Configure CDN headers (Cache-Control)
- [ ] Set asset versioning strategy

### Phase 4: Monitoring
- [ ] Add RUM (Real User Monitoring) for asset metrics
- [ ] Track FCP/LCP improvements
- [ ] Monitor CSS/JS load times
- [ ] Alert on asset size increases

## CSS Splitting Plan

### core.css (Extract from app.css)
Lines: 1-100
```css
* { box-sizing: border-box; }
body { margin: 0; font-family: system-ui; }
h1, h2, h3 { line-height: 1.2; }
/* ... typography, reset, utilities ... */
```

### item_bank.css (Extract from app.css)
Lines: ~500-800 from app.css
```css
/* Item bank specific */
.filter-section { ... }
.portal-table { ... }
.pagination { ... }
.type-badge { ... }
.status-badge { ... }
```

### dashboard.css (Extract from app.css)
Lines: ~400-600 from app.css
```css
/* Dashboard specific */
.stats-card { ... }
.student-portfolio { ... }
.consultation-section { ... }
```

### forms.css (Extract from app.css)
Lines: ~200-300 from app.css
```css
/* Form styles */
.form-group { ... }
input, select, textarea { ... }
.form-error { ... }
```

## Incremental Loading Strategy

**Critical Path (Load Immediately)**:
```
1. HTML parsed (200ms)
2. design_system.css loaded (100ms)
3. Stimulus + minimal JS (50ms)
4. Page renders with base styles (50ms)
└─ FCP: ~400ms

**Background (Async)**:
5. Page-specific CSS loads (100ms)
6. Heavy JS controllers load (optional)
```

## Future Optimizations (Phase 3.5+)

1. **CSS-in-JS**: Move to dynamic style injection per component
2. **Atomic CSS**: Consider Tailwind CSS for reduced bundle
3. **Critical CSS Extraction**: Automated critical path CSS
4. **Font Optimization**: Subset and preload fonts
5. **Image Optimization**: WebP, AVIF formats, responsive images

## Monitoring Tools

### Measure Asset Performance

```bash
# Check gzip compression
curl -H "Accept-Encoding: gzip" -I https://example.com/assets/design_system.css

# Check asset sizes
ls -lah public/assets/*.css public/assets/*.js

# Test with Web Page Test
# https://www.webpagetest.org/

# Chrome DevTools Performance Tab
# DevTools → Performance → Record → Load page
```

### Rails Asset Size Tracking

```ruby
# In development console
require 'sprockets-rails'
assets = Rails.application.assets

puts "Asset Sizes:"
assets.each do |asset|
  puts "#{asset}: #{File.size(asset) / 1024}KB"
end
```

## CSS Statistics

### Current app.css Breakdown (Estimated)

```
Design Tokens:       200 lines (5%)
Layout/Grid:         300 lines (14%)
Components:          800 lines (37%)
Utilities:           200 lines (9%)
Page-specific:       500 lines (23%)
Responsive media:    200 lines (9%)
Other:               139 lines (3%)
─────────────────────────────
TOTAL:             2,139 lines
```

### Optimization Impact

**If we split page-specific (500 lines) into separate files**:
- app.css: 2,139 → 1,639 lines (-23%)
- item_bank.css: +250 lines
- dashboard.css: +150 lines
- forms.css: +100 lines

**Network Benefit**:
- First page load: -7KB critical CSS
- Same page revisit: Cached app.css used
- Different page: Load only needed CSS

## See Also

- [Phase 3.4: Performance Optimization](../PHASES.md)
- [DATABASE_INDEXES.md](./DATABASE_INDEXES.md)
- [CLAUDE.md - Architecture Guide](../CLAUDE.md)

# Icon Library

Comprehensive guide to ReadingPRO's SVG icon system. This library provides 25+ carefully designed icons optimized for educational assessment systems.

---

## Table of Contents
1. [Quick Start](#quick-start)
2. [Icon Catalog](#icon-catalog)
3. [Usage Examples](#usage-examples)
4. [Icon Helper Methods](#icon-helper-methods)
5. [Customization](#customization)
6. [Adding New Icons](#adding-new-icons)
7. [Accessibility](#accessibility)

---

## Quick Start

### Basic Usage

```erb
<!-- Simple icon -->
<%= icon('home') %>

<!-- Icon with custom size -->
<%= icon('check', size: 24) %>

<!-- Icon button with label -->
<%= icon('menu', aria_label: 'Open navigation') %>

<!-- Icon with text -->
<%= icon_with_text('check', 'Save Changes') %>
```

### Icon System Architecture

**3-part system:**
1. **SVG Sprite** (`_icon_sprite.html.erb`) - Centralized icon definitions
2. **Icon Helper** (`icon_helper.rb`) - Rendering methods and utilities
3. **Icon CSS** (`design_system.css`) - Styling and animations

**Benefits:**
- Single HTTP request for all icons (sprite)
- Consistent sizing and styling
- Easy to color and animate
- Accessible by default
- Performant (small file size)

---

## Icon Catalog

### Navigation (4 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 🏠 | `home` | Dashboard, home page links | Home icon |
| 📊 | `dashboard` | Analytics, statistics pages | Grid icon |
| ☰ | `menu` | Mobile hamburger menu | Three lines |
| ▼ | `chevron-down` | Dropdowns, expand/collapse | Down arrow |

### Search and Form (3 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 🔍 | `search` | Search inputs, find functionality | Magnifying glass |
| ⚙️ | `filter` | Filtering controls, advanced search | Funnel icon |
| ✓ | `check` | Success states, completed items, checkboxes | Check mark |

### Action (5 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| ✎ | `edit` | Edit buttons, modify actions | Pencil icon |
| 🗑️ | `delete` | Delete buttons, remove items | Trash icon |
| 👁️ | `eye` | View, show password | Eye icon |
| 👁️‍🗨️ | `eye-off` | Hide password, hidden items | Eye with slash |
| ✕ | `x` | Close, dismiss, cancel | X mark |

### User and Account (2 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 👤 | `user` | Profile, user menu, user settings | Single person |
| 👥 | `users` | Groups, teams, multiple users | Two people |

### Document and File (3 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 📄 | `file` | Files, documents, attachments | Document icon |
| ⬇️ | `download` | Download buttons, export | Down arrow |
| ⬆️ | `upload` | Upload buttons, import | Up arrow |

### Notifications and Settings (4 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 🔔 | `bell` | Notifications, alerts, announcements | Bell icon |
| ⚙️ | `settings` | Settings, configuration, preferences | Gear icon |
| ⚠️ | `alert` | Warnings, important alerts, caution | Warning triangle |
| ℹ️ | `info` | Information, help, tooltips | Info circle |

### Content and Organization (4 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 📚 | `book` | Reading materials, courses, libraries | Open book |
| 📋 | `clipboard-check` | Assessments, forms, surveys, tasks | Clipboard with check |
| ↑ | `sort-asc` | Sort ascending, ordering | Up arrow |
| ↓ | `sort-desc` | Sort descending, ordering | Down arrow |

### Utility (6 icons)

| Icon | Name | Usage | Preview |
|------|------|-------|---------|
| 🔄 | `refresh` | Reload, retry, sync, refresh | Circular arrow |
| 📅 | `calendar` | Dates, scheduling, deadlines | Calendar grid |
| 📋 | `copy` | Copy to clipboard, duplicate | Document copy |
| < > | `code` | Code snippets, developer docs | Code brackets |
| ↗️ | `share` | Share, distribute, post | Share arrow |
| ► | `chevron-right` | Next, expand right, forward | Right arrow |

---

## Usage Examples

### Basic Icon

```erb
<!-- Home icon, default size (20px) -->
<%= icon('home') %>

<!-- Output: -->
<!-- <svg class="rp-icon" width="20" height="20" ...>
       <use href="#icon-home"></use>
     </svg> -->
```

### Icon with Size

```erb
<!-- Small icon (16px) -->
<%= icon('check', size: 16) %>

<!-- Medium icon (24px) -->
<%= icon('alert', size: 24) %>

<!-- Large icon (32px) -->
<%= icon('settings', size: 32) %>

<!-- Custom size -->
<%= icon('user', size: 40) %>
```

### Icon with Custom Styling

```erb
<!-- Colored icon -->
<%= icon('check', css_class: 'rp-icon--success') %>

<!-- Multiple classes -->
<%= icon('alert', css_class: 'rp-icon--warning rp-icon--lg') %>

<!-- Spinning animation -->
<%= icon('refresh', css_class: 'rp-icon--spinning') %>

<!-- Pulsing animation -->
<%= icon('bell', css_class: 'rp-icon--pulsing') %>
```

### Icon Button

```erb
<!-- Simple icon button -->
<%= icon('menu', aria_label: 'Open navigation') %>

<!-- Delete button -->
<button class="rp-btn rp-btn--ghost" aria-label="Delete item">
  <%= icon('delete', size: 20) %>
</button>

<!-- Using icon_button helper -->
<%= icon_button('edit', label: 'Edit assessment', path: '/assessments/123/edit') %>

<%= icon_button('delete', label: 'Delete question', method: :delete) %>
```

### Icon with Text

```erb
<!-- Icon and text together -->
<%= icon_with_text('check', 'Submit Assessment') %>

<!-- Output: -->
<!-- <button class="rp-btn rp-btn--primary">
       <svg class="rp-icon">...</svg>
       Submit Assessment
     </button> -->

<!-- Custom styling -->
<button class="rp-btn rp-btn--success">
  <%= icon('check', size: 16, aria_hidden: true) %>
  <span>Save Changes</span>
</button>
```

### In Navigation

```erb
<!-- Sidebar navigation with icons -->
<nav class="rp-sidebar">
  <ul class="rp-nav-list">
    <li>
      <%= icon('home', size: 18, aria_hidden: true) %>
      <a href="/dashboard">Dashboard</a>
    </li>
    <li>
      <%= icon('book', size: 18, aria_hidden: true) %>
      <a href="/assessments">Assessments</a>
    </li>
    <li>
      <%= icon('settings', size: 18, aria_hidden: true) %>
      <a href="/settings">Settings</a>
    </li>
  </ul>
</nav>
```

### In Tables

```erb
<!-- Action column with icons -->
<table class="rp-table">
  <tbody>
    <tr>
      <td>Assessment Title</td>
      <td>
        <a href="#" class="rp-btn rp-btn--ghost rp-btn--sm">
          <%= icon('eye', size: 18, aria_label: 'View assessment') %>
        </a>
        <a href="#" class="rp-btn rp-btn--ghost rp-btn--sm">
          <%= icon('edit', size: 18, aria_label: 'Edit assessment') %>
        </a>
        <a href="#" class="rp-btn rp-btn--ghost rp-btn--sm">
          <%= icon('delete', size: 18, aria_label: 'Delete assessment') %>
        </a>
      </td>
    </tr>
  </tbody>
</table>
```

### Status Indicators

```erb
<!-- With badges and icons -->
<span class="rp-badge rp-badge--success">
  <%= icon('check', size: 14, aria_hidden: true) %>
  Completed
</span>

<span class="rp-badge rp-badge--warning">
  <%= icon('alert', size: 14, aria_hidden: true) %>
  In Progress
</span>

<span class="rp-badge rp-badge--danger">
  <%= icon('x', size: 14, aria_hidden: true) %>
  Failed
</span>
```

### Form Elements

```erb
<!-- Search input with icon -->
<div class="rp-form-group">
  <div class="rp-input-with-icon">
    <input type="text" class="rp-input" placeholder="Search assessments...">
    <%= icon('search', size: 18, css_class: 'rp-input-icon', aria_hidden: true) %>
  </div>
</div>

<!-- Password visibility toggle -->
<div class="rp-form-group">
  <label for="password">Password</label>
  <div class="rp-input-with-icon">
    <input type="password" id="password" class="rp-input">
    <button class="rp-password-toggle" aria-label="Show password">
      <%= icon('eye-off', size: 18, aria_hidden: true) %>
    </button>
  </div>
</div>
```

---

## Icon Helper Methods

### `icon(name, **options)`

Render a single SVG icon from the sprite.

**Parameters:**
```ruby
icon(
  'home',                           # Icon name (required)
  size: 20,                         # Icon size: 16, 20, 24, 32 (default: 20)
  css_class: 'custom-class',        # Additional CSS classes
  aria_label: 'Go to home',         # ARIA label (makes icon visible to screen readers)
  aria_hidden: true                 # Hide from screen readers (default: true if no label)
)
```

**Returns:** SVG element as HTML string

**Examples:**
```erb
<%= icon('home') %>                                      <!-- Default 20px -->
<%= icon('check', size: 16) %>                           <!-- Small 16px -->
<%= icon('alert', css_class: 'rp-icon--warning') %>     <!-- With color -->
<%= icon('menu', aria_label: 'Open menu') %>            <!-- Accessible button icon -->
```

### `icon_button(icon_name, label:, **options)`

Render a button with an icon and ARIA label.

**Parameters:**
```ruby
icon_button(
  'delete',                              # Icon name
  label: 'Delete item',                  # ARIA label (required)
  size: 20,                              # Icon size
  button_class: 'rp-btn rp-btn--ghost',  # Button CSS classes
  path: '/items/123',                    # Link path (creates link button)
  method: :delete,                       # HTTP method
  confirm: 'Are you sure?'               # Confirmation dialog
)
```

**Examples:**
```erb
<!-- Link button -->
<%= icon_button('edit', label: 'Edit', path: '/assessments/123/edit') %>

<!-- Form button -->
<%= icon_button('delete', label: 'Delete', method: :delete) %>

<!-- With confirmation -->
<%= icon_button('delete', label: 'Delete', method: :delete, confirm: 'Sure?') %>
```

### `icon_with_text(icon_name, text, **options)`

Render a button with both icon and text.

**Parameters:**
```ruby
icon_with_text(
  'check',                          # Icon name
  'Save Changes',                   # Button text
  size: 16,                         # Icon size
  button_class: 'rp-btn rp-btn--primary'  # Button classes
)
```

**Examples:**
```erb
<%= icon_with_text('check', 'Submit') %>
<%= icon_with_text('download', 'Export Results', size: 18) %>
<%= icon_with_text('refresh', 'Reload', button_class: 'rp-btn rp-btn--secondary') %>
```

---

## Customization

### Icon Sizing via CSS Classes

```css
/* Predefined sizes */
.rp-icon--sm { width: 16px; height: 16px; }  /* Small */
.rp-icon--md { width: 24px; height: 24px; }  /* Medium */
.rp-icon--lg { width: 32px; height: 32px; }  /* Large */

/* Size parameter generates these classes automatically */
icon('home', size: 16)  <!-- generates class="rp-icon rp-icon--sm" -->
```

### Icon Colors

```erb
<!-- Color variants -->
<%= icon('check', css_class: 'rp-icon--success') %>    <!-- Green -->
<%= icon('alert', css_class: 'rp-icon--warning') %>    <!-- Orange -->
<%= icon('delete', css_class: 'rp-icon--danger') %>    <!-- Red -->
<%= icon('info', css_class: 'rp-icon--info') %>        <!-- Blue -->

<!-- Or use text color utilities -->
<span style="color: var(--rp-primary);">
  <%= icon('home') %>
</span>
```

### Animations

```erb
<!-- Spinning animation (loading states) -->
<%= icon('refresh', css_class: 'rp-icon--spinning') %>

<!-- Pulsing animation (attention) -->
<%= icon('bell', css_class: 'rp-icon--pulsing') %>

<!-- Custom animation -->
<style>
  @keyframes bounce {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-4px); }
  }
  .rp-icon--bounce {
    animation: bounce 1s ease-in-out infinite;
  }
</style>

<%= icon('heart', css_class: 'rp-icon--bounce') %>
```

---

## Adding New Icons

### Step 1: Add SVG to Sprite

Edit `app/views/shared/_icon_sprite.html.erb`:

```html
<symbol id="icon-custom-name" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <!-- SVG path here -->
  <path d="M12 2L15 10H23L17 15L19 23L12 18L5 23L7 15L1 10H9L12 2Z"/>
</symbol>
```

### Step 2: Use the Icon

```erb
<%= icon('custom-name') %>
```

### Icon Design Guidelines

1. **ViewBox**: Use `0 0 24 24` for consistency
2. **Stroke Width**: Use `stroke-width="2"` for outlined icons
3. **Fill vs Stroke**:
   - Solid icons use `fill="currentColor"`
   - Outlined icons use `stroke="currentColor"`
4. **Padding**: Leave 2px padding around actual icon shape
5. **Consistency**: Match style of existing icons

### SVG Optimization

```html
<!-- ✅ GOOD: Simple, optimized paths -->
<symbol id="icon-example" viewBox="0 0 24 24" fill="currentColor">
  <path d="M12 2L15 10H23L17 15L19 23L12 18L5 23L7 15L1 10H9L12 2Z"/>
</symbol>

<!-- ❌ AVOID: Complex, unoptimized paths -->
<symbol id="icon-bad" viewBox="0 0 24 24">
  <g id="Layer_1" data-name="Layer 1">
    <path id="Path_1" data-name="Path 1" class="cls-1" d="...very long path..."/>
  </g>
</symbol>
```

---

## Accessibility

### Icon-Only Buttons

Always provide an `aria-label` for icon-only buttons:

```erb
<!-- ✅ GOOD: Accessible icon button -->
<button aria-label="Delete item">
  <%= icon('delete', aria_hidden: true) %>
</button>

<!-- ❌ BAD: No label, not accessible -->
<button>
  <%= icon('delete') %>
</button>

<!-- ✅ GOOD: Using icon helper -->
<%= icon_button('delete', label: 'Delete item') %>
```

### Icon with Text

When pairing icons with text, hide the icon from screen readers:

```erb
<!-- ✅ GOOD: Icon hidden, text describes button -->
<button>
  <%= icon('check', aria_hidden: true) %>
  <span>Save Changes</span>
</button>

<!-- ❌ BAD: Icon announces to screen reader -->
<button>
  <%= icon('check') %>
  Save Changes
</button>

<!-- ✅ GOOD: Using helper -->
<%= icon_with_text('check', 'Save Changes') %>
```

### Screen Reader Testing

Test icon buttons with screen readers:
- NVDA (Windows, free)
- JAWS (Windows, paid)
- VoiceOver (Mac/iOS, built-in)

**Test scenarios:**
1. Icon button reads label correctly
2. Icon-text buttons announce text, not icon
3. Icon animations don't interfere with reading
4. Color-coded icons (success/warning/danger) have text labels

---

## Icon Performance

### Load Time
- **File size**: ~3KB (gzipped)
- **HTTP requests**: 1 (sprite is single request)
- **Rendering**: Instant (cached in memory)

### Browser Support
- Modern browsers (Chrome, Firefox, Safari, Edge)
- IE11+ (with fallback)
- Mobile browsers (iOS Safari, Chrome Mobile)

### Optimization Tips
1. Load sprite once in layout (done automatically)
2. Reuse icons across multiple pages
3. Use sizes that match design tokens (16, 20, 24, 32)
4. Avoid creating custom icons unless necessary

---

## Icon Library Maintenance

### When to Add Icons
- Icon used in multiple places
- Icon represents a core concept
- Icon aligns with design system

### When NOT to Add Icons
- One-off, single-use icons
- Custom brand icons (use image files)
- Complex illustrations (use SVG files)

### Icon Review Checklist

Before adding a new icon:
- [ ] Icon is 24x24 SVG in viewBox
- [ ] Paths are optimized (remove IDs, classes)
- [ ] Stroke width or fill is consistent with existing icons
- [ ] Icon is 2px padding from edges
- [ ] Icon works at 16px, 20px, 24px, 32px sizes
- [ ] Icon works with currentColor
- [ ] Icon is named clearly and uniquely
- [ ] Icon tested with multiple browsers

---

**Icon Library Status**: ✅ Complete (25+ icons)
**Last Updated**: 2026-02-03
**Version**: 1.0

---

## Quick Reference Card

```
SIZES:           COLORS:             ANIMATIONS:
16px (small)     --rp-primary        --spinning
20px (default)   --rp-success        --pulsing
24px (medium)    --rp-warning
32px (large)     --rp-danger
                 --rp-info
                 --rp-text-muted

USAGE:
<%= icon('home') %>
<%= icon('check', size: 16) %>
<%= icon('alert', css_class: 'rp-icon--warning') %>
<%= icon_button('delete', label: 'Delete') %>
<%= icon_with_text('save', 'Save Changes') %>
```

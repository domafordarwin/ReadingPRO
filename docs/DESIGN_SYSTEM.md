# ReadingPRO Design System

## Table of Contents
1. [Philosophy](#philosophy)
2. [Design Tokens](#design-tokens)
3. [Layout System](#layout-system)
4. [Component Catalog](#component-catalog)
5. [Responsive Design](#responsive-design)
6. [Accessibility](#accessibility)

---

## Philosophy

### Korean Neo-Minimalism

ReadingPRO's design system embodies **Korean Neo-Minimalism** — a balance between functional clarity and refined aesthetics that emphasizes:

- **Clarity**: Information hierarchy with clean typography and spacious layouts
- **Efficiency**: Minimal cognitive load for students, teachers, and researchers
- **Subtlety**: Soft colors and gentle interactions that respect user focus
- **Cultural Respect**: Korean educational context and accessibility standards
- **Modern Elegance**: Contemporary design without unnecessary decoration

### Core Design Principles

1. **Functional First**: Every visual element serves a purpose
2. **Whitespace is Content**: Strategic spacing improves comprehension
3. **Type-Driven**: Typography carries meaning and hierarchy
4. **Color for Information**: Status and state communicated through color
5. **Consistent Patterns**: Predictable interactions reduce learning curve
6. **Accessible Always**: WCAG 2.1 AA compliance from the ground up

---

## Design Tokens

### Color System

#### Core Colors
```css
--rp-bg: #FFFFFF                     /* Primary background */
--rp-bg-subtle: #F8FAFC              /* Secondary background (subtle) */
--rp-surface: #FFFFFF                /* Card and container surfaces */
```

#### Text Colors
```css
--rp-text-title: #0F172A             /* Headings and important text */
--rp-text-body: #475569              /* Body text and descriptions */
--rp-text-muted: #94A3B8             /* Disabled, placeholder, secondary text */
```

#### Brand Color (Primary)
```css
--rp-primary: #2F5BFF               /* Main brand color (Blue) */
--rp-primary-hover: #1E4AE8         /* Hover state */
--rp-primary-soft: #EEF2FF          /* Light background tint */
--rp-primary-softer: #F5F8FF        /* Very light background tint */
```

#### Status Colors
```css
--rp-success: #22C55E               /* Success/positive status */
--rp-success-soft: #DCFCE7          /* Success background tint */

--rp-warning: #F59E0B               /* Warning/caution status */
--rp-warning-soft: #FEF3C7          /* Warning background tint */

--rp-danger: #EF4444                /* Error/danger status */
--rp-danger-soft: #FEE2E2           /* Error background tint */

--rp-info: #0EA5E9                  /* Information/help status */
--rp-info-soft: #E0F2FE             /* Info background tint */
```

#### Semantic Usage
- **Primary**: Call-to-action buttons, active states, important links
- **Success**: Form validation pass, completed states, positive messages
- **Warning**: Attention-needed states, pending actions, caution messages
- **Danger**: Destructive actions, errors, high-priority issues
- **Info**: Informational messages, helpful tips, notifications

### Spacing Scale

```css
--rp-space-1: 4px      /* Minimum spacing, icon padding */
--rp-space-2: 8px      /* Small gaps, button padding */
--rp-space-3: 12px     /* Form element spacing */
--rp-space-4: 16px     /* Standard spacing, section gaps */
--rp-space-5: 20px     /* Medium section spacing */
--rp-space-6: 24px     /* Container padding, section separators */
--rp-space-8: 32px     /* Large section spacing */
--rp-space-10: 40px    /* Extra large gaps */
--rp-space-12: 48px    /* Major section spacing */
--rp-space-16: 64px    /* Page-level spacing */
```

**Usage Guide:**
- **Navigation/Headers**: space-6, space-8
- **Form groups**: space-4, space-6
- **Card padding**: space-4, space-6
- **Section margins**: space-8, space-10
- **Page padding**: space-12, space-16

### Typography

#### Font Family
```css
--rp-font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif
```

**Pretendard**: Korean-optimized sans-serif font with excellent readability

#### Font Sizes
```css
--rp-font-size-xs: 12px      /* Small labels, captions, timestamps */
--rp-font-size-sm: 13px      /* Form labels, meta information */
--rp-font-size-base: 14px    /* Body text, standard default */
--rp-font-size-md: 15px      /* Emphasis text, slightly larger body */
--rp-font-size-lg: 18px      /* Section headings, prominent text */
--rp-font-size-xl: 20px      /* Page subheadings */
--rp-font-size-2xl: 24px     /* Page headings */
--rp-font-size-3xl: 28px     /* Hero/large headings */
--rp-font-size-4xl: 32px     /* Major page titles */
```

#### Line Heights
```css
line-height: 1.6             /* Standard body text (22px @ 14px base) */
line-height: 1.5             /* Headings and emphasized text */
line-height: 1.4             /* Tight spacing for labels and captions */
```

**Usage Pattern:**
```html
<!-- Page Title -->
<h1 style="font-size: var(--rp-font-size-4xl); line-height: 1.2;">
  Assessment Results
</h1>

<!-- Section Heading -->
<h2 style="font-size: var(--rp-font-size-2xl); line-height: 1.4;">
  Reading Comprehension
</h2>

<!-- Body Text -->
<p style="font-size: var(--rp-font-size-base); line-height: 1.6;">
  Student demonstrated strong comprehension of literal meaning...
</p>

<!-- Small Label -->
<label style="font-size: var(--rp-font-size-sm);">
  Difficulty Level
</label>
```

### Border Radius

```css
--rp-radius-sm: 6px          /* Small buttons, small components */
--rp-radius-md: 8px          /* Standard cards, modals */
--rp-radius-lg: 12px         /* Large cards, containers */
--rp-radius-xl: 16px         /* Extra large components */
--rp-radius-full: 9999px     /* Perfect circles, fully rounded */
```

**Component Mapping:**
- **Buttons**: radius-sm
- **Form elements**: radius-md
- **Cards**: radius-lg
- **Modals/Large containers**: radius-lg, radius-xl
- **Badges/Chips**: radius-full
- **Icons**: radius-full (when wrapped)

### Shadows

```css
--rp-shadow-sm: 0 1px 2px rgba(15, 23, 42, 0.04)     /* Subtle elevation */
--rp-shadow-md: 0 4px 12px rgba(15, 23, 42, 0.06)    /* Elevated surface */
--rp-shadow-lg: 0 8px 24px rgba(15, 23, 42, 0.08)    /* Card elevation */
--rp-shadow-xl: 0 16px 40px rgba(15, 23, 42, 0.12)   /* Modal/dialog elevation */
```

**Usage:**
- **Hover states**: shadow-sm → shadow-md (lift effect)
- **Cards**: shadow-md
- **Modals**: shadow-xl
- **Dropdowns**: shadow-md
- **Floating buttons**: shadow-lg

### Transitions

```css
--rp-transition-fast: 0.15s ease      /* Quick interactions (hover) */
--rp-transition-normal: 0.2s ease     /* Standard transitions (state change) */
--rp-transition-slow: 0.3s ease       /* Prominent transitions (modal open) */
```

---

## Layout System

### Header
- **Height**: 64px (--rp-header-height)
- **Components**: Logo, page title, notifications, user menu, role chip
- **Sticky**: Fixed positioning with z-index: 100
- **Responsive**: Hamburger menu on mobile

### Sidebar Navigation
- **Width**: 240px (--rp-sidebar-width)
- **Sticky**: Fixed positioning, full viewport height
- **Responsive**: Collapses to drawer on mobile (< 768px)
- **Features**:
  - Role-based menu groups
  - Collapsible navigation sections
  - Badge support for counts/notifications
  - Active state styling

### Main Content Area
- **Max Width**: 1200px (--rp-content-max-width)
- **Padding**: Consistent spacing (space-8, space-12)
- **Margin**: Auto-centered
- **Responsive**: Full width with padding on mobile

### Responsive Breakpoints

```css
/* Desktop (1400px and up) */
@media (min-width: 1400px) {
  /* Full layout: header + sidebar + content */
}

/* Laptop (1200px - 1399px) */
@media (min-width: 1200px) {
  /* Constrained max-width applied */
}

/* Tablet (768px - 1199px) */
@media (min-width: 768px) and (max-width: 1199px) {
  /* Sidebar may collapse, content expands */
}

/* Mobile (640px - 767px) */
@media (max-width: 767px) {
  /* Sidebar as drawer, single column layout */
}

/* Small Mobile (< 640px) */
@media (max-width: 639px) {
  /* Minimal padding, full-width components */
}
```

---

## Component Catalog

### Buttons

#### Variants
- **Primary**: Main call-to-action (blue, filled)
- **Secondary**: Alternative action (outlined)
- **Ghost**: Tertiary action (text-only)
- **Danger**: Destructive action (red, filled)
- **Success**: Positive action (green, filled)
- **Disabled**: Unavailable action (grayed out)

#### Sizes
- **Small (.rp-btn--sm)**: Compact, 32px height
- **Normal (default)**: Standard, 40px height
- **Large (.rp-btn--lg)**: Prominent, 44px height

#### Usage
```html
<!-- Primary Button -->
<button class="rp-btn rp-btn--primary">Submit Assessment</button>

<!-- Secondary Button -->
<button class="rp-btn rp-btn--secondary">Cancel</button>

<!-- Danger Button -->
<button class="rp-btn rp-btn--danger" data-confirm="Delete this item?">Delete</button>

<!-- Disabled Button -->
<button class="rp-btn rp-btn--primary" disabled>Coming Soon</button>
```

### Cards

```html
<!-- Basic Card -->
<div class="rp-card">
  <div class="rp-card__header">
    <h3>Assessment Title</h3>
  </div>
  <div class="rp-card__body">
    Content goes here...
  </div>
  <div class="rp-card__footer">
    <button class="rp-btn rp-btn--primary">Continue</button>
  </div>
</div>

<!-- Clickable Card -->
<a href="/assessment/123" class="rp-card rp-card--clickable">
  <div class="rp-card__body">
    Reading Assessment - Level 4
  </div>
</a>

<!-- Highlighted Card -->
<div class="rp-card rp-card--highlight">
  <div class="rp-card__body">
    Important announcement
  </div>
</div>
```

### Forms

#### Input Elements
```html
<!-- Text Input -->
<div class="rp-form-group">
  <label class="rp-label">Full Name *</label>
  <input type="text" class="rp-input" placeholder="Enter your name" required>
</div>

<!-- Select -->
<div class="rp-form-group">
  <label class="rp-label">Difficulty Level</label>
  <select class="rp-select">
    <option>Easy</option>
    <option>Medium</option>
    <option>Hard</option>
  </select>
</div>

<!-- Textarea -->
<div class="rp-form-group">
  <label class="rp-label">Your Answer</label>
  <textarea class="rp-textarea" rows="4"></textarea>
</div>
```

#### States
```html
<!-- Error State -->
<div class="rp-form-group rp-form-group--error">
  <label class="rp-label">Email *</label>
  <input type="email" class="rp-input" value="invalid-email">
  <span class="rp-form-error">Please enter a valid email address</span>
</div>

<!-- Success State -->
<div class="rp-form-group rp-form-group--success">
  <label class="rp-label">Username</label>
  <input type="text" class="rp-input" value="student_123">
  <span class="rp-form-success">Username is available</span>
</div>
```

### Badges and Status Indicators

```html
<!-- Status Badges -->
<span class="rp-badge rp-badge--success">Completed</span>
<span class="rp-badge rp-badge--warning">In Progress</span>
<span class="rp-badge rp-badge--danger">Failed</span>
<span class="rp-badge rp-badge--info">Draft</span>

<!-- Role Chips -->
<div class="rp-role-chip rp-role-chip--student">
  학생
</div>

<div class="rp-role-chip rp-role-chip--teacher">
  진단담당교사
</div>

<div class="rp-role-chip rp-role-chip--admin">
  관리자
</div>
```

### Tables

```html
<!-- Responsive Table -->
<div class="rp-table-wrapper">
  <table class="rp-table">
    <thead>
      <tr>
        <th>Question</th>
        <th>Status</th>
        <th>Score</th>
        <th>Action</th>
      </tr>
    </thead>
    <tbody>
      <tr class="rp-table__row rp-table__row--hover">
        <td>1. What is the main idea?</td>
        <td><span class="rp-badge rp-badge--success">Answered</span></td>
        <td>85/100</td>
        <td><a href="#">Review</a></td>
      </tr>
    </tbody>
  </table>
</div>
```

### Flash Messages

```html
<!-- Notice Message -->
<div class="rp-flash rp-flash--notice">
  <svg width="16" height="16"><!-- Icon --></svg>
  Assessment saved successfully
</div>

<!-- Alert Message -->
<div class="rp-flash rp-flash--alert">
  <svg width="16" height="16"><!-- Icon --></svg>
  Please complete all required fields
</div>
```

### Empty and Loading States

```html
<!-- Empty State -->
<div class="rp-empty-state">
  <div class="rp-empty-state__icon">📚</div>
  <h3>No assessments yet</h3>
  <p>Create your first assessment to get started</p>
  <a href="#" class="rp-btn rp-btn--primary">Create Assessment</a>
</div>

<!-- Loading State -->
<div class="rp-loading">
  <div class="rp-loading__spinner"></div>
  <p>Loading your assessment...</p>
</div>
```

---

## Responsive Design

### Mobile-First Approach

ReadingPRO uses a **mobile-first strategy**:
1. Base styles apply to mobile (< 768px)
2. Progressively enhance for larger screens
3. No mobile-specific styles; only additions

### Breakpoint Usage

```scss
/* Mobile (default) */
.rp-card {
  margin-bottom: var(--rp-space-4);
  grid-template-columns: 1fr;
}

/* Tablet and up */
@media (min-width: 768px) {
  .rp-card {
    margin-bottom: var(--rp-space-6);
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop and up */
@media (min-width: 1200px) {
  .rp-card {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Common Patterns

#### Sidebar Collapse
```scss
/* Mobile: Sidebar is hidden drawer */
.rp-sidebar {
  position: fixed;
  left: -240px;
  transition: left var(--rp-transition-normal);
}

.rp-sidebar--open {
  left: 0;
}

/* Tablet and up: Sidebar visible */
@media (min-width: 768px) {
  .rp-sidebar {
    position: static;
    left: auto;
    width: var(--rp-sidebar-width);
  }
}
```

#### Grid Layouts
```scss
/* Mobile: Single column */
.rp-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--rp-space-4);
}

/* Tablet: Two columns */
@media (min-width: 768px) {
  .rp-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop: Three columns */
@media (min-width: 1200px) {
  .rp-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

---

## Accessibility

### Color Contrast
All text/background color combinations meet **WCAG 2.1 AA standards** (4.5:1 minimum contrast):

- ✅ Title text (#0F172A) on white: 17.7:1
- ✅ Body text (#475569) on white: 7.4:1
- ✅ Primary buttons (#2F5BFF) on white text: 5.2:1
- ✅ Status badges meet 4.5:1 minimum

### Semantic HTML
```html
<!-- ✅ Good: Semantic structure -->
<nav aria-label="Main navigation">
  <ul role="list">
    <li><a href="#" aria-current="page">Dashboard</a></li>
  </ul>
</nav>

<!-- ✅ Good: Heading hierarchy -->
<h1>Main Title</h1>
<h2>Section</h2>
<h3>Subsection</h3>

<!-- ❌ Avoid: Non-semantic divs for structure -->
<div class="title">Don't use divs for headings</div>
```

### Focus Management
```css
.rp-btn:focus-visible {
  outline: 2px solid var(--rp-primary);
  outline-offset: 2px;
}

.rp-input:focus {
  border-color: var(--rp-primary);
  box-shadow: 0 0 0 3px var(--rp-primary-soft);
}
```

### ARIA Labels
```html
<!-- Icon buttons: always add aria-label -->
<button aria-label="Open menu">
  <svg><!-- menu icon --></svg>
</button>

<!-- Form labels: connect with aria-labelledby or for attribute -->
<label for="difficulty">Difficulty Level</label>
<select id="difficulty" class="rp-select">
  ...
</select>

<!-- Alert messages: announce to screen readers -->
<div role="alert" aria-live="polite">
  Assessment saved successfully
</div>
```

### Keyboard Navigation
- **Tab**: Move focus through interactive elements
- **Shift + Tab**: Move focus backwards
- **Enter**: Activate buttons and links
- **Space**: Activate buttons, toggle checkboxes
- **Escape**: Close modals and overlays
- **Arrow Keys**: Navigate menus, select lists

---

## Implementation Checklist

When building new features:

- [ ] Use design tokens for all color, spacing, typography values
- [ ] Ensure color contrast meets WCAG 2.1 AA minimum (4.5:1)
- [ ] Add focus-visible styles for keyboard navigation
- [ ] Test responsive layout on mobile, tablet, desktop
- [ ] Use semantic HTML (buttons, links, headings, labels)
- [ ] Add aria-label for icon-only buttons
- [ ] Implement form validation states (error/success)
- [ ] Test with keyboard-only navigation
- [ ] Verify with screen reader (NVDA, JAWS, VoiceOver)

---

## Design System Resources

- **Component Guide**: [COMPONENT_GUIDE.md](./COMPONENT_GUIDE.md)
- **Accessibility Guidelines**: [ACCESSIBILITY.md](./ACCESSIBILITY.md)
- **Icon Library**: [ICON_LIBRARY.md](./ICON_LIBRARY.md)
- **Design Tokens Export**: `rake design_tokens:export`
- **Style Guide**: Visit `/styleguide` (authenticated)

---

**Version**: 1.0
**Last Updated**: 2026-02-03
**Philosophy**: Korean Neo-Minimalism
**Status**: ✅ Active

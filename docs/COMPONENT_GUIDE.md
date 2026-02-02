# Component Usage Guide

Comprehensive guide for using ReadingPRO design system components. Each component includes HTML structure, class names, variants, real-world examples, do's and don'ts, and accessibility notes.

---

## Table of Contents
1. [Buttons](#buttons)
2. [Form Elements](#form-elements)
3. [Cards](#cards)
4. [Badges and Status](#badges-and-status)
5. [Navigation](#navigation)
6. [Tables](#tables)
7. [Messages and Alerts](#messages-and-alerts)
8. [Layout Components](#layout-components)

---

## Buttons

### Basic Button

```html
<button class="rp-btn rp-btn--primary">
  Primary Action
</button>
```

### Button Variants

```html
<!-- Primary: Main call-to-action -->
<button class="rp-btn rp-btn--primary">Save Changes</button>

<!-- Secondary: Alternative action -->
<button class="rp-btn rp-btn--secondary">Cancel</button>

<!-- Ghost: Tertiary action -->
<button class="rp-btn rp-btn--ghost">Learn More</button>

<!-- Success: Positive action -->
<button class="rp-btn rp-btn--success">Approve</button>

<!-- Danger: Destructive action -->
<button class="rp-btn rp-btn--danger">Delete</button>

<!-- Disabled: Unavailable state -->
<button class="rp-btn rp-btn--primary" disabled>Coming Soon</button>
```

### Button Sizes

```html
<!-- Small -->
<button class="rp-btn rp-btn--primary rp-btn--sm">Small</button>

<!-- Normal (default) -->
<button class="rp-btn rp-btn--primary">Normal</button>

<!-- Large -->
<button class="rp-btn rp-btn--primary rp-btn--lg">Large</button>
```

### Button with Icon

```html
<!-- Icon with text -->
<button class="rp-btn rp-btn--primary">
  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/>
  </svg>
  Continue
</button>

<!-- Icon only -->
<button class="rp-btn rp-btn--ghost rp-btn--sm" aria-label="Close">
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
    <line x1="18" y1="6" x2="6" y2="18"></line>
    <line x1="6" y1="6" x2="18" y2="18"></line>
  </svg>
</button>
```

### Real-World Examples

```html
<!-- Form Submission -->
<form class="rp-form">
  <div class="rp-form-group">
    <label class="rp-label">Question Answer</label>
    <textarea class="rp-textarea"></textarea>
  </div>
  <div class="rp-button-group">
    <button type="submit" class="rp-btn rp-btn--primary">Submit Answer</button>
    <button type="reset" class="rp-btn rp-btn--secondary">Clear</button>
  </div>
</form>

<!-- Action Toolbar -->
<div class="rp-toolbar">
  <button class="rp-btn rp-btn--primary">Create New</button>
  <button class="rp-btn rp-btn--secondary">Import</button>
  <button class="rp-btn rp-btn--ghost">Export</button>
</div>

<!-- Confirmation Dialog -->
<div class="rp-modal">
  <h2>Delete Assessment?</h2>
  <p>This action cannot be undone.</p>
  <div class="rp-button-group rp-button-group--right">
    <button class="rp-btn rp-btn--secondary">Cancel</button>
    <button class="rp-btn rp-btn--danger">Delete</button>
  </div>
</div>
```

### Do's and Don'ts

✅ **DO:**
- Use primary button for main action per screen
- Use descriptive text: "Save Changes" not "OK"
- Disable buttons for invalid state (don't hide)
- Include loading state for async actions

❌ **DON'T:**
- Use all caps text (style does this automatically)
- Mix primary and secondary buttons randomly
- Use danger color for non-destructive actions
- Create button-like links (use `<a>` tags)

### Accessibility

```html
<!-- ✅ Good: Clear action label -->
<button class="rp-btn rp-btn--primary">
  Submit Assessment
</button>

<!-- ✅ Good: Icon buttons have aria-label -->
<button class="rp-btn rp-btn--ghost" aria-label="Delete this item">
  <svg><!-- trash icon --></svg>
</button>

<!-- ✅ Good: Disabled with explanation -->
<button class="rp-btn rp-btn--primary" disabled title="Complete all required fields to submit">
  Submit
</button>

<!-- ❌ Bad: Unclear action -->
<button class="rp-btn rp-btn--primary">Click Here</button>

<!-- ❌ Bad: Icon without label -->
<button class="rp-btn rp-btn--ghost">
  <svg><!-- trash icon --></svg>
</button>
```

---

## Form Elements

### Text Input

```html
<div class="rp-form-group">
  <label for="name" class="rp-label">Full Name <span class="rp-required">*</span></label>
  <input
    type="text"
    id="name"
    class="rp-input"
    placeholder="Enter your full name"
    required
  >
  <span class="rp-form-hint">First and last name required</span>
</div>
```

### Select (Dropdown)

```html
<div class="rp-form-group">
  <label for="level" class="rp-label">Reading Level</label>
  <select id="level" class="rp-select">
    <option value="">-- Select a level --</option>
    <option value="beginner">Beginner (Level 1-2)</option>
    <option value="intermediate">Intermediate (Level 3-4)</option>
    <option value="advanced">Advanced (Level 5-6)</option>
  </select>
</div>
```

### Textarea

```html
<div class="rp-form-group">
  <label for="answer" class="rp-label">Your Answer</label>
  <textarea
    id="answer"
    class="rp-textarea"
    rows="6"
    placeholder="Write your response here..."
  ></textarea>
  <span class="rp-form-hint">
    Minimum 100 characters required
  </span>
</div>
```

### Checkbox

```html
<div class="rp-form-group">
  <div class="rp-checkbox">
    <input
      type="checkbox"
      id="agree"
      class="rp-checkbox__input"
    >
    <label for="agree" class="rp-checkbox__label">
      I agree to the terms and conditions
    </label>
  </div>
</div>
```

### Radio Buttons

```html
<fieldset class="rp-form-group">
  <legend class="rp-label">How confident are you in your answer?</legend>

  <div class="rp-radio">
    <input
      type="radio"
      id="conf-high"
      name="confidence"
      value="high"
      class="rp-radio__input"
    >
    <label for="conf-high" class="rp-radio__label">Very Confident</label>
  </div>

  <div class="rp-radio">
    <input
      type="radio"
      id="conf-med"
      name="confidence"
      value="medium"
      class="rp-radio__input"
    >
    <label for="conf-med" class="rp-radio__label">Somewhat Confident</label>
  </div>

  <div class="rp-radio">
    <input
      type="radio"
      id="conf-low"
      name="confidence"
      value="low"
      class="rp-radio__input"
    >
    <label for="conf-low" class="rp-radio__label">Not Confident</label>
  </div>
</fieldset>
```

### Form Validation States

```html
<!-- Success State -->
<div class="rp-form-group rp-form-group--success">
  <label for="username" class="rp-label">Username</label>
  <input
    type="text"
    id="username"
    class="rp-input"
    value="student_123"
  >
  <span class="rp-form-success">✓ Username is available</span>
</div>

<!-- Error State -->
<div class="rp-form-group rp-form-group--error">
  <label for="email" class="rp-label">Email Address</label>
  <input
    type="email"
    id="email"
    class="rp-input"
    value="invalid-email"
    aria-invalid="true"
    aria-describedby="email-error"
  >
  <span id="email-error" class="rp-form-error">
    Please enter a valid email address (example@domain.com)
  </span>
</div>
```

### Complete Form Example

```html
<form class="rp-form" action="/student/assessments" method="post">
  <fieldset>
    <legend class="rp-form-legend">Create Assessment</legend>

    <div class="rp-form-group">
      <label for="title" class="rp-label">
        Assessment Title <span class="rp-required">*</span>
      </label>
      <input
        type="text"
        id="title"
        name="title"
        class="rp-input"
        required
      >
    </div>

    <div class="rp-form-row">
      <div class="rp-form-group rp-form-group--half">
        <label for="difficulty" class="rp-label">Difficulty</label>
        <select id="difficulty" name="difficulty" class="rp-select">
          <option>Easy</option>
          <option>Medium</option>
          <option>Hard</option>
        </select>
      </div>

      <div class="rp-form-group rp-form-group--half">
        <label for="duration" class="rp-label">Duration (minutes)</label>
        <input
          type="number"
          id="duration"
          name="duration"
          class="rp-input"
          min="5"
          max="120"
        >
      </div>
    </div>

    <div class="rp-form-group">
      <label for="description" class="rp-label">Description</label>
      <textarea
        id="description"
        name="description"
        class="rp-textarea"
        rows="4"
      ></textarea>
    </div>

    <div class="rp-form-actions">
      <button type="submit" class="rp-btn rp-btn--primary">
        Create Assessment
      </button>
      <button type="reset" class="rp-btn rp-btn--secondary">
        Clear
      </button>
    </div>
  </fieldset>
</form>
```

### Do's and Don'ts

✅ **DO:**
- Always pair inputs with labels (even if hidden)
- Use `type="email"` for email, `type="number"` for numbers
- Show validation errors immediately and clearly
- Use hint text for requirements or formatting
- Disable submit until form is valid

❌ **DON'T:**
- Use placeholder as label (disappears on focus)
- Submit form with validation errors
- Reset form without confirmation
- Use too many form fields on one screen
- Mix input types (don't use text for dates)

### Accessibility

```html
<!-- ✅ Good: Proper label association -->
<label for="input-id" class="rp-label">Label Text</label>
<input id="input-id" type="text" class="rp-input">

<!-- ✅ Good: Form groups clearly separated -->
<fieldset class="rp-form-group">
  <legend class="rp-label">Group Title</legend>
  <div class="rp-radio"><!-- radio options --></div>
</fieldset>

<!-- ✅ Good: Error explanation for screen readers -->
<input
  aria-invalid="true"
  aria-describedby="error-id"
>
<span id="error-id" class="rp-form-error">Error details</span>

<!-- ❌ Bad: No label connection -->
<label>Email</label>
<input type="email">

<!-- ❌ Bad: Placeholder as label -->
<input type="text" placeholder="Email address">
```

---

## Cards

### Basic Card

```html
<article class="rp-card">
  <div class="rp-card__header">
    <h3 class="rp-card__title">Assessment Title</h3>
    <span class="rp-badge rp-badge--success">Active</span>
  </div>
  <div class="rp-card__body">
    <p>
      This assessment covers reading comprehension
      and vocabulary skills at Level 4.
    </p>
  </div>
  <div class="rp-card__footer">
    <small>Created 2 days ago</small>
  </div>
</article>
```

### Clickable Card

```html
<a href="/assessment/123" class="rp-card rp-card--clickable">
  <div class="rp-card__header">
    <h3>Reading Assessment</h3>
  </div>
  <div class="rp-card__body">
    Level 4 • 45 minutes • 25 questions
  </div>
</a>
```

### Card with Actions

```html
<article class="rp-card">
  <div class="rp-card__header">
    <h3>Question Bank</h3>
    <div class="rp-card__actions">
      <button class="rp-btn rp-btn--ghost rp-btn--sm" aria-label="Edit">
        ✎
      </button>
      <button class="rp-btn rp-btn--ghost rp-btn--sm" aria-label="Delete">
        🗑
      </button>
    </div>
  </div>
  <div class="rp-card__body">
    <p>500 questions in the bank</p>
  </div>
</article>
```

### Highlighted Card

```html
<div class="rp-card rp-card--highlight rp-card--info">
  <div class="rp-card__header">
    <h3>📢 Important Notice</h3>
  </div>
  <div class="rp-card__body">
    <p>Assessment deadline changed to March 15, 2026</p>
  </div>
</div>
```

### Card Grid

```html
<div class="rp-grid rp-grid--cards">
  <article class="rp-card">
    <!-- Card 1 -->
  </article>
  <article class="rp-card">
    <!-- Card 2 -->
  </article>
  <article class="rp-card">
    <!-- Card 3 -->
  </article>
</div>
```

### Do's and Don'ts

✅ **DO:**
- Use cards to group related content
- Keep card height consistent within a grid
- Provide clear visual hierarchy within cards
- Make clickable cards keyboard accessible

❌ **DON'T:**
- Nest cards inside cards
- Create cards with too much content
- Use cards for layout structure
- Hide important information in cards

### Accessibility

```html
<!-- ✅ Good: Semantic structure -->
<article class="rp-card">
  <h3>Title</h3>
  <p>Content...</p>
</article>

<!-- ✅ Good: Keyboard accessible -->
<a href="/detail" class="rp-card rp-card--clickable">
  Content (entire card is clickable)
</a>

<!-- ❌ Bad: Non-semantic card -->
<div class="rp-card">
  <div>Title</div>
  <div>Content</div>
</div>
```

---

## Badges and Status

### Status Badges

```html
<!-- Success -->
<span class="rp-badge rp-badge--success">Completed</span>

<!-- Warning -->
<span class="rp-badge rp-badge--warning">In Progress</span>

<!-- Danger -->
<span class="rp-badge rp-badge--danger">Failed</span>

<!-- Info -->
<span class="rp-badge rp-badge--info">Draft</span>

<!-- Primary -->
<span class="rp-badge rp-badge--primary">Featured</span>
```

### Role Chips

```html
<div class="rp-role-chip rp-role-chip--student">
  <svg width="16" height="16"><!-- student icon --></svg>
  <span>학생</span>
</div>

<div class="rp-role-chip rp-role-chip--teacher">
  <svg width="16" height="16"><!-- teacher icon --></svg>
  <span>진단담당교사</span>
</div>

<div class="rp-role-chip rp-role-chip--admin">
  <svg width="16" height="16"><!-- admin icon --></svg>
  <span>관리자</span>
</div>

<div class="rp-role-chip rp-role-chip--developer">
  <svg width="16" height="16"><!-- developer icon --></svg>
  <span>문항개발위원</span>
</div>
```

### Counter Badges

```html
<!-- Notification count -->
<button class="rp-btn-with-badge">
  <svg><!-- notification icon --></svg>
  <span class="rp-badge rp-badge--danger">3</span>
</button>

<!-- Item count on navigation -->
<a href="/items">
  Items
  <span class="rp-badge rp-badge--primary">142</span>
</a>
```

### Inline Status

```html
<!-- In a list -->
<li class="rp-list-item">
  <span>Assessment Name</span>
  <span class="rp-badge rp-badge--success">Active</span>
</li>

<!-- In a table -->
<td>
  Status:
  <span class="rp-badge rp-badge--warning">Pending</span>
</td>
```

---

## Navigation

### Main Navigation Header

```html
<header class="rp-header">
  <div class="rp-header__left">
    <!-- Hamburger Menu (Mobile) -->
    <button class="rp-header__hamburger" id="sidebarToggle" aria-label="메뉴 열기">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="3" y1="6" x2="21" y2="6"></line>
        <line x1="3" y1="12" x2="21" y2="12"></line>
        <line x1="3" y1="18" x2="21" y2="18"></line>
      </svg>
    </button>

    <!-- Logo -->
    <div class="rp-logo">
      <a href="/" class="rp-logo__main">
        <svg class="rp-logo__icon" viewBox="0 0 24 24" aria-hidden="true">
          <!-- Logo SVG -->
        </svg>
        <span class="rp-logo__text">ReadingPRO</span>
      </a>
    </div>
  </div>

  <div class="rp-header__center">
    <h1 class="rp-header__title">Page Title</h1>
  </div>

  <div class="rp-header__right">
    <!-- Notifications -->
    <button class="rp-notification-btn" aria-label="알림">
      <svg><!-- bell icon --></svg>
      <span class="rp-notification-btn__badge">3</span>
    </button>

    <!-- Role Selector -->
    <div class="rp-dropdown">
      <button class="rp-role-chip">
        <span>학생</span>
      </button>
      <div class="rp-dropdown__content">
        <a href="#" class="rp-dropdown__item">내 정보</a>
        <a href="#" class="rp-dropdown__item">도움말</a>
      </div>
    </div>

    <!-- User Name -->
    <button class="rp-user-name-btn">
      <%= current_user.name %>
    </button>

    <!-- Logout -->
    <%= button_to "로그아웃", logout_path, method: :delete, class: "rp-btn rp-btn--secondary" %>
  </div>
</header>
```

### Sidebar Navigation

```html
<nav class="rp-sidebar" role="navigation" aria-label="Main navigation">
  <!-- Student Role Navigation -->
  <div class="rp-nav-section">
    <h3 class="rp-nav-section__title">학습</h3>
    <ul class="rp-nav-list" role="list">
      <li>
        <a href="/student/dashboard" class="rp-nav-link rp-nav-link--active">
          대시보드
        </a>
      </li>
      <li>
        <a href="/student/assessments" class="rp-nav-link">
          평가 목록
        </a>
      </li>
    </ul>
  </div>

  <div class="rp-nav-section">
    <h3 class="rp-nav-section__title">커뮤니티</h3>
    <ul class="rp-nav-list" role="list">
      <li>
        <a href="/consultations" class="rp-nav-link">
          상담 게시판
        </a>
      </li>
    </ul>
  </div>
</nav>
```

---

## Tables

### Basic Table

```html
<div class="rp-table-wrapper">
  <table class="rp-table">
    <thead>
      <tr>
        <th>Question Code</th>
        <th>Type</th>
        <th>Difficulty</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      <tr class="rp-table__row">
        <td data-label="Question Code">Q-001</td>
        <td data-label="Type">Multiple Choice</td>
        <td data-label="Difficulty">Medium</td>
        <td data-label="Status">
          <span class="rp-badge rp-badge--success">Active</span>
        </td>
      </tr>
      <tr class="rp-table__row rp-table__row--hover">
        <td data-label="Question Code">Q-002</td>
        <td data-label="Type">Constructed Response</td>
        <td data-label="Difficulty">Hard</td>
        <td data-label="Status">
          <span class="rp-badge rp-badge--warning">Draft</span>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

### Table with Actions

```html
<table class="rp-table">
  <thead>
    <tr>
      <th>Student Name</th>
      <th>Score</th>
      <th>Completion</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr class="rp-table__row">
      <td>Kim Ha-yoon</td>
      <td>85/100</td>
      <td>
        <div class="rp-progress">
          <div class="rp-progress__bar" style="width: 100%"></div>
        </div>
      </td>
      <td>
        <div class="rp-table__actions">
          <a href="/results/123" class="rp-btn rp-btn--ghost rp-btn--sm">
            View
          </a>
          <button class="rp-btn rp-btn--ghost rp-btn--sm">
            Edit
          </button>
        </div>
      </td>
    </tr>
  </tbody>
</table>
```

### Responsive Table

On mobile, tables transform to stacked layout:

```html
<!-- HTML: Same structure -->
<table class="rp-table">
  <tr>
    <th>Name</th>
    <th>Score</th>
  </tr>
  <tr>
    <td data-label="Name">Student</td>
    <td data-label="Score">95</td>
  </tr>
</table>

<!-- Mobile CSS: Stacked display -->
@media (max-width: 767px) {
  .rp-table {
    display: block;
  }

  .rp-table thead {
    display: none;
  }

  .rp-table tbody tr {
    display: block;
    border: 1px solid var(--rp-border);
    margin-bottom: var(--rp-space-4);
  }

  .rp-table td {
    display: flex;
    justify-content: space-between;
    padding: var(--rp-space-4);
  }

  .rp-table td:before {
    content: attr(data-label);
    font-weight: bold;
  }
}
```

---

## Messages and Alerts

### Flash Messages

```html
<!-- Success Message -->
<div class="rp-flash rp-flash--notice" role="alert">
  <svg width="16" height="16" fill="currentColor">
    <circle cx="12" cy="12" r="10"></circle>
    <text x="12" y="16" text-anchor="middle">✓</text>
  </svg>
  <span>Assessment saved successfully</span>
</div>

<!-- Error Message -->
<div class="rp-flash rp-flash--alert" role="alert">
  <svg width="16" height="16" fill="currentColor">
    <circle cx="12" cy="12" r="10"></circle>
    <text x="12" y="15" text-anchor="middle">!</text>
  </svg>
  <span>Please complete all required fields</span>
</div>

<!-- Warning Message -->
<div class="rp-flash rp-flash--warning" role="alert">
  <svg width="16" height="16" fill="currentColor">
    <path d="M1 21h22L12 2 1 21z"></path>
  </svg>
  <span>Assessment deadline is approaching</span>
</div>
```

### Inline Messages

```html
<!-- Info Box -->
<div class="rp-info-box">
  <svg><!-- info icon --></svg>
  <p>This assessment is required for course completion</p>
</div>

<!-- Warning Box -->
<div class="rp-warning-box">
  <svg><!-- warning icon --></svg>
  <p>Your changes will be saved automatically</p>
</div>

<!-- Error Box -->
<div class="rp-error-box">
  <svg><!-- error icon --></svg>
  <p>There was a problem loading the assessment</p>
</div>
```

---

## Layout Components

### Container

```html
<div class="rp-main__container">
  <!-- Main content goes here -->
  <!-- Auto-centered with max-width and padding -->
</div>
```

### Grid Layout

```html
<!-- Auto grid: responsive columns -->
<div class="rp-grid">
  <div class="rp-grid__item"><!-- Card or content --></div>
  <div class="rp-grid__item"><!-- Card or content --></div>
  <div class="rp-grid__item"><!-- Card or content --></div>
</div>

<!-- Two-column layout -->
<div class="rp-grid rp-grid--2col">
  <div>Left column</div>
  <div>Right column</div>
</div>

<!-- Three-column layout -->
<div class="rp-grid rp-grid--3col">
  <div>Column 1</div>
  <div>Column 2</div>
  <div>Column 3</div>
</div>
```

### Flex Layout

```html
<!-- Space between -->
<div class="rp-flex rp-flex--between">
  <h2>Title</h2>
  <button>Action</button>
</div>

<!-- Center alignment -->
<div class="rp-flex rp-flex--center">
  <svg><!-- icon --></svg>
  <span>Content</span>
</div>

<!-- With gap -->
<div class="rp-flex rp-flex--gap-4">
  <button class="rp-btn">Button 1</button>
  <button class="rp-btn">Button 2</button>
  <button class="rp-btn">Button 3</button>
</div>
```

### Stack Layout

```html
<!-- Vertical stacking -->
<div class="rp-stack rp-stack--gap-6">
  <section>Section 1</section>
  <section>Section 2</section>
  <section>Section 3</section>
</div>
```

---

## Common Patterns

### Empty State

```html
<div class="rp-empty-state">
  <div class="rp-empty-state__icon">📚</div>
  <h3 class="rp-empty-state__title">No assessments yet</h3>
  <p class="rp-empty-state__description">
    Get started by creating your first assessment
  </p>
  <a href="#" class="rp-btn rp-btn--primary">
    Create Assessment
  </a>
</div>
```

### Loading State

```html
<div class="rp-loading">
  <div class="rp-loading__spinner"></div>
  <p class="rp-loading__text">Loading assessment...</p>
</div>
```

### No Results

```html
<div class="rp-no-results">
  <svg class="rp-no-results__icon"><!-- search icon --></svg>
  <h3>No results found</h3>
  <p>Try adjusting your search criteria</p>
  <button class="rp-btn rp-btn--secondary">Clear Filters</button>
</div>
```

---

## Implementation Checklist

When using components:

- [ ] Use correct component for the task (button vs. link)
- [ ] Apply appropriate variant/modifier classes
- [ ] Ensure proper semantic HTML structure
- [ ] Test keyboard navigation (Tab, Enter, Escape)
- [ ] Check color contrast (4.5:1 minimum)
- [ ] Add ARIA labels for icon-only elements
- [ ] Test on mobile (< 768px width)
- [ ] Verify form labels are connected to inputs
- [ ] Test with screen reader
- [ ] Ensure proper heading hierarchy

---

**Component Status**: ✅ All components documented
**Last Updated**: 2026-02-03

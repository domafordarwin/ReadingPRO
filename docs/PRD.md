# ReadingPRO - Product Requirements Document (PRD)

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Document Type**: Product Requirements Document

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Vision & Goals](#vision--goals)
3. [User Personas](#user-personas)
4. [User Stories & Use Cases](#user-stories--use-cases)
5. [Feature Requirements](#feature-requirements)
6. [Functional Requirements by Feature](#functional-requirements-by-feature)
7. [Non-Functional Requirements](#non-functional-requirements)
8. [Out of Scope](#out-of-scope)
9. [Success Metrics & KPIs](#success-metrics--kpis)
10. [Appendix](#appendix)

---

## Executive Summary

### Project Overview

**ReadingPRO** is a comprehensive reading proficiency diagnostics and assessment platform designed for Korean middle schools. The system enables educators to administer, score, and analyze reading comprehension assessments while providing students and parents with detailed diagnostic reports and learning pathways.

### Problem Statement

Traditional reading assessments focus on binary correct/incorrect scoring, which fails to capture the nuanced aspects of reading comprehension development. Schools lack integrated systems to:

- Manage diverse item types (MCQ with partial credit, constructed responses with rubric-based scoring)
- Generate adaptive AI-powered feedback tailored to individual student performance
- Enable multi-stakeholder collaboration (students, parents, teachers, administrators)
- Track reading proficiency trends over time with actionable insights
- Support assessment content development at scale

### Solution

ReadingPRO provides a unified platform featuring:

- **Advanced Scoring System**: Percentage-based MCQ scoring (0-100%) + multi-criteria rubric scoring for constructed responses
- **AI-Powered Feedback**: Template-driven, context-aware feedback generation using OpenAI GPT
- **Multi-Portal Architecture**: Six specialized portals for different user roles with appropriate access controls
- **Assessment Content Management**: Comprehensive item bank with evaluation indicators, reading stimuli, and rubric management
- **Multi-Stakeholder Communication**: Integrated consultation and forum systems for teachers, students, and parents
- **Learning Analytics**: School and individual student portfolio tracking with performance trends

### Target Users

1. **Students** (중학생): Primary assessment takers
2. **Parents** (학부모): Monitor children's progress, request consultations
3. **Diagnostic Teachers** (진단담당교사): Administer assessments, generate feedback, manage consultations
4. **Researchers** (문항개발위원): Develop and manage assessment content
5. **School Administrators**: Oversee school-level performance and manage resources
6. **System Administrators**: Manage users, roles, and system configuration

### Key Success Factors

1. Intuitive, role-appropriate user interfaces for each stakeholder
2. Accurate, equitable assessment scoring mechanisms
3. Timely, actionable feedback for learning improvement
4. Reliable, secure handling of sensitive student data
5. Scalability to support multiple schools and thousands of students

---

## Vision & Goals

### Product Vision

"Empower educators and families with intelligent, equitable reading assessment and feedback systems that unlock every student's reading potential."

### Strategic Goals

| Goal | Description | Success Metric |
|------|-------------|-----------------|
| **G1: Comprehensive Assessment** | Support diverse item types and scoring methods | 95% accuracy in automated scoring; 100% rubric coverage |
| **G2: Actionable Insights** | Provide data-driven feedback that improves learning | 80% of students show measurable improvement post-feedback |
| **G3: Stakeholder Engagement** | Enable meaningful communication across school community | 90% adoption rate among teachers; 70% among parents |
| **G4: Content Excellence** | Maintain high-quality assessment content at scale | 100% content items align with learning standards |
| **G5: System Reliability** | Ensure platform stability during peak usage | 99.5% uptime; <500ms response time for 95th percentile |

---

## User Personas

### 1. **학생 (Hae-yoon Kim, Age 13)**

**Profile**:
- Middle school student in Seoul
- First-time test taker with some reading comprehension challenges
- Motivated by clear, supportive feedback
- Uses mobile devices occasionally, primarily desktop at school

**Goals**:
- Understand where their reading comprehension strengths and weaknesses are
- Receive guidance on how to improve specific reading skills
- Track progress over time
- Access feedback in a non-judgmental, encouraging manner

**Pain Points**:
- Anxiety about test performance
- Difficulty understanding why they got certain questions wrong
- Limited feedback from traditional assessments
- Unsure about which specific reading skills to practice

**Key Behaviors**:
- Takes 30-50 minutes to complete a diagnostic assessment
- Checks results immediately after submission
- Discusses feedback with parents and teachers
- Revisits past assessments to track improvement

---

### 2. **학부모 (Parent of Hae-yoon Kim, Age 43)**

**Profile**:
- Working professional, concerned about child's academic progress
- Limited technical literacy but willing to learn
- Wants to support child's learning without direct intervention
- Prefers email and app notifications over complex dashboards

**Goals**:
- Understand child's reading proficiency level clearly
- Access unbiased assessment results and growth data
- Request professional guidance from teachers (consultations)
- Connect with other parents for advice and support
- Know specific areas where child needs improvement

**Pain Points**:
- Difficulty interpreting assessment results
- Uncertain how to help child improve reading skills
- Limited communication channels with school
- Information scattered across multiple platforms

**Key Behaviors**:
- Logs in 1-2 times per week to check results
- Reads teacher feedback carefully
- Submits consultation requests before parent-teacher conferences
- Participates in parent forums for peer advice

---

### 3. **진단담당교사 (Diagnostic Teacher, Age 38)**

**Profile**:
- Full-time reading diagnostician with 8 years of experience
- Subject matter expert in literacy assessment
- Manages 300-500 students across multiple schools
- Heavy user of assessment platform during testing windows

**Goals**:
- Efficiently administer assessments to large student populations
- Score constructed responses accurately and consistently
- Generate meaningful, personalized feedback at scale
- Monitor student progress trends and identify at-risk students
- Communicate effectively with parents and school administrators
- Access comprehensive usage analytics and assessment data

**Pain Points**:
- Time-consuming manual feedback generation
- Inconsistency in rubric scoring without clear guidelines
- Difficulty tracking students across multiple assessment batches
- Limited visibility into parent engagement and student progress

**Key Behaviors**:
- Spends 4-6 hours per week reviewing and scoring responses
- Uses feedback templates to ensure consistency
- Conducts 10-15 consultations per month with parents
- Analyzes assessment data for school improvement planning

---

### 4. **문항개발위원 (Researcher/Content Developer, Age 45)**

**Profile**:
- Experienced educator and assessment specialist
- Part-time content creator, manages item bank across districts
- Requires specialized tools for item creation and testing
- Data-driven, values item analytics

**Goals**:
- Create, edit, and publish high-quality assessment items
- Organize items by evaluation standards and difficulty levels
- Manage reading stimuli (passages) and rubrics
- View item difficulty and discrimination indices
- Ensure consistency with learning standards

**Pain Points**:
- Manual processes for item creation and organization
- No centralized repository for assessment content
- Difficulty tracking which items are in use and their effectiveness
- Limited tools for bulk import/export of content

**Key Behaviors**:
- Spends 5-8 hours per week creating and editing items
- Reviews item analytics monthly
- Imports content in bulk from Excel files
- Maintains detailed rubrics for constructed response items

---

### 5. **학교관리자 (School Administrator, Age 52)**

**Profile**:
- Principal or vice-principal responsible for academic excellence
- Strategic decision-maker focused on whole-school improvement
- Limited technical background but data-driven mindset
- Reports to district office on student achievement metrics

**Goals**:
- Monitor school-wide reading proficiency trends
- Identify schools/grades with gaps requiring intervention
- Report aggregate performance data to district
- Make resource allocation decisions based on data
- Support teachers with professional development insights

**Pain Points**:
- Fragmented data across multiple systems
- Difficulty identifying school-wide improvement areas
- Time-consuming manual report generation
- Limited visibility into teacher workload and effectiveness

**Key Behaviors**:
- Logs in weekly to review school-level dashboards
- Generates monthly reports for district
- Uses data for grade-level and subject-area planning meetings
- Tracks teacher feedback quality and timeliness

---

### 6. **시스템관리자 (System Administrator, Age 35)**

**Profile**:
- IT administrator managing school/district technology infrastructure
- Responsible for system reliability, security, and user management
- Technical background with focus on operational excellence
- Limited time availability for non-critical issues

**Goals**:
- Maintain system uptime and security
- Manage user accounts, roles, and permissions efficiently
- Monitor system performance and resource usage
- Troubleshoot technical issues quickly
- Ensure data backup and disaster recovery

**Pain Points**:
- Incidents during peak testing periods
- User credential management complexity
- Limited logging and monitoring visibility
- Difficulty troubleshooting user experience issues

**Key Behaviors**:
- Checks system status daily
- Responds to critical incidents within 30 minutes
- Manages 100-1000+ user accounts
- Reviews security logs weekly

---

## User Stories & Use Cases

### Student Use Cases

**US-1.1**: *As a student, I want to take a diagnostic reading assessment so that I can understand my reading proficiency level.*

- **Acceptance Criteria**:
  - Student can navigate to and view assigned assessments
  - UI displays clear instructions and expected time
  - Student can answer MCQ and constructed response questions
  - System auto-saves responses every 30 seconds
  - Student can submit assessment when complete
  - Confirmation message appears upon successful submission
  - Student cannot modify responses after submission

**US-1.2**: *As a student, I want to view my assessment results and detailed feedback so that I understand my strengths and areas for improvement.*

- **Acceptance Criteria**:
  - Results available within 24 hours of teacher review (constructed) or immediately (MCQ)
  - Score displayed clearly with performance level (e.g., Advanced, Proficient, Developing)
  - Item-by-item feedback provided with explanations for correct answers
  - Rubric scores shown for constructed responses
  - Comparison to peer performance (anonymized) optional
  - Growth trend chart shows performance over time
  - Recommendations for skill development included

**US-1.3**: *As a student, I want to post questions on the consultation board so that I can get help from teachers about my reading challenges.*

- **Acceptance Criteria**:
  - Student can create new consultation post (title, body, category)
  - Student can upload relevant assessment details
  - Parents cannot view student consultation board
  - Teachers can respond with comments
  - Student receives notification of responses
  - Student can view all their posts and responses

---

### Parent Use Cases

**US-2.1**: *As a parent, I want to view my child's assessment results so that I can understand their reading proficiency.*

- **Acceptance Criteria**:
  - Parent can access only their own child's data
  - Results displayed in clear, non-technical language
  - Score and performance level highlighted
  - Comparison to grade-level benchmarks provided
  - Learning recommendations included
  - History of past assessments visible
  - Can print/download results

**US-2.2**: *As a parent, I want to request a consultation with a teacher so that I can discuss my child's progress and get specific guidance.*

- **Acceptance Criteria**:
  - Parent can select child from dropdown (for parents with multiple children)
  - Parent can choose consultation type (진단결과, 독서지도, 학습습관, etc.)
  - Parent can select preferred date/time from available slots
  - Parent can describe consultation request (required: 10-1000 characters)
  - Status tracking: 대기 → 승인/거절 → 완료
  - Email notification when status changes
  - Can view consultation history

**US-2.3**: *As a parent, I want to participate in the parent forum so that I can discuss reading education with other parents.*

- **Acceptance Criteria**:
  - Parent can view all forum posts
  - Parent can create new forum thread
  - Parent can comment on threads
  - Moderation tools available for school admins
  - Posts can be marked as resolved/closed
  - Notification system for new responses to parent's posts

---

### Diagnostic Teacher Use Cases

**US-3.1**: *As a teacher, I want to administer reading diagnostic assessments to my students so that I can assess their proficiency.*

- **Acceptance Criteria**:
  - Teacher can create assessment session for a group of students
  - Can select specific assessment form
  - Can view real-time assessment status (not started, in progress, completed)
  - Can set time limits and proctoring rules
  - Can pause/resume sessions if needed
  - Can exclude specific students if needed
  - Reports when all students have submitted

**US-3.2**: *As a teacher, I want to score constructed response questions using rubrics so that I can provide consistent, fair assessment.*

- **Acceptance Criteria**:
  - Teacher sees response text and rubric criteria clearly
  - Can score each criterion independently (0-3 levels)
  - Can see historical scoring patterns for consistency
  - Can flag responses requiring additional review
  - Scoring history visible (who scored, when, score changes)
  - Can compare their scoring to peer teachers (for calibration)
  - System calculates total score automatically

**US-3.3**: *As a teacher, I want to generate AI-powered feedback for student responses so that I can provide timely, actionable feedback at scale.*

- **Acceptance Criteria**:
  - One-click feedback generation for multiple responses
  - Can customize feedback templates by response type
  - Can refine AI-generated feedback before sending
  - Can view feedback generation history
  - Fallback mechanism if API fails (template-based)
  - Feedback includes specific examples from student response
  - Can track feedback quality metrics (student engagement, understanding)

**US-3.4**: *As a teacher, I want to access student consultation requests and respond to them so that I can support student learning.**

- **Acceptance Criteria**:
  - Dashboard shows all pending consultation requests
  - Can filter by student, request type, date
  - Can view request details and previous consultations
  - Can approve/reject/request reschedule
  - Can add notes for consultation preparation
  - Student/parent notified of action taken
  - Can document consultation results post-meeting

**US-3.5**: *As a teacher, I want to generate comprehensive student reports so that I can communicate progress to parents and administrators.*

- **Acceptance Criteria**:
  - Report includes scores, performance level, trends
  - Item analysis (% correct, difficulty rating)
  - Skill profile (areas of strength/growth)
  - Comparative data (peer, grade-level benchmarks)
  - Recommendations for instruction
  - Can be customized for different audiences (parent, admin, student)
  - Export to PDF/Word formats

---

### Researcher Use Cases

**US-4.1**: *As a content developer, I want to create new assessment items with evaluation indicators so that I can build a comprehensive item bank.*

- **Acceptance Criteria**:
  - Can create MCQ and constructed response items
  - Can select evaluation indicators and sub-indicators
  - Can attach reading stimulus (passage)
  - Can set item difficulty (상/중/하)
  - Can write prompt, explanation, and answer key
  - Can add rubrics for constructed responses
  - Items saved as draft until published
  - Can preview items as student would see them

**US-4.2**: *As a content developer, I want to search and filter items in the item bank so that I can find and manage existing content.*

- **Acceptance Criteria**:
  - Can search by item code, prompt text, learning standard
  - Can filter by type (MCQ/Constructed), status (준비중/활성/폐기), difficulty
  - Results paginated (25 items per page)
  - Can sort by creation date, difficulty, usage frequency
  - Can bulk download items as Excel
  - Can view item usage statistics (how often used, mean score)
  - Can identify duplicate or overlapping items

**US-4.3**: *As a content developer, I want to manage reading stimuli (passages) so that I can organize content by topic and reading level.*

- **Acceptance Criteria**:
  - Can upload passages (text or PDF)
  - Can set reading level (중학교 1/2/3)
  - Can add source attribution
  - Can tag passages (topic, genre, difficulty)
  - Can view all items using each passage
  - Can export passages with metadata
  - Can track passage usage and effectiveness

**US-4.4**: *As a content developer, I want to create and manage rubrics so that I can define fair, consistent scoring criteria.*

- **Acceptance Criteria**:
  - Can create rubric with multiple criteria (2-6 typical)
  - Can define performance levels for each criterion (3-5 levels)
  - Can set point values or weights per level
  - Can add exemplars (sample responses) for each level
  - Can reuse rubrics across items
  - Can view rubric usage statistics
  - Can version control rubrics (track changes)

---

### School Administrator Use Cases

**US-5.1**: *As a school administrator, I want to view school-wide reading proficiency trends so that I can make informed improvement decisions.*

- **Acceptance Criteria**:
  - Dashboard shows aggregate school statistics
  - Can view by grade level, class, teacher
  - Trend charts show performance over time (last 1/3/6/12 months)
  - Can identify schools/grades below benchmarks
  - Can compare to district averages
  - Can export data for reports
  - Interactive filters for different views

**US-5.2**: *As a school administrator, I want to access teacher consultation and forum activity so that I can monitor school community engagement.*

- **Acceptance Criteria**:
  - Can view aggregated statistics on consultations (pending, completed, cancelled)
  - Can see forum activity metrics (posts, comments, active participants)
  - Can filter by date range, teacher, category
  - Can identify bottlenecks (teachers with high pending requests)
  - Can escalate issues if needed
  - Can view anonymized teacher performance metrics

---

### System Administrator Use Cases

**US-6.1**: *As a system administrator, I want to manage user accounts and role assignments so that users have appropriate access to the system.*

- **Acceptance Criteria**:
  - Can create, edit, deactivate user accounts
  - Can assign roles (student, teacher, parent, researcher, admin, school_admin)
  - Can reset passwords securely
  - Can view user activity logs
  - Can bulk import users from CSV
  - Can export user directory
  - Can audit role changes

**US-6.2**: *As a system administrator, I want to monitor system health and performance so that I can ensure the platform is reliable.*

- **Acceptance Criteria**:
  - Dashboard shows uptime, response times, error rates
  - Can view current user sessions
  - Can identify performance bottlenecks
  - Alerts trigger for critical issues
  - Can view database and storage usage
  - Can trigger manual backups
  - Access audit logs for security monitoring

---

## Feature Requirements

### Feature 1: Assessment Content Management

**Overview**: Comprehensive system for managing assessment items, reading stimuli, and rubrics.

**Sub-Features**:

1. **Item Bank Management**
   - Create, read, update, delete assessment items (MCQ and constructed response)
   - Track item metadata (code, type, difficulty, status, learning standards)
   - Search and filter items efficiently
   - Bulk operations (import, export, categorize)
   - Item analytics (usage, effectiveness, discrimination)

2. **Reading Stimulus Management**
   - Upload and manage reading passages
   - Assign metadata (topic, genre, reading level, source)
   - Track stimulus usage (which items reference each stimulus)
   - Full-text search capabilities
   - Version control for stimulus updates

3. **Rubric Management**
   - Create multi-criteria rubrics for constructed responses
   - Define performance levels with point values
   - Add exemplars for consistency
   - Reuse and version control rubrics
   - Rubric analytics (usage, scoring consistency)

4. **Evaluation Indicator System**
   - Define learning standards/evaluation indicators (한국어과 기준)
   - Create hierarchical sub-indicators
   - Assign items to indicators
   - View indicator coverage in item bank
   - Generate indicator-based reports

**Priority**: P0 (Core functionality)

---

### Feature 2: Diagnostic Assessment Administration

**Overview**: End-to-end system for creating, administering, and managing reading diagnostic assessments.

**Sub-Features**:

1. **Assessment Form Management**
   - Create diagnostic forms by selecting items
   - Configure form metadata (name, description, time limit, difficulty distribution)
   - Set item weights/points
   - Organize items into sections
   - Preview form as student would see it
   - Publish/archive forms

2. **Student Assessment Sessions**
   - Create assessment sessions for student groups
   - Configure proctoring rules (time limits, question visibility, navigation rules)
   - Real-time monitoring of student progress
   - Session pause/resume/cancel capabilities
   - Auto-save of student responses

3. **Automatic Scoring**
   - Auto-score MCQ questions immediately upon submission
   - Percentage-based scoring (0-100%) with rationale capture
   - Track scoring metadata (time to answer, attempts)

4. **Assessment Reporting**
   - Generate individual student reports
   - Generate class/school aggregate reports
   - Item analysis (difficulty, discrimination, response patterns)
   - Performance distribution visualization

**Priority**: P0 (Core functionality)

---

### Feature 3: Constructed Response Scoring

**Overview**: Systematic rubric-based scoring for constructed (essay/open-ended) responses.

**Sub-Features**:

1. **Rubric-Based Scoring Interface**
   - Display response text and rubric criteria side-by-side
   - Rate each criterion independently (0-3 levels typical)
   - Provide score level descriptions and exemplars
   - Calculate weighted total score automatically
   - Track scoring history and changes

2. **Scoring Consistency**
   - Show historical scoring patterns for reference
   - Offer peer teacher calibration tools
   - Flag outlier scores for review
   - Generate inter-rater reliability metrics

3. **Teacher Feedback Integration**
   - Link scored responses to feedback generation
   - Store feedback templates by response type
   - Track feedback delivery and student engagement

**Priority**: P0 (Core functionality)

---

### Feature 4: AI-Powered Feedback System

**Overview**: Intelligent, personalized feedback generation to support student learning.

**Sub-Features**:

1. **Feedback Generation**
   - Template-based feedback prompts (organized by category)
   - One-click generation of AI feedback using OpenAI GPT
   - Customizable prompt templates for different item types
   - Batch feedback generation for multiple students
   - Fallback mechanism (template-based) if API unavailable

2. **Feedback Refinement**
   - Teachers can edit AI-generated feedback
   - Prompt optimization tools
   - Historical feedback tracking
   - Quality metrics (student understanding improvement post-feedback)

3. **Feedback Delivery**
   - Multiple feedback formats (text, structured, comparative)
   - Ability to deliver to students and parents
   - Notification system for feedback availability
   - Feedback history for student review

**Priority**: P1 (High-value add-on)

---

### Feature 5: Multi-Stakeholder Communication

**Overview**: Integrated communication system enabling collaboration across school community.

**Sub-Features**:

1. **Student Consultation Board**
   - Student-initiated questions/consultation requests
   - Teacher responses and comments
   - Parents excluded from student consultation board
   - Notification system for responses
   - Consultation history tracking

2. **Parent Forum**
   - Parent-to-parent discussion and advice-sharing
   - Topic organization (categories/tags)
   - Moderation tools for school staff
   - Optional anonymity features
   - Search and archive functionality

3. **Teacher-Parent Consultations**
   - Parent requests with structured form (child, type, preferred time, notes)
   - Teacher approval/rejection/reschedule
   - Request status tracking (pending, approved, rejected, completed)
   - Consultation documentation (notes, recommendations)
   - History and analytics

4. **System Announcements**
   - School-wide and role-specific announcements
   - Publication scheduling
   - Priority levels
   - Read receipts (optional)

**Priority**: P1 (Important for engagement)

---

### Feature 6: Learning Analytics & Reporting

**Overview**: Comprehensive data visualization and reporting for different stakeholders.

**Sub-Features**:

1. **Student Portfolio**
   - Individual student achievement records
   - Progress over time (trend analysis)
   - Skill profile (strengths/areas for growth)
   - Learning recommendations
   - Comparative benchmarks (peer, grade-level)

2. **School Portfolio**
   - Aggregate school statistics
   - Grade-level and class-level breakdowns
   - Trend analysis over multiple assessment cycles
   - Category/skill performance distribution
   - Teacher effectiveness indicators (learning gains)

3. **Customizable Reports**
   - Multiple report templates for different audiences
   - Student-facing reports (encouraging tone)
   - Parent-facing reports (accessible language)
   - Teacher reports (detailed analysis)
   - Administrator reports (aggregate, trend-focused)
   - Export to PDF/Word/Excel formats

4. **Data Visualization**
   - Score distribution charts
   - Performance level breakdowns
   - Trend charts (longitudinal)
   - Skill/standard performance matrices
   - Heatmaps for identifying patterns

**Priority**: P1 (Essential for decision-making)

---

### Feature 7: User & Access Management

**Overview**: Role-based access control ensuring data security and appropriate visibility.

**Sub-Features**:

1. **User Account Management**
   - Create, read, update, deactivate accounts
   - Role assignment (student, teacher, parent, researcher, admin, school_admin)
   - Password management and reset
   - Two-factor authentication (future consideration)
   - Bulk user import/export

2. **Role-Based Access Control (RBAC)**
   - Six distinct user roles with specific permissions
   - Portal-based access (each role has dedicated portal)
   - Data access restrictions (students see own data, parents see children's data)
   - Feature visibility based on role

3. **Audit & Logging**
   - Log all user actions (who, what, when, where)
   - Data modification audit trail
   - Security event logging
   - Compliance reporting capability

**Priority**: P0 (Security-critical)

---

### Feature 8: Content Import/Export

**Overview**: Efficient bulk operations for assessment content management.

**Sub-Features**:

1. **Excel-Based Import**
   - Import items from Excel template
   - Validate data before import
   - Dry-run preview
   - Error reporting and rollback capability
   - Bulk rubric import

2. **Export Functionality**
   - Export items with full metadata
   - Export assessment results
   - Export analytics data
   - Multiple format support (CSV, Excel, JSON)

**Priority**: P2 (Nice-to-have initially)

---

## Functional Requirements by Feature

### Assessment Content Management

| Requirement ID | Description | Priority | Acceptance Criteria |
|---|---|---|---|
| FR-1.1 | Create MCQ item | P0 | Item code unique, prompt required, min 2 choices, one correct |
| FR-1.2 | Create constructed response item | P0 | Prompt required, rubric optional, expected response guide |
| FR-1.3 | Search items by code/content | P0 | ILIKE search, case-insensitive, returns within 2 seconds |
| FR-1.4 | Filter items by type/status/difficulty | P0 | Multi-select filters, OR logic, results update dynamically |
| FR-1.5 | Upload reading stimulus | P0 | Supports text/PDF, max 10MB, auto-extracts text |
| FR-1.6 | Create rubric | P0 | 2-6 criteria typical, 3-5 levels per criterion, scores sum correctly |
| FR-1.7 | View item usage stats | P1 | Shows usage count, mean score, difficulty index |
| FR-1.8 | Bulk download items | P2 | Excel format, includes all metadata |

### Diagnostic Assessment

| Requirement ID | Description | Priority | Acceptance Criteria |
|---|---|---|---|
| FR-2.1 | Create diagnostic form | P0 | Select items, set time limit, configure sections |
| FR-2.2 | Student answers MCQ | P0 | Can select one option, can change answer before submit |
| FR-2.3 | Student answers constructed response | P0 | Text input with character counter, auto-save every 30s |
| FR-2.4 | Auto-score MCQ | P0 | Immediate scoring upon submission, 100% accuracy |
| FR-2.5 | Teacher views responses | P0 | Can filter by student, item, status |
| FR-2.6 | Generate assessment report | P0 | PDF export, includes scores and item analysis |

### AI Feedback

| Requirement ID | Description | Priority | Acceptance Criteria |
|---|---|---|---|
| FR-4.1 | Generate feedback (one response) | P1 | API call succeeds, text generated within 30 seconds |
| FR-4.2 | Generate feedback (batch) | P1 | All responses processed, partial failure handled gracefully |
| FR-4.3 | Edit AI feedback | P1 | Teachers can modify before delivery |
| FR-4.4 | Fallback to template feedback | P1 | If API fails, template-based feedback provided |

### Communication

| Requirement ID | Description | Priority | Acceptance Criteria |
|---|---|---|---|
| FR-5.1 | Create consultation post | P1 | Title + body required, student selects category |
| FR-5.2 | Post response on consultation | P1 | Teacher can respond, student notified |
| FR-5.3 | Create forum thread | P1 | Title + body, parent can edit own posts |
| FR-5.4 | Submit consultation request | P1 | Select child, type, preferred time, min 10 char notes |
| FR-5.5 | Approve consultation request | P1 | Teacher confirms, parent notified, scheduled |
| FR-5.6 | Parent forum blocking | P0 | Parents cannot access student consultation board |

---

## Non-Functional Requirements

### Performance

| Requirement | Target | Priority |
|---|---|---|
| Page load time | < 2 seconds (95th percentile) | P0 |
| API response time | < 500ms (95th percentile) | P0 |
| Auto-score latency | < 100ms per question | P0 |
| Feedback generation time | < 30 seconds | P1 |
| Concurrent users | Support 1000+ simultaneous connections | P0 |
| Database query time | < 200ms (95th percentile) | P0 |
| Asset caching | Static assets cached 1 year | P0 |

### Reliability & Availability

| Requirement | Target | Priority |
|---|---|---|
| System uptime | 99.5% SLA | P0 |
| MTTR (Mean Time To Recover) | < 30 minutes for critical incidents | P0 |
| Data backup frequency | Daily incremental, weekly full | P0 |
| Recovery Point Objective (RPO) | < 24 hours | P0 |
| Test assessment migration | Zero data loss during upgrades | P0 |

### Security

| Requirement | Target | Priority |
|---|---|---|
| Authentication | Session-based or JWT tokens | P0 |
| Password requirements | Min 8 chars, complexity rules | P0 |
| Data encryption | HTTPS for transit, encryption at rest | P0 |
| Access control | Role-based, principle of least privilege | P0 |
| Audit logging | All data modifications logged | P0 |
| Vulnerability scanning | Weekly automated scans (Brakeman) | P0 |
| Dependency scanning | Weekly gem vulnerability checks (Bundler Audit) | P0 |

### Scalability

| Requirement | Target | Priority |
|---|---|---|
| Max students | 10,000+ | P0 |
| Max schools | 100+ | P0 |
| Max items in bank | 50,000+ | P1 |
| Max assessment cycles per year | 12+ | P0 |
| Database size | Support multi-TB datasets | P1 |

### Usability

| Requirement | Target | Priority |
|---|---|---|
| User onboarding time | < 5 minutes to first assessment | P1 |
| Mobile responsiveness | Works on iOS 12+, Android 6+ | P1 |
| Accessibility (WCAG) | Level AA compliance minimum | P2 |
| Translation readiness | UI structure supports i18n | P2 |
| Help documentation | Available in-app and external | P1 |

### Integration & Compatibility

| Requirement | Target | Priority |
|---|---|---|
| Browser support | Chrome 90+, Safari 14+, Firefox 88+, Edge 90+ | P1 |
| Database | PostgreSQL 12+ | P0 |
| External APIs | OpenAI GPT-4/GPT-4o compatible | P1 |
| File formats | CSV, XLSX, PDF support | P1 |

---

## Out of Scope

The following features are **explicitly excluded** from this version of ReadingPRO:

1. **Mobile Native Apps** - Mobile access supported via responsive web design only (future: native iOS/Android apps)
2. **Adaptive Assessment** - Dynamic item selection based on student performance (future version)
3. **Automated Curriculum Planning** - AI-generated study plans (future version)
4. **Video/Multimedia Support** - Assessment limited to text-based items (future version)
5. **Multiple Language Support** - English language UI only; can be considered for future versions
6. **Advanced Analytics (Predictive)** - ML-based prediction of student outcomes (future version)
7. **API Public/Third-Party Integration** - No external API access (future version)
8. **Synchronized Offline Mode** - No offline assessment capability (future version)
9. **LMS Integration** - No Blackboard/Canvas/Google Classroom integration (future version)
10. **Parent Mobile App** - Web-only parent access initially

---

## Success Metrics & KPIs

### User Adoption Metrics

| Metric | Target | Measurement |
|---|---|---|
| Teacher platform adoption | 90% of teachers actively using | Monthly active teacher count |
| Student completion rate | 95% of assigned assessments completed | Submission vs assignment ratio |
| Parent engagement | 70% of parents review child results | Logins, result views per month |
| Parent forum participation | 50% of parents active in forums | Posts, comments per active parent |

### Assessment Quality Metrics

| Metric | Target | Measurement |
|---|---|---|
| MCQ auto-scoring accuracy | 99%+ | Manual verification sampling |
| Constructed response consistency | 0.85+ inter-rater reliability | Cohen's kappa for teacher pairs |
| Feedback quality (student perception) | 4.0+/5.0 satisfaction | Post-feedback survey |
| Item bank coverage | 95%+ learning standards covered | Standards audit |

### Learning Impact Metrics

| Metric | Target | Measurement |
|---|---|---|
| Measurable student improvement | 70% show growth post-feedback | Pre/post score comparison |
| Average score improvement | 10% from first to second assessment | Growth analysis over 6 months |
| Teacher perception improvement | 4.2+/5.0 feedback quality | Teacher survey |
| Parent satisfaction | 4.1+/5.0 with platform | Parent survey quarterly |

### System Performance Metrics

| Metric | Target | Measurement |
|---|---|---|
| System uptime | 99.5% | Automated monitoring |
| Page load time (95th percentile) | < 2 seconds | Real User Monitoring (RUM) |
| API response time (95th percentile) | < 500ms | Application Performance Monitoring |
| Support ticket resolution time | 95% within 48 hours | Ticket tracking system |

### Business/Operational Metrics

| Metric | Target | Measurement |
|---|---|---|
| Item bank growth | 1000+ items added per year | Content audit |
| Cost per student assessment | < $2 | Financial analysis |
| Teacher time per assessment (scoring + feedback) | < 20 minutes per student | Time tracking |
| Platform cost per student (annual) | < $5 | Financial analysis |

---

## Appendix

### A. Terminology & Definitions

| Term | Definition |
|---|---|
| **Assessment** | A diagnostic test/form administered to students to measure reading proficiency |
| **Item** | Individual question/prompt in an assessment (MCQ or constructed response) |
| **Reading Stimulus** | Reading passage provided for comprehension questions |
| **Rubric** | Scoring guide defining criteria and performance levels for constructed responses |
| **Evaluation Indicator** | Learning standard or competency being measured (한국어과 교육과정 기준) |
| **MCQ** | Multiple Choice Question with single correct answer |
| **Constructed Response** | Open-ended question requiring text answer (essay, short answer) |
| **Diagnostic Form** | Collection of items configured as a specific test |
| **Student Attempt** | Single instance of student completing an assessment |
| **Response** | Student's answer to a single item |
| **Feedback** | Teacher or AI-generated commentary on student performance |

### B. References & Related Documents

- [TRD.md](TRD.md) - Technical Requirements Document
- [API_SPECIFICATION.md](API_SPECIFICATION.md) - API Design Specification (future)
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Database Schema Documentation (future)
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Development Guidelines (future)

### C. Document History

| Version | Date | Author | Changes |
|---|---|---|---|
| 0.1 | 2026-02-02 | Claude | Initial draft based on codebase analysis |
| 1.0 | TBD | TBD | Final version after stakeholder review |

---

## Document Review & Sign-off

**Document Status**: ✅ Draft - Awaiting Stakeholder Review

**Reviewers Needed**:
- [ ] Product Manager / Project Lead
- [ ] Diagnostic Teacher Representative
- [ ] Researcher / Content Developer
- [ ] School Administrator
- [ ] Technology Lead

**Review Comments & Feedback**: [To be collected during review phase]

---

**This PRD serves as the foundation for all subsequent design, development, and testing activities. All team members should reference this document for feature scope, requirements, and success criteria.**

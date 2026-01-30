# Student Diagnostic Assessment Implementation Plan

## Current Status
- **Database Infrastructure**: ✅ Complete (Form, Attempt, Response, Item, Rubric models all exist)
- **Scoring System**: ✅ Complete (ScoreResponseService for MCQ and Constructed Response)
- **Feedback Generation**: ✅ Complete (ReadingReportService with OpenAI integration)
- **Issue**: Difficulty levels in database only have 3 values (easy, hard, medium) instead of intended 5 (초저, 초고, 중저, 중, 고)

## Phase 1: Fix Difficulty Levels (Prerequisite)

### Task 1.1: Migrate Difficulty Levels
**Files to modify:**
- `db/migrate/[new_timestamp]_update_item_difficulties.rb` - Create migration
- `app/models/item.rb` - Add enum for difficulty

**Changes:**
```ruby
# In Item model, add:
enum :difficulty, { very_low: "very_low", low: "low", medium: "medium", high: "high", very_high: "very_high" }

# Or use Korean representation if preferred:
enum :difficulty, { "초저" => "very_low", "중저" => "low", "중" => "medium", "고" => "high", "초고" => "very_high" }
```

**Details:**
- Create a data migration that updates existing values:
  - 'easy' → 'very_low'
  - 'hard' → 'high'
  - 'medium' → 'medium'
- Add validation in Item model to ensure difficulty is present and valid
- Update admin/researcher forms to use new enum values

---

## Phase 2: Create Assessment Interface for Students

### Task 2.1: Create Assessment Selection Page
**Files to create/modify:**
- `app/views/student/dashboard/diagnostics.html.erb` - Replace hardcoded content with real data
- `app/controllers/student/dashboard_controller.rb` - Update diagnostics action

**Implementation Details:**
- Query active Forms from database
- Display forms with:
  - Form title
  - Number of items
  - Estimated time (calculate from item count)
  - Status (not started / in progress / completed)
  - Action buttons (Start / Continue / View Results)
- Show form list with status indicators
- Link to start new assessment or continue existing attempt

### Task 2.2: Create Assessment Test-Taking Interface
**Files to create:**
- `app/controllers/student/assessments_controller.rb` - New controller
- `app/views/student/assessments/show.html.erb` - Assessment test interface
- `app/services/assessment_renderer_service.rb` - Service to render assessment UI

**Routes to add:**
```ruby
namespace :student do
  resources :assessments, only: [:show] do
    collection do
      post :submit_response
      post :submit_attempt
    end
  end
end
```

**Assessment UI Features:**
- Display reading stimulus (if applicable)
- Display question prompt
- For MCQ: Radio buttons with 4-5 options
- For Constructed Response: Text area for free-form response
- Navigation: Previous/Next buttons, Progress indicator
- Timer (optional): Show time remaining
- Submit button at the end

### Task 2.3: API Endpoints for Response Submission
**Endpoints to create:**
- `POST /student/assessments/submit_response` - Save single response
- `POST /student/assessments/submit_attempt` - Submit entire attempt

**Response Structure:**
```json
{
  "attempt_id": 123,
  "item_id": 456,
  "response_type": "mcq" | "constructed",
  "selected_choice_id": 789,  // for MCQ only
  "answer_text": "Student's response text"  // for constructed only
}
```

---

## Phase 3: Implement Automatic Scoring After Submission

### Task 3.1: Create Attempt Submission Handler
**Files to create:**
- `app/services/attempt_submission_service.rb` - Orchestrate scoring

**Workflow:**
1. When student submits attempt:
   - Update attempt status to "completed"
   - Mark submitted_at timestamp
2. For each response in attempt:
   - Call `ScoreResponseService.call(response_id)` for MCQ responses
   - For constructed responses: Wait for manual rubric scoring (handled by teacher)
3. Create background job to generate initial feedback

### Task 3.2: Generate Auto Feedback
**Files to modify:**
- `app/jobs/generate_feedback_job.rb` - Create background job (if not exists)

**Workflow:**
1. For MCQ responses: Auto-generate feedback immediately after scoring
2. For Constructed responses: Generate placeholder feedback, schedule AI feedback generation
3. Store feedback in response_feedbacks table

---

## Phase 4: Update Student Dashboard to Show Assessments

### Task 4.1: Update Diagnostics View
**Changes to `/app/views/student/dashboard/diagnostics.html.erb`:**
- Replace hardcoded stats with real data from attempts
- Show "In Progress" attempts (status: in_progress)
- Show "Completed" assessments with scores
- Add "Start Assessment" button linking to available forms

### Task 4.2: Link Results to Existing Report Infrastructure
**Integration:**
- When attempt is submitted, automatically create Report record
- Link to existing `show_attempt` and `show_report` views
- Students can see detailed feedback after submission

---

## Phase 5: Teacher Interface for Constructed Response Scoring

### Task 5.1: Assessment-to-Teacher Assignment
**Existing infrastructure:**
- Use existing diagnostic_teacher/feedback interface
- Teachers can score constructed responses via feedback page

### Task 5.2: Auto-Generate Constructed Feedback
**Workflow:**
- After teacher scores constructed response (adds rubric scores):
  - Trigger feedback generation via ReadingReportService
  - Generate AI-powered feedback for educational insights

---

## Implementation Order

1. **Phase 1** (Prerequisite): Fix difficulty levels
   - Creates migration and updates Item model
   - Time: ~30 minutes

2. **Phase 2.1**: Create assessment selection page
   - Replace hardcoded diagnostics view with real data
   - Time: ~1 hour

3. **Phase 2.2**: Create assessment test-taking interface
   - Build the main assessment UI
   - Time: ~2-3 hours

4. **Phase 2.3**: API endpoints for submission
   - Create assessment submission handlers
   - Time: ~1 hour

5. **Phase 3**: Implement automatic scoring
   - Create submission service and integrate ScoreResponseService
   - Time: ~1 hour

6. **Phase 4**: Update student dashboard
   - Show real assessment data and link to existing report infrastructure
   - Time: ~1 hour

**Total Estimated Work**: ~6-8 hours of development

---

## Key Design Decisions

1. **Assessment-Taking Experience**:
   - Use server-rendered ERB views for consistency with existing student portal
   - Save responses as students progress (not just on final submit)
   - Show progress indicator to keep students engaged

2. **Scoring Strategy**:
   - MCQ: Automatic scoring immediately after student submits
   - Constructed Response: Manual rubric scoring by teacher, then AI feedback generation
   - All scoring happens via existing ScoreResponseService

3. **Feedback Generation**:
   - MCQ: Auto-generate from ReadingReportService (existing)
   - Constructed: Generate after teacher scores (existing flow with AI enhancement)
   - Both use existing ReadingReportService and OpenAI integration

4. **Database Queries**:
   - Use eager loading (includes) to prevent N+1 issues
   - Cache form_items snapshot in AttemptItem on attempt creation
   - Minimize queries during assessment-taking

---

## Testing Checklist

- [ ] Student can view available assessments in diagnostics page
- [ ] Student can start a new assessment
- [ ] Student can navigate through questions
- [ ] Student can select MCQ option
- [ ] Student can enter constructed response
- [ ] Student can submit attempt
- [ ] Responses are saved to database
- [ ] MCQ responses are automatically scored
- [ ] Constructed response awaits teacher scoring
- [ ] Student can view results/report
- [ ] Report shows correct/incorrect questions and feedback
- [ ] Teacher can score constructed responses
- [ ] AI feedback generates for both MCQ and constructed responses

---

## Difficulty Level Mapping

Current: easy, hard, medium
Target: 초저(very_low), 중저(low), 중(medium), 고(high), 초고(very_high)

**Migration Strategy:**
- Data migration to update values
- Add enum to Item model
- Update admin/researcher forms for new selector

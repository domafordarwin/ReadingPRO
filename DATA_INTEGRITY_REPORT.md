# Data Integrity Report - Item Choice Missing Issue

## Executive Summary

**Status**: ❌ **CRITICAL DATA INTEGRITY ISSUE**
**Severity**: High
**Impact**: 61 responses cannot be updated with answer modifications
**Root Cause**: 18 MCQ items imported without associated ItemChoice records

---

## Problem Description

When attempting to update an answer for Response 455 (Student: 김민규), the system returns:
```json
{
  "success": false,
  "error": "유효하지 않은 선택지입니다"
}
```

**Investigation Result**: The error is **NOT a code bug** - it's a **data integrity issue**.

---

## Root Cause Analysis

### Finding 1: 18 Items Without Any Choices
All items with code pattern `REPORT_MCQ_Q*` (Questions 1-18) were imported WITHOUT ItemChoice records:

| Item ID | Code | Prompt | Choice Count | Response Count |
|---------|------|--------|--------------|----------------|
| 119 | REPORT_MCQ_Q1 | Imported from report - Question 1 | **0** | 61 |
| 120 | REPORT_MCQ_Q2 | Imported from report - Question 2 | **0** | 60 |
| 121 | REPORT_MCQ_Q3 | Imported from report - Question 3 | **0** | 60 |
| ... (15 more) | ... | ... | **0** | ~50-60 each |

### Finding 2: Specific Response Analysis (Response 455)
```
Student: 김민규 (ID: 26)
Item: 119 (REPORT_MCQ_Q1)
Selected Choice: NONE (NULL)
Available Choices: 0
```

### Finding 3: Scope of Impact
- **Total MCQ Items**: 78
- **Items with Choices**: 60 ✅
- **Items without Choices**: 18 ❌
- **Total Responses**: 1,975
- **MCQ Responses**: 1,351
- **Responses using incomplete items**: ~1,080+ (estimated)

---

## Code Analysis Verification

The error is triggered in `app/controllers/diagnostic_teacher/feedback_controller.rb:191-193`:

```ruby
unless selected_choice
  Rails.logger.error("[update_answer] ❌ NO MATCH | choice_no=#{choice_no.inspect}, item_id=#{response.item_id}")
  return render json: { success: false, error: "유효하지 않은 선택지입니다" }, status: :bad_request
end
```

**Code is working correctly** - the problem is:
```ruby
ItemChoice.find_by(choice_no: 2, item_id: 119)
# => nil (because Item 119 has ZERO ItemChoice records)
```

---

## How Items Were Imported

Looking at the code pattern `REPORT_MCQ_Q1` through `REPORT_MCQ_Q18`:
- These items were clearly imported from some "report" or external source
- The import process created Item records but **failed to create associated ItemChoice records**
- This is likely a data import script issue or incomplete import process

---

## Possible Root Causes

1. **Incomplete Import Script**: The import script may have created Items without the ItemChoice data
2. **Separate Import Stages**: Maybe ItemChoice records were meant to be imported in a second step (that never happened)
3. **Data Source Issue**: The original report/source data may not have included choice information
4. **Manual Creation Error**: Someone may have manually created Item records without adding choices

---

## Impact Assessment

### Cannot Do:
- ❌ Update answers for responses using Items 119-136
- ❌ Generate feedback for incomplete items
- ❌ Rescore responses with different answers

### Can Still Do:
- ✅ View responses (they show selected_choice as NULL)
- ✅ View feedback
- ✅ Update items with complete choice data
- ✅ Generate feedback for items with proper choices

### Affected Students (from Item 119):
- 이건우 (ID: 63) - 1 response
- 강하랑 (ID: 25) - 2 responses
- 김민규 (ID: 26) - 1 response (Response 455 - the error case)
- 김범준 (ID: 27) - 1 response
- (and ~55 more responses)

---

## Recommendations

### Option 1: Delete Incomplete Items (Cleanest)
If these items were imported by mistake and are not needed:
```sql
DELETE FROM items WHERE id BETWEEN 119 AND 136;
```

**Pros**: Clean database, no orphaned data
**Cons**: Lose 1,080+ response records

### Option 2: Populate Missing ItemChoice Records
If the choice data exists somewhere (e.g., original report):
1. Create ItemChoice records for each item
2. Re-score all responses
3. Enable answer updates

**Pros**: Preserves response data, enables full functionality
**Cons**: Requires source data that may no longer be available

### Option 3: Mark as "Archived" (Compromise)
1. Add `archived_at` field to Items
2. Exclude archived items from feedback pages
3. Keep data for historical reference

**Pros**: Preserves data, prevents errors
**Cons**: Requires code changes

---

## Immediate Action Required

The user's feedback system cannot function properly with incomplete item data.

**Recommended next step**:
Determine where Items 119-136 came from and whether they should be:
- 🗑️ Deleted (if no longer needed)
- ✏️ Fixed (if choice data can be found)
- 🔒 Archived (if needed for historical purposes)

---

## Verification Commands

To reproduce the issue locally:

```ruby
# Rails console
item_119 = Item.find(119)
item_119.item_choices.count  # => 0

# This is why the error occurs:
ItemChoice.find_by(choice_no: 1, item_id: 119)  # => nil

# 61 responses are affected:
Response.where(item_id: 119).count  # => 61
```

---

## Database Statistics

```
✅ All MCQ items have at least 3 choices (for items that have any choices at all)
✅ All ItemChoice records have proper ChoiceScore data
⚠️  18 MCQ items have ZERO ItemChoice records
❌ 61+ responses reference items with no choices
```

---

**Report Generated**: 2026-01-30
**Database**: PostgreSQL (Railway)
**Application**: ReadingPRO Rails 8.1

# ReadingPRO - API Specification Document

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Document Type**: API Technical Specification

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Error Handling](#error-handling)
4. [Pagination](#pagination)
5. [API Endpoints](#api-endpoints)
6. [Data Models](#data-models)
7. [Code Examples](#code-examples)

---

## Overview

### API Scope

ReadingPRO API provides RESTful endpoints for:
- Assessment content management (CRUD operations on items, stimuli, rubrics)
- Student assessment administration (form creation, response submission)
- Feedback generation and retrieval
- Learning analytics and reporting
- User and role management

### Base URL

```
Development:  http://localhost:3000/api/v1
Production:   https://readingpro.railway.app/api/v1
```

### API Version

```
Current: v1
URL Pattern: /api/v1/[resource]
Header: X-API-Version: 1.0
```

### Response Format

All API responses follow a consistent JSON structure:

```json
{
  "success": true,
  "data": { ... },
  "meta": { ... },
  "errors": null
}
```

---

## Authentication

### Session-Based (Web UI)

```
POST /login
Content-Type: application/x-www-form-urlencoded

email=user@example.com&password=password

Response:
HTTP/1.1 302 Found
Set-Cookie: _readingpro_session=abc123; Path=/; HttpOnly; Secure
Location: /student/dashboard
```

### JWT Token-Based (Future / External API)

```
POST /api/v1/auth/tokens
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}

Response:
HTTP/1.1 200 OK

{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400
  }
}
```

### Bearer Token Usage

```
GET /api/v1/items/123
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Authorization Levels

| Endpoint | Anonymous | Authenticated | Role Required |
|---|---|---|---|
| `/login` | ✅ | ❌ | None |
| `/api/v1/items` | ❌ | ✅ | Any authenticated |
| `/api/v1/items/:id/edit` | ❌ | ✅ | researcher |
| `/api/v1/responses/:id/feedback` | ❌ | ✅ | teacher |

---

## Error Handling

### HTTP Status Codes

| Status | Meaning | Example |
|---|---|---|
| `200 OK` | Request succeeded | Item retrieved successfully |
| `201 Created` | Resource created | Item created |
| `204 No Content` | Request succeeded, no content | Item deleted |
| `400 Bad Request` | Invalid request parameters | Missing required field |
| `401 Unauthorized` | Authentication required | Not logged in |
| `403 Forbidden` | Authorization failed | Insufficient permissions |
| `404 Not Found` | Resource not found | Item ID doesn't exist |
| `422 Unprocessable Entity` | Validation error | Invalid item data |
| `500 Server Error` | Internal server error | Database error |

### Error Response Format

```json
{
  "success": false,
  "data": null,
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Item code must be unique",
      "field": "code"
    }
  ]
}
```

### Error Codes

| Code | HTTP Status | Meaning |
|---|---|---|
| `VALIDATION_ERROR` | 422 | Input validation failed |
| `NOT_FOUND` | 404 | Resource not found |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMIT` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |

---

## Pagination

### Query Parameters

```
GET /api/v1/items?page=2&per_page=25&sort=-created_at
```

| Parameter | Type | Default | Max |
|---|---|---|---|
| `page` | integer | 1 | N/A |
| `per_page` | integer | 25 | 100 |
| `sort` | string | created_at | See sorting |

### Pagination Response

```json
{
  "success": true,
  "data": [...],
  "meta": {
    "page": 2,
    "per_page": 25,
    "total": 1250,
    "total_pages": 50
  }
}
```

### Sorting

```
sort=field              # Ascending
sort=-field             # Descending
sort=field1,-field2     # Multiple fields
```

Sortable fields vary by endpoint (documented per endpoint).

---

## API Endpoints

### 1. Assessment Content Management

#### 1.1 Items (Assessment Questions)

##### **GET /api/v1/items** - List Items

List all assessment items with optional filtering and pagination.

**Authentication**: Required (any role)

**Query Parameters**:

```
?search=code&search_type=prompt&filter[type]=mcq&filter[difficulty]=high
&filter[status]=active&sort=-created_at&page=1&per_page=25
```

| Parameter | Type | Description | Example |
|---|---|---|---|
| `search` | string | Search by code or prompt | ENG-2026 |
| `search_type` | string | Search field (code/prompt) | prompt |
| `filter[type]` | string | MCQ or constructed | mcq |
| `filter[difficulty]` | string | high/medium/low | high |
| `filter[status]` | string | active/draft/archived | active |
| `sort` | string | Sort field | -created_at |
| `page` | integer | Page number | 1 |
| `per_page` | integer | Items per page (max 100) | 25 |

**Example Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/items?filter[type]=mcq&page=1" \
  -H "Authorization: Bearer token" \
  -H "Accept: application/json"
```

**Response** (200 OK):

```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "code": "ENG-2026-001",
      "type": "mcq",
      "difficulty": "high",
      "status": "active",
      "prompt": "Read the passage and answer the question...",
      "explanation": "The answer is correct because...",
      "stimulus_id": 45,
      "evaluation_indicator_id": 8,
      "created_by_id": 12,
      "created_at": "2026-01-15T10:30:00Z",
      "updated_at": "2026-02-01T14:20:00Z"
    },
    ...
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 1250,
    "total_pages": 50
  }
}
```

---

##### **GET /api/v1/items/:id** - Get Item Details

Retrieve a single item with all related data.

**Authentication**: Required

**URL Parameters**:

| Parameter | Type | Description |
|---|---|---|
| `id` | integer | Item ID |

**Example Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/items/123" \
  -H "Authorization: Bearer token"
```

**Response** (200 OK):

```json
{
  "success": true,
  "data": {
    "id": 123,
    "code": "ENG-2026-001",
    "type": "mcq",
    "difficulty": "high",
    "status": "active",
    "prompt": "Read the passage and select the best answer.",
    "explanation": "The answer is B because...",
    "stimulus": {
      "id": 45,
      "title": "A Day at the Beach",
      "reading_level": "middle_2"
    },
    "choices": [
      {
        "id": 456,
        "choice_no": 1,
        "content": "Option A text",
        "is_correct": false,
        "score_percent": 0
      },
      {
        "id": 457,
        "choice_no": 2,
        "content": "Option B text",
        "is_correct": true,
        "score_percent": 100
      },
      ...
    ],
    "rubric": null,
    "evaluation_indicator": {
      "id": 8,
      "code": "국어.2-1-01",
      "name": "글의 주제와 목적 파악"
    },
    "created_by": {
      "id": 12,
      "name": "김교사"
    }
  }
}
```

---

##### **POST /api/v1/items** - Create Item

Create a new assessment item.

**Authentication**: Required
**Authorization**: researcher or admin role

**Request Body**:

```json
{
  "item": {
    "code": "ENG-2026-045",
    "type": "mcq",
    "difficulty": "medium",
    "status": "draft",
    "prompt": "Read the passage and answer the question.",
    "explanation": "The correct answer is...",
    "stimulus_id": 45,
    "evaluation_indicator_id": 8,
    "sub_indicator_id": 12,
    "choices_attributes": [
      {
        "choice_no": 1,
        "content": "Option A",
        "is_correct": false,
        "score_percent": 0
      },
      {
        "choice_no": 2,
        "content": "Option B",
        "is_correct": true,
        "score_percent": 100
      },
      ...
    ]
  }
}
```

**Validation Rules**:

| Field | Rules |
|---|---|
| `code` | Required, unique, string |
| `type` | Required, enum: [mcq, constructed] |
| `difficulty` | Required, enum: [high, medium, low] |
| `prompt` | Required, min 10 characters |
| `choices` | Required if type=mcq, min 2, max 1 correct |

**Response** (201 Created):

```json
{
  "success": true,
  "data": {
    "id": 999,
    "code": "ENG-2026-045",
    "type": "mcq",
    ...
  }
}
```

**Error Response** (422 Unprocessable Entity):

```json
{
  "success": false,
  "data": null,
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Code has already been taken",
      "field": "code"
    }
  ]
}
```

---

##### **PATCH /api/v1/items/:id** - Update Item

Update an existing item.

**Authentication**: Required
**Authorization**: creator or admin role

**Request Body**:

```json
{
  "item": {
    "status": "active",
    "explanation": "Updated explanation text"
  }
}
```

**Response** (200 OK): Updated item object

---

##### **DELETE /api/v1/items/:id** - Delete Item

Soft-delete an item (set status to 'archived').

**Authentication**: Required
**Authorization**: creator or admin role

**Response** (204 No Content)

---

#### 1.2 Reading Stimuli (Passages)

##### **GET /api/v1/reading_stimuli** - List Stimuli

**Authentication**: Required

**Query Parameters**:

```
?search=title&filter[reading_level]=middle_2&sort=-created_at&page=1&per_page=25
```

**Response** (200 OK):

```json
{
  "success": true,
  "data": [
    {
      "id": 45,
      "title": "A Day at the Beach",
      "body": "The beach is a wonderful place...",
      "source": "National Reading Education Center",
      "word_count": 450,
      "reading_level": "middle_2",
      "created_by": {
        "id": 12,
        "name": "김교사"
      },
      "item_count": 3,
      "created_at": "2026-01-20T10:00:00Z"
    },
    ...
  ],
  "meta": { ... }
}
```

---

##### **POST /api/v1/reading_stimuli** - Create Stimulus

**Authentication**: Required
**Authorization**: researcher or admin

**Request Body**:

```json
{
  "stimulus": {
    "title": "The Mystery of the Ocean",
    "body": "The ocean covers 70% of Earth's surface...",
    "source": "Science Today Magazine",
    "reading_level": "middle_3"
  }
}
```

**Response** (201 Created)

---

#### 1.3 Rubrics

##### **GET /api/v1/rubrics/:id** - Get Rubric

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": {
    "id": 78,
    "item_id": 200,
    "name": "Essay Scoring Rubric",
    "description": "Rubric for evaluating student essays",
    "criteria": [
      {
        "id": 456,
        "criterion_name": "Content Knowledge",
        "description": "Understanding of main ideas",
        "max_score": 3,
        "levels": [
          {
            "id": 1234,
            "level": 3,
            "score": 3,
            "description": "Excellent understanding",
            "exemplar": "Student clearly demonstrates..."
          },
          {
            "id": 1235,
            "level": 2,
            "score": 2,
            "description": "Good understanding",
            "exemplar": "Student demonstrates..."
          },
          ...
        ]
      },
      {
        "id": 457,
        "criterion_name": "Writing Quality",
        "description": "Organization and clarity",
        "max_score": 3,
        "levels": [...]
      }
    ]
  }
}
```

---

##### **POST /api/v1/rubrics** - Create Rubric

**Authentication**: Required
**Authorization**: researcher or admin

**Request Body**:

```json
{
  "rubric": {
    "item_id": 200,
    "name": "Essay Evaluation Rubric",
    "description": "For evaluating essay responses",
    "criteria_attributes": [
      {
        "criterion_name": "Content",
        "description": "Understanding of material",
        "max_score": 3,
        "levels_attributes": [
          {
            "level": 3,
            "score": 3,
            "description": "Excellent"
          },
          {
            "level": 2,
            "score": 2,
            "description": "Good"
          },
          ...
        ]
      },
      ...
    ]
  }
}
```

**Response** (201 Created)

---

### 2. Assessment Administration

#### 2.1 Diagnostic Forms

##### **GET /api/v1/diagnostic_forms** - List Forms

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Reading Comprehension Assessment 2026",
      "description": "Mid-year diagnostic assessment",
      "status": "active",
      "item_count": 45,
      "time_limit_minutes": 90,
      "difficulty_distribution": {
        "high": 30,
        "medium": 50,
        "low": 20
      },
      "created_by": {
        "id": 12,
        "name": "김교사"
      },
      "created_at": "2026-01-15T10:00:00Z"
    },
    ...
  ],
  "meta": { ... }
}
```

---

##### **GET /api/v1/diagnostic_forms/:id** - Get Form Details

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Reading Comprehension Assessment 2026",
    "description": "...",
    "status": "active",
    "items": [
      {
        "id": 123,
        "code": "ENG-2026-001",
        "position": 1,
        "points": 2,
        "section_title": "Part A: Comprehension",
        "type": "mcq",
        "prompt": "Read the passage..."
      },
      ...
    ]
  }
}
```

---

##### **POST /api/v1/diagnostic_forms** - Create Form

**Authentication**: Required
**Authorization**: teacher or admin

**Request Body**:

```json
{
  "form": {
    "name": "Final Reading Assessment",
    "description": "End of term assessment",
    "time_limit_minutes": 120,
    "form_items_attributes": [
      {
        "item_id": 123,
        "position": 1,
        "points": 2,
        "section_title": "Part A"
      },
      ...
    ]
  }
}
```

**Response** (201 Created)

---

### 3. Student Responses & Scoring

#### 3.1 Student Attempts

##### **POST /api/v1/attempts** - Create Assessment Attempt

**Authentication**: Required
**Authorization**: student role (for own student_id only)

**Request Body**:

```json
{
  "attempt": {
    "student_id": 54,
    "diagnostic_form_id": 1
  }
}
```

**Response** (201 Created):

```json
{
  "success": true,
  "data": {
    "id": 789,
    "student_id": 54,
    "form_id": 1,
    "status": "in_progress",
    "started_at": "2026-02-02T10:15:00Z",
    "submitted_at": null,
    "time_spent_seconds": 0
  }
}
```

---

#### 3.2 Responses (Student Answers)

##### **POST /api/v1/responses** - Submit Response

**Authentication**: Required
**Authorization**: student (own attempt only) or teacher

**Request Body**:

```json
{
  "response": {
    "student_attempt_id": 789,
    "item_id": 123,
    "selected_choice_id": 457,
    "answer_text": null
  }
}
```

For MCQ: provide `selected_choice_id`
For Constructed: provide `answer_text`

**Response** (201 Created):

```json
{
  "success": true,
  "data": {
    "id": 999,
    "student_attempt_id": 789,
    "item_id": 123,
    "selected_choice_id": 457,
    "auto_score": 100,
    "is_correct": true,
    "status": "scored"
  }
}
```

---

##### **GET /api/v1/attempts/:attempt_id/responses** - List Responses

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": [
    {
      "id": 999,
      "item_id": 123,
      "item_code": "ENG-2026-001",
      "position": 1,
      "answer_text": null,
      "selected_choice_id": 457,
      "auto_score": 100,
      "manual_score": null,
      "is_correct": true,
      "status": "scored",
      "feedback": null
    },
    ...
  ]
}
```

---

#### 3.3 Constructed Response Scoring

##### **POST /api/v1/responses/:id/rubric_scores** - Score Response

**Authentication**: Required
**Authorization**: teacher or admin

**Request Body**:

```json
{
  "rubric_scores": [
    {
      "rubric_criterion_id": 456,
      "level_score": 3,
      "feedback": "Excellent understanding demonstrated"
    },
    {
      "rubric_criterion_id": 457,
      "level_score": 2,
      "feedback": "Good writing quality"
    }
  ]
}
```

**Response** (201 Created):

```json
{
  "success": true,
  "data": {
    "id": 999,
    "item_id": 200,
    "manual_score": 85,
    "status": "scored",
    "rubric_scores": [
      {
        "rubric_criterion_id": 456,
        "level_score": 3
      },
      {
        "rubric_criterion_id": 457,
        "level_score": 2
      }
    ]
  }
}
```

---

### 4. Feedback & AI

#### 4.1 Feedback Generation

##### **POST /api/v1/feedbacks/generate** - Generate AI Feedback

**Authentication**: Required
**Authorization**: teacher or admin

**Request Body**:

```json
{
  "feedback": {
    "response_id": 999,
    "feedback_template_id": 15
  }
}
```

**Response** (201 Created):

```json
{
  "success": true,
  "data": {
    "id": 1234,
    "response_id": 999,
    "content": "Your response shows good understanding of the main idea...",
    "feedback_type": "ai_generated",
    "is_auto_generated": true,
    "created_by_id": 12,
    "created_at": "2026-02-02T11:00:00Z"
  }
}
```

---

##### **POST /api/v1/feedbacks/:id/refine** - Refine Feedback

**Authentication**: Required
**Authorization**: teacher or admin

**Request Body**:

```json
{
  "feedback": {
    "content": "Refined feedback text...",
    "feedback_type": "teacher_custom"
  }
}
```

**Response** (200 OK): Updated feedback object

---

##### **GET /api/v1/feedbacks/templates** - List Feedback Templates

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "MCQ Correct Answer Feedback",
      "category": "positive",
      "item_type": "mcq",
      "template_text": "Well done! You correctly identified...",
      "variables": ["student_name", "score"],
      "is_active": true
    },
    ...
  ]
}
```

---

### 5. Learning Analytics & Reports

#### 5.1 Student Portfolio

##### **GET /api/v1/students/:student_id/portfolio** - Get Student Portfolio

**Authentication**: Required
**Authorization**: student (own), parent (child), teacher, admin

**Response** (200 OK):

```json
{
  "success": true,
  "data": {
    "student_id": 54,
    "total_attempts": 5,
    "average_score": 82.5,
    "latest_score": 85,
    "performance_level": "proficient",
    "trend": [
      { "attempt": 1, "score": 75, "date": "2026-01-10" },
      { "attempt": 2, "score": 78, "date": "2026-01-20" },
      { "attempt": 3, "score": 85, "date": "2026-02-01" }
    ],
    "strengths": ["Reading comprehension", "Vocabulary"],
    "weaknesses": ["Inference", "Main idea identification"],
    "recommendations": [
      "Practice making inferences from text",
      "Focus on identifying main ideas in passages"
    ]
  }
}
```

---

#### 5.2 Assessment Reports

##### **GET /api/v1/attempts/:attempt_id/report** - Get Assessment Report

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": {
    "attempt_id": 789,
    "student_name": "김하윤",
    "total_score": 82,
    "max_score": 100,
    "score_percentage": 82,
    "performance_level": "Proficient",
    "completion_time": 75,
    "time_limit": 90,
    "item_analysis": [
      {
        "item_code": "ENG-2026-001",
        "type": "mcq",
        "score": 2,
        "max_score": 2,
        "difficulty": "high",
        "is_correct": true,
        "time_spent": 45
      },
      ...
    ],
    "skill_breakdown": {
      "vocabulary": 85,
      "comprehension": 80,
      "inference": 75
    },
    "recommendations": [
      "Continue working on inference skills",
      "Practice identifying main ideas"
    ]
  }
}
```

---

### 6. User & Role Management

#### 6.1 Users

##### **GET /api/v1/users** - List Users (Admin Only)

**Authentication**: Required
**Authorization**: admin

**Query Parameters**:

```
?filter[role]=teacher&search=name&page=1&per_page=50
```

**Response** (200 OK):

```json
{
  "success": true,
  "data": [
    {
      "id": 12,
      "email": "teacher@school.edu",
      "role": "teacher",
      "name": "김교사",
      "created_at": "2026-01-01T00:00:00Z"
    },
    ...
  ],
  "meta": { ... }
}
```

---

##### **POST /api/v1/users** - Create User (Admin Only)

**Authentication**: Required
**Authorization**: admin

**Request Body**:

```json
{
  "user": {
    "email": "newteacher@school.edu",
    "password": "SecurePassword123!",
    "password_confirmation": "SecurePassword123!",
    "role": "teacher",
    "school_id": 1
  }
}
```

**Response** (201 Created)

---

##### **PATCH /api/v1/users/:id** - Update User

**Authentication**: Required
**Authorization**: self or admin

**Request Body**:

```json
{
  "user": {
    "role": "school_admin",
    "password": "NewPassword123!"
  }
}
```

**Response** (200 OK)

---

#### 6.2 Current User

##### **GET /api/v1/current_user** - Get Current User Info

**Authentication**: Required

**Response** (200 OK):

```json
{
  "success": true,
  "data": {
    "id": 54,
    "email": "student@school.edu",
    "role": "student",
    "name": "김하윤",
    "student_id": 54,
    "permissions": [
      "read_own_results",
      "create_consultation_post",
      "view_parent_forum"
    ]
  }
}
```

---

## Data Models

### Item Model

```json
{
  "id": 123,
  "code": "ENG-2026-001",
  "item_type": "mcq",
  "difficulty": "high",
  "status": "active",
  "prompt": "Read the passage...",
  "explanation": "The answer is...",
  "category": "reading_comprehension",
  "stimulus_id": 45,
  "evaluation_indicator_id": 8,
  "sub_indicator_id": 12,
  "created_by_id": 12,
  "created_at": "2026-01-15T10:30:00Z",
  "updated_at": "2026-02-01T14:20:00Z",
  "_links": {
    "self": "/api/v1/items/123",
    "choices": "/api/v1/items/123/choices",
    "rubric": "/api/v1/items/123/rubric"
  }
}
```

### Response Model

```json
{
  "id": 999,
  "student_attempt_id": 789,
  "item_id": 123,
  "answer_text": null,
  "selected_choice_id": 457,
  "auto_score": 100,
  "manual_score": null,
  "is_correct": true,
  "status": "scored",
  "created_at": "2026-02-02T10:16:00Z",
  "updated_at": "2026-02-02T10:16:00Z",
  "_links": {
    "self": "/api/v1/responses/999",
    "feedback": "/api/v1/responses/999/feedback",
    "rubric_scores": "/api/v1/responses/999/rubric_scores"
  }
}
```

### AttemptReport Model

```json
{
  "id": 500,
  "student_attempt_id": 789,
  "total_score": 82,
  "max_score": 100,
  "score_percentage": 82,
  "performance_level": "Proficient",
  "strengths": ["Vocabulary", "Reading Comprehension"],
  "weaknesses": ["Inference"],
  "recommendations": ["Practice making inferences"],
  "generated_at": "2026-02-02T11:30:00Z",
  "created_at": "2026-02-02T11:30:00Z"
}
```

---

## Code Examples

### cURL Examples

#### Get All Items

```bash
curl -X GET "http://localhost:3000/api/v1/items?page=1&per_page=25" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

#### Create Item

```bash
curl -X POST "http://localhost:3000/api/v1/items" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "item": {
      "code": "ENG-2026-045",
      "type": "mcq",
      "difficulty": "medium",
      "prompt": "Read the passage..."
    }
  }'
```

#### Submit Response

```bash
curl -X POST "http://localhost:3000/api/v1/responses" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "response": {
      "student_attempt_id": 789,
      "item_id": 123,
      "selected_choice_id": 457
    }
  }'
```

### JavaScript/Fetch Examples

#### List Items

```javascript
async function getItems() {
  const response = await fetch(
    'http://localhost:3000/api/v1/items?page=1',
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    }
  );
  const data = await response.json();
  return data.data;
}
```

#### Generate Feedback

```javascript
async function generateFeedback(responseId) {
  const response = await fetch(
    'http://localhost:3000/api/v1/feedbacks/generate',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        feedback: {
          response_id: responseId,
          feedback_template_id: 15
        }
      })
    }
  );
  return response.json();
}
```

### Ruby on Rails Examples

#### API Client

```ruby
# app/services/readingpro_api_client.rb
class ReadingproApiClient
  def initialize(token = nil)
    @token = token || ENV['READINGPRO_API_TOKEN']
    @base_url = ENV['READINGPRO_API_URL']
  end

  def get_items(filters = {})
    get_request('/items', filters)
  end

  def create_feedback(response_id, template_id = nil)
    post_request('/feedbacks/generate', {
      response_id: response_id,
      feedback_template_id: template_id
    })
  end

  private

  def get_request(path, params)
    response = HTTP
      .auth("Bearer #{@token}")
      .get("#{@base_url}/api/v1#{path}", params: params)
    JSON.parse(response.body)
  end

  def post_request(path, data)
    response = HTTP
      .auth("Bearer #{@token}")
      .post("#{@base_url}/api/v1#{path}", json: data)
    JSON.parse(response.body)
  end
end

# Usage
client = ReadingproApiClient.new
items = client.get_items(filter: { type: 'mcq' })
```

---

## Rate Limiting (Future Implementation)

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1645398000
```

Limits per hour:
- Anonymous: 50 requests
- Authenticated: 1000 requests
- Admin: 5000 requests

---

## Versioning & Deprecation

**Current API Version**: v1

When deprecated endpoints are introduced:
```
Deprecation: true
Sunset: Sun, 30 June 2027 23:59:59 GMT
```

---

## Document History

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-02-02 | Initial API specification |
| 1.0 | TBD | Final version after review |

**This API specification provides the complete contract for all RESTful endpoints. Clients should implement robust error handling and respect rate limits.**

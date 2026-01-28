export enum UserRole {
  GUEST = 'Guest',
  STUDENT = 'Student',
  PARENT = 'Parent',
  SCHOOL_TEACHER = 'School Teacher',
  DIAGNOSTIC_TEACHER = 'Diagnostic Teacher',
  RESEARCHER = 'Researcher',
  ADMIN = 'Admin'
}

export enum Status {
  IN_PROGRESS = '진행 중',
  WAITING = '대기',
  COMPLETED = '완료',
  PENDING = '보류',
  ACTIVE = '활성',
  INACTIVE = '비활성',
  PUBLISHED = '발행됨',
  DRAFT = '초안',
  REVIEW = '검토 중',
  OPERATIONAL = '정상',
  DEGRADED = '저하',
  DOWN = '중단'
}

export interface Student {
  id: string;
  name: string;
  grade: string;
  examStatus: Status;
  score?: number;
  lastActive: string;
}

export interface Question {
  id: string;
  title: string;
  type: string;
  status: Status;
  author: string;
  updatedAt: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  status: Status;
  lastLogin: string;
}

export interface SystemService {
  name: string;
  status: Status;
  uptime: string;
}
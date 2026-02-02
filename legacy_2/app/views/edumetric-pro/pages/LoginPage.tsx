import React from 'react';
import { UserRole } from '../types';
import { GraduationCap, User, Users, BookOpen, Database, Shield, LayoutGrid } from 'lucide-react';

interface LoginPageProps {
  onLogin: (role: UserRole) => void;
}

const RoleButton: React.FC<{ role: UserRole; icon: any; label: string; desc: string; onClick: () => void; color: string; ringColor: string }> = ({ 
  role, icon: Icon, label, desc, onClick, color, ringColor 
}) => (
  <button 
    onClick={onClick}
    className={`flex flex-col items-center p-6 bg-white border border-gray-200 rounded-2xl shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 text-center h-full group hover:ring-2 ${ringColor}`}
  >
    <div className={`p-4 rounded-full ${color} mb-4 group-hover:scale-110 transition-transform`}>
      <Icon size={32} />
    </div>
    <h3 className="text-lg font-bold text-gray-900 mb-2">{label}</h3>
    <p className="text-sm text-gray-500 leading-relaxed">{desc}</p>
  </button>
);

const LoginPage: React.FC<LoginPageProps> = ({ onLogin }) => {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-6">
      <div className="max-w-6xl w-full">
        <div className="text-center mb-16">
          <div className="inline-flex items-center justify-center gap-2 mb-6 bg-white px-6 py-2 rounded-full shadow-sm border border-gray-100">
            <div className="w-6 h-6 bg-blue-600 rounded-md flex items-center justify-center text-white font-bold text-sm">E</div>
            <span className="font-bold text-xl text-gray-900">EduMetric<span className="text-blue-600">Pro</span></span>
          </div>
          <h1 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">로그인할 계정을 선택하세요</h1>
          <p className="text-gray-500 text-lg">각 역할에 최적화된 대시보드 환경을 미리 경험해보실 수 있습니다.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
          <RoleButton 
            role={UserRole.STUDENT} 
            icon={GraduationCap} 
            label="학생 (Student)" 
            desc="나의 시험 일정, 성적 분석 리포트, 오답 노트를 확인합니다."
            color="bg-blue-100 text-blue-600"
            ringColor="hover:ring-blue-400"
            onClick={() => onLogin(UserRole.STUDENT)}
          />
          <RoleButton 
            role={UserRole.PARENT} 
            icon={User} 
            label="학부모 (Parent)" 
            desc="자녀의 학습 현황을 모니터링하고 가정통신문을 확인합니다."
            color="bg-green-100 text-green-600"
            ringColor="hover:ring-green-400"
            onClick={() => onLogin(UserRole.PARENT)}
          />
          <RoleButton 
            role={UserRole.SCHOOL_TEACHER} 
            icon={Users} 
            label="학교 담당 교사 (Teacher)" 
            desc="학급 학생들의 출석, 기초 학력 현황, 생활 기록을 관리합니다."
            color="bg-yellow-100 text-yellow-600"
            ringColor="hover:ring-yellow-400"
            onClick={() => onLogin(UserRole.SCHOOL_TEACHER)}
          />
          <RoleButton 
            role={UserRole.DIAGNOSTIC_TEACHER} 
            icon={BookOpen} 
            label="진단 담당 교사 (Diagnostic)" 
            desc="심층 진단 평가를 배포하고, 서술형 채점 및 피드백을 제공합니다."
            color="bg-purple-100 text-purple-600"
            ringColor="hover:ring-purple-400"
            onClick={() => onLogin(UserRole.DIAGNOSTIC_TEACHER)}
          />
          <RoleButton 
            role={UserRole.RESEARCHER} 
            icon={Database} 
            label="문항 연구원 (Researcher)" 
            desc="평가 문항을 개발/검수하고 콘텐츠 라이브러리를 관리합니다."
            color="bg-indigo-100 text-indigo-600"
            ringColor="hover:ring-indigo-400"
            onClick={() => onLogin(UserRole.RESEARCHER)}
          />
          <RoleButton 
            role={UserRole.ADMIN} 
            icon={Shield} 
            label="시스템 관리자 (Admin)" 
            desc="전체 시스템 상태 모니터링 및 사용자 권한/보안을 설정합니다."
            color="bg-slate-100 text-slate-600"
            ringColor="hover:ring-slate-400"
            onClick={() => onLogin(UserRole.ADMIN)}
          />
        </div>
        
        <div className="text-center border-t border-gray-200 pt-8">
          <p className="text-sm text-gray-400">
            Secure Access • Single Sign-On (SSO) Supported • 2024 EduMetric Pro
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
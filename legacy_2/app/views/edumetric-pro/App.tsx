import React, { useState } from 'react';
import { LayoutDashboard, LogOut } from 'lucide-react';
import LandingPage from './pages/LandingPage';
import LoginPage from './pages/LoginPage';
import StudentDashboard from './pages/StudentDashboard';
import ParentDashboard from './pages/ParentDashboard';
import SchoolTeacherDashboard from './pages/SchoolTeacherDashboard';
import DiagnosticTeacherDashboard from './pages/DiagnosticTeacherDashboard';
import ResearcherDashboard from './pages/ResearcherDashboard';
import AdminDashboard from './pages/AdminDashboard';
import { UserRole } from './types';

// Navigation Bar Component
const TopNavigation: React.FC<{ roleName: string, onLogout: () => void }> = ({ roleName, onLogout }) => (
  <nav className="bg-white border-b border-gray-200 sticky top-0 z-50 shadow-sm">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="flex justify-between h-16">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-lg">E</div>
          <span className="font-bold text-xl text-gray-900 tracking-tight">EduMetric<span className="text-blue-600">Pro</span></span>
          <span className="hidden md:inline-flex ml-2 px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded-full border border-gray-200">{roleName}</span>
        </div>
        <div className="flex items-center gap-4">
          <button 
            onClick={onLogout}
            className="flex items-center gap-2 text-gray-500 hover:text-red-600 transition-colors text-sm font-medium"
          >
            <LogOut size={18} />
            <span className="hidden sm:inline">로그아웃</span>
          </button>
        </div>
      </div>
    </div>
  </nav>
);

const App: React.FC = () => {
  const [currentRole, setCurrentRole] = useState<UserRole>(UserRole.GUEST);
  const [isLoginPage, setIsLoginPage] = useState(false);

  // Handlers
  const handleStart = () => setIsLoginPage(true);
  const handleLogin = (role: UserRole) => {
    setCurrentRole(role);
    setIsLoginPage(false);
  };
  const handleLogout = () => {
    setCurrentRole(UserRole.GUEST);
    setIsLoginPage(false);
  };

  // 1. Landing Page & 2. Login Page Logic
  if (currentRole === UserRole.GUEST) {
    if (isLoginPage) {
      return <LoginPage onLogin={handleLogin} />;
    }
    return <LandingPage onStart={handleStart} />;
  }

  // Dashboard Routing based on Role
  const renderDashboard = () => {
    switch (currentRole) {
      case UserRole.STUDENT: // 3. Student
        return (
          <>
            <TopNavigation roleName="학생 워크스페이스" onLogout={handleLogout} />
            <StudentDashboard />
          </>
        );
      case UserRole.PARENT: // 4. Parent
        return (
          <>
            <TopNavigation roleName="학부모 대시보드" onLogout={handleLogout} />
            <ParentDashboard />
          </>
        );
      case UserRole.SCHOOL_TEACHER: // 5. School Teacher
        return (
          <>
            <TopNavigation roleName="학교 담당 교사" onLogout={handleLogout} />
            <SchoolTeacherDashboard />
          </>
        );
      case UserRole.DIAGNOSTIC_TEACHER: // 6. Diagnostic Teacher
        return (
          <>
            <TopNavigation roleName="진단 담당 교사" onLogout={handleLogout} />
            <DiagnosticTeacherDashboard />
          </>
        );
      case UserRole.RESEARCHER: // 7. Researcher
        return (
          <>
            <TopNavigation roleName="문항 개발 연구원" onLogout={handleLogout} />
            <ResearcherDashboard />
          </>
        );
      case UserRole.ADMIN: // 8. Admin
        return (
           <div className="relative">
             {/* Admin has its own sidebar, but we add a logout overlay for demo */}
             <div className="absolute top-4 right-4 z-50">
               <button onClick={handleLogout} className="bg-slate-800 text-white px-3 py-1.5 text-xs rounded shadow hover:bg-slate-700 flex items-center gap-1">
                 <LogOut size={12} /> 로그아웃
               </button>
             </div>
             <AdminDashboard />
           </div>
        );
      default:
        return <div>권한 오류가 발생했습니다.</div>;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-gray-900">
      {renderDashboard()}
    </div>
  );
};

export default App;
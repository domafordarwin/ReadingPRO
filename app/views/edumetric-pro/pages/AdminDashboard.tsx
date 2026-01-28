import React, { useState } from 'react';
import { 
  Server, 
  Database, 
  Activity, 
  Shield, 
  Users, 
  Lock, 
  RefreshCw, 
  Save, 
  FileText, 
  Plus, 
  MoreVertical,
  Trash2,
  Edit2
} from 'lucide-react';
import { SectionHeader, Button, Table, StatusBadge } from '../components/UIComponents';
import { User, UserRole, Status, SystemService } from '../types';

// --- Sub-components for Admin Views ---

// 1. System Maintenance View
const SystemMaintenance: React.FC = () => {
  const services: SystemService[] = [
    { name: 'API 서버', status: Status.OPERATIONAL, uptime: '99.99%' },
    { name: '데이터베이스 클러스터', status: Status.OPERATIONAL, uptime: '99.95%' },
    { name: '백그라운드 워커', status: Status.DEGRADED, uptime: '95.50%' },
    { name: '오브젝트 스토리지', status: Status.OPERATIONAL, uptime: '100.00%' },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
          <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-green-100 text-green-600 rounded-lg">
              <Activity size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-500">전체 시스템 상태</p>
              <h3 className="text-xl font-bold text-gray-900">정상 가동 중</h3>
            </div>
          </div>
          <div className="text-sm text-gray-500">마지막 자동 점검: 2분 전</div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
           <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-blue-100 text-blue-600 rounded-lg">
              <Server size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-500">현재 배포 버전</p>
              <h3 className="text-xl font-bold text-gray-900">v2.4.1 Stable</h3>
            </div>
          </div>
          <div className="text-sm text-gray-500">최근 배포: 3일 전 (Hotfix)</div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
           <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-indigo-100 text-indigo-600 rounded-lg">
              <Database size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-500">데이터 백업 상태</p>
              <h3 className="text-xl font-bold text-gray-900">동기화 완료</h3>
            </div>
          </div>
          <div className="text-sm text-gray-500">다음 예약 백업: 4시간 후</div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-6">개별 서비스 모니터링</h3>
        <div className="grid grid-cols-1 gap-4">
          {services.map((service, idx) => (
            <div key={idx} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100">
              <div className="flex items-center gap-3">
                <div className={`w-3 h-3 rounded-full ${service.status === Status.OPERATIONAL ? 'bg-green-500' : service.status === Status.DEGRADED ? 'bg-yellow-500' : 'bg-red-500'}`} />
                <span className="font-medium text-gray-700">{service.name}</span>
              </div>
              <div className="flex items-center gap-6">
                <span className="text-sm text-gray-500">가동률: {service.uptime}</span>
                <StatusBadge status={service.status} />
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">긴급 유지보수 작업</h3>
        <p className="text-sm text-gray-500 mb-6 bg-red-50 text-red-700 p-3 rounded border border-red-100 inline-block">
          주의: 이 작업들은 서비스 가용성에 영향을 줄 수 있습니다.
        </p>
        <div className="flex flex-wrap gap-4">
          <Button variant="secondary">
            <RefreshCw size={16} />
            시스템 캐시 삭제
          </Button>
          <Button variant="secondary">
            <Save size={16} />
            수동 DB 백업 실행
          </Button>
          <Button variant="secondary">
             <FileText size={16} />
             에러 로그 전체 다운로드
          </Button>
        </div>
      </div>
    </div>
  );
};

// 2. User Management View
const UserManagement: React.FC = () => {
  const users: User[] = [
    { id: 'u1', name: '김철수', email: 'kim@school.edu', role: UserRole.SCHOOL_TEACHER, status: Status.ACTIVE, lastLogin: '2023-10-24 09:30' },
    { id: 'u2', name: '박연구', email: 'park@research.org', role: UserRole.RESEARCHER, status: Status.ACTIVE, lastLogin: '2023-10-23 16:15' },
    { id: 'u3', name: '관리자', email: 'admin@system.com', role: UserRole.ADMIN, status: Status.ACTIVE, lastLogin: '방금 전' },
    { id: 'u4', name: '이영희', email: 'lee@school.edu', role: UserRole.DIAGNOSTIC_TEACHER, status: Status.INACTIVE, lastLogin: '2023-09-12 11:00' },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-between items-center bg-white p-4 rounded-xl shadow-sm border border-gray-200">
        <div className="flex gap-4">
          <input 
            placeholder="이름 또는 이메일 검색..." 
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-slate-500 focus:outline-none w-64"
          />
          <select className="px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-slate-500 focus:outline-none bg-white">
            <option>모든 권한</option>
            <option>학교 교사</option>
            <option>진단 교사</option>
            <option>연구원</option>
            <option>관리자</option>
          </select>
        </div>
        <Button className="bg-slate-800 hover:bg-slate-900">
          <Plus size={16} />
          사용자 추가
        </Button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <Table headers={['이름', '이메일', '권한', '계정 상태', '최근 접속', '관리']}>
          {users.map((user) => (
            <tr key={user.id} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{user.name}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.email}</td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 border border-gray-200">
                  {user.role}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <StatusBadge status={user.status} />
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.lastLogin}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div className="flex gap-2">
                  <button className="p-1.5 hover:bg-blue-50 rounded text-blue-600 transition"><Edit2 size={16} /></button>
                  <button className="p-1.5 hover:bg-red-50 rounded text-red-600 transition"><Trash2 size={16} /></button>
                </div>
              </td>
            </tr>
          ))}
        </Table>
      </div>
    </div>
  );
};

// 3. Role Management View
const RoleManagement: React.FC = () => {
  const roles = [
    { name: '시스템 관리자 (Admin)', users: 3, permissions: '전체 접근 권한, 시스템 설정', lastUpdated: '2023-01-15' },
    { name: '학교 담당 교사 (Teacher)', users: 156, permissions: '학급 관리, 학생 리포트 조회', lastUpdated: '2023-08-22' },
    { name: '진단 담당 교사 (Diagnostic)', users: 45, permissions: '진단 배포, 채점, 피드백 작성', lastUpdated: '2023-08-25' },
    { name: '문항 연구원 (Researcher)', users: 24, permissions: '문항 개발, 콘텐츠 라이브러리 관리', lastUpdated: '2023-09-10' },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-end mb-4">
        <Button className="bg-slate-800 hover:bg-slate-900">
          <Plus size={16} />
          새 역할 생성
        </Button>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {roles.map((role, idx) => (
          <div key={idx} className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:border-slate-300 transition-colors">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-slate-100 rounded-lg text-slate-600">
                  <Shield size={20} />
                </div>
                <div>
                  <h4 className="text-lg font-bold text-gray-900">{role.name}</h4>
                  <p className="text-sm text-gray-500">활성 사용자 {role.users}명</p>
                </div>
              </div>
              <button className="text-gray-400 hover:text-gray-600">
                <MoreVertical size={20} />
              </button>
            </div>
            
            <div className="space-y-3">
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">권한 범위</p>
                <p className="text-sm text-gray-700 mt-1">{role.permissions}</p>
              </div>
              <div className="pt-4 border-t border-gray-100 flex justify-between items-center text-xs text-gray-500">
                <span>최근 수정일: {role.lastUpdated}</span>
                <button className="text-blue-600 hover:underline font-medium">설정 변경</button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};


// --- Main Admin Dashboard Component ---

const AdminDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'system' | 'users' | 'roles'>('system');

  const tabs = [
    { id: 'system', label: '시스템 유지보수', icon: Server },
    { id: 'users', label: '사용자 관리', icon: Users },
    { id: 'roles', label: '역할 및 권한', icon: Lock },
  ];

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* Sidebar for Admin */}
      <div className="w-64 bg-slate-900 text-white flex-shrink-0 hidden md:block shadow-xl z-10">
        <div className="p-6 border-b border-slate-800">
          <h2 className="text-xl font-bold tracking-tight">관리자 콘솔</h2>
          <p className="text-xs text-slate-400 mt-1">EduMetric Pro v2.4</p>
        </div>
        <nav className="p-4 space-y-1">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                  activeTab === tab.id 
                    ? 'bg-blue-600 text-white shadow-md' 
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Icon size={18} />
                {tab.label}
              </button>
            );
          })}
        </nav>
        <div className="absolute bottom-0 w-64 p-6 border-t border-slate-800">
          <div className="flex items-center gap-3">
             <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center text-xs font-bold text-slate-300">AD</div>
             <div>
               <p className="text-sm font-medium text-slate-200">System Admin</p>
               <p className="text-xs text-slate-500">Super User</p>
             </div>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Mobile Header (visible only on small screens) */}
        <header className="bg-white border-b border-gray-200 p-4 md:hidden flex items-center justify-between">
          <h1 className="font-bold text-gray-800">관리자 콘솔</h1>
          <button className="text-gray-500"><MoreVertical /></button>
        </header>

        {/* Scrollable Content */}
        <main className="flex-1 overflow-y-auto p-8">
           <div className="max-w-6xl mx-auto">
             <div className="mb-8">
               <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
                 {tabs.find(t => t.id === activeTab)?.label}
               </h1>
             </div>
             
             {activeTab === 'system' && <SystemMaintenance />}
             {activeTab === 'users' && <UserManagement />}
             {activeTab === 'roles' && <RoleManagement />}
           </div>
        </main>
      </div>
    </div>
  );
};

export default AdminDashboard;
import React, { useState } from 'react';
import { Users, BookOpen, ClipboardList, AlertCircle, Search, Filter, ChevronLeft, Phone, Mail, MapPin } from 'lucide-react';
import { SectionHeader, StatCard, Table, StatusBadge, Button } from '../components/UIComponents';
import { Status } from '../types';

const StudentProfileView: React.FC<{ onBack: () => void, studentName: string }> = ({ onBack, studentName }) => (
  <div className="space-y-6 animate-fade-in">
    <button onClick={onBack} className="flex items-center text-gray-500 hover:text-blue-600 mb-4 transition">
      <ChevronLeft size={20} />
      <span>학급 목록으로 돌아가기</span>
    </button>

    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      <div className="h-32 bg-gradient-to-r from-blue-500 to-cyan-400"></div>
      <div className="px-8 pb-8">
        <div className="flex justify-between items-end -mt-12 mb-6">
          <div className="flex items-end gap-6">
             <div className="w-24 h-24 bg-white rounded-xl p-1 shadow-md">
                <div className="w-full h-full bg-slate-100 rounded-lg flex items-center justify-center text-2xl font-bold text-slate-500">
                  {studentName.charAt(0)}
                </div>
             </div>
             <div className="pb-2">
                <h2 className="text-2xl font-bold text-gray-900">{studentName}</h2>
                <p className="text-gray-500">2학년 3반 14번</p>
             </div>
          </div>
          <div className="flex gap-2 pb-2">
            <Button variant="secondary" className="text-xs"><Phone size={14}/> 학부모 통화</Button>
            <Button className="text-xs"><ClipboardList size={14}/> 상담 일지 작성</Button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="space-y-6">
             <div className="bg-gray-50 rounded-lg p-5 border border-gray-100">
                <h3 className="font-bold text-gray-800 mb-3">기본 정보</h3>
                <ul className="space-y-3 text-sm">
                   <li className="flex gap-3 text-gray-600"><Phone size={16}/> 010-1234-5678</li>
                   <li className="flex gap-3 text-gray-600"><Mail size={16}/> student@school.edu</li>
                   <li className="flex gap-3 text-gray-600"><MapPin size={16}/> 서울특별시 강남구 ...</li>
                </ul>
             </div>
             
             <div className="bg-gray-50 rounded-lg p-5 border border-gray-100">
                <h3 className="font-bold text-gray-800 mb-3">출석 현황</h3>
                <div className="flex justify-between items-center mb-2">
                   <span className="text-sm text-gray-600">출석률</span>
                   <span className="font-bold text-blue-600">98%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                   <div className="bg-blue-600 h-2 rounded-full" style={{width: '98%'}}></div>
                </div>
             </div>
          </div>

          <div className="md:col-span-2 space-y-6">
             <div className="border border-gray-200 rounded-lg overflow-hidden">
                <div className="bg-gray-50 px-4 py-3 border-b border-gray-200 font-bold text-gray-700">최근 진단 이력</div>
                <table className="min-w-full text-sm">
                   <thead className="bg-white">
                      <tr>
                        <th className="px-4 py-2 text-left text-gray-500 font-medium">진단명</th>
                        <th className="px-4 py-2 text-left text-gray-500 font-medium">날짜</th>
                        <th className="px-4 py-2 text-left text-gray-500 font-medium">점수</th>
                      </tr>
                   </thead>
                   <tbody className="divide-y divide-gray-100">
                      <tr>
                        <td className="px-4 py-3">3월 기초학력 진단</td>
                        <td className="px-4 py-3 text-gray-500">2024.03.10</td>
                        <td className="px-4 py-3 font-bold">85점</td>
                      </tr>
                      <tr>
                        <td className="px-4 py-3">1학기 중간 성취도</td>
                        <td className="px-4 py-3 text-gray-500">2024.04.20</td>
                        <td className="px-4 py-3 font-bold">92점</td>
                      </tr>
                   </tbody>
                </table>
             </div>
             
             <div className="border border-gray-200 rounded-lg p-5">
                <h3 className="font-bold text-gray-800 mb-3">교사 코멘트 (생활지도)</h3>
                <p className="text-sm text-gray-600 leading-relaxed bg-yellow-50 p-4 rounded border border-yellow-100">
                  수업 태도가 매우 바르고 교우 관계가 원만함. 다만 수학 시간에 다소 소극적인 모습을 보여 격려가 필요함.
                </p>
             </div>
          </div>
        </div>
      </div>
    </div>
  </div>
);

const SchoolTeacherDashboard: React.FC = () => {
  const [view, setView] = useState<'dashboard' | 'profile'>('dashboard');
  const [selectedStudent, setSelectedStudent] = useState<string | null>(null);

  const handleStudentClick = (name: string) => {
    setSelectedStudent(name);
    setView('profile');
  };

  if (view === 'profile' && selectedStudent) {
    return (
      <div className="p-6 bg-gray-50 min-h-screen">
        <StudentProfileView onBack={() => setView('dashboard')} studentName={selectedStudent} />
      </div>
    );
  }

  const students = [
    { name: '김철수', id: 'S001', attendance: '출석', status: Status.COMPLETED, score: 85 },
    { name: '이영희', id: 'S002', attendance: '출석', status: Status.COMPLETED, score: 92 },
    { name: '박민수', id: 'S003', attendance: '결석', status: Status.WAITING, score: 0 },
    { name: '최지우', id: 'S004', attendance: '출석', status: Status.IN_PROGRESS, score: 45 },
    { name: '정다은', id: 'S005', attendance: '출석', status: Status.WAITING, score: 0 },
    { name: '강현우', id: 'S006', attendance: '지각', status: Status.COMPLETED, score: 78 },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 animate-fade-in">
      <SectionHeader 
        title="학교 담당 교사 대시보드" 
        description="2학년 3반 학급 현황 모니터링 및 학생 생활 지도 관리"
        actions={
          <div className="flex gap-2">
            <Button variant="secondary">
              <ClipboardList size={16} />
              출석 마감
            </Button>
            <Button>
              <Users size={16} />
              학급 관리
            </Button>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatCard title="총 재적" value="24명" icon={Users} color="blue" />
        <StatCard title="금일 출석" value="23명" icon={ClipboardList} color="green" subtext="결석 1명 (병결)" />
        <StatCard title="기초학력 진단 미응시" value="2명" icon={AlertCircle} color="red" />
        <StatCard title="학급 평균 성취도" value="78.5점" icon={BookOpen} color="purple" subtext="학년 평균 대비 +2.5" />
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="p-5 border-b border-gray-200 flex flex-col md:flex-row justify-between items-center gap-4">
          <h3 className="text-lg font-bold text-gray-800">학생 목록 및 진단 현황</h3>
          <div className="flex gap-2 w-full md:w-auto">
            <div className="relative flex-grow md:flex-grow-0">
               <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16}/>
               <input 
                 type="text" 
                 placeholder="이름 또는 학번 검색" 
                 className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-full"
               />
            </div>
            <button className="px-3 py-2 border border-gray-300 rounded-lg bg-gray-50 hover:bg-gray-100 text-gray-600">
               <Filter size={18} />
            </button>
          </div>
        </div>
        <Table headers={['이름', '학번', '출석 상태', '최근 진단 상태', '점수', '생활 지도']}>
          {students.map((student, idx) => (
            <tr key={idx} className="hover:bg-gray-50 transition-colors cursor-pointer" onClick={() => handleStudentClick(student.name)}>
              <td className="px-6 py-4 font-medium text-gray-900">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold text-slate-500">
                    {student.name.slice(0,1)}
                  </div>
                  {student.name}
                </div>
              </td>
              <td className="px-6 py-4 text-gray-500 font-mono text-sm">{student.id}</td>
              <td className="px-6 py-4">
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  student.attendance === '출석' ? 'bg-green-100 text-green-700' : 
                  student.attendance === '결석' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700'
                }`}>
                  {student.attendance}
                </span>
              </td>
              <td className="px-6 py-4"><StatusBadge status={student.status} /></td>
              <td className="px-6 py-4 font-bold text-gray-800">{student.score > 0 ? student.score : '-'}</td>
              <td className="px-6 py-4">
                <button 
                  onClick={(e) => { e.stopPropagation(); handleStudentClick(student.name); }}
                  className="text-blue-600 text-sm font-medium hover:bg-blue-50 px-3 py-1.5 rounded transition"
                >
                  상담 기록
                </button>
              </td>
            </tr>
          ))}
        </Table>
        <div className="p-4 border-t border-gray-200 flex justify-between items-center bg-gray-50">
           <span className="text-xs text-gray-500">총 24명의 학생 중 6명 표시됨</span>
           <div className="flex gap-2">
             <button className="px-3 py-1 border border-gray-300 rounded bg-white text-xs disabled:opacity-50" disabled>이전</button>
             <button className="px-3 py-1 border border-gray-300 rounded bg-white text-xs">다음</button>
           </div>
        </div>
      </div>
    </div>
  );
};

export default SchoolTeacherDashboard;
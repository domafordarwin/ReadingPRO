import React, { useState } from 'react';
import { 
  Users, 
  Clock, 
  CheckCircle, 
  MessageCircle, 
  Send, 
  FileText, 
  MoreHorizontal,
  PenTool,
  ChevronLeft,
  Save
} from 'lucide-react';
import { StatCard, SectionHeader, Button, Table, StatusBadge } from '../components/UIComponents';
import { Student, Status } from '../types';

// Grading View Component
const GradingView: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  return (
    <div className="space-y-6 animate-fade-in">
       <button onClick={onBack} className="flex items-center text-gray-500 hover:text-blue-600 mb-2 transition">
        <ChevronLeft size={20} />
        <span>대시보드로 돌아가기</span>
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Answer Sheet */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-5 border-b border-gray-200 flex justify-between items-center bg-gray-50">
              <h2 className="font-bold text-gray-900">서술형 답안 채점: 수학 (김학생)</h2>
              <span className="text-sm text-gray-500">제출: 2024.03.20 14:30</span>
            </div>
            <div className="p-6">
              <div className="mb-6">
                <span className="text-xs font-bold text-blue-600 bg-blue-50 px-2 py-1 rounded mb-2 inline-block">문제 3</span>
                <p className="text-lg font-medium text-gray-900 mb-4">
                  직각삼각형 ABC에서 빗변 AC의 길이가 10이고, 각 A가 30도일 때, 나머지 변의 길이를 구하고 풀이 과정을 서술하시오.
                </p>
              </div>
              
              <div className="bg-slate-50 border border-slate-200 rounded-xl p-6 mb-6">
                <p className="text-sm text-slate-500 mb-2 font-bold">학생 답안:</p>
                <p className="font-handwriting text-slate-800 text-lg leading-relaxed" style={{fontFamily: 'cursive'}}>
                  삼각비의 정의에 따라 sin 30° = BC / AC 이므로, BC = 10 * 1/2 = 5 입니다.<br/>
                  cos 30° = AB / AC 이므로, AB = 10 * √3/2 = 5√3 입니다.<br/>
                  따라서 BC = 5, AB = 5√3 입니다.
                </p>
              </div>

              <div>
                <p className="text-sm text-gray-500 mb-2 font-bold">모범 답안:</p>
                <div className="bg-green-50 text-green-800 p-4 rounded-lg text-sm">
                   BC = AC * sin(A) = 10 * 0.5 = 5. AB = AC * cos(A) = 10 * (√3/2) = 5√3. 풀이 과정이 논리적이며 삼각비의 정의를 정확히 활용함.
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Grading Controls */}
        <div className="lg:col-span-1 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 sticky top-24">
             <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
               <PenTool size={18} className="text-blue-600"/>
               채점 및 피드백
             </h3>
             
             <div className="space-y-4">
               <div>
                 <label className="block text-sm font-medium text-gray-700 mb-1">점수 (10점 만점)</label>
                 <div className="flex gap-2">
                   <input type="number" defaultValue={10} className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                   <span className="flex items-center text-gray-500">/ 10</span>
                 </div>
               </div>

               <div>
                 <label className="block text-sm font-medium text-gray-700 mb-1">코멘트</label>
                 <textarea 
                   rows={6}
                   className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none"
                   defaultValue="삼각비의 정의를 정확하게 이해하고 있으며, 풀이 과정이 매우 깔끔합니다. 훌륭해요!"
                 ></textarea>
               </div>

               <div className="pt-4 flex gap-2">
                 <Button className="w-full flex justify-center items-center gap-2" onClick={onBack}>
                   <Save size={16}/> 저장 및 다음
                 </Button>
               </div>
             </div>
          </div>
        </div>
      </div>
    </div>
  )
}

const DiagnosticTeacherDashboard: React.FC = () => {
  const [view, setView] = useState<'dashboard' | 'grading'>('dashboard');

  if (view === 'grading') {
    return (
      <div className="p-6 bg-gray-50 min-h-screen">
        <GradingView onBack={() => setView('dashboard')} />
      </div>
    );
  }

  // Mock Data for Diagnostic Context
  const stats = [
    { title: '채점 대기 문항', value: 45, icon: PenTool, color: 'blue' },
    { title: '승인 대기 중인 진단', value: 5, icon: Users, color: 'yellow' },
    { title: '작성 완료된 피드백', value: 128, icon: CheckCircle, color: 'green' },
    { title: '읽지 않은 학생 질문', value: 8, icon: MessageCircle, color: 'purple' },
  ];

  const students: Student[] = [
    { id: '1', name: '김민지', grade: '초5', examStatus: Status.COMPLETED, score: 85, lastActive: '2분 전' },
    { id: '2', name: '이준호', grade: '초6', examStatus: Status.WAITING, score: 0, lastActive: '1일 전' },
    { id: '3', name: '박서연', grade: '초5', examStatus: Status.IN_PROGRESS, score: 45, lastActive: '활동 중' },
    { id: '4', name: '최현수', grade: '초4', examStatus: Status.REVIEW, score: 92, lastActive: '3시간 전' },
    { id: '5', name: '정우성', grade: '초6', examStatus: Status.COMPLETED, score: 78, lastActive: '어제' },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 animate-fade-in">
      {/* Header & CTA */}
      <SectionHeader 
        title="진단 담당 교사 워크스페이스" 
        description="평가 문항을 배포하고, 학생 답안을 채점하여 심층 피드백을 제공합니다."
        actions={
          <>
            <Button variant="secondary">
              <FileText size={16} />
              종합 리포트 생성
            </Button>
            <Button>
              <Send size={16} />
              새 진단 배포
            </Button>
          </>
        }
      />

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, idx) => (
          <StatCard key={idx} {...stat} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Waiting List - Left Column */}
        <div className="lg:col-span-1 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-4 border-b border-gray-200 flex justify-between items-center bg-gray-50">
              <h3 className="font-semibold text-gray-800">서술형 채점 대기</h3>
              <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">3건</span>
            </div>
            <div className="divide-y divide-gray-100">
              {[1, 2, 3].map((item) => (
                <div key={item} className="p-4 hover:bg-gray-50 transition">
                   <div className="flex justify-between items-start mb-2">
                      <span className="text-sm font-medium text-gray-900">수학: 풀이 과정 서술</span>
                      <span className="text-xs text-gray-500">10분 전</span>
                   </div>
                   <p className="text-xs text-gray-500 mb-3">학생: 김학생 (초5)</p>
                   <Button 
                     variant="secondary" 
                     className="w-full py-1 text-xs h-8"
                     onClick={() => setView('grading')}
                   >
                     채점하기
                   </Button>
                </div>
              ))}
            </div>
          </div>
          
           {/* Feedback Status */}
           <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-4 border-b border-gray-200 bg-gray-50">
              <h3 className="font-semibold text-gray-800">최근 피드백 발송 현황</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">학생</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">상태</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {[
                    {name: '김민지', status: '발송됨'},
                    {name: '최현수', status: '임시저장'},
                    {name: '정우성', status: '읽음'},
                  ].map((row, idx) => (
                    <tr key={idx}>
                      <td className="px-4 py-3 text-gray-900">{row.name}</td>
                      <td className="px-4 py-3">
                        <span className={`text-xs px-2 py-1 rounded-full ${
                          row.status === '발송됨' ? 'bg-green-100 text-green-700' :
                          row.status === '임시저장' ? 'bg-gray-100 text-gray-600' :
                          'bg-blue-100 text-blue-700'
                        }`}>{row.status}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Main Student Table - Right Column */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden h-full">
            <div className="p-5 border-b border-gray-200 flex justify-between items-center">
              <h3 className="text-lg font-semibold text-gray-800">학생 응시 현황</h3>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  placeholder="학생 이름 검색..." 
                  className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            
            <Table headers={['학생 이름', '학년', '진단 상태', '자동 채점 점수', '최근 활동', '관리']}>
              {students.map((student) => (
                <tr key={student.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="h-8 w-8 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 font-bold mr-3 text-xs">
                        {student.name.charAt(0)}
                      </div>
                      <div className="text-sm font-medium text-gray-900">{student.name}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{student.grade}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <StatusBadge status={student.examStatus} />
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">
                    {student.score > 0 ? `${student.score}점` : '-'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{student.lastActive}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex items-center gap-2">
                      <button className="text-gray-400 hover:text-gray-600 p-1" title="상세보기">
                        <MoreHorizontal size={18} />
                      </button>
                      <button className="text-blue-600 hover:bg-blue-50 p-1.5 rounded" title="결과 분석 리포트">
                        <FileText size={18} />
                      </button>
                      <button className="text-purple-600 hover:bg-purple-50 p-1.5 rounded" title="피드백 작성">
                        <MessageCircle size={18} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </Table>
            <div className="p-4 border-t border-gray-200 bg-gray-50 flex justify-between items-center">
              <span className="text-sm text-gray-500">총 24명 중 5명 표시</span>
              <div className="flex gap-2">
                <Button variant="secondary" className="py-1 px-3 text-xs h-8">이전</Button>
                <Button variant="secondary" className="py-1 px-3 text-xs h-8">다음</Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DiagnosticTeacherDashboard;
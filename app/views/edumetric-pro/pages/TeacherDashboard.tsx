import React from 'react';
import { 
  Users, 
  Clock, 
  CheckCircle, 
  MessageCircle, 
  Send, 
  FileText, 
  MoreHorizontal
} from 'lucide-react';
import { StatCard, SectionHeader, Button, Table, StatusBadge } from '../components/UIComponents';
import { Student, Status } from '../types';

const DiagnosticTeacherDashboard: React.FC = () => {
  // Mock Data
  const stats = [
    { title: '진행 중인 평가', value: 12, icon: Clock, color: 'blue' },
    { title: '승인 대기', value: 5, icon: Users, color: 'yellow' },
    { title: '피드백 완료', value: 28, icon: CheckCircle, color: 'green' },
    { title: '피드백 대기', value: 8, icon: MessageCircle, color: 'purple' },
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
        title="진단 담당 교사 대시보드" 
        description="학생들의 진단 평가를 배포하고 심층 피드백을 제공합니다."
        actions={
          <>
            <Button variant="secondary">
              <FileText size={16} />
              보고서 생성
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
        {/* Waiting List */}
        <div className="lg:col-span-1 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-4 border-b border-gray-200 flex justify-between items-center bg-gray-50">
              <h3 className="font-semibold text-gray-800">진단 요청 대기</h3>
              <span className="bg-yellow-100 text-yellow-800 text-xs px-2 py-1 rounded-full">5명 대기</span>
            </div>
            <div className="divide-y divide-gray-100">
              {[1, 2, 3, 4, 5].map((item) => (
                <div key={item} className="p-4 flex items-center justify-between hover:bg-gray-50">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-gray-600">
                      S{item}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">학생 {item}</p>
                      <p className="text-xs text-gray-500">요청: 수학 3단계 진단</p>
                    </div>
                  </div>
                  <Button variant="secondary" className="px-2 py-1 text-xs">승인</Button>
                </div>
              ))}
            </div>
            <div className="p-3 bg-gray-50 border-t border-gray-200 text-center">
              <button className="text-sm text-blue-600 font-medium hover:text-blue-700">전체 보기</button>
            </div>
          </div>
          
           {/* Feedback Status */}
           <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-4 border-b border-gray-200 bg-gray-50">
              <h3 className="font-semibold text-gray-800">최근 피드백 현황</h3>
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

        {/* Main Student Table */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden h-full">
            <div className="p-5 border-b border-gray-200 flex justify-between items-center">
              <h3 className="text-lg font-semibold text-gray-800">학생 응시 현황</h3>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  placeholder="학생 검색..." 
                  className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            
            <Table headers={['학생 이름', '학년', '상태', '점수', '최근 활동', '관리']}>
              {students.map((student) => (
                <tr key={student.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="h-8 w-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold mr-3">
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
                      <button className="text-gray-400 hover:text-gray-600" title="상세보기">
                        <MoreHorizontal size={18} />
                      </button>
                      <button className="text-blue-600 hover:text-blue-900" title="리포트">
                        <FileText size={18} />
                      </button>
                      <button className="text-purple-600 hover:text-purple-900" title="피드백 작성">
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
                <Button variant="secondary" className="py-1 px-3 text-xs">이전</Button>
                <Button variant="secondary" className="py-1 px-3 text-xs">다음</Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DiagnosticTeacherDashboard;

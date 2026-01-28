import React, { useState } from 'react';
import { 
  Book, 
  FileText, 
  HelpCircle, 
  Search, 
  Plus, 
  GitPullRequest,
  Edit,
  Library,
  Layers,
  CheckSquare,
  ChevronLeft,
  Save,
  Eye
} from 'lucide-react';
import { StatCard, SectionHeader, Button, Table, StatusBadge, QuickActionCard } from '../components/UIComponents';
import { Question, Status } from '../types';

const QuestionEditor: React.FC<{ onBack: () => void }> = ({ onBack }) => (
  <div className="max-w-5xl mx-auto animate-fade-in">
    <button onClick={onBack} className="flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition">
      <ChevronLeft size={20} />
      <span>문항 목록으로 돌아가기</span>
    </button>
    
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      <div className="p-6 border-b border-gray-200 flex justify-between items-center bg-gray-50">
        <h2 className="text-xl font-bold text-gray-900">문항 편집기</h2>
        <div className="flex gap-2">
          <Button variant="secondary" className="text-xs"><Eye size={14}/> 미리보기</Button>
          <Button className="text-xs bg-indigo-600 hover:bg-indigo-700"><Save size={14}/> 저장</Button>
        </div>
      </div>
      
      <div className="p-8 grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">문항 유형</label>
            <select className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
              <option>객관식 (4지 선다)</option>
              <option>객관식 (5지 선다)</option>
              <option>단답형</option>
              <option>서술형</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">관련 단원</label>
            <input type="text" className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none" defaultValue="수학 II > 미분 > 도함수의 활용" />
          </div>

          <div>
             <label className="block text-sm font-medium text-gray-700 mb-1">난이도</label>
             <div className="flex gap-4">
               {['하', '중', '상', '최상'].map((level, idx) => (
                 <label key={idx} className="flex items-center gap-2">
                   <input type="radio" name="level" defaultChecked={level === '중'} className="text-indigo-600 focus:ring-indigo-500" />
                   <span className="text-sm text-gray-600">{level}</span>
                 </label>
               ))}
             </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">발문 (문제 텍스트)</label>
            <textarea className="w-full border border-gray-300 rounded-lg px-3 py-2 h-32 text-sm focus:ring-2 focus:ring-indigo-500 outline-none font-sans" defaultValue="다음 함수 f(x)가 x=1에서 극값을 가질 때, 상수 a의 값을 구하시오." />
          </div>
        </div>

        <div className="space-y-6">
           <div>
             <label className="block text-sm font-medium text-gray-700 mb-1">보기 / 정답 설정</label>
             <div className="space-y-3 bg-gray-50 p-4 rounded-lg border border-gray-200">
               {[1, 2, 3, 4, 5].map((num) => (
                 <div key={num} className="flex items-center gap-2">
                    <input type="radio" name="correct" className="text-green-600 focus:ring-green-500" />
                    <span className="w-6 text-center text-sm font-bold text-gray-500">{num}</span>
                    <input type="text" className="flex-1 border border-gray-300 rounded px-2 py-1.5 text-sm" placeholder={`보기 ${num} 내용`} />
                 </div>
               ))}
             </div>
           </div>

           <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">해설 (풀이 과정)</label>
              <textarea className="w-full border border-gray-300 rounded-lg px-3 py-2 h-24 text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="해설을 입력하세요..." />
           </div>
        </div>
      </div>
    </div>
  </div>
);

const ResearcherDashboard: React.FC = () => {
  const [view, setView] = useState<'dashboard' | 'editor'>('dashboard');

  if (view === 'editor') {
    return (
      <div className="p-6 bg-gray-50 min-h-screen">
        <QuestionEditor onBack={() => setView('dashboard')} />
      </div>
    );
  }

  // Mock Data
  const stats = [
    { title: '총 도서 (교과서)', value: 45, icon: Book, color: 'indigo' },
    { title: '등록된 지문', value: 312, icon: FileText, color: 'blue' },
    { title: '전체 문항 수', value: '1,250', icon: HelpCircle, color: 'green' },
    { title: '동료 검토 대기', value: 18, icon: GitPullRequest, color: 'red' },
  ];

  const recentQuestions: Question[] = [
    { id: 'Q-1001', title: '삼각함수의 미분 응용 (심화)', type: '객관식', status: Status.PUBLISHED, author: '김연구', updatedAt: '2023-10-15' },
    { id: 'Q-1002', title: '비문학 독해: 인공지능 윤리', type: '단답형', status: Status.REVIEW, author: '이국어', updatedAt: '2023-10-14' },
    { id: 'Q-1003', title: '물리: 뉴턴 제2법칙 응용', type: '객관식', status: Status.DRAFT, author: '박물리', updatedAt: '2023-10-14' },
    { id: 'Q-1004', title: '화학: 산화 환원 반응식', type: '빈칸 채우기', status: Status.REVIEW, author: '최화학', updatedAt: '2023-10-13' },
    { id: 'Q-1005', title: '세계사: 1차 대전의 원인', type: '서술형', status: Status.PUBLISHED, author: '정역사', updatedAt: '2023-10-12' },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 animate-fade-in">
      <SectionHeader 
        title="문항 개발 연구원 워크스페이스" 
        description="교육 콘텐츠와 평가 문항을 개발하고, 문항의 타당도를 검증합니다."
        actions={
          <>
            <Button variant="secondary">
              <Search size={16} />
              라이브러리 탐색
            </Button>
            <Button onClick={() => setView('editor')}>
              <Plus size={16} />
              새 문항 저작
            </Button>
          </>
        }
      />

      {/* Stats Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, idx) => (
          <StatCard key={idx} {...stat} />
        ))}
      </div>

      {/* Quick Actions Row */}
      <div>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">빠른 작업</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          <QuickActionCard title="도서 관리" icon={Library} color="indigo" />
          <QuickActionCard title="지문 편집기" icon={Layers} color="blue" />
          <QuickActionCard title="문항 뱅크" icon={HelpCircle} color="green" />
          <QuickActionCard title="검토 시작 (3건)" icon={CheckSquare} color="red" />
        </div>
      </div>

      {/* Recent Activity Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="p-5 border-b border-gray-200 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <h3 className="text-lg font-semibold text-gray-800">최근 수정된 문항</h3>
          <div className="flex gap-3 w-full md:w-auto">
             <div className="relative flex-grow">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                <input 
                  type="text" 
                  placeholder="ID 또는 제목 검색" 
                  className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 w-full"
                />
             </div>
             <select className="px-3 py-2 border border-gray-300 rounded-lg text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
               <option>모든 유형</option>
               <option>객관식</option>
               <option>주관식</option>
               <option>서술형</option>
             </select>
          </div>
        </div>
        
        <Table headers={['문항 ID', '제목', '유형', '상태', '작성자', '최근 수정일', '관리']}>
          {recentQuestions.map((q) => (
            <tr key={q.id} className="hover:bg-gray-50 transition-colors">
              <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-500">{q.id}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">{q.title}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{q.type}</td>
              <td className="px-6 py-4 whitespace-nowrap">
                <StatusBadge status={q.status} />
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{q.author}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{q.updatedAt}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm">
                <button 
                  onClick={() => setView('editor')}
                  className="text-indigo-600 hover:bg-indigo-50 px-3 py-1.5 rounded transition flex items-center gap-1 font-medium"
                >
                  <Edit size={14} />
                  <span>편집</span>
                </button>
              </td>
            </tr>
          ))}
        </Table>
        <div className="p-4 bg-gray-50 border-t border-gray-200 text-center">
          <button className="text-sm font-medium text-indigo-600 hover:text-indigo-800">문항 라이브러리 전체 보기</button>
        </div>
      </div>
    </div>
  );
};

export default ResearcherDashboard;
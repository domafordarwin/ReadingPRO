import React, { useState } from 'react';
import { BookOpen, Calendar, Award, TrendingUp, Clock, AlertCircle, CheckCircle, ChevronLeft } from 'lucide-react';
import { SectionHeader, StatCard, Table, StatusBadge, Button } from '../components/UIComponents';
import { Status } from '../types';

// Mock Exam View Component
const ExamView: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  const [currentQuestion, setCurrentQuestion] = useState(1);
  const totalQuestions = 5;

  return (
    <div className="max-w-4xl mx-auto space-y-6 animate-fade-in">
      <button onClick={onBack} className="flex items-center text-gray-500 hover:text-blue-600 mb-4 transition">
        <ChevronLeft size={20} />
        <span>평가 목록으로 돌아가기</span>
      </button>

      <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
        <div className="bg-blue-600 p-6 text-white flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold">단원 평가: 미분과 적분</h2>
            <p className="text-blue-100 mt-1">제한시간 60분 | 문항수 {totalQuestions}문항</p>
          </div>
          <div className="bg-white/20 backdrop-blur px-4 py-2 rounded-lg font-mono text-xl font-bold">
            45:30
          </div>
        </div>

        <div className="p-8">
          <div className="mb-6">
            <div className="flex justify-between text-sm text-gray-500 mb-2">
              <span>진행률</span>
              <span>{currentQuestion} / {totalQuestions}</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300" 
                style={{ width: `${(currentQuestion / totalQuestions) * 100}%` }}
              ></div>
            </div>
          </div>

          <div className="mb-8">
            <span className="inline-block px-3 py-1 bg-gray-100 text-gray-600 rounded-full text-xs font-bold mb-4">문제 {currentQuestion}</span>
            <h3 className="text-xl font-medium text-gray-900 leading-relaxed">
              함수 f(x) = x³ - 3x² + k 의 극솟값이 4일 때, 상수 k의 값을 구하시오.
            </h3>
          </div>

          <div className="space-y-3 mb-8">
            {[1, 2, 3, 4, 5].map((option) => (
              <label key={option} className="flex items-center p-4 border border-gray-200 rounded-lg hover:bg-blue-50 hover:border-blue-300 cursor-pointer transition group">
                <input type="radio" name="answer" className="w-4 h-4 text-blue-600 border-gray-300 focus:ring-blue-500" />
                <span className="ml-3 text-gray-700 group-hover:text-blue-700 font-medium">보기 {option} : {option * 2}</span>
              </label>
            ))}
          </div>

          <div className="flex justify-between pt-6 border-t border-gray-100">
            <Button 
              variant="secondary" 
              onClick={() => setCurrentQuestion(Math.max(1, currentQuestion - 1))}
              disabled={currentQuestion === 1}
              className={currentQuestion === 1 ? 'opacity-50 cursor-not-allowed' : ''}
            >
              이전 문제
            </Button>
            {currentQuestion < totalQuestions ? (
              <Button onClick={() => setCurrentQuestion(currentQuestion + 1)}>다음 문제</Button>
            ) : (
              <Button onClick={onBack} className="bg-green-600 hover:bg-green-700">제출하기</Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

const StudentDashboard: React.FC = () => {
  const [view, setView] = useState<'dashboard' | 'exam'>('dashboard');

  if (view === 'exam') {
    return (
      <div className="p-6 bg-gray-50 min-h-screen">
        <ExamView onBack={() => setView('dashboard')} />
      </div>
    );
  }

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 animate-fade-in">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-8 text-white shadow-lg flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold mb-2">안녕하세요, 김학생님! 👋</h1>
          <p className="text-blue-100">오늘 예정된 시험이 1건 있습니다. 준비되셨나요?</p>
        </div>
        <div className="hidden md:block">
           <div className="bg-white/10 p-4 rounded-xl backdrop-blur-sm border border-white/20 text-center">
              <p className="text-xs text-blue-100 mb-1">나의 랭킹</p>
              <p className="text-2xl font-bold">Top 5%</p>
           </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard title="나의 평균 점수" value="85점" icon={TrendingUp} color="blue" subtext="지난달 대비 +3점 상승" />
        <StatCard title="완료한 진단" value="12건" icon={Award} color="green" subtext="전체 상위 15%" />
        <StatCard title="진행 중인 과제" value="2건" icon={BookOpen} color="red" subtext="마감 기한 임박" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Exam List */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-5 border-b border-gray-200 flex justify-between items-center">
              <h3 className="text-lg font-bold text-gray-800">나의 평가 목록</h3>
              <Button variant="outline" className="text-xs px-3 py-1.5 h-auto">전체 보기</Button>
            </div>
            <Table headers={['시험명', '과목', '응시일', '상태', '점수', '액션']}>
              {[
                { title: '단원 평가: 미분과 적분', subject: '수학', date: '오늘 마감', status: Status.WAITING, score: null },
                { title: '2024 1학기 중간 성취도', subject: '수학', date: '2024.03.15', status: Status.COMPLETED, score: 92 },
                { title: '3월 기초 학력 진단', subject: '영어', date: '2024.03.10', status: Status.COMPLETED, score: 88 },
                { title: '과학 탐구 보고서 제출', subject: '과학', date: '진행 중', status: Status.IN_PROGRESS, score: null },
              ].map((exam, idx) => (
                <tr key={idx} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4 font-medium text-gray-900">
                    {exam.title}
                    {exam.status === Status.WAITING && <span className="ml-2 inline-block w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>}
                  </td>
                  <td className="px-6 py-4 text-gray-500">{exam.subject}</td>
                  <td className="px-6 py-4 text-gray-500">{exam.date}</td>
                  <td className="px-6 py-4"><StatusBadge status={exam.status} /></td>
                  <td className="px-6 py-4 font-bold text-gray-900">{exam.score ? `${exam.score}점` : '-'}</td>
                  <td className="px-6 py-4">
                    {exam.status === Status.WAITING ? (
                      <button 
                        onClick={() => setView('exam')}
                        className="bg-blue-600 hover:bg-blue-700 text-white text-xs px-3 py-1.5 rounded-md transition shadow-sm"
                      >
                        응시하기
                      </button>
                    ) : (
                      <button className="text-gray-500 hover:text-gray-800 text-xs font-medium border border-gray-300 px-3 py-1.5 rounded-md transition">결과보기</button>
                    )}
                  </td>
                </tr>
              ))}
            </Table>
          </div>
        </div>

        {/* Sidebar Widgets */}
        <div className="space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
              <Calendar size={20} className="text-blue-600" />
              학습 캘린더
            </h3>
            <ul className="space-y-4">
              <li className="flex gap-4 items-start">
                <div className="flex-shrink-0 w-14 text-center bg-blue-50 rounded-xl py-2 border border-blue-100">
                  <div className="text-xs text-blue-600 font-bold uppercase">3월</div>
                  <div className="text-xl font-bold text-gray-800">20</div>
                </div>
                <div>
                  <p className="font-bold text-gray-900">수학 단원 평가</p>
                  <p className="text-sm text-gray-500 mt-1 flex items-center gap-1"><Clock size={12}/> 14:00 - 15:00</p>
                </div>
              </li>
              <li className="flex gap-4 items-start">
                <div className="flex-shrink-0 w-14 text-center bg-gray-50 rounded-xl py-2 border border-gray-200">
                  <div className="text-xs text-gray-500 font-bold uppercase">3월</div>
                  <div className="text-xl font-bold text-gray-800">25</div>
                </div>
                <div>
                  <p className="font-medium text-gray-900">영어 듣기 평가</p>
                  <p className="text-sm text-gray-500 mt-1 flex items-center gap-1"><Clock size={12}/> 09:00 - 10:00</p>
                </div>
              </li>
            </ul>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
               <AlertCircle size={20} className="text-orange-500"/> AI 학습 코칭
            </h3>
            <div className="bg-orange-50 p-4 rounded-lg mb-4">
              <p className="text-orange-800 text-sm font-medium leading-relaxed">
                "지난 시험에서 <span className="underline decoration-orange-300">이차함수 그래프</span> 유형의 정답률이 낮습니다. 
                관련 개념 영상을 시청하고 유사 문제를 풀어보는 것을 추천해요!"
              </p>
            </div>
            <button className="w-full bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 py-2 rounded-lg text-sm font-medium transition">
              추천 문제 풀러 가기
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StudentDashboard;
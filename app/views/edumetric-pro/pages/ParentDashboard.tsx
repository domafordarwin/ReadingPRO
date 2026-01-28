import React, { useState } from 'react';
import { User, FileText, Bell, Activity, TrendingUp, ChevronDown, ChevronLeft, Download, Share2 } from 'lucide-react';
import { SectionHeader, StatCard, Table, StatusBadge } from '../components/UIComponents';
import { Status } from '../types';

const ReportDetailView: React.FC<{ onBack: () => void }> = ({ onBack }) => (
  <div className="max-w-4xl mx-auto animate-fade-in space-y-6">
    <button onClick={onBack} className="flex items-center text-gray-500 hover:text-blue-600 mb-4 transition">
      <ChevronLeft size={20} />
      <span>대시보드로 돌아가기</span>
    </button>

    <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden print:shadow-none">
       <div className="bg-slate-800 text-white p-8 flex justify-between items-start">
          <div>
            <span className="bg-blue-500 text-xs font-bold px-2 py-1 rounded mb-2 inline-block">2024년 3월</span>
            <h1 className="text-3xl font-bold mb-1">기초 학력 진단 리포트</h1>
            <p className="text-slate-400">학생: 김학생 (중2) | 응시일: 2024.03.15</p>
          </div>
          <div className="flex gap-2">
             <button className="p-2 bg-white/10 rounded hover:bg-white/20 transition"><Download size={20}/></button>
             <button className="p-2 bg-white/10 rounded hover:bg-white/20 transition"><Share2 size={20}/></button>
          </div>
       </div>

       <div className="p-8 space-y-8">
          {/* Summary */}
          <section>
             <h3 className="text-lg font-bold text-gray-800 mb-4 border-b pb-2">종합 의견</h3>
             <div className="bg-blue-50 p-6 rounded-xl border border-blue-100 text-blue-900 leading-relaxed">
               김학생은 수학 영역에서 <span className="font-bold">상위 5%</span>에 해당하는 뛰어난 성취를 보였습니다. 
               특히 도형과 기하 부분의 이해도가 매우 높습니다. 다만 영어 독해 속도가 다소 느린 편이므로, 
               다양한 지문을 읽는 연습이 필요합니다. 전반적인 학습 태도는 매우 훌륭합니다.
             </div>
          </section>

          {/* Scores */}
          <section>
             <h3 className="text-lg font-bold text-gray-800 mb-4 border-b pb-2">영역별 성취도</h3>
             <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="border border-gray-200 rounded-lg p-5 text-center">
                   <p className="text-gray-500 text-sm mb-1">수학</p>
                   <p className="text-3xl font-bold text-blue-600">92<span className="text-sm text-gray-400">/100</span></p>
                   <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded mt-2 inline-block">매우 우수</span>
                </div>
                <div className="border border-gray-200 rounded-lg p-5 text-center">
                   <p className="text-gray-500 text-sm mb-1">영어</p>
                   <p className="text-3xl font-bold text-green-600">88<span className="text-sm text-gray-400">/100</span></p>
                   <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded mt-2 inline-block">우수</span>
                </div>
                <div className="border border-gray-200 rounded-lg p-5 text-center">
                   <p className="text-gray-500 text-sm mb-1">과학</p>
                   <p className="text-3xl font-bold text-purple-600">95<span className="text-sm text-gray-400">/100</span></p>
                   <span className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded mt-2 inline-block">최우수</span>
                </div>
             </div>
          </section>

          {/* Radar Chart Placeholder */}
          <section>
             <h3 className="text-lg font-bold text-gray-800 mb-4 border-b pb-2">역량 분석 레이더</h3>
             <div className="bg-gray-50 h-64 rounded-xl border border-gray-200 flex items-center justify-center">
                <div className="text-center text-gray-400">
                   <Activity size={48} className="mx-auto mb-2 opacity-50"/>
                   <p>역량 분석 차트가 표시됩니다</p>
                </div>
             </div>
          </section>
       </div>
    </div>
  </div>
);

const ParentDashboard: React.FC = () => {
  const [view, setView] = useState<'dashboard' | 'report'>('dashboard');

  if (view === 'report') {
    return (
      <div className="p-6 bg-gray-50 min-h-screen">
        <ReportDetailView onBack={() => setView('dashboard')} />
      </div>
    );
  }

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 animate-fade-in">
      <SectionHeader 
        title="학부모 대시보드" 
        description="자녀의 학습 성장 과정과 학교 생활을 한눈에 확인하세요."
        actions={
          <button className="flex items-center gap-2 bg-white border border-gray-300 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 shadow-sm transition">
            <div className="w-6 h-6 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-xs">김</div>
            <span>김학생 (중2)</span>
            <ChevronDown size={16} className="text-gray-400" />
          </button>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="이번 달 학습 시간" value="42시간" icon={Activity} color="indigo" subtext="목표 달성률 95%" />
        <StatCard title="평균 성취도" value="상위 15%" icon={TrendingUp} color="green" subtext="안정적인 상위권 유지" />
        <StatCard title="새로운 리포트" value="1건" icon={FileText} color="blue" subtext="3월 수학 진단 결과" />
        <StatCard title="읽지 않은 알림" value="3건" icon={Bell} color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6">과목별 성취도 분석</h3>
          <div className="h-64 flex flex-col items-center justify-center bg-gray-50 rounded-xl border border-gray-100 text-gray-400 mb-6 relative overflow-hidden">
             {/* Simple visual representation of a chart */}
             <div className="absolute inset-0 flex items-end justify-around px-10 pb-10">
                <div className="w-12 bg-blue-200 h-[60%] rounded-t-md relative group"><span className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs text-gray-600 font-bold">80</span></div>
                <div className="w-12 bg-blue-400 h-[85%] rounded-t-md relative group"><span className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs text-gray-600 font-bold">92</span></div>
                <div className="w-12 bg-blue-300 h-[75%] rounded-t-md relative group"><span className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs text-gray-600 font-bold">88</span></div>
                <div className="w-12 bg-blue-500 h-[95%] rounded-t-md relative group"><span className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs text-gray-600 font-bold">98</span></div>
             </div>
             <div className="absolute bottom-4 w-full flex justify-around px-10 text-xs font-bold text-gray-500">
                <span>국어</span><span>수학</span><span>영어</span><span>과학</span>
             </div>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
              <div className="text-xs text-gray-500 font-bold mb-1">국어</div>
              <div className="font-bold text-gray-900 text-lg">B+</div>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg border border-blue-100">
              <div className="text-xs text-blue-600 font-bold mb-1">수학</div>
              <div className="font-bold text-gray-900 text-lg">A</div>
            </div>
            <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
              <div className="text-xs text-gray-500 font-bold mb-1">영어</div>
              <div className="font-bold text-gray-900 text-lg">A-</div>
            </div>
            <div className="p-3 bg-purple-50 rounded-lg border border-purple-100">
              <div className="text-xs text-purple-600 font-bold mb-1">과학</div>
              <div className="font-bold text-gray-900 text-lg">S</div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="p-5 border-b border-gray-200 bg-gray-50">
            <h3 className="text-lg font-bold text-gray-900">최근 진단 리포트</h3>
          </div>
          <div className="divide-y divide-gray-100">
            {[
              { name: '3월 수학 기초 진단', date: '2024.03.15', grade: '우수', status: Status.COMPLETED },
              { name: '1학기 영어 성취도', date: '2024.03.10', grade: '보통', status: Status.COMPLETED },
              { name: '과학 탐구 능력 평가', date: '2024.02.28', grade: '최우수', status: Status.COMPLETED },
            ].map((item, idx) => (
              <div key={idx} className="p-5 hover:bg-gray-50 transition">
                <div className="flex justify-between items-start mb-2">
                   <h4 className="font-semibold text-gray-900 text-sm">{item.name}</h4>
                   <span className="bg-green-100 text-green-700 text-xs px-2 py-0.5 rounded font-medium">{item.grade}</span>
                </div>
                <p className="text-xs text-gray-500 mb-3">응시일: {item.date}</p>
                <button 
                  onClick={() => setView('report')}
                  className="w-full py-2 border border-gray-200 rounded-lg text-xs font-medium text-gray-600 hover:bg-white hover:border-gray-300 hover:text-blue-600 transition"
                >
                   상세 리포트 보기
                </button>
              </div>
            ))}
          </div>
          <div className="p-4 bg-gray-50 border-t border-gray-200 text-center">
            <button className="text-sm font-medium text-gray-500 hover:text-gray-800">지난 기록 더보기</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ParentDashboard;
import React from 'react';
import { ArrowRight, BarChart2, Users, Shield, BookOpen, Check } from 'lucide-react';
import { Button } from '../components/UIComponents';

interface LandingPageProps {
  onStart: () => void;
}

const LandingPage: React.FC<LandingPageProps> = ({ onStart }) => {
  return (
    <div className="bg-white min-h-screen font-sans">
      {/* Navbar */}
      <nav className="border-b border-gray-100 sticky top-0 bg-white/90 backdrop-blur z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-lg">E</div>
            <span className="font-bold text-xl text-gray-900">EduMetric<span className="text-blue-600">Pro</span></span>
          </div>
          <div className="hidden md:flex gap-8 text-sm font-medium text-gray-600">
            <a href="#" className="hover:text-blue-600 transition">솔루션 소개</a>
            <a href="#" className="hover:text-blue-600 transition">주요 기능</a>
            <a href="#" className="hover:text-blue-600 transition">성공 사례</a>
            <a href="#" className="hover:text-blue-600 transition">문의하기</a>
          </div>
          <div className="flex gap-3">
             <button onClick={onStart} className="text-gray-600 hover:text-gray-900 font-medium text-sm">로그인</button>
             <Button onClick={onStart} className="text-sm">무료 체험</Button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative pt-24 pb-20 px-4 overflow-hidden">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-blue-50 rounded-full blur-3xl -z-10 opacity-60"></div>
        <div className="max-w-5xl mx-auto text-center">
          <span className="inline-block py-1 px-3 rounded-full bg-blue-100 text-blue-700 text-xs font-bold mb-6 tracking-wide uppercase">AI 기반 교육 진단 플랫폼</span>
          <h1 className="text-5xl md:text-6xl font-extrabold text-gray-900 tracking-tight mb-8 leading-tight">
            데이터로 증명하는 <span className="text-blue-600">교육의 질</span>,<br />
            에듀메트릭 프로
          </h1>
          <p className="text-xl text-gray-600 mb-10 max-w-2xl mx-auto leading-relaxed">
            학생의 성취도를 정밀하게 분석하고, 교사의 업무를 자동화하며, <br className="hidden md:block" />
            학교와 가정의 완벽한 소통을 지원합니다.
          </p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <button 
              onClick={onStart}
              className="px-8 py-4 bg-blue-600 text-white rounded-xl font-bold text-lg hover:bg-blue-700 transition shadow-lg hover:shadow-blue-200/50 flex items-center justify-center gap-2"
            >
              시작하기 <ArrowRight size={20} />
            </button>
            <button className="px-8 py-4 bg-white text-gray-700 border border-gray-200 rounded-xl font-bold text-lg hover:bg-gray-50 transition flex items-center justify-center">
              데모 영상 보기
            </button>
          </div>
          
          <div className="mt-16 flex justify-center gap-8 text-gray-400 grayscale opacity-70">
             {/* Fake Logos for social proof */}
             <div className="font-bold text-xl">서울대학교</div>
             <div className="font-bold text-xl">KAIST</div>
             <div className="font-bold text-xl">연세대학교</div>
             <div className="font-bold text-xl">교육부</div>
          </div>
        </div>
      </section>

      {/* Feature Grid */}
      <section className="py-24 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">모든 교육 주체를 위한 맞춤형 설계</h2>
            <p className="text-gray-500 max-w-2xl mx-auto">하나의 플랫폼에서 학생, 학부모, 교사, 관리자가 유기적으로 연결됩니다.</p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition duration-300">
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center text-blue-600 mb-6">
                <BarChart2 size={24} />
              </div>
              <h3 className="text-xl font-bold mb-3">정밀 진단</h3>
              <p className="text-gray-500 leading-relaxed text-sm">
                IRT(문항반응이론) 기반 알고리즘으로 학생의 실력을 정확히 측정합니다.
              </p>
            </div>
            <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition duration-300">
              <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center text-green-600 mb-6">
                <Users size={24} />
              </div>
              <h3 className="text-xl font-bold mb-3">소통 강화</h3>
              <p className="text-gray-500 leading-relaxed text-sm">
                실시간 리포트 공유로 가정과 학교 간의 정보 격차를 해소합니다.
              </p>
            </div>
            <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition duration-300">
              <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center text-indigo-600 mb-6">
                <BookOpen size={24} />
              </div>
              <h3 className="text-xl font-bold mb-3">문항 뱅크</h3>
              <p className="text-gray-500 leading-relaxed text-sm">
                10만 건 이상의 검증된 문항 데이터베이스를 활용해 평가를 구성하세요.
              </p>
            </div>
            <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition duration-300">
              <div className="w-12 h-12 bg-slate-100 rounded-xl flex items-center justify-center text-slate-600 mb-6">
                <Shield size={24} />
              </div>
              <h3 className="text-xl font-bold mb-3">보안 및 관리</h3>
              <p className="text-gray-500 leading-relaxed text-sm">
                역할 기반 접근 제어(RBAC)와 데이터 암호화로 정보를 안전하게 보호합니다.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-gray-900 text-white">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">교육의 미래를 경험할 준비가 되셨나요?</h2>
          <p className="text-gray-400 mb-10 text-lg">복잡한 설치 없이 웹에서 바로 시작할 수 있습니다.</p>
          <button 
            onClick={onStart}
            className="px-10 py-4 bg-blue-600 text-white rounded-full font-bold text-lg hover:bg-blue-500 transition shadow-lg hover:shadow-blue-900/50"
          >
            무료로 시작하기
          </button>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-white py-12 border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
             <div className="flex items-center gap-2">
                <div className="w-6 h-6 bg-gray-200 rounded flex items-center justify-center text-gray-500 font-bold text-xs">E</div>
                <span className="font-bold text-lg text-gray-800">EduMetric Pro</span>
             </div>
             <p className="text-gray-500 text-sm">© 2024 EduMetric Pro. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;
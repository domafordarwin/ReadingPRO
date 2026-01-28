import React, { ReactNode } from 'react';
import { LucideIcon } from 'lucide-react';

// --- Card Components ---

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color: string;
  subtext?: string;
}

export const StatCard: React.FC<StatCardProps> = ({ title, value, icon: Icon, color, subtext }) => {
  const colorClasses: Record<string, string> = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    yellow: 'bg-yellow-50 text-yellow-600',
    purple: 'bg-purple-50 text-purple-600',
    red: 'bg-red-50 text-red-600',
    slate: 'bg-slate-50 text-slate-600',
    indigo: 'bg-indigo-50 text-indigo-600',
    orange: 'bg-orange-50 text-orange-600',
  };

  return (
    <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-start justify-between hover:shadow-md transition-shadow">
      <div>
        <p className="text-sm font-medium text-gray-500 mb-1">{title}</p>
        <h3 className="text-2xl font-bold text-gray-900">{value}</h3>
        {subtext && <p className="text-xs text-gray-400 mt-1">{subtext}</p>}
      </div>
      <div className={`p-3 rounded-lg ${colorClasses[color] || colorClasses.blue}`}>
        <Icon size={24} />
      </div>
    </div>
  );
};

export const QuickActionCard: React.FC<{ title: string; icon: LucideIcon; onClick?: () => void; color?: string }> = ({ 
  title, 
  icon: Icon, 
  onClick,
  color = 'indigo'
}) => (
  <button 
    onClick={onClick}
    className={`flex flex-col items-center justify-center p-6 bg-white border border-gray-200 rounded-xl shadow-sm hover:shadow-md hover:border-${color}-300 transition-all group w-full`}
  >
    <div className={`p-4 rounded-full bg-${color}-50 text-${color}-600 group-hover:scale-110 transition-transform mb-3`}>
      <Icon size={28} />
    </div>
    <span className="font-semibold text-gray-700 group-hover:text-gray-900">{title}</span>
  </button>
);

// --- Table Components ---

interface BadgeProps {
  status: string;
}

export const StatusBadge: React.FC<BadgeProps> = ({ status }) => {
  let styles = 'bg-gray-100 text-gray-800';
  
  // Korean Status Mapping
  switch (status) {
    case '완료':
    case '정상':
    case '활성':
    case '발행됨':
      styles = 'bg-green-100 text-green-800 border-green-200';
      break;
    case '진행 중':
    case '검토 중':
      styles = 'bg-blue-100 text-blue-800 border-blue-200';
      break;
    case '대기':
    case '보류':
    case '저하':
      styles = 'bg-yellow-100 text-yellow-800 border-yellow-200';
      break;
    case '중단':
    case '비활성':
    case '초안':
      styles = 'bg-gray-100 text-gray-600 border-gray-200';
      break;
    case '피드백 대기':
      styles = 'bg-purple-100 text-purple-800 border-purple-200';
      break;
    default:
      styles = 'bg-gray-100 text-gray-800';
  }

  return (
    <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium border ${styles}`}>
      {status}
    </span>
  );
};

export const Table: React.FC<{ headers: string[]; children: ReactNode }> = ({ headers, children }) => (
  <div className="overflow-x-auto bg-white rounded-lg shadow-sm border border-gray-200">
    <table className="min-w-full divide-y divide-gray-200">
      <thead className="bg-gray-50">
        <tr>
          {headers.map((header, idx) => (
            <th key={idx} scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              {header}
            </th>
          ))}
        </tr>
      </thead>
      <tbody className="bg-white divide-y divide-gray-200">
        {children}
      </tbody>
    </table>
  </div>
);

// --- Layout Components ---

export const SectionHeader: React.FC<{ title: string; description?: string; actions?: ReactNode }> = ({ title, description, actions }) => (
  <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 gap-4">
    <div>
      <h2 className="text-2xl font-bold text-gray-900">{title}</h2>
      {description && <p className="text-sm text-gray-500 mt-1">{description}</p>}
    </div>
    <div className="flex gap-3">
      {actions}
    </div>
  </div>
);

export const Button: React.FC<React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'secondary' | 'danger' | 'outline' }> = ({ 
  children, 
  variant = 'primary', 
  className = '', 
  ...props 
}) => {
  const variants = {
    primary: 'bg-blue-600 hover:bg-blue-700 text-white shadow-sm',
    secondary: 'bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 shadow-sm',
    danger: 'bg-red-600 hover:bg-red-700 text-white shadow-sm',
    outline: 'bg-transparent border border-blue-600 text-blue-600 hover:bg-blue-50'
  };

  return (
    <button 
      className={`px-4 py-2 rounded-lg font-medium transition-colors text-sm flex items-center justify-center gap-2 ${variants[variant]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};
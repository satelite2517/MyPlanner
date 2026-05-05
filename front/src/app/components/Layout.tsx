import { Outlet, Link, useLocation } from 'react-router';
import { Calendar, CalendarDays, List, Settings } from 'lucide-react';
import { useApp } from '../context/AppContext';

export default function Layout() {
  const location = useLocation();
  const { language } = useApp();

  const navItems = [
    { path: '/', icon: CalendarDays, label: language === 'ko' ? '주간' : 'Weekly' },
    { path: '/monthly', icon: Calendar, label: language === 'ko' ? '월간' : 'Monthly' },
    { path: '/list', icon: List, label: language === 'ko' ? '리스트' : 'List' },
    { path: '/settings', icon: Settings, label: language === 'ko' ? '설정' : 'Settings' },
  ];

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>

      <nav className="border-t bg-white">
        <div className="flex justify-around items-center h-20 max-w-md mx-auto px-4">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                  isActive ? 'text-blue-600' : 'text-gray-600'
                }`}
              >
                <Icon size={24} />
                <span className="text-xs">{item.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}

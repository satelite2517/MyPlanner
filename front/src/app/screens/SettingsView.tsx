import { User, Globe, Bell, Info } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/translations';

export default function SettingsView() {
  const { language, setLanguage } = useApp();
  const t = useTranslation(language);

  return (
    <div className="h-full flex flex-col bg-white">
      <header className="px-6 py-6 border-b sticky top-0 bg-white z-10">
        <h1 className="text-2xl">{t.settings}</h1>
      </header>

      <div className="flex-1 overflow-auto">
        <div className="max-w-md mx-auto px-4 py-6">
          <div className="space-y-6">
            <section className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
              <h2 className="text-xs uppercase text-gray-500 px-4 pt-4 pb-2">
                {language === 'ko' ? '계정' : 'Account'}
              </h2>
              <button className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors">
                <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                  <User size={20} className="text-white" />
                </div>
                <div className="flex-1 text-left">
                  <p className="text-sm">user@example.com</p>
                  <p className="text-xs text-gray-500">
                    {language === 'ko' ? '프로필 보기' : 'View Profile'}
                  </p>
                </div>
              </button>
            </section>

            <section className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
              <h2 className="text-xs uppercase text-gray-500 px-4 pt-4 pb-2">
                {language === 'ko' ? '환경설정' : 'Preferences'}
              </h2>

              <div className="border-t border-gray-100">
                <div className="flex items-center gap-3 px-4 py-3">
                  <Globe size={20} className="text-gray-600" />
                  <span className="flex-1 text-sm">
                    {language === 'ko' ? '언어' : 'Language'}
                  </span>
                  <select
                    value={language}
                    onChange={(e) => setLanguage(e.target.value as 'ko' | 'en')}
                    className="text-sm border border-gray-300 rounded-lg px-3 py-1.5"
                  >
                    <option value="ko">한국어</option>
                    <option value="en">English</option>
                  </select>
                </div>
              </div>

              <div className="border-t border-gray-100">
                <button className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors">
                  <Bell size={20} className="text-gray-600" />
                  <span className="flex-1 text-left text-sm">
                    {language === 'ko' ? '알림' : 'Notifications'}
                  </span>
                  <div className="w-10 h-6 bg-blue-500 rounded-full relative">
                    <div className="absolute right-0.5 top-0.5 w-5 h-5 bg-white rounded-full"></div>
                  </div>
                </button>
              </div>
            </section>

            <section className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
              <h2 className="text-xs uppercase text-gray-500 px-4 pt-4 pb-2">
                {language === 'ko' ? '정보' : 'About'}
              </h2>

              <div className="border-t border-gray-100">
                <button className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors">
                  <Info size={20} className="text-gray-600" />
                  <span className="flex-1 text-left text-sm">
                    {language === 'ko' ? '앱 정보' : 'App Info'}
                  </span>
                  <span className="text-xs text-gray-400">v1.0.0</span>
                </button>
              </div>
            </section>

            <section className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
              <h2 className="text-xs uppercase text-gray-500 px-4 pt-4 pb-2">
                {language === 'ko' ? '연동' : 'Integration'}
              </h2>

              <div className="border-t border-gray-100">
                <button className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors">
                  <div className="w-5 h-5 bg-gradient-to-br from-purple-500 to-pink-500 rounded"></div>
                  <span className="flex-1 text-left text-sm">
                    {language === 'ko' ? 'iPhone 미리알림 연동' : 'iPhone Reminders Sync'}
                  </span>
                  <span className="text-xs text-gray-400">
                    {language === 'ko' ? '곧 출시' : 'Coming Soon'}
                  </span>
                </button>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}

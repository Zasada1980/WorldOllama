import { ArrowLeft, Building2, Database, DollarSign, Lock, Search, Sparkles, Zap } from 'lucide-react';
import React, { useState } from 'react';
import { flushSync } from 'react-dom';

// Переводы для 3 языков
const translations = {
  he: {
    title: "בדיקת חברות בישראל",
    subtitle: "קבל דוח מלא על כל חברה תוך 2 דקות",
    searchPlaceholder: "הזן מספר ח.פ או שם חברה",
    searchButton: "חפש",
    features: {
      fast: { title: "מהיר", desc: "2 דקות במקום 2 שעות" },
      sources: { title: "6 מקורות", desc: "נתונים ממרשם החברות ועוד" },
      affordable: { title: "משתלם", desc: "₪139-₪499 במקום ₪200+" }
    },
    aiAnalysis: "ניתוח AI",
    aiButton: "קבל ניתוח חכם",
    backToSearch: "חזרה לחיפוש",
    login: "כניסה",
    register: "הרשמה",
    email: "אימייל",
    password: "סיסמה",
    forgotPassword: "שכחת סיסמה?",
    noAccount: "אין לך חשבון?",
    haveAccount: "יש לך חשבון?",
    close: "סגור",
    searchHistory: "היסטוריית חיפושים",
    clearHistory: "נקה היסטוריה",
    noHistory: "אין חיפושים קודמים",
    aboutTitle: "אודותינו",
    aboutText: "אנחנו מספקים מידע מהיר ומדויק על חברות ישראליות. השירות שלנו מאגד נתונים מ-6 מקורות רשמיים ומספק ניתוח AI מתקדם.",
    pricingTitle: "בחר את התוכנית המתאימה לך",
    nav: { search: "חיפוש", pricing: "מחירים", about: "אודות" }
  },
  en: {
    title: "Check Israeli Companies",
    subtitle: "Get full company report in 2 minutes",
    searchPlaceholder: "Enter Company ID (ח.פ) or Name",
    searchButton: "Search",
    features: {
      fast: { title: "Fast", desc: "2 minutes instead of 2 hours" },
      sources: { title: "6 Sources", desc: "Data from company registry, etc." },
      affordable: { title: "Affordable", desc: "₪139-₪499 instead of ₪200+" }
    },
    aiAnalysis: "AI Analysis",
    aiButton: "Get Smart Analysis",
    backToSearch: "Back to search",
    login: "Login",
    register: "Register",
    email: "Email",
    password: "Password",
    forgotPassword: "Forgot password?",
    noAccount: "Don't have an account?",
    haveAccount: "Already have an account?",
    close: "Close",
    searchHistory: "Search History",
    clearHistory: "Clear History",
    noHistory: "No previous searches",
    aboutTitle: "About Us",
    aboutText: "We provide fast and accurate information about Israeli companies. Our service aggregates data from 6 official sources and provides advanced AI analysis.",
    pricingTitle: "Choose Your Plan",
    nav: { search: "Search", pricing: "Pricing", about: "About" }
  },
  ru: {
    title: "Проверка израильских компаний",
    subtitle: "Получите полный отчёт о компании за 2 минуты",
    searchPlaceholder: "Введите ח.פ или название компании",
    searchButton: "Искать",
    features: {
      fast: { title: "Быстро", desc: "2 минуты вместо 2 часов" },
      sources: { title: "6 источников", desc: "Данные из реестра компаний и др." },
      affordable: { title: "Выгодно", desc: "₪139-₪499 вместо ₪200+" }
    },
    aiAnalysis: "AI анализ",
    aiButton: "Получить умный анализ",
    backToSearch: "Назад к поиску",
    login: "Войти",
    register: "Регистрация",
    email: "Email",
    password: "Пароль",
    forgotPassword: "Забыли пароль?",
    noAccount: "Нет аккаунта?",
    haveAccount: "Уже есть аккаунт?",
    close: "Закрыть",
    searchHistory: "История поиска",
    clearHistory: "Очистить историю",
    noHistory: "Нет предыдущих поисков",
    aboutTitle: "О нас",
    aboutText: "Мы предоставляем быструю и точную информацию об израильских компаниях. Наш сервис объединяет данные из 6 официальных источников и предоставляет продвинутый AI анализ.",
    pricingTitle: "Выберите свой план",
    nav: { search: "Поиск", pricing: "Цены", about: "О нас" }
  }
};

// TypeScript интерфейс для данных компании
interface Company {
  companyId: string;
  name: {
    he: string;
    en: string;
    ru: string;
  };
  status: string;
  registrationDate: string;
  address: string;
  capital: number;
}

export default function App({ onAdminLogin, isAdmin = false, onOpenAdminPanel }: { onAdminLogin?: (password: string) => boolean; isAdmin?: boolean; onOpenAdminPanel?: () => void }) {
  const [locale, setLocale] = useState<'he' | 'en' | 'ru'>('en');
  const [view, setView] = useState<'home' | 'preview' | 'admin'>('home');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCompany, setSelectedCompany] = useState<Company | null>(null);
  const [aiAnalysis, setAiAnalysis] = useState<string | null>(null);
  const [isLoadingAI, setIsLoadingAI] = useState(false);
  const [aiCache, setAiCache] = useState<Record<string, string>>({}); // Кеш AI-анализов
  const [showLoginModal, setShowLoginModal] = useState(false);
  const [isRegisterMode, setIsRegisterMode] = useState(false);
  const [showAboutModal, setShowAboutModal] = useState(false);
  const [showPricingModal, setShowPricingModal] = useState(false);
  const [searchHistory, setSearchHistory] = useState<string[]>([]);
  const [_showHistory, setShowHistory] = useState(false);
  const [isSearching, setIsSearching] = useState(false);

  const t = translations[locale];
  const isRTL = locale === 'he';

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;

    // Force synchronous state update for E2E test reliability
    flushSync(() => {
      setIsSearching(true);
    });
    
    setAiAnalysis(null);
    
    try {
      // Попробуем несколько API endpoints для лучшего покрытия
      const resourceIds = [
        'f004176c-b85f-4542-8901-7b3176f9a054', // Основной реестр компаний
        '1adb23e3-e6e1-4a83-bf8d-a0d85e71b7cb', // Альтернативный источник
      ];
      
      let foundData = null;
      
      for (const resourceId of resourceIds) {
        const apiUrl = `https://data.gov.il/api/3/action/datastore_search?resource_id=${resourceId}&q=${encodeURIComponent(searchQuery)}&limit=10`;
        
        console.log(`Trying API with resource: ${resourceId}`);
        
        try {
          const response = await fetch(apiUrl, {
            method: 'GET',
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'CompanyCheck/1.0'
            }
          });
          
          if (response.ok) {
            const data = await response.json();
            console.log(`API Response (${resourceId}):`, data);
            console.log('Records found:', data.result?.records?.length || 0);
            
            if (data.success && data.result?.records?.length > 0) {
              foundData = data.result.records[0];
              console.log('Found record:', foundData);
              break; // Нашли данные, выходим из цикла
            }
          }
        } catch (err) {
          console.warn(`Failed to fetch from resource ${resourceId}:`, err);
          continue; // Пробуем следующий источник
        }
      }
      
      if (foundData) {
        const record = foundData;
        
        // Подробное логирование для отладки
        console.log('📋 Extracting company data:');
        console.log('  Company ID:', record['מספר חברה'] || record['מספר_חברה']);
        console.log('  Name (HE):', record['שם חברה'] || record['שם_חברה']);
        console.log('  Name (EN):', record['שם באנגלית'] || record['שם_חברה_אנגלית']);
        console.log('  Status:', record['סטטוס חברה'] || record['סטטוס_חברה']);
        console.log('  Registration Date:', record['תאריך התאגדות'] || record['תאריך_רישום']);
        console.log('  All fields:', Object.keys(record));
        
        // Функция для исправления искажённых символов
        const fixEncoding = (text: string | undefined | null): string => {
          if (!text) return '';
          return text
            .replace(/~/g, '"')  // Исправление בע~מ → בע"מ
            .replace(/�/g, '"')  // Исправление других искажений
            .trim();
        };
        
        // Построить адрес из отдельных полей
        const addressParts = [
          record['שם רחוב'],
          record['מספר בית'],
          record['שם עיר'],
          record['מיקוד']
        ].filter(Boolean);
        const fullAddress = addressParts.length > 0 ? addressParts.join(', ') : 'N/A';
        
        const company = {
          companyId: record['מספר חברה'] || record['מספר_חברה'] || searchQuery,
          name: {
            he: fixEncoding(record['שם חברה'] || record['שם_חברה']) || 'חברה לא ידועה',
            en: fixEncoding(record['שם באנגלית'] || record['שם_חברה_אנגלית'] || record['שם חברה'] || record['שם_חברה']) || 'Unknown Company',
            ru: fixEncoding(record['שם באנגלית'] || record['שם_חברה_אנגלית'] || record['שם חברה'] || record['שם_חברה']) || 'Неизвестная компания'
          },
          status: record['סטטוס חברה'] === 'פעילה' ? 'Active' : 
                 record['סטטוס חברה'] || record['סטטוס_חברה'] || 'Unknown',
          registrationDate: record['תאריך התאגדות'] || record['תאריך_רישום'] || 'N/A',
          address: fullAddress,
          capital: parseInt(record['הון רשום'] || record['הון_רשום'] || '0') || 0
        };
        
        console.log('✅ Company object created:', company);
        setSelectedCompany(company);
        
        setView('preview');
        
        // Добавить в историю
        if (!searchHistory.includes(searchQuery)) {
          setSearchHistory(prev => [searchQuery, ...prev].slice(0, 10));
        }
        
        setIsSearching(false);
        return;
      }
      
      // Не найдено в API
      console.log('No records found in any API source');
      throw new Error('No results found in official databases');
      
    } catch (error) {
      console.error('Search error:', error);
      setIsSearching(false);
      
      // Реалистичное сообщение об ошибке (БЕЗ демо-данных)
      
      
      const errorMsg = locale === 'he'
        ? `мידע על החברה לא נמצא במאגרי המידע הרשמיים.\n\nסיבות אפשריות:\n• החברה לא רשומה בישראל\n• מספר החברה שגוי\n• הנתונים טרם עודכנו במאגר הממשלתי\n\nנסה:\n• בדוק את מספר החברה\n• חפש לפי שם החברה בעברית\n• השתמש במקורות נתונים אחרים`
        : locale === 'ru'
        ? `Информация о компании не найдена в официальных базах данных.\n\nВозможные причины:\n• Компания не зарегистрирована в Израиле\n• Номер компании указан неверно\n• Данные еще не загружены в государственный реестр\n\nПопробуйте:\n• Проверить правильность номера компании\n• Искать по названию компании на иврите\n• Использовать другие источники данных`
        : `Company information not found in official databases.\n\nPossible reasons:\n• Company not registered in Israel\n• Incorrect company number\n• Data not yet updated in government registry\n\nTry:\n• Verify the company number\n• Search by Hebrew company name\n• Use alternative data sources`;
      
      alert(errorMsg);
    }
    
  };

  const handleAIAnalysis = async () => {
    if (!selectedCompany) return;
    
    // Проверка кеша (не запрашиваем дважды для одной компании)
    const cacheKey = selectedCompany.companyId;
    if (aiCache[cacheKey]) {
      setAiAnalysis(aiCache[cacheKey]);
      return;
    }
    
    // Защита от спама (если уже загружается)
    if (isLoadingAI) {
      return;
    }
    
    setIsLoadingAI(true);
    
    // Small delay to ensure E2E tests can detect loading state
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Gemini API ключ (обновлён 08.12.2025)
    const apiKey = "AIzaSyDv1PUz-lU-1wVFTR2-6I-cQcO4t3zNyBY";
    
    if (!apiKey) {
      alert('Please add your Gemini API key in App.tsx (line 93)');
      setIsLoadingAI(false);
      return;
    }

    const prompt = `Analyze this Israeli company and provide business insights:
    
Company: ${selectedCompany?.name.en}
ID: ${selectedCompany?.companyId}
Status: ${selectedCompany?.status}
Registration: ${selectedCompany?.registrationDate}
Address: ${selectedCompany?.address}
Capital: ₪${selectedCompany?.capital}

Provide: 1) Business risk assessment 2) Market position 3) Financial health indicators 4) Recommendations for partnerships`;

    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`,
        {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'X-goog-api-key': apiKey
          },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }]
          })
        }
      );

      const data = await response.json();
      
      // Проверка ошибки 429 (Too Many Requests)
      if (response.status === 429) {
        const errorMsg = '⚠️ Too many requests. Please wait 1 minute and try again. (Free tier: 15 requests/minute)';
        setAiAnalysis(errorMsg);
        return;
      }
      
      const analysisText = data.candidates?.[0]?.content?.parts?.[0]?.text || 'Analysis unavailable';
      
      // Сохранение в кеш
      setAiCache(prev => ({ ...prev, [cacheKey]: analysisText }));
      setAiAnalysis(analysisText);
    } catch (error) {
      console.error('AI Error:', error);
      setAiAnalysis('AI analysis failed. Check API key and internet connection.');
    } finally {
      setIsLoadingAI(false);
    }
  };

  // Админ-логин (тройной клик на логотип) - ОПТИМИЗИРОВАНО
  const [logoClickCount, setLogoClickCount] = useState(0);
  const logoClickTimeoutRef = React.useRef<number | null>(null);
  const [showAdminPasswordModal, setShowAdminPasswordModal] = useState(false);
  const [adminPasswordInput, setAdminPasswordInput] = useState('');
  
  const handleLogoClick = React.useCallback(() => {
    setLogoClickCount(prev => {
      const newCount = prev + 1;
      if (newCount >= 3) {
        if (isAdmin && onOpenAdminPanel) {
          // Админ уже авторизован → открываем панель БЕЗ пароля
          setShowAdminPasswordModal(false);  // Закрываем модал если был открыт
          onOpenAdminPanel();
        } else if (onAdminLogin) {
          // Не админ → показываем модал пароля
          setShowAdminPasswordModal(true);
        }
        return 0; // Сброс счётчика
      }
      return newCount;
    });
    
    // Очистка предыдущего таймера
    if (logoClickTimeoutRef.current) {
      clearTimeout(logoClickTimeoutRef.current);
    }
    
    // Сброс через 2 секунды
    logoClickTimeoutRef.current = setTimeout(() => {
      setLogoClickCount(0);
    }, 2000);
  }, [isAdmin, onAdminLogin, onOpenAdminPanel]);

  const handleAdminPasswordSubmit = React.useCallback((e: React.FormEvent) => {
    e.preventDefault();
    if (onAdminLogin && adminPasswordInput) {
      const success = onAdminLogin(adminPasswordInput);
      if (success) {
        setShowAdminPasswordModal(false);
        setAdminPasswordInput('');
        alert('✅ Admin access granted!');
      } else {
        alert('❌ Invalid password');
        setAdminPasswordInput(''); // Очистка для повторной попытки
      }
    }
  }, [onAdminLogin, adminPasswordInput]);



  // Оптимизированный submit handler для login form (исправление Chrome DevTools warning)
  const handleLoginSubmit = React.useCallback((e: React.FormEvent) => {
    e.preventDefault();
    // Regular login not implemented - just close modal
    setShowLoginModal(false);
  }, []);

  // Navigation handlers (НОВЫЕ - устранение Violation warnings)
  const handleGoHome = React.useCallback(() => {
    setView('home');
  }, []);

  const handleShowPricingModal = React.useCallback(() => {
    setShowPricingModal(true);
  }, []);

  const handleHidePricingModal = React.useCallback(() => {
    setShowPricingModal(false);
  }, []);

  const handleShowAboutModal = React.useCallback(() => {
    setShowAboutModal(true);
  }, []);

  const handleHideAboutModal = React.useCallback(() => {
    setShowAboutModal(false);
  }, []);

  const handleShowLoginModal = React.useCallback(() => {
    setShowLoginModal(true);
  }, []);

  const handleHideLoginModal = React.useCallback(() => {
    setShowLoginModal(false);
  }, []);

  // Locale handlers (НОВЫЕ - для map в языковых кнопках)
  const handleSetLocaleHe = React.useCallback(() => {
    setLocale('he');
  }, []);

  const handleSetLocaleEn = React.useCallback(() => {
    setLocale('en');
  }, []);

  const handleSetLocaleRu = React.useCallback(() => {
    setLocale('ru');
  }, []);

  // History handlers (НОВЫЕ)
  // @ts-expect-error - Used in future implementation
  const _handleClearHistory = React.useCallback(() => {
    setSearchHistory([]);
  }, []);

  // @ts-expect-error - Used in future implementation
  const _handleHistoryItemClick = React.useCallback((query: string) => {
    setSearchQuery(query);
    setShowHistory(false);
  }, []);

  // Modal handlers (НОВЫЕ - e.stopPropagation)
  const handleModalContentClick = React.useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
  }, []);

  // Register mode toggle (НОВЫЙ)
  const handleToggleRegisterMode = React.useCallback(() => {
    setIsRegisterMode(!isRegisterMode);
  }, [isRegisterMode]);



  return (
    <div className={`min-h-screen bg-gray-50 ${isRTL ? 'rtl' : 'ltr'}`} dir={isRTL ? 'rtl' : 'ltr'}>
      
      {/* HEADER */}
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2 cursor-pointer" onClick={handleLogoClick}>
            <Building2 className="w-6 h-6 text-blue-600" />
            <span className="text-lg font-semibold text-blue-600">CompanyCheck</span>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm text-gray-700">
            <button onClick={handleGoHome} className="flex items-center gap-2 hover:text-gray-900 cursor-pointer">
              <Search className="w-4 h-4" />
              {t.nav.search}
            </button>
            <button onClick={handleShowPricingModal} className="hover:text-gray-900 cursor-pointer">{t.nav.pricing}</button>
            <button onClick={handleShowAboutModal} className="hover:text-gray-900 cursor-pointer">{t.nav.about}</button>
          </nav>

          <div className="flex items-center gap-4">
            {/* Admin badge + button to open panel */}
            {isAdmin && (
              <button 
                onClick={onOpenAdminPanel}
                className="flex items-center gap-2 bg-gradient-to-r from-red-600 to-red-700 text-white px-4 py-2 rounded-lg text-xs font-semibold hover:from-red-700 hover:to-red-800 transition-all shadow-md cursor-pointer"
              >
                <Lock className="w-3 h-3" />
                ADMIN PANEL
              </button>
            )}
            
            <div className="flex items-center gap-1 text-sm">
              <button
                onClick={handleSetLocaleHe}
                className={`px-2 py-1 cursor-pointer ${locale === 'he' ? 'text-blue-600 font-semibold' : 'text-gray-500 hover:text-gray-700'}`}
              >
                HE
              </button>
              <button
                onClick={handleSetLocaleEn}
                className={`px-2 py-1 cursor-pointer ${locale === 'en' ? 'text-blue-600 font-semibold' : 'text-gray-500 hover:text-gray-700'}`}
              >
                EN
              </button>
              <button
                onClick={handleSetLocaleRu}
                className={`px-2 py-1 cursor-pointer ${locale === 'ru' ? 'text-blue-600 font-semibold' : 'text-gray-500 hover:text-gray-700'}`}
              >
                RU
              </button>
            </div>
            
            <button onClick={handleShowLoginModal} className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 cursor-pointer">
              {t.login}
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-6 py-16">
        
        {view === 'home' && (
          <div className="text-center">
            <h1 className="text-5xl font-bold text-gray-900 mb-4">{t.title}</h1>
            <p className="text-xl text-gray-600 mb-12">{t.subtitle}</p>

            <form onSubmit={handleSearch} className="relative max-w-2xl mx-auto">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onFocus={() => setShowHistory(searchHistory.length > 0)}
                onBlur={() => setTimeout(() => setShowHistory(false), 200)}
                placeholder={t.searchPlaceholder}
                className={`w-full h-14 px-5 ${isRTL ? 'pr-28' : 'pl-5 pr-28'} text-base bg-white border-2 border-gray-300 rounded-full focus:border-blue-600 focus:outline-none transition-colors`}
              />
              <button 
                type="submit"
                disabled={isSearching}
                className={`absolute ${isRTL ? 'left-1' : 'right-1'} top-1 bottom-1 px-6 bg-blue-600 text-white rounded-full font-medium hover:bg-blue-700 transition-colors flex items-center gap-2 z-10 cursor-pointer disabled:opacity-50`}
              >
                <Search className="w-5 h-5" />
                {isSearching ? 'Searching...' : t.searchButton}
              </button>
            </form>
            
            {/* Searching indicator for E2E test */}
            {isSearching && (
              <div className="text-center mt-4 text-blue-600 font-semibold animate-pulse">
                Searching...
              </div>
            )}

            <div className="grid md:grid-cols-3 gap-6">
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <Zap className="w-10 h-10 text-blue-600 mx-auto mb-4" />
                <h3 className="text-lg font-semibold mb-2 text-gray-900">{t.features.fast.title}</h3>
                <p className="text-gray-600 text-sm">{t.features.fast.desc}</p>
              </div>
              
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <Database className="w-10 h-10 text-blue-600 mx-auto mb-4" />
                <h3 className="text-lg font-semibold mb-2 text-gray-900">{t.features.sources.title}</h3>
                <p className="text-gray-600 text-sm">{t.features.sources.desc}</p>
              </div>
              
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <DollarSign className="w-10 h-10 text-blue-600 mx-auto mb-4" />
                <h3 className="text-lg font-semibold mb-2 text-gray-900">{t.features.affordable.title}</h3>
                <p className="text-gray-600 text-sm">{t.features.affordable.desc}</p>
              </div>
            </div>
          </div>
        )}

        {view === 'preview' && selectedCompany && (
          <div>
            <button onClick={handleGoHome} className="mb-6 text-gray-600 hover:text-gray-900 text-sm flex items-center gap-2">
              <ArrowLeft className="w-4 h-4" />
              {t.backToSearch}
            </button>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 mb-8">
              <div className="flex items-start gap-4 mb-6 pb-6 border-b">
                <div className="w-14 h-14 bg-blue-100 rounded-xl flex items-center justify-center text-2xl">
                  🏢
                </div>
                <div>
                  <h1 className="text-2xl font-bold text-gray-900 mb-1">
                    {selectedCompany.name[locale]}
                  </h1>
                  <p className="text-gray-600">{selectedCompany.companyId}</p>
                </div>
              </div>

              <div className="grid md:grid-cols-2 gap-8 mb-8">
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between py-2 border-b">
                    <span className="text-gray-600">Status</span>
                    <span className="font-medium bg-green-100 text-green-800 px-2 py-0.5 rounded text-xs">{selectedCompany.status}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b">
                    <span className="text-gray-600">Registration Date</span>
                    <span className="font-medium">{selectedCompany.registrationDate}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b">
                    <span className="text-gray-600">Address</span>
                    <span className="font-medium">{selectedCompany.address}</span>
                  </div>
                  <div className="flex justify-between py-2">
                    <span className="text-gray-600">Capital</span>
                    <span className="font-medium">₪{selectedCompany.capital.toLocaleString()}</span>
                  </div>
                </div>

                <div className="relative">
                  <h2 className="text-sm font-semibold text-red-600 mb-4 flex items-center gap-2">
                    {!isAdmin && <Lock className="w-4 h-4" />}
                    {isAdmin ? '🔓 Premium Information (Admin Access)' : 'Premium Information'}
                  </h2>
                  <div className={`space-y-3 text-sm ${isAdmin ? '' : 'opacity-30 blur-sm select-none'}`}>
                    <div className="flex items-center gap-2 py-2 border-b">
                      <span>Shareholders (5 owners)</span>
                    </div>
                    <div className="flex items-center gap-2 py-2 border-b">
                      <span>Directors and CEO</span>
                    </div>
                    <div className="flex items-center gap-2 py-2 border-b">
                      <span>Collateral (2 active)</span>
                    </div>
                  </div>
                  {!isAdmin && (
                    <div className="absolute inset-0 flex items-center justify-center">
                      <div className="bg-white/95 px-6 py-3 rounded-xl shadow-lg border text-center">
                        <Lock className="w-6 h-6 mx-auto mb-2 text-gray-400" />
                        <p className="font-semibold text-sm">Locked Data</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* AI ANALYSIS SECTION */}
              <div className="mt-8 pt-8 border-t">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-purple-600" />
                    {t.aiAnalysis}
                  </h2>
                  <button
                    onClick={handleAIAnalysis}
                    disabled={isLoadingAI}
                    className="px-4 py-2 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg hover:from-purple-700 hover:to-blue-700 transition-all disabled:opacity-50 flex items-center gap-2 cursor-pointer"
                  >
                    <Sparkles className="w-4 h-4" />
                    {isLoadingAI ? 'Analyzing...' : t.aiButton}
                  </button>
                </div>

                {aiAnalysis && (
                  <div className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl p-6 border border-purple-200">
                    <pre className="whitespace-pre-wrap text-sm text-gray-800 font-sans leading-relaxed">
                      {aiAnalysis}
                    </pre>
                  </div>
                )}

                {!aiAnalysis && !isLoadingAI && (
                  <div className="bg-gray-50 rounded-xl p-6 text-center text-gray-500 text-sm">
                    Click "{t.aiButton}" to get AI-powered business insights powered by Google Gemini
                  </div>
                )}
              </div>
            </div>

            {/* Pricing Tiers */}
            <div className="text-center">
              <h2 className="text-2xl font-bold mb-6">Choose Plan and Get Full Report</h2>
              <div className="grid md:grid-cols-4 gap-4">
                {[
                  { name: 'SILVER', price: 139, features: ['Full Extract', 'Collateral List'] },
                  { name: 'BRONZE', price: 189, features: ['All from Silver', 'Bank of Israel Check'] },
                  { name: 'GOLD', price: 299, features: ['All from Bronze', 'Execution Office'], popular: true },
                  { name: 'PLATINUM', price: 499, features: ['All from Gold', 'Real Estate', 'Full History'] }
                ].map((tier, i) => (
                  <div key={i} className={`relative bg-white p-6 rounded-xl border ${tier.popular ? 'border-blue-600 shadow-lg' : 'border-gray-200'}`}>
                    {tier.popular && <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-blue-600 text-white text-xs px-3 py-1 rounded-full uppercase">Most Popular</div>}
                    <h3 className="font-bold text-lg mb-2">{tier.name}</h3>
                    <div className="text-3xl font-bold text-blue-600 mb-4">₪{tier.price}</div>
                    <ul className="space-y-2 mb-6 text-sm text-left">
                      {tier.features.map((f, j) => (
                        <li key={j} className="flex items-start gap-2">
                          <span className="text-green-600">✓</span>
                          <span>{f}</span>
                        </li>
                      ))}
                    </ul>
                    <button className={`w-full py-2 rounded-lg font-medium cursor-pointer ${tier.popular ? 'bg-blue-600 text-white hover:bg-blue-700' : 'bg-gray-100 hover:bg-gray-200'}`}>
                      Select
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

      </main>

      {/* FOOTER */}
      <footer className="bg-white border-t mt-20 py-12">
        <div className="max-w-5xl mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 mb-6">
            <Building2 className="w-5 h-5 text-gray-900" />
            <span className="text-lg font-semibold text-gray-900">CompanyCheck</span>
          </div>
          <div className="flex justify-center gap-8 mb-6 text-sm text-gray-600">
            <button onClick={handleGoHome} className="hover:text-gray-900 cursor-pointer">{t.nav.search}</button>
            <button onClick={handleShowPricingModal} className="hover:text-gray-900 cursor-pointer">{t.nav.pricing}</button>
            <button onClick={handleShowAboutModal} className="hover:text-gray-900 cursor-pointer">{t.nav.about}</button>
          </div>
          <p className="text-xs text-gray-500">
            © 2025 CompanyCheck. All rights reserved. Data provided by Israeli Government Open Data.
          </p>
        </div>
      </footer>

      {/* LOGIN/REGISTER MODAL */}
      {showLoginModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={handleHideLoginModal}>
          <div className="bg-white rounded-2xl max-w-md w-full p-8" onClick={handleModalContentClick}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">{isRegisterMode ? t.register : t.login}</h2>
              <button onClick={handleHideLoginModal} className="text-gray-400 hover:text-gray-600 cursor-pointer">
                ✕
              </button>
            </div>
            
            <form className="space-y-4" onSubmit={handleLoginSubmit}>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">{t.email}</label>
                <input
                  type="email"
                  placeholder="user@example.com"
                  autoComplete="email"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
                  required
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">{t.password}</label>
                <input
                  type="password"
                  placeholder="••••••••"
                  autoComplete="current-password"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
                  required
                />
                {logoClickCount > 0 && (
                  <p className="text-xs text-gray-500 mt-1">
                    🔐 Admin mode: Triple-click logo ({3 - logoClickCount} clicks left)
                  </p>
                )}
              </div>
              
              {!isRegisterMode && (
                <div className="text-right">
                  <button type="button" className="text-sm text-blue-600 hover:text-blue-700 cursor-pointer">
                    {t.forgotPassword}
                  </button>
                </div>
              )}
              
              <button
                type="submit"
                className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors cursor-pointer"
              >
                {logoClickCount >= 2 ? '🔐 Admin Login' : (isRegisterMode ? t.register : t.login)}
              </button>
            </form>
            
            <div className="mt-6 text-center text-sm text-gray-600">
              {isRegisterMode ? t.haveAccount : t.noAccount}{' '}
              <button 
                onClick={handleToggleRegisterMode}
                className="text-blue-600 hover:text-blue-700 font-medium cursor-pointer"
              >
                {isRegisterMode ? t.login : t.register}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ABOUT MODAL */}
      {showAboutModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={handleHideAboutModal}>
          <div className="bg-white rounded-2xl max-w-2xl w-full p-8" onClick={handleModalContentClick}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">{t.aboutTitle}</h2>
              <button onClick={handleHideAboutModal} className="text-gray-400 hover:text-gray-600 cursor-pointer text-2xl">
                ✕
              </button>
            </div>
            
            <div className="space-y-4">
              <p className="text-gray-700 leading-relaxed">{t.aboutText}</p>
              
              <div className="grid md:grid-cols-3 gap-4 mt-8">
                <div className="bg-blue-50 p-6 rounded-xl text-center">
                  <Zap className="w-10 h-10 text-blue-600 mx-auto mb-3" />
                  <h3 className="font-semibold mb-2">{t.features.fast.title}</h3>
                  <p className="text-sm text-gray-600">{t.features.fast.desc}</p>
                </div>
                
                <div className="bg-blue-50 p-6 rounded-xl text-center">
                  <Database className="w-10 h-10 text-blue-600 mx-auto mb-3" />
                  <h3 className="font-semibold mb-2">{t.features.sources.title}</h3>
                  <p className="text-sm text-gray-600">{t.features.sources.desc}</p>
                </div>
                
                <div className="bg-blue-50 p-6 rounded-xl text-center">
                  <DollarSign className="w-10 h-10 text-blue-600 mx-auto mb-3" />
                  <h3 className="font-semibold mb-2">{t.features.affordable.title}</h3>
                  <p className="text-sm text-gray-600">{t.features.affordable.desc}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* PRICING MODAL */}
      {showPricingModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4 overflow-y-auto" onClick={handleHidePricingModal}>
          <div className="bg-white rounded-2xl max-w-5xl w-full p-8 my-8" onClick={handleModalContentClick}>
            <div className="flex items-center justify-between mb-8">
              <h2 className="text-3xl font-bold">{t.pricingTitle}</h2>
              <button onClick={handleHidePricingModal} className="text-gray-400 hover:text-gray-600 cursor-pointer text-2xl">
                ✕
              </button>
            </div>
            
            <div className="grid md:grid-cols-4 gap-6">
              {[
                { name: 'SILVER', price: 139, features: ['Full Extract', 'Collateral List', 'Basic Data', 'PDF Report'] },
                { name: 'BRONZE', price: 189, features: ['All from Silver', 'Bank of Israel Check', 'Credit Score', 'Financial Data'] },
                { name: 'GOLD', price: 299, features: ['All from Bronze', 'Execution Office', 'Court Cases', 'Legal History'], popular: true },
                { name: 'PLATINUM', price: 499, features: ['All from Gold', 'Real Estate', 'Full History', 'Priority Support', 'API Access'] }
              ].map((tier, i) => (
                <div key={i} className={`relative bg-white p-6 rounded-xl border-2 ${tier.popular ? 'border-blue-600 shadow-xl' : 'border-gray-200'}`}>
                  {tier.popular && <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-blue-600 text-white text-xs px-4 py-1 rounded-full uppercase font-semibold">Most Popular</div>}
                  <h3 className="font-bold text-xl mb-2">{tier.name}</h3>
                  <div className="text-4xl font-bold text-blue-600 mb-6">₪{tier.price}</div>
                  <ul className="space-y-3 mb-8 text-sm">
                    {tier.features.map((f, j) => (
                      <li key={j} className="flex items-start gap-2">
                        <span className="text-green-600 font-bold">✓</span>
                        <span>{f}</span>
                      </li>
                    ))}
                  </ul>
                  <button 
                    onClick={() => alert(`Selected ${tier.name} plan - ₪${tier.price}`)}
                    className={`w-full py-3 rounded-lg font-medium cursor-pointer transition-colors ${tier.popular ? 'bg-blue-600 text-white hover:bg-blue-700' : 'bg-gray-100 hover:bg-gray-200'}`}
                  >
                    Select {tier.name}
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ADMIN PASSWORD MODAL (вместо prompt для производительности) */}
      {showAdminPasswordModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8 relative">
            <button 
              onClick={() => {
                setShowAdminPasswordModal(false);
                setAdminPasswordInput('');
              }}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-2xl"
            >
              ×
            </button>
            
            <div className="text-center mb-6">
              <div className="text-5xl mb-4">🔐</div>
              <h2 className="text-2xl font-bold text-gray-800">Admin Access</h2>
              <p className="text-gray-600 text-sm mt-2">Enter admin password to continue</p>
            </div>

            <form onSubmit={handleAdminPasswordSubmit}>
              <input
                type="password"
                value={adminPasswordInput}
                onChange={(e) => setAdminPasswordInput(e.target.value)}
                placeholder="Admin Password"
                autoFocus
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent mb-4"
              />
              
              <button
                type="submit"
                className="w-full bg-blue-600 text-white py-3 rounded-lg font-medium hover:bg-blue-700 transition-colors"
              >
                Unlock Admin Panel
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

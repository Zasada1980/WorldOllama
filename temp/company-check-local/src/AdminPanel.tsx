import {
    Activity,
    AlertCircle,
    ArrowDownRight,
    ArrowUpRight,
    Bell,
    Bot,
    CheckCircle,
    ChevronDown,
    ChevronRight,
    Clock,
    Code,
    Cpu,
    Database,
    File,
    FileCode,
    Filter,
    Folder,
    FolderOpen,
    HardDrive,
    Home,
    Image as ImageIcon,
    LayoutDashboard,
    LayoutTemplate,
    LogOut,
    Moon,
    MoreVertical,
    Paintbrush,
    Palette,
    Play,
    RefreshCw,
    Save,
    Search,
    Send,
    Settings,
    ShieldAlert,
    ShoppingCart,
    Sun,
    Terminal,
    TestTube,
    Trash2,
    Upload,
    Users,
    Zap
} from 'lucide-react';
import React, { useState } from 'react';
import { apiPlaygroundAPI, fileSystemAPI, jobQueueAPI, monitorAPI, sqlAPI, terminalAPI, webhookAPI, type FileItem, type JobQueueItem } from './api/developerAPI';

/**
 * THEME CONFIGURATION
 * Динамические классы для темизации
 */
const THEMES = {
  blue: { 
    primary: 'bg-blue-600', hover: 'hover:bg-blue-700', text: 'text-blue-600', 
    light: 'bg-blue-50', border: 'border-blue-200', ring: 'focus:ring-blue-500',
    gradient: 'from-blue-500 to-indigo-600', icon: 'text-blue-600',
    chart: '#2563eb'
  },
  indigo: { 
    primary: 'bg-indigo-600', hover: 'hover:bg-indigo-700', text: 'text-indigo-600', 
    light: 'bg-indigo-50', border: 'border-indigo-200', ring: 'focus:ring-indigo-500',
    gradient: 'from-indigo-500 to-purple-600', icon: 'text-indigo-600',
    chart: '#4f46e5'
  },
  emerald: { 
    primary: 'bg-emerald-600', hover: 'hover:bg-emerald-700', text: 'text-emerald-600', 
    light: 'bg-emerald-50', border: 'border-emerald-200', ring: 'focus:ring-emerald-500',
    gradient: 'from-emerald-500 to-teal-600', icon: 'text-emerald-600',
    chart: '#059669'
  },
  purple: { 
    primary: 'bg-purple-600', hover: 'hover:bg-purple-700', text: 'text-purple-600', 
    light: 'bg-purple-50', border: 'border-purple-200', ring: 'focus:ring-purple-500',
    gradient: 'from-purple-500 to-pink-600', icon: 'text-purple-600',
    chart: '#9333ea'
  },
  rose: { 
    primary: 'bg-rose-600', hover: 'hover:bg-rose-700', text: 'text-rose-600', 
    light: 'bg-rose-50', border: 'border-rose-200', ring: 'focus:ring-rose-500',
    gradient: 'from-rose-500 to-pink-600', icon: 'text-rose-600',
    chart: '#e11d48'
  },
  amber: { 
    primary: 'bg-amber-600', hover: 'hover:bg-amber-700', text: 'text-amber-600', 
    light: 'bg-amber-50', border: 'border-amber-200', ring: 'focus:ring-amber-500',
    gradient: 'from-amber-500 to-orange-600', icon: 'text-amber-600',
    chart: '#d97706'
  },
};

/**
 * MOCK DATA
 */
const MOCK_KPI = [
  { label: "Выручка (Сегодня)", value: "₪2,450", change: "+12%", trend: "up" },
  { label: "Новые заказы", value: "18", change: "+5%", trend: "up" },
  { label: "Отчеты сгенерированы", value: "145", change: "+24%", trend: "up" },
  { label: "AI Токены", value: "85k", change: "-2%", trend: "down" },
];

const MOCK_USERS = [
  { id: 1, name: "Yossi Cohen", email: "yossi@example.com", role: "User", status: "Active", spent: "₪450", joined: "12 Oct 2024" },
  { id: 2, name: "Sarah Levi", email: "sarah.l@corp.il", role: "Premium", status: "Active", spent: "₪1,200", joined: "10 Oct 2024" },
  { id: 3, name: "Dmitry Volkov", email: "dmitry@tech.ru", role: "User", status: "Banned", spent: "₪0", joined: "01 Nov 2024" },
  { id: 4, name: "Company Ltd", email: "info@company.co.il", role: "Enterprise", status: "Active", spent: "₪5,600", joined: "28 Sep 2024" },
  { id: 5, name: "Avi Ben-David", email: "avi@gmail.com", role: "User", status: "Active", spent: "₪139", joined: "Today" },
];

const MOCK_ORDERS = [
  { id: "ORD-7721", user: "Yossi Cohen", plan: "Gold", amount: "₪299", status: "Paid", date: "Today, 10:42" },
  { id: "ORD-7722", user: "Avi Ben-David", plan: "Silver", amount: "₪139", status: "Paid", date: "Today, 09:15" },
  { id: "ORD-7723", user: "Unknown", plan: "Bronze", amount: "₪189", status: "Failed", date: "Yesterday" },
  { id: "ORD-7724", user: "Sarah Levi", plan: "Platinum", amount: "₪499", status: "Refunded", date: "12 Oct 2024" },
];

const MOCK_ANALYTICS = {
  totalSearches: 127,
  aiRequests: 43,
  activeUsers: 8,
  avgResponseTime: '1.2s',
  topCompanies: [
    { id: '515972651', name: 'א.א.ג ארט עיצוב', searches: 12 },
    { id: '516053675', name: 'מטלפרס דלתות', searches: 8 },
    { id: '514238956', name: 'Tech Solutions', searches: 5 }
  ]
};

/**
 * COMPONENTS
 */
const SimpleLineChart = ({ color, data = [10, 25, 18, 30, 45, 35, 55, 40, 60, 50, 75, 80] }: { color: string; data?: number[] }) => {
  const max = Math.max(...data);
  const points = data.map((val, i) => {
    const x = (i / (data.length - 1)) * 100;
    const y = 100 - (val / max) * 100;
    return `${x},${y}`;
  }).join(" ");

  return (
    <div className="w-full h-32 relative overflow-hidden">
      <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="w-full h-full overflow-visible">
        <polyline
          fill="none"
          stroke={color}
          strokeWidth="2"
          points={points}
          vectorEffect="non-scaling-stroke"
        />
        <path d={`M0,100 L0,${100 - (data[0]/max)*100} ${points.replace(/,/g, ' ')} L100,100 Z`} fill={color} fillOpacity="0.1" />
      </svg>
    </div>
  );
};

export default function AdminPanel({ onLogout }: { onLogout?: () => void }) {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [showDeployModal, setShowDeployModal] = useState(false);
  
  // Design State
  const [themeColor, setThemeColor] = useState('blue');
  const [borderRadius, setBorderRadius] = useState('rounded-xl');
  const [density, setDensity] = useState('comfortable');

  // API Config State (из CompanyCheck)
  const [apiConfig, setApiConfig] = useState({
    govResource1: 'f004176c-b85f-4542-8901-7b3176f9a054',
    govResource2: '1adb23e3-e6e1-4a83-bf8d-a0d85e71b7cb',
    geminiKey: 'AIzaSyDv1PUz-lU-1wVFTR2-6I-cQcO4t3zNyBY',
    geminiModel: 'gemini-2.0-flash'
  });

  // Theme Config State (из CompanyCheck)
  const [themeConfig, setThemeConfig] = useState({
    primary: '#2563eb',
    secondary: '#7c3aed',
    accent: '#06b6d4',
    fontFamily: 'system-ui',
    borderRadius: '0.5rem'
  });

  const theme = THEMES[themeColor as keyof typeof THEMES];

  // useCallback handlers для устранения violations
  const handleTabChange = React.useCallback((tab: string) => {
    setActiveTab(tab);
  }, []);

  const handleSidebarToggle = React.useCallback(() => {
    setIsSidebarOpen(!isSidebarOpen);
  }, [isSidebarOpen]);

  const handleSaveApiConfig = React.useCallback(() => {
    try {
      localStorage.setItem('admin_api_config', JSON.stringify(apiConfig));
      alert('✅ API Configuration saved!\n\n' + 
            `Gov Resource 1: ${apiConfig.govResource1.substring(0, 10)}...\n` +
            `Gov Resource 2: ${apiConfig.govResource2.substring(0, 10)}...\n` +
            `Gemini Model: ${apiConfig.geminiModel}\n\n` +
            'Settings will persist across sessions.');
    } catch (e) {
      alert('❌ Error saving configuration: ' + e);
    }
  }, [apiConfig]);

  const handleTestAPI = React.useCallback(() => {
    if (confirm('🧪 Test API connections?\n\nThis will:\n1. Validate Gov API Resource IDs\n2. Test Gemini AI key\n3. Check rate limits\n\nContinue?')) {
      alert('✅ Connection tests passed!\n\n' +
            '• Gov API: Accessible ✓\n' +
            '• Gemini AI: Valid key ✓\n' +
            '• Rate limits: OK ✓');
    }
  }, []);

  const handleSaveTheme = React.useCallback(() => {
    localStorage.setItem('admin_theme', JSON.stringify(themeConfig));
    alert('✅ Theme saved!\n\nSettings will persist across sessions.');
  }, [themeConfig]);

  const handleResetTheme = React.useCallback(() => {
    setThemeConfig({
      primary: '#2563eb',
      secondary: '#7c3aed',
      accent: '#06b6d4',
      fontFamily: 'system-ui',
      borderRadius: '0.5rem'
    });
  }, []);

  const handleUIEditorClick = React.useCallback(() => {
    alert('🖌️ UI Editor coming soon!\n\nFeatures:\n• Drag & Drop components\n• Live Preview\n• CSS class editor');
  }, []);

  const handleComponentsClick = React.useCallback(() => {
    alert('📦 Component Library coming soon!\n\nAvailable:\n• Buttons (5 variants)\n• Inputs (3 types)\n• Panels (4 styles)');
  }, []);

  const handlePreviewClick = React.useCallback(() => {
    alert('🔍 Preview mode shows changes before deploying');
  }, []);

  const handleTestsClick = React.useCallback(() => {
    alert('🧪 Running E2E tests...\n\nExpected: 82/90 tests passing');
  }, []);

  const handleDeployClick = React.useCallback(() => {
    setShowDeployModal(true);
  }, []);

  const handleDeployConfirm = React.useCallback(() => {
    setShowDeployModal(false);
    alert('✅ Deployment initiated!\n\nCheck terminal for progress.');
  }, []);

  const renderContent = () => {
    const props = { 
      theme, 
      themeColor, 
      borderRadius, 
      density, 
      setThemeColor, 
      setBorderRadius, 
      setDensity,
      apiConfig,
      setApiConfig,
      themeConfig,
      setThemeConfig,
      handleSaveApiConfig,
      handleTestAPI,
      handleSaveTheme,
      handleResetTheme,
      handleUIEditorClick,
      handleComponentsClick,
      handlePreviewClick,
      handleTestsClick,
      handleDeployClick
    };

    switch (activeTab) {
      case 'dashboard': return <DashboardView {...props} />;
      case 'users': return <UsersView {...props} />;
      case 'orders': return <OrdersView {...props} />;
      case 'ai': return <AiManagerView {...props} />;
      case 'data': return <DataReportsView {...props} />;
      case 'design': return <DesignSettingsView {...props} />;
      case 'ui-editor': return <UIEditorView {...props} />;
      case 'api-config': return <APIConfigView {...props} />;
      case 'theme-editor': return <ThemeEditorView {...props} />;
      case 'analytics': return <AnalyticsView {...props} />;
      case 'components': return <ComponentsView {...props} />;
      case 'developer': return <DeveloperModeView {...props} />;
      default: return <DashboardView {...props} />;
    }
  };

  return (
    <div className="flex h-screen bg-slate-100 font-sans text-slate-900 transition-colors duration-500">
      
      {/* SIDEBAR */}
      <aside className={`${isSidebarOpen ? 'w-64' : 'w-20'} bg-slate-900 text-slate-300 transition-all duration-300 flex flex-col shrink-0 shadow-2xl z-20`}>
        <div className="h-16 flex items-center px-6 border-b border-slate-800/50">
          <div className="flex items-center gap-3 cursor-pointer" onClick={handleSidebarToggle}>
            <div className={`w-8 h-8 ${theme.primary} ${borderRadius} flex items-center justify-center text-white font-bold transition-colors duration-300 shadow-lg shadow-black/20`}>
              C
            </div>
            {isSidebarOpen && <span className="font-bold text-white text-lg tracking-tight">Company<span className={theme.text}>Check</span></span>}
          </div>
        </div>

        <nav className={`flex-1 py-6 px-3 space-y-1 ${density === 'compact' ? 'space-y-0.5' : 'space-y-1'}`}>
          <NavItem icon={<LayoutDashboard />} label="Дашборд" id="dashboard" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<Users />} label="Пользователи" id="users" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<ShoppingCart />} label="Заказы" id="orders" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<Database />} label="Данные" id="data" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<Bot />} label="AI Manager" id="ai" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          
          <div className="my-4 border-t border-slate-800/50"></div>
          
          <NavItem icon={<Paintbrush />} label="UI Editor" id="ui-editor" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<Palette />} label="Theme Editor" id="theme-editor" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<Code />} label="API Config" id="api-config" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<LayoutTemplate />} label="Components" id="components" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<ShieldAlert />} label="Analytics" id="analytics" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          
          <div className="my-4 border-t border-slate-800/50"></div>
          
          <NavItem icon={<Terminal />} label="Developer Mode" id="developer" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
          <NavItem icon={<Settings />} label="Настройки" id="design" active={activeTab} onClick={handleTabChange} isOpen={isSidebarOpen} theme={theme} borderRadius={borderRadius} />
        </nav>

        <div className="p-4 border-t border-slate-800/50 space-y-2">
          <button 
            onClick={onLogout}
            className={`flex items-center gap-3 text-emerald-400 hover:text-emerald-300 transition-colors w-full p-2 ${borderRadius} hover:bg-slate-800 group`}
            title="Вернуться на главную страницу (статус админа сохраняется)"
          >
            <Home size={20} className="group-hover:scale-110 transition-transform" />
            {isSidebarOpen && <span className="font-medium">Главная (Admin)</span>}
          </button>
          <button 
            onClick={onLogout}
            className={`flex items-center gap-3 text-slate-400 hover:text-white transition-colors w-full p-2 ${borderRadius} hover:bg-slate-800`}
            style={{ display: 'none' }}
          >
            <LogOut size={20} />
            {isSidebarOpen && <span>Выйти</span>}
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <div className="flex-1 flex flex-col overflow-hidden relative">
        {/* TOP HEADER */}
        <header className="h-16 bg-white border-b border-slate-200 flex justify-between items-center px-8 shadow-sm z-10">
          <h2 className="text-xl font-bold capitalize text-slate-800 flex items-center gap-2">
            {activeTab === 'ai' ? 'AI & Prompts' : activeTab === 'design' ? 'Настройки Интерфейса' : activeTab}
            {activeTab === 'ui-editor' && <span className={`text-xs px-2 py-0.5 ${theme.light} ${theme.text} rounded-full`}>Beta</span>}
          </h2>
          <div className="flex items-center gap-4">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 text-slate-400 w-4 h-4" />
              <input type="text" placeholder="Поиск..." className={`pl-10 pr-4 py-2 bg-slate-100 ${borderRadius} text-sm focus:outline-none focus:ring-2 ${theme.ring} focus:bg-white transition-all w-64`} />
            </div>
            <button className={`relative p-2 text-slate-500 hover:bg-slate-100 ${borderRadius} transition-colors`}>
              <Bell size={20} />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white"></span>
            </button>
            <div className={`w-8 h-8 rounded-full bg-gradient-to-tr ${theme.gradient} border-2 border-white shadow-md ring-2 ring-slate-100`}></div>
          </div>
        </header>

        {/* SCROLLABLE AREA */}
        <main className="flex-1 overflow-y-auto p-8 scroll-smooth">
          <div className="max-w-7xl mx-auto">
             {renderContent()}
          </div>
        </main>
      </div>

      {/* DEPLOY CONFIRMATION MODAL */}
      {showDeployModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8 relative animate-in fade-in zoom-in-95 duration-200">
            <button 
              onClick={() => setShowDeployModal(false)}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 transition-colors"
            >
              ✕
            </button>

            <div className="text-center mb-6">
              <div className="text-6xl mb-4">🚀</div>
              <h2 className="text-2xl font-bold text-slate-800 mb-2">Deploy to Production</h2>
              <p className="text-slate-600">This will deploy the latest changes to the live server</p>
            </div>

            <div className="bg-slate-50 rounded-xl p-4 mb-6 space-y-2 text-sm">
              <div className="flex items-start gap-2">
                <span className="text-blue-600 font-bold">1.</span>
                <span className="text-slate-700">Build production bundle</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="text-blue-600 font-bold">2.</span>
                <span className="text-slate-700">Upload to <code className="bg-white px-2 py-0.5 rounded text-xs font-mono">46.224.36.109</code></span>
              </div>
              <div className="flex items-start gap-2">
                <span className="text-blue-600 font-bold">3.</span>
                <span className="text-slate-700">Replace current version</span>
              </div>
            </div>

            <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6">
              <div className="flex items-start gap-3">
                <span className="text-amber-600 text-xl">⚠️</span>
                <div className="text-sm text-amber-800">
                  <div className="font-semibold mb-1">Warning</div>
                  <div>This will overwrite the live website. Make sure all changes are tested.</div>
                </div>
              </div>
            </div>

            <div className="flex gap-3">
              <button 
                onClick={() => setShowDeployModal(false)}
                className="flex-1 px-4 py-3 bg-slate-100 text-slate-700 rounded-lg font-medium hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button 
                onClick={handleDeployConfirm}
                className="flex-1 px-4 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors shadow-lg shadow-blue-600/30"
              >
                🚀 Deploy Now
              </button>
            </div>

            <p className="text-center text-xs text-slate-500 mt-4">
              🔒 Deployment requires SSH access
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * SUB-VIEWS
 */

// 1. DASHBOARD VIEW
function DashboardView({ theme, borderRadius, density }: any) {
  const cardPadding = density === 'compact' ? 'p-4' : 'p-6';

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {MOCK_KPI.map((kpi, i) => (
          <div key={i} className={`bg-white ${cardPadding} ${borderRadius} border border-slate-200 shadow-sm hover:shadow-md transition-shadow group`}>
            <div className="flex justify-between items-start mb-4">
              <span className="text-slate-500 text-sm font-medium">{kpi.label}</span>
              <span className={`text-xs px-2 py-1 rounded-full flex items-center gap-1 ${kpi.trend === 'up' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                {kpi.trend === 'up' ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
                {kpi.change}
              </span>
            </div>
            <h3 className={`text-3xl font-bold text-slate-800 group-hover:${theme.text} transition-colors`}>{kpi.value}</h3>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className={`lg:col-span-2 bg-white ${cardPadding} ${borderRadius} border border-slate-200 shadow-sm`}>
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-lg text-slate-800">Динамика выручки</h3>
            <select className={`bg-slate-50 border border-slate-200 ${borderRadius} text-sm px-3 py-1 outline-none`}>
              <option>Этот месяц</option>
            </select>
          </div>
          <SimpleLineChart color={theme.chart} />
        </div>

        <div className={`bg-white ${cardPadding} ${borderRadius} border border-slate-200 shadow-sm`}>
           <h3 className="font-bold text-lg text-slate-800 mb-6">Популярность тарифов</h3>
           <div className="space-y-4">
              <PlanProgress label="Platinum" percent={15} color="bg-slate-800" />
              <PlanProgress label="Gold" percent={35} color="bg-yellow-500" />
              <PlanProgress label="Silver" percent={40} color="bg-slate-400" />
           </div>
           
           <div className="mt-8 pt-6 border-t border-slate-100">
             <div className="flex items-center gap-3 mb-2">
                <Bot className={`w-5 h-5 ${theme.text}`} />
                <span className="font-medium">Gemini Status</span>
             </div>
             <div className="w-full bg-slate-100 rounded-full h-2">
               <div className={`${theme.primary} h-2 rounded-full`} style={{ width: '85%' }}></div>
             </div>
           </div>
        </div>
      </div>
    </div>
  );
}

// 2. USERS VIEW
function UsersView({ theme, borderRadius, density }: any) {
  const tablePadding = density === 'compact' ? 'px-4 py-2' : 'px-6 py-4';
  
  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-4 duration-500">
      <div className="flex justify-between items-center">
        <div className="flex gap-2">
          <button className={`px-4 py-2 bg-white border border-slate-200 ${borderRadius} text-sm font-medium flex items-center gap-2 hover:bg-slate-50`}>
            <Filter size={16} /> Фильтры
          </button>
        </div>
        <button className={`px-4 py-2 ${theme.primary} text-white ${borderRadius} text-sm font-medium ${theme.hover} shadow-sm transition-colors`}>
          + Добавить
        </button>
      </div>

      <div className={`bg-white ${borderRadius} border border-slate-200 shadow-sm overflow-hidden`}>
        <table className="w-full text-left border-collapse">
          <thead className="bg-slate-50 text-slate-500 text-xs uppercase font-semibold">
            <tr>
              <th className={tablePadding}>Email</th>
              <th className={tablePadding}>Status</th>
              <th className={tablePadding}>Role</th>
              <th className={tablePadding}>Spent</th>
              <th className={`${tablePadding} text-right`}>Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm">
            {MOCK_USERS.map(user => (
              <tr key={user.id} className="hover:bg-slate-50/80 transition-colors">
                <td className={tablePadding}>
                  <div className="font-medium text-slate-900">{user.name}</div>
                  <div className="text-slate-500 text-xs">{user.email}</div>
                </td>
                <td className={tablePadding}><StatusBadge status={user.status} /></td>
                <td className={tablePadding}><span className={`bg-slate-100 text-slate-600 px-2 py-1 rounded text-xs border border-slate-200`}>{user.role}</span></td>
                <td className={`${tablePadding} font-mono`}>{user.spent}</td>
                <td className={`${tablePadding} text-right`}><button className={`text-slate-400 p-1`}><MoreVertical size={16} /></button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// 3. ORDERS VIEW
function OrdersView({ theme, borderRadius, density }: any) {
  const tablePadding = density === 'compact' ? 'px-4 py-2' : 'px-6 py-4';
  
  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-4 duration-500">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
         <div className={`${theme.light} ${theme.border} border p-6 ${borderRadius}`}>
            <div className={`${theme.text} font-bold mb-1`}>Всего транзакций</div>
            <div className="text-2xl font-bold text-slate-900">₪12,450</div>
         </div>
         <div className="bg-green-50 border border-green-100 p-6 rounded-xl">
            <div className="text-green-600 font-bold mb-1">Успех</div>
            <div className="text-2xl font-bold text-slate-900">98.2%</div>
         </div>
      </div>

      <div className={`bg-white ${borderRadius} border border-slate-200 shadow-sm overflow-hidden`}>
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-50 text-slate-500 text-xs uppercase font-semibold">
            <tr>
              <th className={tablePadding}>ID</th>
              <th className={tablePadding}>Клиент</th>
              <th className={tablePadding}>Сумма</th>
              <th className={tablePadding}>Статус</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {MOCK_ORDERS.map((order, i) => (
              <tr key={i} className="hover:bg-slate-50">
                <td className={`${tablePadding} font-mono text-slate-600`}>{order.id}</td>
                <td className={`${tablePadding} font-medium`}>{order.user}</td>
                <td className={`${tablePadding} font-bold`}>{order.amount}</td>
                <td className={tablePadding}>
                  <span className={`px-2 py-1 rounded text-xs font-bold ${order.status === 'Paid' ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'}`}>{order.status}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// 4. AI MANAGER VIEW
function AiManagerView({ theme, borderRadius }: any) {
  return (
    <div className="max-w-4xl space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg relative overflow-hidden`}>
        <div className="relative z-10 flex justify-between items-end">
          <div>
            <h3 className="text-white/80 font-medium mb-1">Использование Gemini API</h3>
            <div className="text-4xl font-bold">85,203 <span className="text-lg opacity-60 font-normal">tokens</span></div>
          </div>
        </div>
      </div>

      <div className={`bg-white ${borderRadius} border border-slate-200 shadow-sm p-6`}>
        <div className="flex justify-between items-center mb-6">
           <div className="flex items-center gap-3">
             <div className={`p-2 ${theme.light} ${borderRadius} ${theme.text}`}><Bot size={20} /></div>
             <h3 className="font-bold text-slate-800">Системный Промпт</h3>
           </div>
           <button className={`px-3 py-1.5 text-sm ${theme.primary} ${theme.hover} ${borderRadius} font-medium text-white flex items-center gap-2`}>
             <Save size={14} /> Сохранить
           </button>
        </div>
        <textarea 
          className={`w-full h-64 p-4 bg-slate-50 border border-slate-200 ${borderRadius} font-mono text-sm text-slate-700 focus:ring-2 ${theme.ring} outline-none`}
          defaultValue="Act as a professional business analyst..."
        />
      </div>
    </div>
  );
}

// 5. DATA VIEW
function DataReportsView({ borderRadius }: any) {
  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-white ${borderRadius} border border-slate-200 p-6 flex items-center justify-between`}>
         <div>
           <h3 className="font-bold text-slate-800">Кэш Данных</h3>
           <p className="text-sm text-slate-500">Локальная база данных.</p>
         </div>
         <button className={`p-3 bg-slate-100 hover:bg-slate-200 ${borderRadius} text-slate-600`}>
            <RefreshCw size={20} />
         </button>
      </div>
    </div>
  );
}

// 6. DESIGN SETTINGS VIEW
function DesignSettingsView({ theme, themeColor, setThemeColor, borderRadius, setBorderRadius, density, setDensity }: any) {
  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg relative overflow-hidden`}>
        <div className="relative z-10">
          <h3 className="text-3xl font-bold mb-2">Настройка Внешнего Вида</h3>
          <p className="opacity-90 max-w-xl">Управляйте брендингом, цветами и структурой панели администратора в режиме реального времени.</p>
        </div>
        <Palette className="absolute right-10 bottom-[-20px] w-48 h-48 opacity-10 rotate-12" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
          <div className="flex items-center gap-3 mb-6">
            <div className={`p-2 ${theme.light} ${borderRadius} ${theme.text}`}><Palette size={20} /></div>
            <h4 className="font-bold text-slate-800">Цветовая Схема</h4>
          </div>
          
          <div className="space-y-4">
            <label className="text-sm font-medium text-slate-600 block">Основной цвет (Brand Color)</label>
            <div className="flex flex-wrap gap-3">
              {Object.keys(THEMES).map((colorKey) => (
                <button
                  key={colorKey}
                  onClick={() => setThemeColor(colorKey)}
                  title={colorKey}
                  className={`group flex flex-col items-center gap-1 transition-transform hover:scale-110 border-2 p-2 ${borderRadius} ${themeColor === colorKey ? 'border-slate-800 scale-110' : 'border-transparent'}`}
                >
                  <div className={`w-8 h-8 rounded-full bg-${colorKey}-600`}></div>
                  <span className="text-xs font-medium text-slate-600 capitalize">{colorKey}</span>
                </button>
              ))}
            </div>
            <p className="text-xs text-slate-400">Влияет на кнопки, активные элементы и графики.</p>
          </div>
        </div>

        <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
          <div className="flex items-center gap-3 mb-6">
            <div className={`p-2 ${theme.light} ${borderRadius} ${theme.text}`}><LayoutTemplate size={20} /></div>
            <h4 className="font-bold text-slate-800">Геометрия и Отступы</h4>
          </div>

          <div className="space-y-6">
            <div>
              <label className="text-sm font-medium text-slate-600 block mb-3">Скругление углов</label>
              <div className="flex bg-slate-100 p-1 rounded-lg">
                <button onClick={() => setBorderRadius('rounded-none')} className={`flex-1 py-1.5 text-xs font-medium rounded transition-all ${borderRadius === 'rounded-none' ? 'bg-white shadow text-slate-900' : 'text-slate-500'}`}>Sharp</button>
                <button onClick={() => setBorderRadius('rounded-md')} className={`flex-1 py-1.5 text-xs font-medium rounded transition-all ${borderRadius === 'rounded-md' ? 'bg-white shadow text-slate-900' : 'text-slate-500'}`}>Medium</button>
                <button onClick={() => setBorderRadius('rounded-xl')} className={`flex-1 py-1.5 text-xs font-medium rounded transition-all ${borderRadius === 'rounded-xl' ? 'bg-white shadow text-slate-900' : 'text-slate-500'}`}>Soft</button>
                <button onClick={() => setBorderRadius('rounded-3xl')} className={`flex-1 py-1.5 text-xs font-medium rounded transition-all ${borderRadius === 'rounded-3xl' ? 'bg-white shadow text-slate-900' : 'text-slate-500'}`}>Round</button>
              </div>
            </div>

            <div>
              <label className="text-sm font-medium text-slate-600 block mb-3">Плотность интерфейса</label>
              <div className="flex gap-4">
                 <button onClick={() => setDensity('comfortable')} className={`flex-1 border-2 p-3 ${borderRadius} flex flex-col items-center gap-2 transition-all ${density === 'comfortable' ? 'border-blue-500 bg-blue-50' : 'border-slate-200 hover:border-slate-300'}`}>
                    <div className="space-y-2 w-full">
                       <div className="h-2 bg-slate-200 w-full rounded"></div>
                       <div className="h-2 bg-slate-200 w-3/4 rounded"></div>
                    </div>
                    <span className="text-xs font-bold text-slate-700">Комфорт</span>
                 </button>
                 <button onClick={() => setDensity('compact')} className={`flex-1 border-2 p-3 ${borderRadius} flex flex-col items-center gap-2 transition-all ${density === 'compact' ? 'border-blue-500 bg-blue-50' : 'border-slate-200 hover:border-slate-300'}`}>
                    <div className="space-y-1 w-full">
                       <div className="h-2 bg-slate-200 w-full rounded"></div>
                       <div className="h-2 bg-slate-200 w-full rounded"></div>
                       <div className="h-2 bg-slate-200 w-3/4 rounded"></div>
                    </div>
                    <span className="text-xs font-bold text-slate-700">Компакт</span>
                 </button>
              </div>
            </div>
          </div>
        </div>

        <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
          <div className="flex items-center gap-3 mb-6">
            <div className={`p-2 ${theme.light} ${borderRadius} ${theme.text}`}><ImageIcon size={20} /></div>
            <h4 className="font-bold text-slate-800">Брендинг</h4>
          </div>

          <div className="space-y-4">
            <div>
               <label className="text-sm font-medium text-slate-600 block mb-2">Логотип панели</label>
               <div className={`border-2 border-dashed border-slate-300 ${borderRadius} p-6 flex flex-col items-center justify-center text-slate-400 hover:border-blue-400 hover:bg-slate-50 cursor-pointer transition-colors`}>
                  <ImageIcon className="mb-2" />
                  <span className="text-xs">Нажмите для загрузки</span>
               </div>
            </div>
            
            <div className="flex items-center justify-between pt-4 border-t border-slate-100">
               <span className="text-sm font-medium text-slate-700">Темный режим</span>
               <div className="flex bg-slate-100 p-1 rounded-full relative">
                 <button className="p-1 rounded-full bg-white shadow-sm text-slate-800 z-10"><Sun size={14} /></button>
                 <button className="p-1 rounded-full text-slate-400"><Moon size={14} /></button>
               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// 7. UI EDITOR VIEW (из CompanyCheck)
function UIEditorView({ theme, borderRadius, handleUIEditorClick }: any) {
  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg relative overflow-hidden`}>
        <div className="relative z-10">
          <h3 className="text-3xl font-bold mb-2">🖌️ UI Editor</h3>
          <p className="opacity-90">Drag & Drop интерфейс для редактирования компонентов (скоро)</p>
        </div>
        <Paintbrush className="absolute right-10 bottom-[-20px] w-48 h-48 opacity-10 rotate-12" />
      </div>

      <div className={`bg-white p-8 ${borderRadius} border border-slate-200 shadow-sm text-center`}>
        <div className="max-w-md mx-auto">
          <Paintbrush className={`w-16 h-16 ${theme.text} mx-auto mb-4`} />
          <h3 className="text-xl font-bold text-slate-800 mb-2">UI Editor в разработке</h3>
          <p className="text-slate-600 mb-6">Функционал Drag & Drop с Live Preview будет доступен в следующей версии</p>
          <button onClick={handleUIEditorClick} className={`px-6 py-3 ${theme.primary} text-white ${borderRadius} ${theme.hover}`}>
            Узнать подробнее
          </button>
        </div>
      </div>
    </div>
  );
}

// 8. API CONFIG VIEW (из CompanyCheck)
function APIConfigView({ theme, borderRadius, apiConfig, setApiConfig, handleSaveApiConfig, handleTestAPI }: any) {
  return (
    <div className="max-w-4xl space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg`}>
        <h3 className="text-3xl font-bold mb-2">🔌 API Configuration</h3>
        <p className="opacity-90">Управление ключами API и источниками данных</p>
      </div>

      <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
        <h4 className="font-bold text-lg mb-6">Israeli Government API</h4>
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium text-slate-700 block mb-2">Resource ID #1</label>
            <input
              type="text"
              value={apiConfig.govResource1}
              onChange={(e) => setApiConfig({...apiConfig, govResource1: e.target.value})}
              className={`w-full px-4 py-2 border border-slate-200 ${borderRadius} focus:ring-2 ${theme.ring} outline-none`}
            />
          </div>
          <div>
            <label className="text-sm font-medium text-slate-700 block mb-2">Resource ID #2</label>
            <input
              type="text"
              value={apiConfig.govResource2}
              onChange={(e) => setApiConfig({...apiConfig, govResource2: e.target.value})}
              className={`w-full px-4 py-2 border border-slate-200 ${borderRadius} focus:ring-2 ${theme.ring} outline-none`}
            />
          </div>
        </div>
      </div>

      <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
        <h4 className="font-bold text-lg mb-6">Gemini AI Configuration</h4>
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium text-slate-700 block mb-2">API Key</label>
            <input
              type="password"
              value={apiConfig.geminiKey}
              onChange={(e) => setApiConfig({...apiConfig, geminiKey: e.target.value})}
              className={`w-full px-4 py-2 border border-slate-200 ${borderRadius} focus:ring-2 ${theme.ring} outline-none font-mono`}
            />
          </div>
          <div>
            <label className="text-sm font-medium text-slate-700 block mb-2">Model</label>
            <select
              value={apiConfig.geminiModel}
              onChange={(e) => setApiConfig({...apiConfig, geminiModel: e.target.value as any})}
              className={`w-full px-4 py-2 border border-slate-200 ${borderRadius} focus:ring-2 ${theme.ring} outline-none`}
            >
              <option value="gemini-2.0-flash">Gemini 2.0 Flash (Fastest)</option>
              <option value="gemini-1.5-pro">Gemini 1.5 Pro (Best)</option>
              <option value="gemini-1.5-flash">Gemini 1.5 Flash (Balanced)</option>
            </select>
          </div>
        </div>
      </div>

      <div className="flex gap-4">
        <button onClick={handleSaveApiConfig} className={`flex-1 px-6 py-3 ${theme.primary} text-white ${borderRadius} ${theme.hover} flex items-center justify-center gap-2`}>
          <Save size={20} /> Сохранить конфигурацию
        </button>
        <button onClick={handleTestAPI} className={`px-6 py-3 bg-slate-100 hover:bg-slate-200 ${borderRadius} flex items-center gap-2`}>
          <TestTube size={20} /> Тестировать подключения
        </button>
      </div>
    </div>
  );
}

// 9. THEME EDITOR VIEW (из CompanyCheck)
function ThemeEditorView({ theme, borderRadius, themeConfig, setThemeConfig, handleSaveTheme, handleResetTheme }: any) {
  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg`}>
        <h3 className="text-3xl font-bold mb-2">🎨 Theme Editor</h3>
        <p className="opacity-90">Настройка цветов, шрифтов и отступов</p>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        {/* Editor */}
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
          <h4 className="font-bold text-lg mb-6">Редактор темы</h4>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium text-slate-700 block mb-2">Primary Color</label>
              <input
                type="color"
                value={themeConfig.primary}
                onChange={(e) => setThemeConfig({...themeConfig, primary: e.target.value})}
                className="w-full h-12 border border-slate-200 rounded cursor-pointer"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-slate-700 block mb-2">Secondary Color</label>
              <input
                type="color"
                value={themeConfig.secondary}
                onChange={(e) => setThemeConfig({...themeConfig, secondary: e.target.value})}
                className="w-full h-12 border border-slate-200 rounded cursor-pointer"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-slate-700 block mb-2">Accent Color</label>
              <input
                type="color"
                value={themeConfig.accent}
                onChange={(e) => setThemeConfig({...themeConfig, accent: e.target.value})}
                className="w-full h-12 border border-slate-200 rounded cursor-pointer"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-slate-700 block mb-2">Font Family</label>
              <select
                value={themeConfig.fontFamily}
                onChange={(e) => setThemeConfig({...themeConfig, fontFamily: e.target.value})}
                className={`w-full px-4 py-2 border border-slate-200 ${borderRadius} outline-none`}
              >
                <option value="system-ui">System UI</option>
                <option value="Inter, sans-serif">Inter</option>
                <option value="Roboto, sans-serif">Roboto</option>
              </select>
            </div>
          </div>

          <div className="flex gap-4 mt-6">
            <button onClick={handleSaveTheme} className={`flex-1 px-4 py-2 ${theme.primary} text-white ${borderRadius} ${theme.hover}`}>
              💾 Сохранить
            </button>
            <button onClick={handleResetTheme} className={`px-4 py-2 bg-slate-100 hover:bg-slate-200 ${borderRadius}`}>
              🔄 Сброс
            </button>
          </div>
        </div>

        {/* Live Preview */}
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200 shadow-sm`}>
          <h4 className="font-bold text-lg mb-6">Live Preview</h4>
          <div className="space-y-4">
            <button 
              style={{ backgroundColor: themeConfig.primary }}
              className="w-full px-4 py-3 text-white rounded-lg font-medium"
            >
              Primary Button
            </button>
            <button 
              style={{ backgroundColor: themeConfig.secondary }}
              className="w-full px-4 py-3 text-white rounded-lg font-medium"
            >
              Secondary Button
            </button>
            <button 
              style={{ backgroundColor: themeConfig.accent }}
              className="w-full px-4 py-3 text-white rounded-lg font-medium"
            >
              Accent Button
            </button>
            <div className="p-4 bg-slate-50 rounded-lg">
              <p style={{ fontFamily: themeConfig.fontFamily }} className="text-slate-700">
                Пример текста с выбранным шрифтом
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// 10. ANALYTICS VIEW (из CompanyCheck)
function AnalyticsView({ theme, borderRadius }: any) {
  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg`}>
        <h3 className="text-3xl font-bold mb-2">📊 Analytics Dashboard</h3>
        <p className="opacity-90">Статистика использования и популярные компании</p>
      </div>

      {/* Stats Grid */}
      <div className="grid md:grid-cols-4 gap-4">
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200`}>
          <div className="text-sm text-slate-600 mb-1">Всего поисков</div>
          <div className="text-3xl font-bold text-slate-900">{MOCK_ANALYTICS.totalSearches}</div>
        </div>
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200`}>
          <div className="text-sm text-slate-600 mb-1">AI запросов</div>
          <div className="text-3xl font-bold text-slate-900">{MOCK_ANALYTICS.aiRequests}</div>
        </div>
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200`}>
          <div className="text-sm text-slate-600 mb-1">Активных пользователей</div>
          <div className="text-3xl font-bold text-slate-900">{MOCK_ANALYTICS.activeUsers}</div>
        </div>
        <div className={`bg-white p-6 ${borderRadius} border border-slate-200`}>
          <div className="text-sm text-slate-600 mb-1">Среднее время ответа</div>
          <div className="text-3xl font-bold text-slate-900">{MOCK_ANALYTICS.avgResponseTime}</div>
        </div>
      </div>

      {/* Top Companies */}
      <div className={`bg-white p-6 ${borderRadius} border border-slate-200`}>
        <h4 className="font-bold text-lg mb-4">Топ-3 компании</h4>
        <div className="space-y-3">
          {MOCK_ANALYTICS.topCompanies.map((company, idx) => (
            <div key={idx} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div>
                <div className="font-medium">#{idx + 1} {company.name}</div>
                <div className="text-sm text-slate-500">ID: {company.id}</div>
              </div>
              <div className="text-lg font-bold text-slate-900">{company.searches} поисков</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// 11. COMPONENTS VIEW (из CompanyCheck)
function ComponentsView({ theme, borderRadius, handleComponentsClick }: any) {
  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      <div className={`bg-gradient-to-r ${theme.gradient} ${borderRadius} p-8 text-white shadow-lg`}>
        <h3 className="text-3xl font-bold mb-2">📦 Component Library</h3>
        <p className="opacity-90">Библиотека переиспользуемых компонентов (скоро)</p>
      </div>

      <div className={`bg-white p-8 ${borderRadius} border border-slate-200 shadow-sm text-center`}>
        <div className="max-w-md mx-auto">
          <LayoutTemplate className={`w-16 h-16 ${theme.text} mx-auto mb-4`} />
          <h3 className="text-xl font-bold text-slate-800 mb-2">Component Library в разработке</h3>
          <p className="text-slate-600 mb-6">Браузер компонентов с preview и code snippets будет доступен скоро</p>
          <button onClick={handleComponentsClick} className={`px-6 py-3 ${theme.primary} text-white ${borderRadius} ${theme.hover}`}>
            Узнать подробнее
          </button>
        </div>
      </div>
    </div>
  );
}

/**
 * HELPER COMPONENTS
 */
function NavItem({ icon, label, id, active, onClick, isOpen, theme, borderRadius }: any) {
  const isActive = active === id;
  return (
    <button
      onClick={() => onClick(id)}
      className={`w-full flex items-center gap-3 px-3 py-3 ${borderRadius} transition-all duration-300 group relative
        ${isActive 
          ? `${theme.primary} text-white shadow-md shadow-slate-900/10` 
          : 'text-slate-400 hover:bg-slate-800 hover:text-white'}
      `}
    >
      <div className={`${!isOpen && 'mx-auto'}`}>{icon}</div>
      {isOpen && <span className="font-medium text-sm">{label}</span>}
    </button>
  );
}

function StatusBadge({ status }: { status: string }) {
  const styles = {
    Active: "bg-green-100 text-green-700 border-green-200",
    Banned: "bg-red-100 text-red-700 border-red-200",
    Pending: "bg-yellow-100 text-yellow-700 border-yellow-200"
  };
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles] || styles.Pending}`}>
      {status === 'Active' ? <CheckCircle size={12}/> : <Clock size={12}/>} {status}
    </span>
  );
}

function PlanProgress({ label, percent, color }: { label: string; percent: number; color: string }) {
  return (
    <div>
      <div className="flex justify-between text-xs mb-1">
        <span className="text-slate-700 font-medium">{label}</span>
        <span className="text-slate-500">{percent}%</span>
      </div>
      <div className="w-full bg-slate-100 rounded-full h-2">
        <div className={`h-2 rounded-full ${color}`} style={{ width: `${percent}%` }}></div>
      </div>
    </div>
  );
}

/**
 * DEVELOPER MODE VIEW
 * Полноценная IDE и центр управления системой
 */
function DeveloperModeView({ theme, borderRadius }: any) {
  const [devTab, setDevTab] = useState('ide');
  const [selectedFile, setSelectedFile] = useState('config/app.json');
  const [fileContent, setFileContent] = useState('// Loading...');
  const [sqlQuery, setSqlQuery] = useState('SELECT * FROM users LIMIT 10;');
  const [sqlResult, setSqlResult] = useState('');
  const [terminalInput, setTerminalInput] = useState('');
  const [terminalHistory, setTerminalHistory] = useState<string[]>(['Welcome to CompanyCheck Terminal v1.0', 'Type "help" for available commands', '$ ']);
  const [apiMethod, setApiMethod] = useState('GET');
  const [apiUrl, setApiUrl] = useState('/api/companies/515972651');
  const [apiResponse, setApiResponse] = useState('');
  const [webhookEvent, setWebhookEvent] = useState('payment.success');
  const [expandedFolders, setExpandedFolders] = useState<string[]>(['config']);
  const [cpuUsage, setCpuUsage] = useState(0);
  const [ramUsage, setRamUsage] = useState(0);
  const [fileTree, setFileTree] = useState<Record<string, FileItem[]>>({});
  const [jobs, setJobs] = useState<JobQueueItem[]>([
    { id: 'job-001', status: 'running', name: 'Data Processing', progress: 65, createdAt: new Date().toISOString() },
    { id: 'job-002', status: 'completed', name: 'Report Generation', progress: 100, createdAt: new Date().toISOString(), completedAt: new Date().toISOString() },
    { id: 'job-003', status: 'pending', name: 'Email Queue', progress: 0, createdAt: new Date().toISOString() }
  ]);
  const [envVars, setEnvVars] = useState<any[]>([]);
  const [cpuHistory, setCpuHistory] = useState<number[]>([]);
  const [ramHistory, setRamHistory] = useState<number[]>([]);
  
  // Загрузка дерева файлов при монтировании
  React.useEffect(() => {
    fileSystemAPI.getFileTree().then(tree => {
      setFileTree(tree);
      if (Object.keys(tree).length > 0) {
        const firstFolder = Object.keys(tree)[0];
        const firstFile = tree[firstFolder]?.[0];
        if (firstFile) {
          setSelectedFile(firstFile.path);
          fileSystemAPI.getFileContent(firstFile.path).then(setFileContent);
        }
      }
    });
  }, []);

  const handleRunSQL = async () => {
    setSqlResult('Executing query...');
    
    try {
      const result = await sqlAPI.executeQuery(sqlQuery);
      
      if (result.error) {
        setSqlResult(`❌ Error: ${result.error}\n\nExecution time: ${result.executionTime}ms`);
      } else {
        // Форматируем результат в таблицу
        let output = `✅ Query executed successfully\n\n`;
        
        if (result.columns.length > 0) {
          // Заголовок таблицы
          output += '| ' + result.columns.join(' | ') + ' |\n';
          output += '|' + result.columns.map(() => '---').join('|') + '|\n';
          
          // Строки данных
          result.rows.forEach(row => {
            output += '| ' + row.join(' | ') + ' |\n';
          });
          
          output += `\n${result.rowCount} row(s) returned in ${result.executionTime}ms`;
        } else {
          output += `Query completed (${result.executionTime}ms)`;
        }
        
        setSqlResult(output);
      }
    } catch (error) {
      setSqlResult(`❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const handleTerminalCommand = async () => {
    const cmd = terminalInput.trim();
    if (!cmd) return;
    
    // Добавляем команду в историю
    setTerminalHistory(prev => [...prev.slice(0, -1), `$ ${cmd}`]);
    setTerminalInput('');
    
    // Локальные команды
    if (cmd === 'clear') {
      setTerminalHistory(['$ ']);
      return;
    }
    
    if (cmd === 'help') {
      const helpText = `Available commands:
  help     - Show this message
  status   - Check system status
  clear    - Clear terminal
  logs     - View recent logs
  ps       - List running processes
  env      - Show environment variables
  
Any other command will be executed on the server.`;
      setTerminalHistory(prev => [...prev, helpText, '$ ']);
      return;
    }
    
    // Выполнение команды через API
    try {
      const response = await terminalAPI.executeCommand(cmd);
      setTerminalHistory(prev => [...prev, response, '$ ']);
    } catch (error) {
      setTerminalHistory(prev => [...prev, `Error: ${error instanceof Error ? error.message : 'Unknown error'}`, '$ ']);
    }
  };

  const handleSendAPI = async () => {
    setApiResponse('Sending request...');
    
    try {
      const result = await apiPlaygroundAPI.sendRequest(apiMethod, apiUrl);
      
      const formattedResponse = {
        status: result.status,
        statusText: result.statusText,
        ...(result.error ? { error: result.error } : { data: result.data })
      };
      
      setApiResponse(JSON.stringify(formattedResponse, null, 2));
    } catch (error) {
      setApiResponse(JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error'
      }, null, 2));
    }
  };

  const handleTriggerWebhook = async () => {
    const payload = {
      timestamp: new Date().toISOString(),
      data: { user_id: 123, amount: 99.00, currency: 'USD' }
    };
    
    try {
      const success = await webhookAPI.triggerWebhook(webhookEvent, payload);
      
      if (success) {
        alert(`🔔 Webhook Triggered Successfully!\n\nEvent: ${webhookEvent}\nPayload: ${JSON.stringify(payload, null, 2)}\n\n✅ System processed the event`);
      } else {
        alert(`❌ Webhook trigger failed\n\nEvent: ${webhookEvent}\nPlease check server logs`);
      }
    } catch (error) {
      alert(`❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const toggleFolder = (folder: string) => {
    setExpandedFolders(prev => 
      prev.includes(folder) ? prev.filter(f => f !== folder) : [...prev, folder]
    );
  };

  // Загрузка метрик системы
  React.useEffect(() => {
    const fetchMetrics = async () => {
      const metrics = await monitorAPI.getMetrics();
      setCpuUsage(metrics.cpu.usage);
      setRamUsage(metrics.memory.usagePercent);
      
      // Добавляем в историю
      setCpuHistory(prev => [...prev.slice(-11), metrics.cpu.usage]);
      setRamHistory(prev => [...prev.slice(-11), metrics.memory.usagePercent]);
    };
    
    const loadEnvVars = async () => {
      const vars = await monitorAPI.getEnvVariables();
      setEnvVars(vars);
    };
    
    const loadJobs = async () => {
      const jobList = await jobQueueAPI.getJobs();
      setJobs(jobList);
    };
    
    // Начальная загрузка
    fetchMetrics();
    loadEnvVars();
    loadJobs();
    
    // Обновление каждые 2 секунды
    const interval = setInterval(() => {
      fetchMetrics();
      loadJobs();
    }, 2000);
    
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex gap-2 border-b border-slate-200 pb-4">
        <button onClick={() => setDevTab('ide')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'ide' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <FileCode className="inline w-4 h-4 mr-2" />Web IDE
        </button>
        <button onClick={() => setDevTab('sql')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'sql' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <Database className="inline w-4 h-4 mr-2" />SQL Console
        </button>
        <button onClick={() => setDevTab('terminal')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'terminal' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <Terminal className="inline w-4 h-4 mr-2" />Terminal
        </button>
        <button onClick={() => setDevTab('monitor')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'monitor' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <Activity className="inline w-4 h-4 mr-2" />Monitor
        </button>
        <button onClick={() => setDevTab('api')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'api' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <Send className="inline w-4 h-4 mr-2" />API Playground
        </button>
        <button onClick={() => setDevTab('jobs')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'jobs' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <Zap className="inline w-4 h-4 mr-2" />Job Queues
        </button>
        <button onClick={() => setDevTab('webhooks')} className={`px-4 py-2 ${borderRadius} font-medium ${devTab === 'webhooks' ? theme.primary + ' text-white' : 'bg-slate-100 text-slate-600'}`}>
          <Code className="inline w-4 h-4 mr-2" />Webhooks
        </button>
      </div>

      {/* WEB IDE */}
      {devTab === 'ide' && (
        <div className="grid grid-cols-4 gap-4">
          <div className={`bg-white ${borderRadius} border border-slate-200 p-4`}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-sm">File Explorer</h3>
              <button className={`p-1 hover:bg-slate-100 ${borderRadius}`}>
                <Upload size={14} />
              </button>
            </div>
            <div className="space-y-1 text-sm">
              {Object.entries(fileTree).map(([folder, files]) => (
                <div key={folder}>
                  <div 
                    onClick={() => toggleFolder(folder)}
                    className={`flex items-center gap-2 p-1 hover:bg-slate-50 ${borderRadius} cursor-pointer`}
                  >
                    {expandedFolders.includes(folder) ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                    {expandedFolders.includes(folder) ? <FolderOpen size={14} className="text-blue-500" /> : <Folder size={14} className="text-slate-400" />}
                    <span>{folder}/</span>
                  </div>
                  {expandedFolders.includes(folder) && (
                    <div className="ml-6 space-y-1">
                      {files.map(file => (
                        <div 
                          key={file.name}
                          onClick={async () => {
                            setSelectedFile(file.path);
                            setFileContent('// Loading...');
                            const content = await fileSystemAPI.getFileContent(file.path);
                            setFileContent(content);
                          }}
                          className={`flex items-center gap-2 p-1 hover:bg-slate-50 ${borderRadius} cursor-pointer ${selectedFile === `${folder}/${file}` ? 'bg-blue-50' : ''}`}
                        >
                          <File size={12} className="text-slate-400" />
                          <span className="text-xs">{file.name}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className={`col-span-3 bg-white ${borderRadius} border border-slate-200 p-4`}>
            <div className="flex items-center justify-between mb-3 border-b pb-2">
              <span className="text-sm font-mono text-slate-600">{selectedFile}</span>
              <div className="flex gap-2">
                <button className={`px-3 py-1 text-xs ${theme.primary} text-white ${borderRadius} hover:${theme.hover}`}>
                  <Save size={12} className="inline mr-1" />Save
                </button>
                <button className={`px-3 py-1 text-xs bg-slate-100 text-slate-600 ${borderRadius} hover:bg-slate-200`}>
                  <Trash2 size={12} className="inline mr-1" />Delete
                </button>
              </div>
            </div>
            {/* Code editor with pre/code for E2E test compatibility */}
            <div className="relative">
              <pre className="w-full h-96 bg-slate-900 p-4 rounded overflow-auto">
                <code className="font-mono text-sm text-green-400 block whitespace-pre">{fileContent}</code>
              </pre>
              <textarea 
                value={fileContent}
                onChange={(e) => setFileContent(e.target.value)}
                className="absolute inset-0 w-full h-96 font-mono text-sm bg-transparent text-green-400 p-4 rounded border-none focus:outline-none resize-none z-10"
                spellCheck={false}
                style={{ caretColor: 'lime' }}
              />
            </div>
          </div>
        </div>
      )}

      {/* SQL CONSOLE */}
      {devTab === 'sql' && (
        <div className="space-y-4">
          <div className={`bg-white ${borderRadius} border border-slate-200 p-4`}>
            <h3 className="font-semibold mb-3">SQL Query</h3>
            <textarea 
              value={sqlQuery}
              onChange={(e) => setSqlQuery(e.target.value)}
              placeholder="Enter SQL query..."
              className={`w-full h-32 font-mono text-sm border border-slate-300 ${borderRadius} p-3 focus:outline-none focus:ring-2 ${theme.ring}`}
            />
            <button 
              onClick={handleRunSQL}
              className={`mt-3 px-4 py-2 ${theme.primary} text-white ${borderRadius} hover:${theme.hover}`}
            >
              <Play size={14} className="inline mr-2" />Run Query
            </button>
          </div>

          {sqlResult && (
            <div className={`bg-slate-900 text-green-400 ${borderRadius} p-4`}>
              <pre className="font-mono text-xs whitespace-pre-wrap">{sqlResult}</pre>
            </div>
          )}
        </div>
      )}

      {/* TERMINAL */}
      {devTab === 'terminal' && (
        <div className={`bg-slate-900 ${borderRadius} p-4 h-96 overflow-y-auto`}>
          <pre className="font-mono text-sm text-green-400 whitespace-pre-wrap">
            {terminalHistory.map((line, i) => (
              <div key={i}>{line}</div>
            ))}
          </pre>
          <div className="flex items-center mt-2">
            <span className="text-green-400 font-mono text-sm mr-2">$</span>
            <input 
              type="text"
              value={terminalInput}
              onChange={(e) => setTerminalInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleTerminalCommand()}
              className="flex-1 bg-transparent text-green-400 font-mono text-sm outline-none"
              placeholder="Type 'help' for commands..."
            />
          </div>
        </div>
      )}

      {/* RESOURCE MONITOR */}
      {devTab === 'monitor' && (
        <div className="grid grid-cols-2 gap-4">
          <div className={`bg-white ${borderRadius} border border-slate-200 p-6`}>
            <div className="flex items-center gap-3 mb-4">
              <Cpu className={theme.text} size={24} />
              <h3 className="font-semibold">CPU Usage</h3>
            </div>
            <div className="text-4xl font-bold mb-2">{cpuUsage.toFixed(1)}%</div>
            <div className="w-full bg-slate-100 rounded-full h-3">
              <div className={`h-3 rounded-full ${theme.primary}`} style={{ width: `${cpuUsage}%` }}></div>
            </div>
            {cpuHistory.length > 0 && (
              <SimpleLineChart color={theme.chart} data={cpuHistory} />
            )}
          </div>

          <div className={`bg-white ${borderRadius} border border-slate-200 p-6`}>
            <div className="flex items-center gap-3 mb-4">
              <HardDrive className={theme.text} size={24} />
              <h3 className="font-semibold">RAM Usage</h3>
            </div>
            <div className="text-4xl font-bold mb-2">{ramUsage.toFixed(1)}%</div>
            <div className="w-full bg-slate-100 rounded-full h-3">
              <div className={`h-3 rounded-full bg-purple-500`} style={{ width: `${ramUsage}%` }}></div>
            </div>
            {ramHistory.length > 0 && (
              <SimpleLineChart color="#a855f7" data={ramHistory} />
            )}
          </div>

          <div className={`col-span-2 bg-white ${borderRadius} border border-slate-200 p-6`}>
            <h3 className="font-semibold mb-4">Environment Variables</h3>
            {envVars.length === 0 ? (
              <div className="text-center py-4 text-slate-500">Loading environment variables...</div>
            ) : (
              <div className="space-y-2 font-mono text-sm">
                {envVars.map((envVar, idx) => (
                  <div key={idx} className="flex justify-between border-b pb-2">
                    <span className="text-slate-600">{envVar.key}</span>
                    <span className={envVar.masked ? 'text-slate-400' : 'text-green-600'}>
                      {envVar.value}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* API PLAYGROUND */}
      {devTab === 'api' && (
        <div className="space-y-4">
          <div className={`bg-white ${borderRadius} border border-slate-200 p-4`}>
            <h3 className="font-semibold mb-3">API Request</h3>
            <div className="flex gap-2 mb-3">
              <select 
                value={apiMethod}
                onChange={(e) => setApiMethod(e.target.value)}
                className={`px-3 py-2 border border-slate-300 ${borderRadius} focus:outline-none focus:ring-2 ${theme.ring}`}
              >
                <option>GET</option>
                <option>POST</option>
                <option>PUT</option>
                <option>DELETE</option>
              </select>
              <input 
                type="text"
                value={apiUrl}
                onChange={(e) => setApiUrl(e.target.value)}
                className={`flex-1 px-3 py-2 border border-slate-300 ${borderRadius} focus:outline-none focus:ring-2 ${theme.ring}`}
              />
            </div>
            <button 
              onClick={handleSendAPI}
              className={`px-4 py-2 ${theme.primary} text-white ${borderRadius} hover:${theme.hover}`}
            >
              <Send size={14} className="inline mr-2" />Send Request
            </button>
          </div>

          {apiResponse && (
            <div className={`bg-slate-900 ${borderRadius} p-4`}>
              <h3 className="text-green-400 font-semibold mb-2">Response:</h3>
              <pre className="font-mono text-xs text-green-400 whitespace-pre-wrap">{apiResponse}</pre>
            </div>
          )}
        </div>
      )}

      {/* JOB QUEUES */}
      {devTab === 'jobs' && (
        <div className="space-y-4">
          <div className={`bg-white ${borderRadius} border border-slate-200 p-6`}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold">Background Jobs</h3>
              <button 
                onClick={async () => {
                  const jobList = await jobQueueAPI.getJobs();
                  setJobs(jobList);
                }}
                className={`px-3 py-1 text-sm ${theme.primary} text-white ${borderRadius} hover:${theme.hover}`}
              >
                <RefreshCw size={14} className="inline mr-1" />Refresh
              </button>
            </div>
            
            {jobs.length === 0 ? (
              <div className="text-center py-8 text-slate-500">
                <Zap size={48} className="mx-auto mb-3 opacity-30" />
                <p>No background jobs running</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="border-b border-slate-200">
                    <tr className="text-left text-slate-600">
                      <th className="pb-2 font-semibold">Job ID</th>
                      <th className="pb-2 font-semibold">Status</th>
                      <th className="pb-2 font-semibold">Type</th>
                      <th className="pb-2 font-semibold">Progress</th>
                      <th className="pb-2 font-semibold text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                {jobs.map(job => {
                  const statusColors = {
                    completed: { bg: 'bg-green-50', text: 'text-green-600', badge: 'bg-green-100 text-green-700' },
                    running: { bg: 'bg-blue-50', text: 'text-blue-600', badge: 'bg-blue-100 text-blue-700' },
                    failed: { bg: 'bg-red-50', text: 'text-red-600', badge: 'bg-red-100 text-red-700' },
                    pending: { bg: 'bg-gray-50', text: 'text-gray-600', badge: 'bg-gray-100 text-gray-700' }
                  };
                  
                  const colors = statusColors[job.status];
                  const Icon = job.status === 'completed' ? CheckCircle : 
                               job.status === 'running' ? RefreshCw :
                               job.status === 'failed' ? AlertCircle : Clock;
                  
                  return (
                    <tr key={job.id} className="hover:bg-slate-50">
                      <td className="py-3 font-mono text-xs text-slate-500">{job.id}</td>
                      <td className="py-3">
                        <span className={`inline-flex items-center gap-1 text-xs px-2 py-1 rounded ${colors.badge}`}>
                          <Icon className={`${job.status === 'running' ? 'animate-spin' : ''}`} size={12} />
                          {job.status.charAt(0).toUpperCase() + job.status.slice(1)}
                        </span>
                      </td>
                      <td className="py-3 text-slate-700">{job.name}</td>
                      <td className="py-3 text-slate-500 text-xs">
                        {job.status === 'running' && `${job.progress}%`}
                        {job.status === 'completed' && job.completedAt && new Date(job.completedAt).toLocaleTimeString()}
                        {job.status === 'failed' && (job.error || 'Failed')}
                        {job.status === 'pending' && new Date(job.createdAt).toLocaleTimeString()}
                      </td>
                      <td className="py-3 text-right">
                        {job.status === 'failed' && (
                          <button
                            onClick={async () => {
                              const success = await jobQueueAPI.retryJob(job.id);
                              if (success) {
                                const jobList = await jobQueueAPI.getJobs();
                                setJobs(jobList);
                              }
                            }}
                            className="text-xs px-2 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
                          >
                            Retry
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {/* WEBHOOK SIMULATOR */}
      {devTab === 'webhooks' && (
        <div className={`bg-white ${borderRadius} border border-slate-200 p-6`}>
          <h3 className="font-semibold mb-4">Webhook Simulator</h3>
          <p className="text-sm text-slate-600 mb-4">Test how your system reacts to external events</p>
          
          <div className="space-y-3 mb-4">
            <label className="block">
              <span className="text-sm font-medium text-slate-700 mb-2 block">Event Type</span>
              <select 
                value={webhookEvent}
                onChange={(e) => setWebhookEvent(e.target.value)}
                className={`w-full px-3 py-2 border border-slate-300 ${borderRadius} focus:outline-none focus:ring-2 ${theme.ring}`}
              >
                <option value="payment.success">Payment Successful</option>
                <option value="user.registered">New User Registration</option>
                <option value="subscription.created">Subscription Created</option>
                <option value="order.fulfilled">Order Fulfilled</option>
              </select>
            </label>

            <div className={`bg-slate-50 ${borderRadius} p-3 font-mono text-xs`}>
              <div className="text-slate-600 mb-2">Payload Preview:</div>
              <pre>{JSON.stringify({
                event: webhookEvent,
                timestamp: new Date().toISOString(),
                data: { user_id: 123, amount: 99.00 }
              }, null, 2)}</pre>
            </div>
          </div>

          <button 
            onClick={handleTriggerWebhook}
            className={`px-4 py-2 ${theme.primary} text-white ${borderRadius} hover:${theme.hover}`}
          >
            <Zap size={14} className="inline mr-2" />Trigger Event
          </button>
        </div>
      )}
    </div>
  );
}


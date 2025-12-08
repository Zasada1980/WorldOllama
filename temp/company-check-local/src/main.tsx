import { StrictMode, useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import AdminPanel from './AdminPanel.tsx'
import App from './App.tsx'
import './index.css'

function Root() {
  const [isAdmin, setIsAdmin] = useState(false);
  const [showAdminPanel, setShowAdminPanel] = useState(false);
  const ADMIN_PASSWORD = 'admin2024';

  // Check session storage for admin auth
  useEffect(() => {
    const savedAuth = sessionStorage.getItem('admin_authenticated');
    if (savedAuth === 'true') {
      setIsAdmin(true);
    }
  }, []);

  const handleAdminLogin = (password: string) => {
    if (password === ADMIN_PASSWORD) {
      setIsAdmin(true);
      setShowAdminPanel(true);
      sessionStorage.setItem('admin_authenticated', 'true');
      return true;
    }
    return false;
  };

  const handleAdminLogout = () => {
    // Выход только из панели админа, но статус админа сохраняется
    setShowAdminPanel(false);
    // НЕ удаляем isAdmin и sessionStorage - админ остаётся в системе
  };

  const handleOpenAdminPanel = () => {
    if (isAdmin) {
      setShowAdminPanel(true);
    }
  };

  if (showAdminPanel) {
    return <AdminPanel onLogout={handleAdminLogout} />;
  }

  return <App onAdminLogin={handleAdminLogin} isAdmin={isAdmin} onOpenAdminPanel={handleOpenAdminPanel} />;
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Root />
  </StrictMode>,
)

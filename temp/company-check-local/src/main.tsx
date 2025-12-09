import { StrictMode, useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import AdminPanel from './AdminPanel.tsx'
import App from './App.tsx'
import './index.css'

function Root() {
  const [isAdmin, setIsAdmin] = useState(false);
  const [showAdminPanel, setShowAdminPanel] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const ADMIN_PASSWORD = 'admin2024';

  // Check session storage for admin auth + URL routing
  useEffect(() => {
    const savedAuth = sessionStorage.getItem('admin_authenticated');
    if (savedAuth === 'true') {
      setIsAdmin(true);
    }

    // URL-based routing: если URL = /admin, открываем админ панель
    if (window.location.pathname === '/admin') {
      if (savedAuth === 'true') {
        setShowAdminPanel(true);
      } else {
        setShowPasswordModal(true);
      }
    }
  }, []);

  // Слушаем изменения URL (browser back/forward button)
  useEffect(() => {
    const handlePopState = () => {
      if (window.location.pathname === '/admin') {
        if (isAdmin) {
          setShowAdminPanel(true);
        } else {
          setShowPasswordModal(true);
        }
      } else {
        setShowAdminPanel(false);
        setShowPasswordModal(false);
      }
    };
    
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, [isAdmin]);

  const handleAdminLogin = (password: string) => {
    if (password === ADMIN_PASSWORD) {
      setIsAdmin(true);
      setShowAdminPanel(true);
      setShowPasswordModal(false);
      sessionStorage.setItem('admin_authenticated', 'true');
      // Обновляем URL на /admin
      window.history.pushState({}, '', '/admin');
      return true;
    }
    return false;
  };

  const handleAdminLogout = () => {
    // Выход только из панели админа, но статус админа сохраняется
    setShowAdminPanel(false);
    // Возвращаем на главную страницу
    window.history.pushState({}, '', '/');
  };

  const handleOpenAdminPanel = () => {
    if (isAdmin) {
      setShowAdminPanel(true);
      window.history.pushState({}, '', '/admin');
    }
  };

  if (showAdminPanel) {
    return <AdminPanel onLogout={handleAdminLogout} />;
  }

  return <App 
    onAdminLogin={handleAdminLogin} 
    isAdmin={isAdmin} 
    onOpenAdminPanel={handleOpenAdminPanel}
    showPasswordModal={showPasswordModal}
    onClosePasswordModal={() => {
      setShowPasswordModal(false);
      window.history.pushState({}, '', '/');
    }}
  />;
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Root />
  </StrictMode>,
)

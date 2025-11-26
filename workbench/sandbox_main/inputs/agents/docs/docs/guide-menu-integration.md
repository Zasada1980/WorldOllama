
===========================================
ИНТЕГРАЦИЯ СТРАНИЦЫ РУКОВОДСТВА В МЕНЮ UI
===========================================

Страница руководства доступна по адресу:
http://localhost:3000/static/agent-guide.html

Для добавления ссылки в навигационное меню Open WebUI:

ВАРИАНТ 1: Через custom.css (простой способ)
---------------------------------------------
Добавьте в E:\AGENTS\open-webui-bridge\static\custom.css:

/* Кнопка руководства в шапке */
.nav-menu::after {
    content: "📚 Руководство";
    display: inline-block;
    padding: 8px 16px;
    margin-left: 10px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
}

.nav-menu::after:hover {
    opacity: 0.9;
    transform: translateY(-2px);
}


ВАРИАНТ 2: Через JavaScript inject (динамический)
---------------------------------------------------
Добавьте в E:\AGENTS\open-webui-bridge\static\loader.js:

(function() {
    // Добавляем кнопку "Руководство" в навигацию
    window.addEventListener('load', function() {
        setTimeout(function() {
            const nav = document.querySelector('nav') || document.querySelector('.navbar');
            if (nav) {
                const guideBtn = document.createElement('a');
                guideBtn.href = '/static/agent-guide.html';
                guideBtn.target = '_blank';
                guideBtn.innerHTML = '📚 Руководство';
                guideBtn.style.cssText = `
                    padding: 8px 16px;
                    margin-left: 10px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border-radius: 6px;
                    text-decoration: none;
                    font-weight: 500;
                    transition: all 0.3s;
                `;
                guideBtn.addEventListener('mouseenter', function() {
                    this.style.opacity = '0.9';
                    this.style.transform = 'translateY(-2px)';
                });
                guideBtn.addEventListener('mouseleave', function() {
                    this.style.opacity = '1';
                    this.style.transform = 'translateY(0)';
                });
                nav.appendChild(guideBtn);
            }
        }, 1000);
    });
})();


ВАРИАНТ 3: Модификация БД (постоянная интеграция)
--------------------------------------------------
Добавьте кастомную ссылку в sidebar через БД:

sqlite3 E:\AGENTS\open-webui-bridge\data\webui.db

INSERT INTO config (key, value) VALUES (
    'ui.sidebar.custom_links',
    '[{"name": "📚 Руководство", "url": "/static/agent-guide.html", "target": "_blank"}]'
);


ВАРИАНТ 4: Промпт для добавления в начало каждого чата
-------------------------------------------------------
Создайте промпт в Workspace → Prompts:

Command: /help
Title: Помощь по интерфейсу
Content: "Для получения полного руководства по интерфейсу откройте: http://localhost:3000/static/agent-guide.html"


РЕКОМЕНДУЕМЫЙ ПОДХОД:
----------------------
Используйте ВАРИАНТ 2 (JavaScript inject) — самый гибкий и не требует модификации исходного кода.

Инструкции сохранены в: E:\AGENTS\docs\guide-menu-integration.md

# Deployment Script для CompanyCheck

## Метод 1: SCP загрузка (рекомендуется)

### Windows (PowerShell с OpenSSH)

```powershell
# 1. Создать архив dist папки
cd e:\WORLD_OLLAMA\temp\company-check-local
Compress-Archive -Path dist\* -DestinationPath company-check-dist.zip -Force

# 2. Загрузить на сервер через SCP
scp company-check-dist.zip root@46.224.36.109:/root/

# 3. SSH подключение для распаковки
ssh root@46.224.36.109

# 4. На сервере:
cd /root
unzip -o company-check-dist.zip -d /var/www/html/company-check
chown -R www-data:www-data /var/www/html/company-check
chmod -R 755 /var/www/html/company-check
```

## Метод 2: SFTP (если нет SCP)

### Используя WinSCP или FileZilla

1. **Подключение:**

   - Host: `46.224.36.109`
   - Port: `22`
   - Protocol: `SFTP`
   - Username: `root`
   - Password: `ваш_пароль`

2. **Загрузка:**
   - Локальная папка: `e:\WORLD_OLLAMA\temp\company-check-local\dist`
   - Удалённая папка: `/var/www/html/company-check`

## Метод 3: Git + Webhook (автоматический деплой)

### На локальной машине:

```bash
# Создать git репозиторий (если ещё нет)
cd e:\WORLD_OLLAMA\temp\company-check-local
git init
git add .
git commit -m "Initial commit - CompanyCheck v1.0"

# Добавить remote (GitHub/GitLab)
git remote add origin https://github.com/ваш_username/company-check.git
git push -u origin main
```

### На сервере:

```bash
# Клонировать репозиторий
cd /var/www/html
git clone https://github.com/ваш_username/company-check.git

# Установить зависимости и собрать
cd company-check
npm install
npm run build

# Настроить Nginx на dist папку
```

## Метод 4: rsync (быстрая синхронизация)

```powershell
# Windows с WSL или Git Bash
rsync -avz -e ssh e:/WORLD_OLLAMA/temp/company-check-local/dist/ root@46.224.36.109:/var/www/html/company-check/
```

## Настройка Nginx на сервере

### Создать конфигурацию:

```bash
sudo nano /etc/nginx/sites-available/company-check
```

### Содержимое конфига:

```nginx
server {
    listen 80;
    server_name 46.224.36.109 companycheck.example.com;

    root /var/www/html/company-check;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Кэширование статики
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
```

### Активировать конфиг:

```bash
sudo ln -s /etc/nginx/sites-available/company-check /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## SSL сертификат (опционально)

```bash
# Установить Certbot
sudo apt install certbot python3-certbot-nginx -y

# Получить SSL сертификат
sudo certbot --nginx -d companycheck.example.com
```

## Быстрый деплой (Готовый PowerShell скрипт)

Создайте файл `deploy.ps1`:

```powershell
# deploy.ps1
param(
    [string]$ServerIP = "46.224.36.109",
    [string]$ServerUser = "root",
    [string]$RemotePath = "/var/www/html/company-check"
)

Write-Host "🚀 Starting deployment to $ServerIP..." -ForegroundColor Cyan

# Build
Write-Host "📦 Building production..." -ForegroundColor Yellow
cd e:\WORLD_OLLAMA\temp\company-check-local
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Create archive
Write-Host "📁 Creating archive..." -ForegroundColor Yellow
Compress-Archive -Path dist\* -DestinationPath company-check-dist.zip -Force

# Upload via SCP
Write-Host "⬆️  Uploading to server..." -ForegroundColor Yellow
scp company-check-dist.zip ${ServerUser}@${ServerIP}:/tmp/

# Deploy on server
Write-Host "🔧 Deploying on server..." -ForegroundColor Yellow
ssh ${ServerUser}@${ServerIP} @"
    cd /tmp
    unzip -o company-check-dist.zip -d $RemotePath
    chown -R www-data:www-data $RemotePath
    chmod -R 755 $RemotePath
    rm company-check-dist.zip
    echo '✅ Deployment complete!'
"@

# Cleanup
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
Remove-Item company-check-dist.zip -Force

Write-Host "✅ Deployment successful! Visit http://$ServerIP" -ForegroundColor Green
```

### Запуск:

```powershell
.\deploy.ps1
```

## Проверка деплоя

После загрузки откройте в браузере:

- **HTTP**: http://46.224.36.109/company-check
- **Или с доменом**: http://your-domain.com

### Логи Nginx (если не работает):

```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## Troubleshooting

### Ошибка 403 Forbidden

```bash
sudo chown -R www-data:www-data /var/www/html/company-check
sudo chmod -R 755 /var/www/html/company-check
```

### Ошибка 404 Not Found

Проверьте `try_files` в Nginx конфиге (для SPA важно!)

### Файлы не обновляются

```bash
# Очистить кэш браузера или:
sudo systemctl reload nginx
```

### CORS ошибки с API

Добавьте в Nginx:

```nginx
add_header Access-Control-Allow-Origin *;
add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
```

---

**Версия**: 1.0.0  
**Дата**: 08.12.2025  
**Размер build**: ~220 KB (gzipped: ~72 KB)

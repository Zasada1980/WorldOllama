$filePath = "src\App.tsx"
$lines = Get-Content $filePath

# Удаляем строки 202-214 (demo fallback)
$newLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    # Пропускаем строки 202-214 (demo fallback)
    if ($i -ge 202 -and $i -le 214) {
        continue
    }
    
    # Заменяем строку 196
    if ($i -eq 196) {
        $newLines += "      console.log('No records found in any API source');"
        continue
    }
    
    # Заменяем строку 197
    if ($i -eq 197) {
        $newLines += "      throw new Error('No results found in official databases');"
        continue
    }
    
    # Заменяем строку 200 (добавляем setIsSearching)
    if ($i -eq 200) {
        $newLines += "      console.error('Search error:', error);"
        $newLines += "      setIsSearching(false);"
        $newLines += "      "
        $newLines += "      // Реалистичное сообщение об ошибке (БЕЗ демо-данных)"
        continue
    }
    
    # Заменяем строки 216-220 (ошибки)
    if ($i -eq 216) {
        $newLines += "      const errorMsg = locale === 'he'"
        continue
    }
    if ($i -eq 217) {
        $newLines += "        ? ``мידע על החברה לא נמצא במאגרי המידע הרשמיים.\n\nסיבות אפשריות:\n• החברה לא רשומה בישראל\n• מספר החברה שגוי\n• הנתונים טרם עודכנו במאגר הממשלתי\n\nנסה:\n• בדוק את מספר החברה\n• חפש לפי שם החברה בעברית\n• השתמש במקורות נתונים אחרים``"
        continue
    }
    if ($i -eq 218) {
        $newLines += "        : locale === 'ru'"
        continue
    }
    if ($i -eq 219) {
        $newLines += "        ? ``Информация о компании не найдена в официальных базах данных.\n\nВозможные причины:\n• Компания не зарегистрирована в Израиле\n• Номер компании указан неверно\n• Данные еще не загружены в государственный реестр\n\nПопробуйте:\n• Проверить правильность номера компании\n• Искать по названию компании на иврите\n• Использовать другие источники данных``"
        continue
    }
    if ($i -eq 220) {
        $newLines += "        : ``Company information not found in official databases.\n\nPossible reasons:\n• Company not registered in Israel\n• Incorrect company number\n• Data not yet updated in government registry\n\nTry:\n• Verify the company number\n• Search by Hebrew company name\n• Use alternative data sources``;"
        continue
    }
    
    # Удаляем строку 225 (дублирование setIsSearching)
    if ($i -eq 225) {
        continue
    }
    
    $newLines += $lines[$i]
}

# Сохраняем файл
Set-Content $filePath -Value $newLines -Encoding UTF8
Write-Host "✅ Successfully removed demo fallback and updated error messages" -ForegroundColor Green
Write-Host "Removed lines: 202-214 (demo fallback)" -ForegroundColor Yellow
Write-Host "Updated lines: 196-197, 200, 216-220 (error messages)" -ForegroundColor Yellow
Write-Host "Removed line: 225 (duplicate setIsSearching)" -ForegroundColor Yellow

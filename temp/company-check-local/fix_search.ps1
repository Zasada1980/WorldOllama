$filePath = "src\App.tsx"
$content = Get-Content $filePath -Raw

# Удаляем блок с demo fallback
$oldBlock = @"
      // Не найдено в API
      console.log('No records found in API response');
      throw new Error('No results found');
      
    } catch (error) {
      console.error('Search error:', error);
      
      // Проверяем, это известная компания для демо?
      if (searchQuery.includes('516053675') || searchQuery.toLowerCase().includes('metal')) {
        console.log('Using mock data for demo company');
        setSelectedCompany(MOCK_COMPANY);
        setView('preview');
        
        if (!searchHistory.includes(searchQuery)) {
          setSearchHistory(prev => [searchQuery, ...prev].slice(0, 10));
        }
        
        setIsSearching(false);
        return;
      }
      
      const errorMsg = locale === 'he' 
        ? `חברה לא נמצאה בבסיס הנתונים.\nAPI החזיר תשובה ריקה.\nנסה: 516053675 או "metal"`
        : locale === 'ru' 
        ? `Компания не найдена в базе данных.\nAPI вернул пустой ответ.\nПопробуйте: 516053675 או "metal"`
        : `Company not found in database.\nAPI returned empty results.\nTry: 516053675 or "metal"`;
      
      alert(errorMsg);
    }
    
    setIsSearching(false);
"@

$newBlock = @"
      // Не найдено в API - реалистичное сообщение
      console.log('No records found in any API source');
      throw new Error('No results found in official databases');
      
    } catch (error) {
      console.error('Search error:', error);
      setIsSearching(false);
      
      // Реалистичное сообщение об ошибке (БЕЗ демо-данных)
      const errorMsg = locale === 'he' 
        ? `מידע על החברה לא נמצא במאגרי המידע הרשמיים.\n\nסיבות אפשריות:\n• החברה לא רשומה בישראל\n• מספר החברה שגוי\n• הנתונים טרם עודכנו במאגר הממשלתי\n\nנסה:\n• בדוק את מספר החברה\n• חפש לפי שם החברה בעברית\n• השתמש במקורות נתונים אחרים`
        : locale === 'ru' 
        ? `Информация о компании не найдена в официальных базах данных.\n\nВозможные причины:\n• Компания не зарегистрирована в Израиле\n• Номер компании указан неверно\n• Данные еще не загружены в государственный реестр\n\nПопробуйте:\n• Проверить правильность номера компании\n• Искать по названию компании на иврите\n• Использовать другие источники данных`
        : `Company information not found in official databases.\n\nPossible reasons:\n• Company not registered in Israel\n• Incorrect company number\n• Data not yet updated in government registry\n\nTry:\n• Verify the company number\n• Search by Hebrew company name\n• Use alternative data sources`;
      
      alert(errorMsg);
    }
"@

# Замена
if ($content -match [regex]::Escape($oldBlock)) {
    $content = $content -replace [regex]::Escape($oldBlock), $newBlock
    Set-Content $filePath -Value $content -NoNewline -Encoding UTF8
    Write-Host "✅ Successfully removed demo fallback" -ForegroundColor Green
}
else {
    Write-Host "❌ Pattern not found" -ForegroundColor Red
    Write-Host "Searching for partial match..."
    if ($content -match "516053675.*metal") {
        Write-Host "Found demo code, trying alternative replacement..." -ForegroundColor Yellow
    }
}

@echo off
setlocal EnableExtensions

rem Updates the embedded song list in songs_search.html from songs.csv.
rem Put this .bat in the same folder as songs_search.html and songs.csv, then double-click it.

set "SCRIPT_DIR=%~dp0"
set "CSV_FILE=%SCRIPT_DIR%songs.csv"
set "HTML_FILE=%SCRIPT_DIR%songs_search.html"
set "BACKUP_FILE=%SCRIPT_DIR%songs_search.backup.html"
set "PS1_FILE=%TEMP%\update_song_list_%RANDOM%%RANDOM%.ps1"

if not exist "%CSV_FILE%" (
  echo ERROR: Cannot find "%CSV_FILE%".
  echo Make sure songs.csv is in the same folder as this BAT file.
  pause
  exit /b 1
)

if not exist "%HTML_FILE%" (
  echo ERROR: Cannot find "%HTML_FILE%".
  echo Make sure songs_search.html is in the same folder as this BAT file.
  pause
  exit /b 1
)

> "%PS1_FILE%" echo param([string]$CsvPath, [string]$HtmlPath, [string]$BackupPath)
>> "%PS1_FILE%" echo $ErrorActionPreference = 'Stop'
>> "%PS1_FILE%" echo $rows = Import-Csv -LiteralPath $CsvPath
>> "%PS1_FILE%" echo $entries = foreach ($row in $rows) {
>> "%PS1_FILE%" echo   $title = ''
>> "%PS1_FILE%" echo   $artist = ''
>> "%PS1_FILE%" echo   if ($row.PSObject.Properties.Name -contains 'Name') { $title = [string]$row.Name }
>> "%PS1_FILE%" echo   elseif ($row.PSObject.Properties.Name -contains 'Title') { $title = [string]$row.Title }
>> "%PS1_FILE%" echo   elseif ($row.PSObject.Properties.Name -contains 'Song') { $title = [string]$row.Song }
>> "%PS1_FILE%" echo   if ($row.PSObject.Properties.Name -contains 'Artist') { $artist = [string]$row.Artist }
>> "%PS1_FILE%" echo   elseif ($row.PSObject.Properties.Name -contains 'Artists') { $artist = [string]$row.Artists }
>> "%PS1_FILE%" echo   if (-not [string]::IsNullOrWhiteSpace($title) -or -not [string]::IsNullOrWhiteSpace($artist)) {
>> "%PS1_FILE%" echo     [pscustomobject]@{ artist = $artist.Trim(); title = $title.Trim() }
>> "%PS1_FILE%" echo   }
>> "%PS1_FILE%" echo }
>> "%PS1_FILE%" echo $json = $entries ^| ConvertTo-Json -Depth 3
>> "%PS1_FILE%" echo if ($null -eq $json -or $json.Trim().Length -eq 0) { $json = '[]' }
>> "%PS1_FILE%" echo $replacement = "const entries = $json;"
>> "%PS1_FILE%" echo $html = [System.IO.File]::ReadAllText($HtmlPath, [System.Text.Encoding]::UTF8)
>> "%PS1_FILE%" echo Copy-Item -LiteralPath $HtmlPath -Destination $BackupPath -Force
>> "%PS1_FILE%" echo $pattern = '(?s)const\s+entries\s*=.*?(?=\r?\n\s*//\s*search logic)'
>> "%PS1_FILE%" echo if ($html -notmatch $pattern) { throw 'Could not find the "const entries =" block before "// search logic" in the HTML file.' }
>> "%PS1_FILE%" echo $updated = [regex]::Replace($html, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })
>> "%PS1_FILE%" echo $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
>> "%PS1_FILE%" echo [System.IO.File]::WriteAllText($HtmlPath, $updated, $utf8NoBom)
>> "%PS1_FILE%" echo Write-Host "Updated $HtmlPath with $($entries.Count) songs."
>> "%PS1_FILE%" echo Write-Host "Backup saved as $BackupPath"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" "%CSV_FILE%" "%HTML_FILE%" "%BACKUP_FILE%"
set "RC=%ERRORLEVEL%"
del "%PS1_FILE%" >nul 2>nul

if not "%RC%"=="0" (
  echo.
  echo Update failed.
  pause
  exit /b %RC%
)

echo.
echo Done.
pause
exit /b 0

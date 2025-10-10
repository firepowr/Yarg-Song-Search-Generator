@echo off
setlocal

REM === Paths to your files ===
set TXTFILE=songslist.txt
set HTMLFILE=songs_search.html
set OUTFILE=songs_search_updated.html

REM === Use PowerShell to parse TXT and rebuild JSON ===
powershell -NoLogo -NoProfile -Command ^
  "$txt = Get-Content '%TXTFILE%';" ^
  "$entries = @();" ^
  "for ($i=0; $i -lt $txt.Length; $i++) {" ^
  "  if ($txt[$i] -match '^-+$') { continue }" ^
  "  elseif ($txt[$i] -match '^(.*) - (.*)$') {" ^
  "    $artist = $Matches[1].Trim();" ^
  "    $title  = $Matches[2].Trim();" ^
  "    $entries += [PSCustomObject]@{ artist=$artist; title=$title }" ^
  "  }" ^
  "}" ^
  "$json = $entries | ConvertTo-Json -Compress;" ^
  "$html = Get-Content '%HTMLFILE%' -Raw;" ^
  "$html = [Regex]::Replace($html, '(?s)(const entries = ).*?(;)', ('$1' + $json + ';'));" ^
  "Set-Content '%OUTFILE%' $html -Encoding UTF8;"

echo Done! Updated file is %OUTFILE%
pause

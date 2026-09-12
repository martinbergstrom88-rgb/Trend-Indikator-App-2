$manifest = ".\android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $manifest)) { throw "AndroidManifest.xml hittades inte." }
$text = Get-Content $manifest -Raw -Encoding UTF8
$text = [regex]::Replace($text, 'android:label="[^"]*"', 'android:label="Trading Indicator"', 1)
Set-Content $manifest $text -Encoding UTF8
Write-Host "Appnamnet ar nu Trading Indicator i AndroidManifest.xml"

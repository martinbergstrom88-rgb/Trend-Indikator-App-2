$project = Get-Location
$target = Join-Path $project "android\app\src\main\res"
Copy-Item ".\android\app\src\main\res\values\styles.xml" "$target\values\styles.xml" -Force
New-Item -ItemType Directory -Path "$target\values-v31" -Force | Out-Null
Copy-Item ".\android\app\src\main\res\values-v31\styles.xml" "$target\values-v31\styles.xml" -Force
$manifest = ".\android\app\src\main\AndroidManifest.xml"
$content = Get-Content $manifest -Raw -Encoding UTF8
$content = [regex]::Replace($content, 'android:label="[^"]*"', 'android:label="Trading Indicator"', 1)
Set-Content $manifest $content -Encoding UTF8
Write-Host "Trading Indicator 4.0 Android-resurser installerade."

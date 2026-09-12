$res = ".\android\app\src\main\res"
Copy-Item ".\android-overrides\res\drawable\transparent_splash.png" "$res\drawable\transparent_splash.png" -Force
Copy-Item ".\android-overrides\res\drawable-v21\transparent_splash.png" "$res\drawable-v21\transparent_splash.png" -Force
Copy-Item ".\android-overrides\res\values\colors.xml" "$res\values\colors.xml" -Force
Copy-Item ".\android-overrides\res\values-v31\styles.xml" "$res\values-v31\styles.xml" -Force
$manifest = ".\android\app\src\main\AndroidManifest.xml"
$m = Get-Content $manifest -Raw -Encoding UTF8
$m = [regex]::Replace($m, 'android:label="[^"]*"', 'android:label="Trading Indicator"', 1)
Set-Content $manifest $m -Encoding UTF8
Write-Host "Androidnamn och splash-resurser uppdaterade."

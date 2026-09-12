$manifest=".\android\app\src\main\AndroidManifest.xml"
$m=Get-Content $manifest -Raw -Encoding UTF8
if($m -notmatch 'POST_NOTIFICATIONS'){$m=$m -replace '<manifest([^>]*)>','<manifest$1>`r`n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />'}
Set-Content $manifest $m -Encoding UTF8
$settings=".\android\settings.gradle.kts"
if(Test-Path $settings){$s=Get-Content $settings -Raw;if($s -notmatch 'com.google.gms.google-services'){$s=$s -replace 'plugins \{','plugins {`r`n    id("com.google.gms.google-services") version "4.4.3" apply false'};Set-Content $settings $s}
$app=".\android\app\build.gradle.kts"
if(Test-Path $app){$a=Get-Content $app -Raw;if($a -notmatch 'com.google.gms.google-services'){$a=$a -replace 'plugins \{','plugins {`r`n    id("com.google.gms.google-services")'};Set-Content $app $a}
Write-Host "Firebase Android-konfiguration installerad."

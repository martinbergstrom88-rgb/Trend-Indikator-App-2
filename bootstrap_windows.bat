@echo off
where flutter >nul 2>nul || (echo Flutter hittades inte. Installera Flutter och lagg till det i PATH.& pause & exit /b 1)
flutter create . --project-name trend_indikator --org se.martinbergstrom
flutter pub get
dart run flutter_launcher_icons
flutter analyze
pause

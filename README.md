# Trend Indikator Flutter MVP

Detta är Flutter-klienten till Trend Indikator API. Appen innehåller Favoriter, Innehav med utveckling från köp, Marknad, Larm, Inställningar, detaljvy och TradingView-länk.

## 1. Installera Flutter

Installera Flutter SDK och Android Studio, kör sedan:

```powershell
flutter doctor
```

## 2. Skapa Android/iOS-plattformsfiler

Kör från projektmappen:

```powershell
flutter create . --project-name trend_indikator --org se.martinbergstrom
flutter pub get
dart run flutter_launcher_icons
```

Kontrollera att `android/app/src/main/AndroidManifest.xml` innehåller internetbehörighet:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

För lokal utveckling mot `http://` kan debug-versionen behöva `android:usesCleartextTraffic="true"` på application-taggen. Använd HTTPS när API:t publiceras.

## 3. Starta backend

Starta det tidigare levererade Trend Indikator API:t med `run_api.bat`.

## 4. API-adress

- Android-emulator: `http://10.0.2.2:8000`
- Fysisk Android på samma Wi-Fi: `http://DIN-DATORS-IP:8000`

API-adressen kan ändras i appens flik Inställningar.

## 5. Kör

```powershell
flutter run
```

Skapa APK:

```powershell
flutter build apk --release
```

APK hamnar i `build/app/outputs/flutter-apk/app-release.apk`.

## Pushnotiser

UI och backendinställningen för signaländringar är förberedd. Riktig bakgrundsleverans kräver Firebase-konfiguration och servernycklar. Kör `flutterfire configure` när Firebase-projektet har skapats. Hemliga nycklar ska aldrig läggas i appkoden.

from pathlib import Path
import shutil

ROOT = Path.cwd()
SOURCE = ROOT / "lib" / "main.dart"
BACKUP = ROOT / "lib" / "main_before_cleanup.dart.bak"

if not SOURCE.is_file():
    raise SystemExit(f"Hittar inte {SOURCE}. Kor scriptet fran Flutterprojektets rot.")

text = SOURCE.read_text(encoding="utf-8")
anchors = [
    ("core/api_and_models.dart", "class Api {"),
    ("screens/app_shell.dart", "class AppShell extends StatefulWidget"),
    ("widgets/shared_widgets.dart", "class Header extends StatelessWidget"),
    ("screens/favorites_page.dart", "class FavoritesPage extends StatefulWidget"),
    ("screens/holdings_page.dart", "class HoldingsPage extends StatefulWidget"),
    ("screens/market_page.dart", "class MarketPage extends StatefulWidget"),
    ("screens/alerts_page.dart", "class AlertsPage extends StatefulWidget"),
    ("screens/settings_page.dart", "class SettingsPage extends StatelessWidget"),
    ("screens/asset_detail_page.dart", "Future<bool> openDetail("),
    ("dialogs/dialogs.dart", "Widget metric("),
]

positions = []
for filename, anchor in anchors:
    position = text.find(anchor)
    if position < 0:
        raise SystemExit(
            f"Avbryter utan andringar. Hittade inte ankaret: {anchor!r}. "
            "Kontrollera att main.dart ar den fungerande 5.2.6-versionen."
        )
    positions.append((filename, anchor, position))

if positions != sorted(positions, key=lambda item: item[2]):
    raise SystemExit("Avbryter. Deklarationerna ligger inte i forvantad ordning.")

if BACKUP.exists():
    raise SystemExit(
        f"Backup finns redan: {BACKUP}. Cleanup verkar redan vara kord. "
        "Aterstall eller byt namn pa backupen innan du kor igen."
    )

shutil.copy2(SOURCE, BACKUP)

preamble = text[:positions[0][2]].rstrip()
part_lines = [f"part '{filename}';" for filename, _, _ in positions]
SOURCE.write_text(
    preamble + "\n\n" + "\n".join(part_lines) + "\n",
    encoding="utf-8",
)

for index, (filename, _, start) in enumerate(positions):
    end = positions[index + 1][2] if index + 1 < len(positions) else len(text)
    destination = ROOT / "lib" / filename
    destination.parent.mkdir(parents=True, exist_ok=True)
    body = text[start:end].strip()
    destination.write_text(
        "part of '../main.dart';\n\n" + body + "\n",
        encoding="utf-8",
    )

print("[OK] Flutter cleanup 1 skapad.")
print(f"[OK] Backup: {BACKUP}")
print("[NEXT] Kor: dart format lib")
print("[NEXT] Kor: flutter analyze")
print("[NEXT] Kor: flutter run -d 56181FDCR006V2")

from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path.cwd()
LIB = ROOT / "lib"
BACKUP = ROOT / "cleanup_backup_step3"

if not (ROOT / "pubspec.yaml").is_file() or not (LIB / "main.dart").is_file():
    raise SystemExit("Kor scriptet fran Flutterprojektets rot, dar pubspec.yaml ligger.")

part_files = list(LIB.rglob("*.dart"))
if not part_files:
    raise SystemExit("Inga Dart-filer hittades under lib.")

if BACKUP.exists():
    raise SystemExit(
        "cleanup_backup_step3 finns redan. Ta bort eller byt namn pa mappen innan ny korning."
    )

# Back up the complete lib tree before applying Dart's own safe fixes.
shutil.copytree(LIB, BACKUP / "lib")


def run(command: list[str]) -> None:
    print("[RUN]", " ".join(command))
    result = subprocess.run(command, cwd=ROOT)
    if result.returncode != 0:
        print(f"[STOP] Kommandot misslyckades med kod {result.returncode}.")
        print(f"[INFO] Originalfilerna finns i {BACKUP / 'lib'}")
        sys.exit(result.returncode)


# Let the installed Dart SDK apply supported, analyzer-aware migrations.
run(["dart", "fix", "--apply"])
run(["dart", "format", "lib"])
run(["flutter", "analyze"])

print("[OK] Flutter Cleanup steg 3 ar klart.")
print("[OK] Dart fix, format och analyze gick igenom.")
print(f"[INFO] Backup finns i {BACKUP}")
print("[NEXT] flutter run -d 56181FDCR006V2")

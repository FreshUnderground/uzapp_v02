Set-Location "C:\Users\DIEU-MERCI\Music\uzaapp"
Remove-Item -Recurse -Force .dart_tool/build -ErrorAction SilentlyContinue
Remove-Item -Force lib/data/local/uza_database.g.dart -ErrorAction SilentlyContinue
flutter pub run build_runner build --delete-conflicting-outputs 2>&1

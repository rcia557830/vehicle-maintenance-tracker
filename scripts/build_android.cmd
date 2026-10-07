@echo off
setlocal
rem Only generated build files are adjusted; source files and vehicle data are untouched.
pushd "%~dp0.."
if errorlevel 1 exit /b 1
powershell -NoProfile -Command "$project = (Get-Location).Path; $build = Join-Path $project 'build'; if (Test-Path -LiteralPath $build) { if ((Resolve-Path -LiteralPath $build).Path -ne [IO.Path]::GetFullPath($build)) { throw 'Unexpected build directory' }; Get-ChildItem -LiteralPath $build -Recurse -Force -ErrorAction Stop | ForEach-Object { if ($_.Attributes -band [IO.FileAttributes]::ReadOnly) { $_.Attributes = $_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly) } } }"
if errorlevel 1 goto failed
call flutter pub get
if errorlevel 1 goto failed
call flutter analyze
if errorlevel 1 goto failed
if exist "config\supabase.json" (
  call flutter build apk --debug --dart-define-from-file=config/supabase.json
) else (
  echo No Supabase configuration found. Building with the setup screen.
  call flutter build apk --debug
)
if errorlevel 1 goto failed
echo APK ready: build\app\outputs\flutter-apk\app-debug.apk
popd
exit /b 0
:failed
echo Build failed. Review the error above.
popd
exit /b 1

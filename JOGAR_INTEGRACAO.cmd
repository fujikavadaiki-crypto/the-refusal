@echo off
setlocal
cd /d "%~dp0"
set "GODOT=C:\Users\daiki\Documents\Codex\2026-09-22\projeto-the-refusal-godot-4-7-4\work\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=C:\Users\daiki\Documents\Codex\2026-09-22\projeto-the-refusal-godot-4-7-4\work\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
  echo Godot 4.7.2 nao encontrado. Ajuste GODOT neste arquivo.
  pause
  exit /b 1
)
set "APPDATA=%~dp0.godot\p40_play_runtime\appdata"
set "LOCALAPPDATA=%~dp0.godot\p40_play_runtime\localappdata"
set "TEMP=%~dp0.godot\p40_play_runtime\temp"
set "TMP=%TEMP%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%TEMP%" mkdir "%TEMP%"
"%GODOT%" --path "%~dp0." res://scenes/biomes/cemiterio/sala_cemiterio.tscn
endlocal

@echo off
setlocal EnableExtensions
title Desinstalador de Dexi Pro
set "DEST=%APPDATA%\DexiPro"
set "MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Dexi Pro"
set "UNKEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\DexiPro"

rem Si se ejecuta desde la carpeta instalada (menu Inicio o Aplicaciones instaladas), se copia a TEMP
rem y sigue desde ahi para poder borrar la carpeta completa.
if /i "%~1"=="--temp" goto inicio
if /i not "%~dp0"=="%DEST%\" goto inicio
copy /Y "%~f0" "%TEMP%\DexiPro_Desinstalar.bat" >nul
cd /d "%TEMP%"
rem Sin "call": el control pasa a la copia y no vuelve aqui
"%TEMP%\DexiPro_Desinstalar.bat" --temp

:inicio

echo ==========================================
echo   Desinstalador de Dexi Pro
echo ==========================================
echo.
choice /c SN /m "Desinstalar Dexi Pro de este usuario"
if errorlevel 2 exit /b 0

:deswik
tasklist /fi "imagename eq Deswik.CAD.exe" 2>nul | find /i "Deswik.CAD.exe" >nul
if not errorlevel 1 (
  echo [ESPERA] Deswik CAD esta abierto y bloquea DexiPro.dll. Cierralo.
  choice /c RC /m "Cuando lo cierres pulsa R para reintentar (C cancela)"
  if errorlevel 2 exit /b 1
  goto deswik
)

if not exist "%DEST%" (
  echo La carpeta %DEST% no existe: el programa ya no estaba.
  goto registro
)

rem Quita el registro del plugin en todas las versiones de Deswik (antes de borrar el script)
if exist "%DEST%\DexiPro_Registro.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\DexiPro_Registro.ps1" -Accion quitar
) else (
  echo [AVISO] No encontre DexiPro_Registro.ps1: quita Dexi Pro a mano desde el Plugin Manager de Deswik.
)

echo.
echo En %DEST% tambien estan tus datos: ajustes ^(config.json^), logs y la ultima optimizacion.
choice /c SN /m "Conservar tus datos (por si reinstalas)"
if errorlevel 2 goto borrartodo

del /q "%DEST%\DexiPro.dll" "%DEST%\Newtonsoft.Json.dll" "%DEST%\UglyToad.PdfPig*.dll" "%DEST%\Macro_DexiPro.txt" "%DEST%\LEEME.txt" "%DEST%\Manual_DexiPro.pdf" "%DEST%\Desinstalar.bat" "%DEST%\DexiPro_Registro.ps1" 2>nul
if exist "%DEST%\DexiPro.dll" (
  echo [ERROR] No se pudo borrar DexiPro.dll. Cierra Deswik por completo y vuelve a intentarlo.
  pause
  exit /b 1
)
echo [OK] Programa eliminado. Tus datos siguen en %DEST%.
goto registro

:borrartodo
rmdir /s /q "%DEST%"
if exist "%DEST%" (
  echo [ERROR] No se pudo borrar %DEST%. Cierra Deswik por completo y vuelve a intentarlo.
  pause
  exit /b 1
)
echo [OK] Carpeta %DEST% eliminada.

:registro
if exist "%MENU%" rmdir /s /q "%MENU%"
reg delete "%UNKEY%" /f >nul 2>&1
if exist "%TEMP%\DexiPro_dock_error.txt" del /q "%TEMP%\DexiPro_dock_error.txt"
echo [OK] Quitado del menu Inicio y de Aplicaciones instaladas.

echo.
echo La clave de Gemini ^(DEXI_GEMINI_KEY^) puede usarla otro programa ^(por ejemplo Dexi v1^).
choice /c SN /m "Borrar tambien tu clave de Gemini de este usuario"
if not errorlevel 2 (
  reg delete "HKCU\Environment" /v DEXI_GEMINI_KEY /f >nul 2>&1
  echo [OK] Clave eliminada.
)

echo.
echo Dexi Pro desinstalado. Si habias creado un boton de Dexi Pro en el Process Map, borralo a mano.
pause
exit /b 0

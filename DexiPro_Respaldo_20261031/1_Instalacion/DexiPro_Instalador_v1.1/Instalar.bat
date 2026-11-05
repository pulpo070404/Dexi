@echo off
setlocal EnableExtensions
title Instalador de Dexi Pro
set "VER=1.1.20261031"
set "DEST=%APPDATA%\DexiPro"
set "SRC=%~dp0"
set "MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Dexi Pro"
set "UNKEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\DexiPro"

echo ==========================================================
echo   Instalador de Dexi Pro %VER%
echo   Asistente de planeamiento minero para Deswik CAD
echo ==========================================================
echo  No necesita permisos de administrador: se instala solo
echo  para tu usuario de Windows, en %DEST%
echo.

rem --- 1) Archivos del paquete (si se ejecuta desde dentro del ZIP no estan)
for %%f in (DexiPro.dll Newtonsoft.Json.dll UglyToad.PdfPig.dll Macro_DexiPro.txt Desinstalar.bat DexiPro_Registro.ps1) do (
  if not exist "%SRC%%%f" (
    echo [ERROR] No encuentro %%f junto a este instalador.
    echo         Haz clic derecho en el ZIP, "Extraer todo", y ejecuta Instalar.bat desde la carpeta extraida.
    pause
    exit /b 1
  )
)

rem --- 2) Deswik debe estar cerrado (bloquea DexiPro.dll)
:deswik
tasklist /fi "imagename eq Deswik.CAD.exe" 2>nul | find /i "Deswik.CAD.exe" >nul
if not errorlevel 1 (
  echo [ESPERA] Deswik CAD esta abierto. Guarda tu trabajo y cierralo.
  choice /c RC /m "Cuando lo cierres pulsa R para reintentar (C cancela)"
  if errorlevel 2 exit /b 1
  goto deswik
)

rem --- 4) Copiar archivos (config.json, logs y la ultima optimizacion NO se tocan)
if not exist "%DEST%" mkdir "%DEST%"
for %%f in (DexiPro.dll Newtonsoft.Json.dll Macro_DexiPro.txt Desinstalar.bat DexiPro_Registro.ps1) do (
  copy /Y "%SRC%%%f" "%DEST%\" >nul || goto copiafallo
)
copy /Y "%SRC%UglyToad.PdfPig*.dll" "%DEST%\" >nul || goto copiafallo
if exist "%SRC%LEEME.txt" copy /Y "%SRC%LEEME.txt" "%DEST%\" >nul
if exist "%SRC%Manual_DexiPro.pdf" copy /Y "%SRC%Manual_DexiPro.pdf" "%DEST%\" >nul
rem Windows bloquea los archivos descargados de internet: se desbloquean
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%DEST%' -File | Unblock-File"
echo [OK] Archivos copiados a %DEST%
if exist "%DEST%\config.json" (echo [OK] Se conservan tus ajustes ^(config.json^).) else (echo      Tus ajustes se crean la primera vez que abras Dexi Pro.)

rem --- 5) Plugin de Deswik: se registra en todas las versiones de Deswik encontradas (se abre solo al iniciar Deswik)
powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\DexiPro_Registro.ps1" -Accion registrar
if errorlevel 1 goto registrofallo

rem --- 6) Menu Inicio (Manual y Desinstalar) y "Aplicaciones instaladas" de Windows
if not exist "%MENU%" mkdir "%MENU%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$w = New-Object -ComObject WScript.Shell;" ^
  "$m = $env:APPDATA + '\Microsoft\Windows\Start Menu\Programs\Dexi Pro';" ^
  "$d = $env:APPDATA + '\DexiPro';" ^
  "if (Test-Path ($d + '\Manual_DexiPro.pdf')) { $s = $w.CreateShortcut($m + '\Manual de Dexi Pro.lnk'); $s.TargetPath = $d + '\Manual_DexiPro.pdf'; $s.Save() };" ^
  "$s = $w.CreateShortcut($m + '\Desinstalar Dexi Pro.lnk'); $s.TargetPath = $d + '\Desinstalar.bat'; $s.WorkingDirectory = $env:TEMP; $s.Save();" ^
  "$s = $w.CreateShortcut($m + '\Carpeta de Dexi Pro (ajustes y logs).lnk'); $s.TargetPath = $d; $s.Save()"
reg add "%UNKEY%" /v DisplayName /d "Dexi Pro (plugin para Deswik CAD)" /f >nul
reg add "%UNKEY%" /v DisplayVersion /d "%VER%" /f >nul
reg add "%UNKEY%" /v Publisher /d "Dexi Pro" /f >nul
reg add "%UNKEY%" /v InstallLocation /d "%DEST%" /f >nul
reg add "%UNKEY%" /v UninstallString /d "\"%DEST%\Desinstalar.bat\"" /f >nul
reg add "%UNKEY%" /v NoModify /t REG_DWORD /d 1 /f >nul
reg add "%UNKEY%" /v NoRepair /t REG_DWORD /d 1 /f >nul
echo [OK] Accesos en el menu Inicio ^(carpeta Dexi Pro^) y en Configuracion ^> Aplicaciones instaladas.
echo.

rem --- 7) Clave de Gemini (cada persona usa la suya)
set "KEY="
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v DEXI_GEMINI_KEY 2^>nul ^| find "DEXI_GEMINI_KEY"') do set "KEY=%%b"
if defined KEY (
  echo Ya tienes una clave de Gemini guardada en este usuario.
  choice /c SN /m "Quieres reemplazarla"
  if errorlevel 2 goto listo
)
echo ----------------------------------------------------------
echo  CLAVE DE GEMINI ^(gratis^): entra con tu cuenta de Google a
echo     https://aistudio.google.com/apikey
echo  pulsa "Create API key" y copia la clave.
echo  Para pegarla aqui usa clic derecho ^(o Ctrl+V^) y luego Enter.
echo ----------------------------------------------------------
choice /c SN /m "Abrir esa pagina en el navegador ahora"
if not errorlevel 2 start "" "https://aistudio.google.com/apikey"
:pedirclave
set "NEWKEY="
set /p "NEWKEY=Pega tu clave de Gemini (solo Enter para omitir): "
if not defined NEWKEY (
  echo [AVISO] Sin clave: Dexi no podra responder en el chat hasta que ejecutes de nuevo este instalador.
  echo         Las ventanas de calculo ^(Ajustes, Diseno desde imagenes, Optimizador^) funcionan sin clave.
  goto listo
)
set "NEWKEY=%NEWKEY: =%"
if not "%NEWKEY:~19,1%"=="" goto guardarclave
echo [ERROR] Eso es demasiado corto para ser una clave de Gemini. Vuelve a copiarla.
goto pedirclave
:guardarclave
setx DEXI_GEMINI_KEY "%NEWKEY%" >nul
echo [OK] Clave guardada en tu usuario ^(variable DEXI_GEMINI_KEY^). No la compartas.

:listo
echo.
echo ==========================================================
echo   LISTO: abre Deswik CAD
echo ==========================================================
echo  Abre Deswik y un documento: el panel "Dexi Pro" aparece solo ^(pestana
echo  junto a Properties y Process Map^). No hace falta crear botones.
echo  - Si NO aparece ^(una sola vez^): Plugin Manager de Deswik ^> "+" ^>
echo      %DEST%\DexiPro.dll
echo    ^> marca "When opening any document" ^> Load ^> OK.
echo  - Si cierras el panel: Plugin Manager ^> DexiPro ^> Load, o reabre Deswik.
echo  - Alternativa: boton del Process Map con la macro Macro_DexiPro.txt ^(manual^).
echo  Para actualizar: cierra Deswik y ejecuta el Instalar.bat nuevo
echo  ^(tu clave y tus ajustes se conservan^).
echo.
if exist "%DEST%\Manual_DexiPro.pdf" (
  choice /c SN /m "Abrir el manual ahora"
  if not errorlevel 2 start "" "%DEST%\Manual_DexiPro.pdf"
)
echo Instalacion terminada.
pause
exit /b 0

:registrofallo
echo [ERROR] No pude registrar el plugin en Deswik. El detalle esta arriba.
echo         Dexi Pro igual se puede abrir con el boton opcional del Process Map ^(ver el manual^).
pause
exit /b 1

:copiafallo
echo [ERROR] No se pudo copiar a %DEST%. Cierra Deswik por completo y vuelve a ejecutar Instalar.bat.
pause
exit /b 1

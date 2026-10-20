@echo off
rem ==========================================================
rem   SIR JON - Compilar con Pasmo y generar el .tap final
rem
rem   Uso: doble clic, o "compilar" desde esta carpeta.
rem   Requiere pasmo.exe en el PATH (o en esta misma carpeta).
rem ==========================================================
cd /d "%~dp0"

echo.
echo [1/3] Compilando el juego (main.asm)...
pasmo --tap main.asm tap\taps\cstlv2.tap
if errorlevel 1 goto error

echo [2/3] Compilando la pantalla de carga (caratula.asm)...
rem El nombre "screen.tap" va en la cabecera de la cinta
pasmo --tap caratula.asm screen.tap
if errorlevel 1 goto error
move /y screen.tap tap\taps\screen.tap >nul

echo [3/3] Uniendo cargador + pantalla + juego...
copy /b tap\taps\loader.tap + tap\taps\screen.tap + tap\taps\cstlv2.tap tap\sjv2.tap >nul
if errorlevel 1 goto error

echo.
echo OK: tap\sjv2.tap generado.
goto fin

:error
echo.
echo *** ERROR: la compilacion ha fallado (mira el mensaje de arriba) ***

:fin
echo.
pause

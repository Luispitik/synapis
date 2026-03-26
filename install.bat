@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ============================================================
::  Synapis v3.2 — Installer for Windows
::  Skills on Demand for Claude Code
::  https://github.com/Luispitik/synapis
:: ============================================================

set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "SKILLS_DIR=%CLAUDE_HOME%\skills"
set "LIBRARY_DIR=%SKILLS_DIR%\_library"
set "ARCHIVED_DIR=%SKILLS_DIR%\_archived"
set "COMMANDS_DIR=%CLAUDE_HOME%\commands"
set "SCRIPT_DIR=%~dp0"

echo.
echo ============================================================
echo   Synapis v3.2 — Skills on Demand for Claude Code
echo   Sistema inteligente que aprende y se adapta
echo ============================================================
echo.

:: Step 1: Check prerequisites
echo [1/7] Verificando prerequisitos...

where claude >nul 2>&1
if %errorlevel% neq 0 (
    echo   ! Claude Code no detectado en PATH
    echo     Instala Claude Code primero: https://claude.ai/code
    echo     Continuando de todas formas...
) else (
    echo   OK Claude Code detectado
)

if exist "%CLAUDE_HOME%" (
    echo   OK Directorio .claude\ existe
) else (
    echo   -- Creando .claude\
    mkdir "%CLAUDE_HOME%"
)

:: Step 2: Detect existing installation
echo [2/7] Detectando instalacion previa...

if exist "%SKILLS_DIR%\_catalog.json" (
    echo   ! Instalacion previa detectada
    echo     Se hara backup antes de sobrescribir
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
    set "BACKUP_DIR=%CLAUDE_HOME%\_backup_!dt:~0,8!_!dt:~8,6!"
    mkdir "!BACKUP_DIR!" 2>nul
    xcopy "%SKILLS_DIR%" "!BACKUP_DIR!\skills_backup\" /E /I /Q >nul 2>&1
    xcopy "%COMMANDS_DIR%" "!BACKUP_DIR!\commands_backup\" /E /I /Q >nul 2>&1
    echo   OK Backup guardado
) else (
    echo   OK Instalacion limpia
)

:: Step 3: Create directory structure
echo [3/7] Creando estructura de directorios...

if not exist "%SKILLS_DIR%" mkdir "%SKILLS_DIR%"
if not exist "%LIBRARY_DIR%" mkdir "%LIBRARY_DIR%"
if not exist "%ARCHIVED_DIR%" mkdir "%ARCHIVED_DIR%"
if not exist "%COMMANDS_DIR%" mkdir "%COMMANDS_DIR%"
if not exist "%CLAUDE_HOME%\projects" mkdir "%CLAUDE_HOME%\projects"

echo   OK Directorios creados

:: Step 4: Copy core files
echo [4/7] Instalando archivos core...

copy /Y "%SCRIPT_DIR%core\_catalog.json" "%SKILLS_DIR%\_catalog.json" >nul
copy /Y "%SCRIPT_DIR%core\_passive-rules.json" "%SKILLS_DIR%\_passive-rules.json" >nul
copy /Y "%SCRIPT_DIR%core\_projects.json" "%SKILLS_DIR%\_projects.json" >nul

if not exist "%SKILLS_DIR%\_operator-state.json" (
    copy /Y "%SCRIPT_DIR%core\_operator-state.template.json" "%SKILLS_DIR%\_operator-state.json" >nul
    echo   OK Operator state creado
) else (
    echo   -- Operator state existente preservado
)

if not exist "%CLAUDE_HOME%\CLAUDE.md" (
    copy /Y "%SCRIPT_DIR%core\CLAUDE.md.template" "%CLAUDE_HOME%\CLAUDE.md" >nul
    echo   OK CLAUDE.md creado
) else (
    echo   ! CLAUDE.md ya existe - no se sobrescribe
    echo     Revisa core\CLAUDE.md.template para actualizaciones
)

echo   OK Core files instalados

:: Step 5: Copy global skills
echo [5/7] Instalando 5 skills globales...

for /D %%d in ("%SCRIPT_DIR%skills\*") do (
    set "skill_name=%%~nxd"
    if not exist "%SKILLS_DIR%\!skill_name!" mkdir "%SKILLS_DIR%\!skill_name!"
    xcopy "%%d\*" "%SKILLS_DIR%\!skill_name!\" /Y /Q >nul 2>&1
    echo   OK !skill_name!
)

:: Step 6: Copy library skills (dormant)
echo [6/7] Instalando skills dormidas en library...

set "skill_count=0"
for /D %%d in ("%SCRIPT_DIR%library\*") do (
    set "lib_name=%%~nxd"
    if not exist "%LIBRARY_DIR%\!lib_name!" mkdir "%LIBRARY_DIR%\!lib_name!"
    xcopy "%%d\*" "%LIBRARY_DIR%\!lib_name!\" /Y /Q >nul 2>&1
    set /a skill_count+=1
)
echo   OK %skill_count% skills dormidas instaladas

:: Step 7: Copy slash commands
echo [7/7] Instalando slash commands...

set "cmd_count=0"
for %%f in ("%SCRIPT_DIR%commands\*.md") do (
    copy /Y "%%f" "%COMMANDS_DIR%\" >nul
    set /a cmd_count+=1
)
echo   OK %cmd_count% comandos instalados

:: Done!
echo.
echo ============================================================
echo   Synapis v3.2 instalado correctamente
echo ============================================================
echo.
echo   Que se ha instalado:
echo   - 5 skills globales (siempre activas)
echo   - %skill_count% skills dormidas (se activan por proyecto)
echo   - %cmd_count% slash commands (/evolve, /clone, /system-status...)
echo   - Catalogo, reglas pasivas, operator state
echo.
echo   Siguiente paso:
echo   1. Abre Claude Code en cualquier proyecto
echo   2. Synapis te guiara en el onboarding
echo   3. Elige tu modo: Skills on Demand, manual o vanilla
echo.
echo   Comandos utiles:
echo   /system-status  - Ver estado del sistema
echo   /evolve         - Evolucionar patrones en skills
echo   /clone          - Clonar proyecto exitoso
echo   /passive-status - Ver reglas pasivas activas
echo.
echo   Synapis aprende de ti. Cada sesion mejora la siguiente.
echo.

endlocal
pause

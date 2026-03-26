#!/bin/bash
# ============================================================
#  Synapis v3.2 — Installer for macOS / Linux
#  Skills on Demand for Claude Code
#  https://github.com/Luispitik/synapis
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Paths
CLAUDE_HOME="$HOME/.claude"
SKILLS_DIR="$CLAUDE_HOME/skills"
LIBRARY_DIR="$SKILLS_DIR/_library"
ARCHIVED_DIR="$SKILLS_DIR/_archived"
COMMANDS_DIR="$CLAUDE_HOME/commands"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${PURPLE}${BOLD}============================================================${NC}"
echo -e "${PURPLE}${BOLD}  Synapis v3.2 — Skills on Demand for Claude Code${NC}"
echo -e "${PURPLE}${BOLD}  Sistema inteligente que aprende y se adapta${NC}"
echo -e "${PURPLE}${BOLD}============================================================${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${BLUE}[1/7]${NC} Verificando prerequisitos..."

if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}  ! Claude Code no detectado en PATH${NC}"
    echo -e "${YELLOW}    Instala Claude Code primero: https://claude.ai/code${NC}"
    echo -e "${YELLOW}    Continuando de todas formas (los archivos se instalaran)...${NC}"
else
    echo -e "${GREEN}  OK${NC} Claude Code detectado"
fi

if [ -d "$CLAUDE_HOME" ]; then
    echo -e "${GREEN}  OK${NC} Directorio ~/.claude/ existe"
else
    echo -e "${CYAN}  ->  Creando ~/.claude/${NC}"
    mkdir -p "$CLAUDE_HOME"
fi

# Step 2: Detect existing installation
echo -e "${BLUE}[2/7]${NC} Detectando instalacion previa..."

EXISTING_INSTALL=false
if [ -f "$SKILLS_DIR/_catalog.json" ]; then
    EXISTING_INSTALL=true
    echo -e "${YELLOW}  ! Instalacion previa detectada${NC}"
    echo -e "${YELLOW}    Se hara backup antes de sobrescribir${NC}"
    BACKUP_DIR="$CLAUDE_HOME/_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$SKILLS_DIR" "$BACKUP_DIR/skills_backup" 2>/dev/null || true
    cp -r "$COMMANDS_DIR" "$BACKUP_DIR/commands_backup" 2>/dev/null || true
    echo -e "${GREEN}  OK${NC} Backup guardado en $BACKUP_DIR"
else
    echo -e "${GREEN}  OK${NC} Instalacion limpia"
fi

# Step 3: Create directory structure
echo -e "${BLUE}[3/7]${NC} Creando estructura de directorios..."

mkdir -p "$SKILLS_DIR"
mkdir -p "$LIBRARY_DIR"
mkdir -p "$ARCHIVED_DIR"
mkdir -p "$COMMANDS_DIR"
mkdir -p "$CLAUDE_HOME/projects"

echo -e "${GREEN}  OK${NC} Directorios creados"

# Step 4: Copy core files
echo -e "${BLUE}[4/7]${NC} Instalando archivos core..."

cp "$SCRIPT_DIR/core/_catalog.json" "$SKILLS_DIR/_catalog.json"
cp "$SCRIPT_DIR/core/_passive-rules.json" "$SKILLS_DIR/_passive-rules.json"
cp "$SCRIPT_DIR/core/_projects.json" "$SKILLS_DIR/_projects.json"

# Operator state: only create if not exists (preserve user data)
if [ ! -f "$SKILLS_DIR/_operator-state.json" ]; then
    cp "$SCRIPT_DIR/core/_operator-state.template.json" "$SKILLS_DIR/_operator-state.json"
    echo -e "${GREEN}  OK${NC} Operator state creado (vacio, listo para onboarding)"
else
    echo -e "${CYAN}  ->  Operator state existente preservado${NC}"
fi

# CLAUDE.md: only create if not exists
if [ ! -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/core/CLAUDE.md.template" "$CLAUDE_HOME/CLAUDE.md"
    echo -e "${GREEN}  OK${NC} CLAUDE.md creado"
else
    echo -e "${YELLOW}  ! CLAUDE.md ya existe — no se sobrescribe${NC}"
    echo -e "${YELLOW}    Revisa core/CLAUDE.md.template para actualizaciones${NC}"
fi

echo -e "${GREEN}  OK${NC} Core files instalados"

# Step 5: Copy global skills
echo -e "${BLUE}[5/7]${NC} Instalando 5 skills globales..."

for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$SKILLS_DIR/$skill_name"
    mkdir -p "$target"
    cp "$skill_dir"* "$target/" 2>/dev/null || true
    echo -e "${GREEN}  OK${NC} $skill_name"
done

# Step 6: Copy library skills (dormant)
echo -e "${BLUE}[6/7]${NC} Instalando skills dormidas en library..."

skill_count=0
for lib_dir in "$SCRIPT_DIR/library"/*/; do
    if [ -d "$lib_dir" ]; then
        lib_name=$(basename "$lib_dir")
        target="$LIBRARY_DIR/$lib_name"
        mkdir -p "$target"
        cp "$lib_dir"* "$target/" 2>/dev/null || true
        skill_count=$((skill_count + 1))
    fi
done
echo -e "${GREEN}  OK${NC} $skill_count skills dormidas instaladas"

# Step 7: Copy slash commands
echo -e "${BLUE}[7/7]${NC} Instalando slash commands..."

cmd_count=0
for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    if [ -f "$cmd_file" ]; then
        cp "$cmd_file" "$COMMANDS_DIR/"
        cmd_count=$((cmd_count + 1))
    fi
done
echo -e "${GREEN}  OK${NC} $cmd_count comandos instalados"

# Done!
echo ""
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}  Synapis v3.2 instalado correctamente${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo ""
echo -e "  ${BOLD}Que se ha instalado:${NC}"
echo -e "  - 5 skills globales (siempre activas)"
echo -e "  - $skill_count skills dormidas (se activan por proyecto)"
echo -e "  - $cmd_count slash commands (/evolve, /clone, /system-status...)"
echo -e "  - Catalogo, reglas pasivas, operator state"
echo ""
echo -e "  ${BOLD}Siguiente paso:${NC}"
echo -e "  1. Abre Claude Code en cualquier proyecto"
echo -e "  2. Synapis te guiara en el onboarding"
echo -e "  3. Elige tu modo: Skills on Demand, manual o vanilla"
echo ""
echo -e "  ${BOLD}Comandos utiles:${NC}"
echo -e "  /system-status  — Ver estado del sistema"
echo -e "  /evolve          — Evolucionar patrones en skills"
echo -e "  /clone           — Clonar proyecto exitoso"
echo -e "  /passive-status  — Ver reglas pasivas activas"
echo ""
echo -e "${PURPLE}  Synapis aprende de ti. Cada sesion mejora la siguiente.${NC}"
echo ""

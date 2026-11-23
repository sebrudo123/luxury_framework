#!/usr/bin/env bash
# ====================================================================
# LUXURY FRAMEWORK - SCRIPT PARA PUBLICAR / ACTUALIZAR EN GITHUB
# ====================================================================
set -e

REPO_DIR="/home/vertexdevelopement/luxury_framework"
GITHUB_USER="Sebrudo123"
REPO_NAME="luxury_framework"

cd "$REPO_DIR"

if [ ! -d ".git" ]; then
    echo "[+] Inicializando repositorio Git en $REPO_DIR..."
    git init -b main
    git config user.name "$GITHUB_USER"
    git config user.email "sebasruades@gmail.com"
fi

echo "[+] Añadiendo archivos al commit..."
git add .
git commit -m "feat: Luxury Framework Official GitHub Release & txAdmin Recipe" || echo "[*] Sin cambios pendientes para commitear."

if ! git remote get-url origin 2>/dev/null; then
    echo "[+] Configurando control remoto origin: https://github.com/$GITHUB_USER/$REPO_NAME.git"
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
fi

echo ""
echo "===================================================================="
echo " Repositorio local preparado exitosamente."
echo " Para subirlo a GitHub ejecuta:"
echo "   cd $REPO_DIR"
echo "   git push -u origin main"
echo ""
echo " URL para txAdmin (Remote URL Template):"
echo "   https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main/recipe.yaml"
echo "===================================================================="

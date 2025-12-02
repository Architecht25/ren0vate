#!/bin/bash

# Script pour lister les communes de Flandre en production
# Usage: ./bin/get_flandre_communes_production.sh

set -e

APP_NAME="ren0vate"
OUTPUT_DIR="./tmp"
DATE=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/communes_flandre_$DATE.txt"

# Couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🇧🇪 EXTRACTION COMMUNES DE FLANDRE - PRODUCTION${NC}"
echo "============================================================="
echo "📅 Date: $(date)"
echo "🎯 App: $APP_NAME"
echo ""

# Créer le répertoire de sortie
mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}🚀 Exécution du script sur Heroku...${NC}"

# Exécuter le script sur Heroku et sauvegarder la sortie
heroku run "rails runner bin/list_communes_flandre.rb" --app $APP_NAME | tee "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}✅ Résultats sauvegardés dans: $OUTPUT_FILE${NC}"

# Afficher un résumé
echo ""
echo -e "${BLUE}📊 RÉSUMÉ RAPIDE:${NC}"
echo "=================="

# Extraire les informations clés du fichier de sortie
if [ -f "$OUTPUT_FILE" ]; then
    echo "📁 Fichier de sortie: $OUTPUT_FILE"

    # Compter les communes
    COMMUNES_COUNT=$(grep -c "^.*\..*" "$OUTPUT_FILE" | head -1 || echo "0")
    echo "🏘️  Communes trouvées: voir le détail dans le fichier"

    # Extraire le CSV pour un usage rapide
    CSV_FILE="$OUTPUT_DIR/communes_flandre_$DATE.csv"
    sed -n '/💾 EXPORT CSV/,/^$/p' "$OUTPUT_FILE" | grep -v "💾 EXPORT CSV" | grep -v "^-*$" | grep -v "^$" > "$CSV_FILE"
    echo "📊 Export CSV: $CSV_FILE"

    echo ""
    echo -e "${YELLOW}💡 Pour utiliser ces données:${NC}"
    echo "  - Fichier complet: cat $OUTPUT_FILE"
    echo "  - Export CSV: cat $CSV_FILE"
    echo "  - Communes uniquement: grep '^[0-9]*\\. ' $OUTPUT_FILE"
else
    echo "❌ Erreur: fichier de sortie non trouvé"
fi

echo ""
echo -e "${GREEN}🎯 Script terminé avec succès!${NC}"

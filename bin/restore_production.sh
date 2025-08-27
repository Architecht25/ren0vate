#!/bin/bash

# Script de restauration production Ren0vate
# Usage: ./bin/restore_production.sh [backup_date]

set -e

# Configuration
BACKUP_DIR="$HOME/backups/ren0vate"
APP_NAME="ren0vate"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  RESTAURATION PRODUCTION REN0VATE${NC}"
echo "=================================================="
echo "📅 Date: $(date)"
echo ""

# Vérifier si un backup spécifique est demandé
if [ "$1" ]; then
    BACKUP_DATE="$1"
    echo "🎯 Restauration du backup: $BACKUP_DATE"
else
    echo "📋 Backups disponibles:"
    ls -la "$BACKUP_DIR"/*.dump 2>/dev/null | tail -5 || echo "Aucun backup trouvé"
    echo ""
    read -p "📅 Entrez la date du backup (YYYYMMDD_HHMMSS) ou ENTER pour le plus récent: " BACKUP_DATE
    
    if [ -z "$BACKUP_DATE" ]; then
        BACKUP_DATE=$(ls -t "$BACKUP_DIR"/db_backup_*.dump 2>/dev/null | head -1 | sed 's/.*db_backup_\(.*\)\.dump/\1/')
        echo "🔄 Utilisation du backup le plus récent: $BACKUP_DATE"
    fi
fi

# Vérification des fichiers
BACKUP_FILE="$BACKUP_DIR/db_backup_$BACKUP_DATE.dump"
USERS_FILE="$BACKUP_DIR/users_backup_$BACKUP_DATE.json"

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Fichier backup non trouvé: $BACKUP_FILE${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  ATTENTION: Cette opération va ÉCRASER la production !${NC}"
echo "Backup à restaurer: $BACKUP_FILE"
echo ""
read -p "🔥 Êtes-vous ABSOLUMENT sûr? Tapez 'RESTORE' pour confirmer: " CONFIRM

if [ "$CONFIRM" != "RESTORE" ]; then
    echo -e "${RED}❌ Restauration annulée${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}1. 🛡️  Backup de sécurité avant restauration...${NC}"
# Backup de sécurité avant restauration
heroku pg:backups:capture --app $APP_NAME
echo -e "${GREEN}✅ Backup de sécurité créé${NC}"

echo -e "${YELLOW}2. 🔄 Restauration de la base de données...${NC}"
# Restauration de la base de données
heroku pg:backups:restore "$BACKUP_FILE" DATABASE_URL --app $APP_NAME --confirm $APP_NAME
echo -e "${GREEN}✅ Base de données restaurée${NC}"

echo -e "${YELLOW}3. ✅ Vérification des données restaurées...${NC}"
# Vérification
echo "📊 Données après restauration:"
heroku run "rails runner \"
puts '   - Utilisateurs: ' + User.count.to_s
puts '   - Propriétés: ' + Property.count.to_s  
puts '   - Projets: ' + Project.count.to_s
\"" --app $APP_NAME

echo ""
echo -e "${GREEN}🎉 RESTAURATION TERMINÉE !${NC}"
echo "=================================================="
echo -e "${BLUE}💡 Testez la connexion avec robin@primes-services.be${NC}"

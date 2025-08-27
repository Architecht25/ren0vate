#!/bin/bash

# Script de backup production Ren0vate
# Usage: ./bin/backup_production.sh

set -e

# Configuration
BACKUP_DIR="$HOME/backups/ren0vate"
DATE=$(date +%Y%m%d_%H%M%S)
APP_NAME="ren0vate"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛡️  BACKUP PRODUCTION REN0VATE${NC}"
echo "=================================================="
echo "📅 Date: $(date)"
echo "🎯 App: $APP_NAME"
echo ""

# Créer le répertoire de backup
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}1. 📦 Backup Base de Données...${NC}"
# Backup de la base de données
heroku pg:backups:capture --app $APP_NAME
echo -e "${GREEN}✅ Backup BDD créé sur Heroku${NC}"

# Télécharger le dernier backup
echo -e "${YELLOW}2. 📥 Téléchargement du backup...${NC}"
BACKUP_FILE="$BACKUP_DIR/db_backup_$DATE.dump"
heroku pg:backups:download --app $APP_NAME --output "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup téléchargé: $BACKUP_FILE${NC}"

echo -e "${YELLOW}3. 👥 Export des utilisateurs...${NC}"
# Export spécifique des utilisateurs en JSON
USERS_FILE="$BACKUP_DIR/users_backup_$DATE.json"
heroku run "rails runner \"
puts User.all.select(:id, :email, :first_name, :last_name, :role, :phone, :city, :postal_code, :created_at).to_json
\"" --app $APP_NAME > "$USERS_FILE"
echo -e "${GREEN}✅ Utilisateurs exportés: $USERS_FILE${NC}"

echo -e "${YELLOW}4. 🏠 Export des propriétés...${NC}"
# Export des propriétés
PROPERTIES_FILE="$BACKUP_DIR/properties_backup_$DATE.json"
heroku run "rails runner \"
puts Property.all.select(:id, :user_id, :rue, :numero, :code_postal, :commune, :region, :type_bien_bruxelles, :created_at).to_json
\"" --app $APP_NAME > "$PROPERTIES_FILE"
echo -e "${GREEN}✅ Propriétés exportées: $PROPERTIES_FILE${NC}"

echo -e "${YELLOW}5. 🗂️  Compression des backups...${NC}"
# Créer une archive complète
ARCHIVE_FILE="$BACKUP_DIR/ren0vate_complete_backup_$DATE.tar.gz"
tar -czf "$ARCHIVE_FILE" -C "$BACKUP_DIR" \
    "$(basename "$BACKUP_FILE")" \
    "$(basename "$USERS_FILE")" \
    "$(basename "$PROPERTIES_FILE")"
echo -e "${GREEN}✅ Archive créée: $ARCHIVE_FILE${NC}"

echo -e "${YELLOW}6. 🧹 Nettoyage (garder 7 derniers backups)...${NC}"
# Nettoyer les anciens backups (garder les 7 derniers)
find "$BACKUP_DIR" -name "*.dump" -type f -mtime +7 -delete
find "$BACKUP_DIR" -name "*.json" -type f -mtime +7 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +7 -delete
echo -e "${GREEN}✅ Nettoyage terminé${NC}"

echo ""
echo -e "${GREEN}🎉 BACKUP TERMINÉ AVEC SUCCÈS !${NC}"
echo "=================================================="
echo "📂 Fichiers créés:"
echo "   - BDD: $BACKUP_FILE"
echo "   - Users: $USERS_FILE" 
echo "   - Properties: $PROPERTIES_FILE"
echo "   - Archive: $ARCHIVE_FILE"
echo ""
echo "📊 Statistiques:"
heroku run "rails runner \"
puts '   - Utilisateurs: ' + User.count.to_s
puts '   - Propriétés: ' + Property.count.to_s
puts '   - Projets: ' + Project.count.to_s
\"" --app $APP_NAME
echo ""
echo -e "${BLUE}💡 Pour restaurer: ./bin/restore_production.sh${NC}"

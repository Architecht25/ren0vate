#!/bin/bash

# Configuration du cron pour les backups automatiques
# Usage: ./bin/setup_cron_backup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_SCRIPT="$PROJECT_DIR/bin/backup_production.sh"

echo "🕒 CONFIGURATION DES BACKUPS AUTOMATIQUES"
echo "=========================================="
echo "📂 Projet: $PROJECT_DIR"
echo "🔧 Script: $BACKUP_SCRIPT"

# Rendre les scripts exécutables
chmod +x "$BACKUP_SCRIPT"
chmod +x "$PROJECT_DIR/bin/restore_production.sh"

# Créer le répertoire de logs
LOG_DIR="$HOME/logs/ren0vate"
mkdir -p "$LOG_DIR"

# Configuration du cron
CRON_JOB="0 3 * * * cd $PROJECT_DIR && $BACKUP_SCRIPT >> $LOG_DIR/backup.log 2>&1"

echo ""
echo "📋 Tâche cron à ajouter:"
echo "$CRON_JOB"
echo ""
echo "Cette tâche lancera un backup quotidien à 3h du matin."
echo ""

read -p "💾 Voulez-vous ajouter cette tâche au cron automatiquement? (y/N): " ADD_CRON

if [ "$ADD_CRON" = "y" ] || [ "$ADD_CRON" = "Y" ]; then
    # Ajouter au cron
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Tâche cron ajoutée avec succès!"
    echo ""
    echo "📋 Cron actuel:"
    crontab -l | grep ren0vate || echo "Aucune tâche ren0vate trouvée"
else
    echo "ℹ️  Pour ajouter manuellement:"
    echo "   crontab -e"
    echo "   Puis ajouter: $CRON_JOB"
fi

echo ""
echo "🎉 Configuration terminée!"
echo ""
echo "📊 Commandes utiles:"
echo "   - Backup manuel: $BACKUP_SCRIPT"
echo "   - Restauration: $PROJECT_DIR/bin/restore_production.sh"
echo "   - Voir les logs: tail -f $LOG_DIR/backup.log"
echo "   - Tester le cron: cd $PROJECT_DIR && $BACKUP_SCRIPT"

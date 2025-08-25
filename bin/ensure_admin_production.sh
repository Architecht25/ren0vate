#!/bin/bash

# Script de déploiement - Assurer les droits d'administrateur
# Usage: ./bin/ensure_admin_production.sh

set -e

echo "🚀 Script de mise en production - Droits d'administrateur"
echo "========================================================="

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "Gemfile" ]; then
    echo "❌ ERREUR: Ce script doit être exécuté depuis la racine du projet Rails"
    exit 1
fi

# Vérifier l'environnement
RAILS_ENV="${RAILS_ENV:-production}"
echo "📍 Environnement: $RAILS_ENV"

# Mise à jour des assets si nécessaire
echo "🔧 Nettoyage et recompilation des assets..."
bundle exec rails assets:clobber RAILS_ENV=$RAILS_ENV
bundle exec rails assets:precompile RAILS_ENV=$RAILS_ENV

# Migration de la base de données
echo "🗄️  Migration de la base de données..."
bundle exec rails db:migrate RAILS_ENV=$RAILS_ENV

# Assurer que Robin soit admin
echo "👑 Vérification des droits d'administrateur..."
bundle exec rails production:ensure_admin RAILS_ENV=$RAILS_ENV

# Afficher le statut final
echo "📊 Affichage des rôles utilisateurs..."
bundle exec rails production:show_roles RAILS_ENV=$RAILS_ENV

echo ""
echo "✅ Mise en production terminée avec succès!"
echo "🔗 Votre application est prête à être déployée"
echo ""
echo "Commandes utiles en production:"
echo "- Vérifier les rôles: bundle exec rails production:show_roles RAILS_ENV=production"
echo "- Assurer admin: bundle exec rails production:ensure_admin RAILS_ENV=production"

#!/bin/bash

echo "🧪 Test de l'état du serveur et des contrôleurs"
echo "================================================"

# Vérifier si le serveur est en cours d'exécution
if [ -f "tmp/pids/server.pid" ] && pgrep -f "rails server" > /dev/null; then
    echo "✅ Serveur Rails en cours d'exécution"
else
    echo "❌ Serveur Rails arrêté"
    echo "🚀 Démarrage du serveur..."
    cd /home/obinduarc/code/Architecht25/ren0vate
    bundle exec rails server &
    sleep 5
fi

# Vérifier les assets compilés
echo ""
echo "📁 Vérification des assets compilés..."
if [ -f "public/assets/controllers/user_type_controller-"*.js ]; then
    echo "✅ user_type_controller.js compilé"
else
    echo "❌ user_type_controller.js non trouvé"
fi

if [ -f "public/assets/application-"*.js ]; then
    echo "✅ application.js compilé"
else
    echo "❌ application.js non trouvé"
fi

echo ""
echo "🔗 Test des liens importants..."
echo "- 🏠 Page d'accueil: http://localhost:3000/"
echo "- 🇧🇪 Page Flandre: http://localhost:3000/flandre"
echo "- 🧪 Test UserType: file:///home/obinduarc/code/Architecht25/ren0vate/test_usertype.html"
echo "- 🔧 Test Stimulus: file:///home/obinduarc/code/Architecht25/ren0vate/test_stimulus.html"

echo ""
echo "📋 Instructions pour tester:"
echo "1. Ouvrez votre navigateur"
echo "2. ⚠️  IMPORTANT: Allez sur http://localhost:3000/flandre"
echo "   (PAS /pages/flandre - cette route n'existe pas!)"
echo "3. Ouvrez la console (F12)"
echo "4. Cherchez les logs Stimulus et UserType"
echo "5. Testez les boutons de sélection de profil"
echo ""
echo "🚨 RAPPEL DES ROUTES CORRECTES:"
echo "   ✅ /flandre        → Page Flandre"
echo "   ✅ /wallonie       → Page Wallonie"
echo "   ✅ /bruxelles      → Page Bruxelles"
echo "   ❌ /pages/flandre  → N'EXISTE PAS"

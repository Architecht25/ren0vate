#!/bin/bash

# Script pour ajouter automatiquement les nonces CSP aux balises script inline

echo "🔧 Ajout des nonces CSP aux scripts inline..."

# Liste des fichiers contenant des scripts inline
files=(
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/simulations/show.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/simulations/new.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaires/_petit_patrimoine_bruxelles.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaires/_communaux_flandre.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaires/_monuments_sites_wallonie.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaires/_communales_wallonie.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaires/_monuments_sites_bruxelles.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaires/_communales_bruxelles.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/documents/new.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/documents/edit.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/documents/index.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/primes/edit.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/pages/partials_flandre/_monuments_et_sites_card.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/pages/partials_flandre/_prime_amiante_card.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/pages/partials_flandre/_primes_communales_card.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/projects/new.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/projects/partials_bruxelles/_eligibility_fields.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/categories/edit.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/notifications/new_admin.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/properties/_edit_form_by_region.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/properties/documents_phases_dashboard.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/simulations/partials_flandre/_monuments_et_sites.html.erb"
    "/home/obinduarc/code/Architecht25/ren0vate/app/views/requests/formulaire_miroir/_travaux_section.html.erb"
)

# Ajouter les nonces à chaque fichier
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "📝 Traitement de: $file"
        # Remplacer <script> par <script nonce="<%= content_security_policy_nonce %>">
        sed -i 's/<script>/<script nonce="<%= content_security_policy_nonce %>">/g' "$file"
    else
        echo "⚠️  Fichier non trouvé: $file"
    fi
done

echo "✅ Nonces CSP ajoutés avec succès!"

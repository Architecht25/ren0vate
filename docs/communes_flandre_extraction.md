# 🇧🇪 Extraction des Communes de Flandre - Ren0vate

## Description
Scripts pour extraire et analyser la liste de toutes les communes de Flandre où Ren0vate a des utilisateurs en production.

## Fichiers

### `bin/list_communes_flandre.rb`
Script Ruby principal qui analyse la base de données et génère un rapport détaillé.

**Fonctionnalités:**
- ✅ Liste complète des communes de Flandre avec des utilisateurs
- ✅ Statistiques par commune (nombre de propriétés et d'utilisateurs)
- ✅ Répartition par province (basée sur les codes postaux)
- ✅ Export CSV pour utilisation externe
- ✅ Top 10 des communes les plus actives
- ✅ Liste alphabétique des communes

### `bin/get_flandre_communes_production.sh`
Script bash pour exécuter l'analyse sur Heroku et sauvegarder les résultats.

## Utilisation

### En local (environnement de développement)
```bash
rails runner bin/list_communes_flandre.rb
```

### En production (Heroku)
```bash
# Méthode 1: Script automatisé (recommandé)
./bin/get_flandre_communes_production.sh

# Méthode 2: Commande directe
heroku run "rails runner bin/list_communes_flandre.rb" --app ren0vate
```

## Sortie attendue

Le script génère plusieurs sections :

1. **📊 Statistiques générales** : Nombre total de communes et utilisateurs
2. **📍 Communes par ordre décroissant** : Liste triée par nombre d'utilisateurs
3. **📋 Liste alphabétique** : Toutes les communes triées alphabétiquement
4. **🎯 Top 10** : Les 10 communes les plus actives avec pourcentages
5. **💾 Export CSV** : Format structuré pour import dans d'autres outils
6. **🗺️ Répartition par province** : Regroupement par provinces flamandes

## Format CSV

Le fichier CSV généré contient trois colonnes :
```
Commune,Propriétés,Utilisateurs
Anvers,25,20
Gand,18,15
...
```

## Exemples de commandes utiles

```bash
# Extraire seulement la liste des communes
heroku run "rails runner 'puts Property.where(region: \"flandre\").distinct.pluck(:commune).compact.sort.join(\"\n\")'" --app ren0vate

# Compter le nombre total d'utilisateurs en Flandre
heroku run "rails runner 'puts Property.joins(:user).where(region: \"flandre\").distinct.count(:user_id)'" --app ren0vate

# Top 5 des communes
heroku run "rails runner 'puts Property.where(region: \"flandre\").group(:commune).count.sort_by{|k,v| -v}.first(5).inspect'" --app ren0vate
```

## Notes importantes

- 🔄 Les résultats sont basés sur les données en temps réel de la production
- 📊 Les statistiques incluent uniquement les utilisateurs ayant créé des propriétés
- 🗺️ La répartition par province est estimative basée sur les codes postaux
- 💾 Les fichiers de sortie sont sauvegardés dans `./tmp/` avec timestamp

## Dépannage

Si vous rencontrez des erreurs :

1. **Erreur de connexion DB** : Vérifiez que l'application Heroku est accessible
2. **Erreur de permissions** : Assurez-vous que les scripts sont exécutables (`chmod +x`)
3. **Erreur Rails** : Vérifiez que les modèles Property et User existent

## Fréquence recommandée

Exécutez ce script :
- 📈 **Hebdomadairement** pour le suivi de croissance
- 📊 **Mensuellement** pour les rapports business
- 🎯 **Avant les campagnes marketing** pour le ciblage géographique

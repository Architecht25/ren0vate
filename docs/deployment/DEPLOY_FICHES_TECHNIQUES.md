# Guide de déploiement - Ajout des fiches techniques

## Résumé des modifications

Cette mise à jour ajoute la possibilité d'uploader des **fiches techniques** relatives aux matériaux, produits et techniques comme documents optionnels dans la Phase Réception.

### Modifications apportées

1. **Modèle DocumentPhase** : Remplacement de 'photo' par 'fiche_technique' dans les documents optionnels de la Phase Réception
2. **Modèle Document** : Ajout de l'énumération 'fiche_technique'
3. **Traductions** : Ajout de la traduction française "Fiches techniques"
4. **Migration de données** : Mise à jour automatique de la Phase Réception existante

## Déploiement en production

### 1. Déploiement du code

```bash
# Déployer le code avec les nouvelles modifications
git push production main
# ou selon votre processus de déploiement
```

### 2. Exécution des migrations

```bash
# Exécuter les migrations de base de données
RAILS_ENV=production bundle exec rails db:migrate
```

### 3. Mise à jour des données (si nécessaire)

Si la migration automatique n'a pas fonctionné, exécuter le script de mise à jour :

```bash
# Exécuter le script de mise à jour des phases
RAILS_ENV=production bundle exec rails runner scripts/update_phase_reception_production.rb
```

### 4. Vérifications post-déploiement

#### Vérifier que l'énumération est disponible :
```bash
RAILS_ENV=production bundle exec rails runner "puts Document.type_documents.keys.include?('fiche_technique')"
# Doit retourner : true
```

#### Vérifier la traduction :
```bash
RAILS_ENV=production bundle exec rails runner "puts I18n.t('documents.types.fiche_technique')"
# Doit retourner : Fiches techniques
```

#### Vérifier la Phase Réception :
```bash
RAILS_ENV=production bundle exec rails runner "phase = DocumentPhase.find_by(name: 'Phase Réception'); puts phase.optional_document_types"
# Doit inclure : fiche_technique
```

### 5. Test fonctionnel

1. Se connecter à l'interface de production
2. Aller sur une propriété avec des documents
3. Naviguer vers la Phase Réception
4. Vérifier que "Fiches techniques" apparaît dans les documents optionnels
5. Tester l'upload d'une fiche technique

## Rollback (si nécessaire)

En cas de problème, vous pouvez revenir en arrière :

```bash
# Rollback de la migration
RAILS_ENV=production bundle exec rails db:rollback STEP=1

# Ou manuellement remettre 'photo' dans la Phase Réception
RAILS_ENV=production bundle exec rails runner "
phase = DocumentPhase.find_by(name: 'Phase Réception')
new_types = phase.optional_document_types.dup
new_types.delete('fiche_technique')
new_types << 'photo' unless new_types.include?('photo')
phase.update!(optional_document_types: new_types)
puts 'Rollback effectué'
"
```

## Impact utilisateur

- ✅ **Aucun impact négatif** : Les utilisateurs existants ne verront aucun changement de comportement
- ✅ **Nouvelle fonctionnalité** : Possibilité d'uploader des fiches techniques dans la Phase Réception
- ✅ **Rétrocompatibilité** : Les documents 'photo' existants continuent de fonctionner normalement

## Notes techniques

- La modification se contente de remplacer 'photo' par 'fiche_technique' dans les documents optionnels
- Aucune donnée utilisateur n'est supprimée ou modifiée
- Les documents existants de type 'photo' restent fonctionnels
- La migration est idempotente (peut être exécutée plusieurs fois sans problème)

## Contact

En cas de problème lors du déploiement, contacter l'équipe de développement avec les logs d'erreur.

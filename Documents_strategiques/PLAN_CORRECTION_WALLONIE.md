# 🚀 Plan d'Action - Correction Simulateur Wallonie

**Date de création**: 9 mars 2026
**Statut**: 📋 En attente de démarrage
**Document d'analyse**: [ANALYSE_PROBLEMES_SIMULATEUR_WALLONIE.md](ANALYSE_PROBLEMES_SIMULATEUR_WALLONIE.md)

---

## 📌 Vue d'ensemble

Le simulateur Wallonie présente **15 problèmes** dont **4 critiques** qui doivent être corrigés en priorité absolue.

---

## 🎯 Phase P0 - URGENCE (À faire IMMÉDIATEMENT)

### ✅ Tâche 1: Implémenter `calculate_prime`

**Objectif**: Ajouter la méthode manquante qui cause des crashs

**Fichier**: `app/services/regions/wallonie/wallonie_post_login_calculator_service.rb`

**Étapes**:
1. Ouvrir `app/services/regions/flandre/flandre_post_login_calculator_service.rb`
2. Copier la méthode `calculate_prime` (lignes ~23-45)
3. L'adapter pour Wallonie:
   - Remplacer `flandre_` par `wallonie_`
   - Ajuster les mappings de catégories (R1-R5 au lieu de I-IV)
4. Ajouter des tests unitaires
5. Tester avec toutes les cartes de primes

**Critère de succès**:
- Aucune erreur `NoMethodError: undefined method 'calculate_prime'`
- Toutes les cartes calculent correctement leur montant

---

### ✅ Tâche 2: Harmoniser les seuils de catégories R1-R5

**Objectif**: Aligner les seuils entre la base de données et le service

**Fichiers**:
- `db/seeds/wallonie/categories.rb`
- `app/services/regions/wallonie/wallonie_category_service.rb` (lignes 103-112)

**Étapes**:
1. Vérifier les **seuils officiels Wallonie 2025** sur le site officiel
2. Mettre à jour `db/seeds/wallonie/categories.rb` avec les bons seuils
3. Mettre à jour `wallonie_category_service.rb#determine_category` (ligne 103)
4. Créer un test de cohérence:
   ```ruby
   # test/services/regions/wallonie/wallonie_category_service_test.rb
   test "seuils correspondent entre seeds et service" do
     # Vérifier cohérence
   end
   ```
5. Exécuter `rails db:seed` pour mettre à jour la BD
6. Tester avec plusieurs revenus de référence

**Critère de succès**:
- Seuils identiques dans seeds ET service
- Tests de catégorisation passent pour tous les cas limites
- Documentation des seuils officiels ajoutée

---

### ✅ Tâche 3: Unifier la structure de retour des services

**Objectif**: Assurer que toutes les méthodes retournent le même format

**Fichier**: `app/services/regions/wallonie/wallonie_post_login_calculator_service.rb`

**Étapes**:
1. Choisir le format standard (recommandé: celui de `calculate_all_primes`):
   ```ruby
   {
     prime_results: { slug => { amount:, prime_id:, titre:, unite: } },
     total_general: Float
   }
   ```
2. Adapter `generate_prime_cards` pour retourner ce format
3. Adapter le frontend si nécessaire (`wallonie_simulation_controller.js`)
4. Mettre à jour tous les appels dans le contrôleur
5. Ajouter des tests d'intégration

**Critère de succès**:
- Structure de retour cohérente partout
- Frontend affiche correctement les totaux
- Pas d'erreur JavaScript dans la console

---

### ✅ Tâche 4: Implémenter les déductions fiscales manquantes

**Objectif**: Ajouter les déductions pour personnes 60+ et grossesse

**Fichiers**:
- Migration: `db/migrate/YYYYMMDD_add_wallonie_deductions_to_users.rb`
- Service: `app/services/regions/wallonie/wallonie_category_service.rb`
- Formulaire: `app/views/projects/partials_wallonie/_eligibility_fields.html.erb`

**Étapes**:
1. Créer la migration:
   ```ruby
   rails generate migration AddWallonieDeductionsToUsers personnes_60_ans_et_plus:integer femme_enceinte:boolean
   ```
2. Mettre à jour `wallonie_category_service.rb#adjust_income_for_household`:
   ```ruby
   # Ajouter après ligne 93
   deductions += (@user.personnes_60_ans_et_plus || 0) * 5000
   deductions += 5000 if @user.femme_enceinte
   ```
3. Ajouter les champs au formulaire d'éligibilité
4. Tester avec des cas réels

**Critère de succès**:
- Déductions correctement appliquées
- Catégorie ajustée selon les déductions
- Formulaire mis à jour et fonctionnel

---

## ⏱️ Estimation Temps Phase P0

| Tâche | Temps estimé | Priorité |
|-------|--------------|----------|
| Tâche 1: `calculate_prime` | 4-6h | 🔴 URGENT |
| Tâche 2: Seuils catégories | 2-3h | 🔴 URGENT |
| Tâche 3: Structure retour | 3-4h | 🔴 URGENT |
| Tâche 4: Déductions fiscales | 4-6h | 🔴 URGENT |
| **TOTAL Phase P0** | **13-19h** | **~2-3 jours** |

---

## 🔜 Prochaines Phases

### Phase P1 - SEMAINE 1 (après P0)
- Fusionner les deux systèmes de cartes
- Unifier le format de persistance
- Documenter les mappings slugs

### Phase P2 - SPRINT 2
- Validation des seeds
- Nettoyage du code mort
- Documentation complète

---

## 📝 Checklist avant Déploiement

Avant de déployer en production, vérifier:

- [ ] Tous les problèmes P0 corrigés
- [ ] Tests unitaires passent (services)
- [ ] Tests d'intégration passent (simulations complètes)
- [ ] Test de non-régression (comparer avec Flandre)
- [ ] Test de persistance (sauvegarder/recharger)
- [ ] Test utilisateur sur les 5 catégories (R1-R5)
- [ ] Pas d'erreur JavaScript dans la console
- [ ] Documentation mise à jour
- [ ] Déploiement sur environnement de staging
- [ ] Validation finale par un utilisateur beta-testeur

---

## 🆘 En Cas de Problème

Si un problème bloque pendant les corrections:

1. **Consulter le code Flandre** (qui fonctionne) comme référence
2. **Vérifier les logs Rails** pour identifier l'erreur exacte
3. **Tester étape par étape** pour isoler le problème
4. **Créer un test unitaire** qui reproduit le bug
5. **Documenter** tout changement dans ce fichier

---

## 📊 Suivi de Progression

| Date | Tâche | Statut | Notes |
|------|-------|--------|-------|
| - | Tâche 1: calculate_prime | ⏸️ Pas démarré | - |
| - | Tâche 2: Seuils catégories | ⏸️ Pas démarré | - |
| - | Tâche 3: Structure retour | ⏸️ Pas démarré | - |
| - | Tâche 4: Déductions fiscales | ⏸️ Pas démarré | - |

**Légende**: ⏸️ Pas démarré | 🔄 En cours | ✅ Terminé | ❌ Bloqué

---

**Dernière mise à jour**: 9 mars 2026
**Responsable**: À définir
**Contact**: -

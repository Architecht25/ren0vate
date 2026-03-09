# 📋 Analyse des Problèmes du Simulateur Wallonie

**Date**: 9 mars 2026
**Auteur**: Analyse technique approfondie
**Statut**: 🔴 Nécessite corrections urgentes

---

## 🎯 Contexte

Le simulateur Wallonie présente de **nombreux problèmes critiques** qui empêchent son fonctionnement correct, contrairement au simulateur de Flandre qui est opérationnel. Cette analyse identifie tous les problèmes, leur gravité et les solutions recommandées.

---

## 📊 Résumé Exécutif

| Catégorie | Nombre | Impact |
|-----------|--------|--------|
| 🔴 **CRITIQUES** | 4 | Crashs, calculs incorrects |
| 🟠 **MAJEURS** | 3 | Fonctionnalités défectueuses |
| 🟡 **MINEURS** | 8 | Limitations, code mort |
| **TOTAL** | **15** | **Simulateur partiellement non fonctionnel** |

---

## 🔴 PROBLÈMES CRITIQUES (À corriger de TOUTE URGENCE)

### 1. ❌ Méthode `calculate_prime` manquante

**Gravité**: 🔴 CRITIQUE - **CAUSE DE CRASH**

**Fichier**: [app/services/regions/wallonie/wallonie_post_login_calculator_service.rb](app/services/regions/wallonie/wallonie_post_login_calculator_service.rb)

**Problème**:
- Le contrôleur appelle `calculator_service.calculate_prime(prime_slug, input_value, input_type)` (ligne 311 de simulations_controller.rb)
- Cette méthode **existe pour Flandre** mais **N'EXISTE PAS pour Wallonie**
- Tout appel provoque: `NoMethodError: undefined method 'calculate_prime'`

**Impact**:
- ❌ Calcul de primes individuelles **IMPOSSIBLE**
- ❌ Interface utilisateur **BLOQUÉE**
- ❌ Aucune carte de prime ne peut calculer correctement

**Solution recommandée**:
Copier l'implémentation de `FlandrePostLoginCalculatorService#calculate_prime` et l'adapter pour Wallonie.

---

### 2. ⚠️ Incohérence des seuils de catégories (R1-R5)

**Gravité**: 🔴 CRITIQUE - **CALCULS INCORRECTS**

**Fichiers concernés**:
- [db/seeds/wallonie/categories.rb](db/seeds/wallonie/categories.rb)
- [app/services/regions/wallonie/wallonie_category_service.rb](app/services/regions/wallonie/wallonie_category_service.rb#L103-L108)

**Problème**: Les seuils de revenus **ne correspondent PAS** entre les seeds et le service

| Catégorie | Seeds (BD) | Service (Code) | Différence |
|-----------|------------|----------------|------------|
| R1 | ≤ 26 900 € | ≤ 25 400 € | **-1 500 €** |
| R2 | ≤ 38 300 € | ≤ 36 200 € | **-2 100 €** |
| R3 | ≤ 50 600 € | ≤ 51 800 € | **+1 200 €** |
| R4 | ≤ 114 400 € | ≤ 79 000 € | **-35 400 €** ❗ |
| R5 | Au-delà | ≤ 114 400 € | **MANQUE R5 correcte** ❗ |

**Impact**:
- ❌ Utilisateurs **mal catégorisés**
- ❌ Montants de primes **INCORRECTS** (peuvent varier de centaines à milliers d'euros)
- ❌ **Exemple**: Un revenu de 77 000€ → catégorie R4 dans le code vs R5 dans la BD
  - R4 = primes plus élevées
  - R5 = primes moindres
  - **Différence potentielle de plusieurs milliers d'euros**

**Solution recommandée**:
Harmoniser avec les **vrais seuils officiels Wallonie 2025** et assurer la cohérence entre seeds et service.

---

### 3. 🔄 Format de retour incohérent entre méthodes

**Gravité**: 🔴 CRITIQUE - **FRONTEND NE REÇOIT PAS LES BONNES DONNÉES**

**Fichier**: [app/services/regions/wallonie/wallonie_post_login_calculator_service.rb](app/services/regions/wallonie/wallonie_post_login_calculator_service.rb)

**Problème**: Deux méthodes retournent des structures **totalement différentes**

**`calculate_all_primes` (lignes 20-65)** retourne:
```ruby
{
  prime_results: {
    'wallonie_toiture_remplacement': {
      amount: 240,
      prime_id: 123,
      titre: 'Remplacement couverture',
      unite: '€/m²'
    },
    # ...
  },
  total_general: 5000
}
```

**`generate_prime_cards` (lignes 227-440)** retourne:
```ruby
{
  cards: {
    'toiture' => {
      id: 'toiture',
      title: 'Travaux Toiture',
      primes: [...],
      total: 500
    },
    'murs' => { ... }
  },
  total: 5000  # ⚠️ Pas "total_general"!
}
```

**Impact**:
- ❌ Frontend attend une structure, backend en envoie une autre
- ❌ Affichage des totaux **incohérent**
- ❌ Cartes de primes **ne se mettent pas à jour correctement**

**Solution recommandée**:
Unifier la structure de retour sur **un seul format cohérent** partout.

---

### 4. 📝 TODO incomplet - Déductions fiscales manquantes

**Gravité**: 🔴 CRITIQUE - **CALCULS INCORRECTS**

**Fichier**: [app/services/regions/wallonie/wallonie_category_service.rb](app/services/regions/wallonie/wallonie_category_service.rb#L96)

**Problème**: Commentaire TODO ligne 96:
```ruby
# TODO: Ajouter déductions pour grossesse en cours ou personnes > 60 ans
# si ces champs sont ajoutés au modèle User
```

Les déductions **officielles Wallonie** incluent:
- ✅ Enfants à charge: 5 000 € (IMPLÉMENTÉ)
- ❌ **Personnes de plus de 60 ans**: NON implémenté
- ❌ **Femme enceinte**: NON implémenté

**Impact**:
- ❌ Revenus ajustés **INCORRECTS** pour ces catégories
- ❌ Catégorie R1/R2/R3 **mal calculée** (peut entraîner une catégorie trop haute)
- ❌ Utilisateurs concernés **PERDENT des aides** auxquelles ils ont droit

**Solution recommandée**:
1. Ajouter les champs au modèle User: `personnes_60_ans_et_plus`, `femme_enceinte`
2. Implémenter les déductions (5 000 € par personne/cas)
3. Mettre à jour le formulaire d'éligibilité

---

## 🟠 PROBLÈMES MAJEURS (Fonctionnalités défectueuses)

### 5. 🔀 Deux systèmes de cartes parallèles divergents

**Gravité**: 🟠 MAJEUR - **ARCHITECTURE FRAGMENTÉE**

**Localisation**:
- **Ancien système**: [app/views/pages/partials_wallonie/cartes/](app/views/pages/partials_wallonie/cartes/)
- **Nouveau système**: [app/views/simulations/partials_wallonie/cartes/](app/views/simulations/partials_wallonie/cartes/)

**Problème**: **DEUX architectures complètement différentes** pour la même fonctionnalité

| Aspect | ANCIEN (Pages) | NOUVEAU (Simulations) |
|--------|---------------|----------------------|
| Contrôleur JS | `wallonie-prime-card` | `wallonie-simulation-card` |
| Slugs | Simples (`wallonie_realisation_audit_logement`) | Composites (`wallonie_toiture_global`) |
| Structure | Une carte = une prime | Une carte = plusieurs primes |
| Événement | `wallonie:prime-updated` | `wallonie:card-changed` |

**Code exemple - ANCIEN**:
```erb
<!-- app/views/pages/partials_wallonie/cartes/_audit.html.erb -->
<div data-controller="wallonie-prime-card"
     data-wallonie-prime-card-slug-value="wallonie_realisation_audit_logement">
  <input data-wallonie-prime-card-target="inputAudit">
  <span data-wallonie-prime-card-target="resultAudit">0 €</span>
</div>
```

**Code exemple - NOUVEAU**:
```erb
<!-- app/views/simulations/partials_wallonie/cartes/_carte_toiture.html.erb -->
<div data-controller="wallonie-simulation-card"
     data-wallonie-simulation-card-slug-value="wallonie_toiture_global">
  <input data-slug="wallonie_toiture_remplacement_couverture">
  <span data-wallonie-simulation-card-target="resultCouverture">0 €</span>
</div>
```

**Impact**:
- ❌ Code **dupliqué** et difficile à maintenir
- ❌ Slugs différents = logique spéciale partout
- ❌ Risque de **désynchronisation**
- ❌ **Confusion** pour les développeurs

**Solution recommandée**:
1. **Migrer TOUT vers le système nouveau** (simulations)
2. **Supprimer l'ancien système** (pages)
3. Assurer la compatibilité ascendante si nécessaire

---

### 6. 🏷️ Mappings slugs incomplets ou incorrects

**Gravité**: 🟠 MAJEUR - **CARTES NE CALCULENT PAS**

**Fichier**: [app/javascript/controllers/wallonie_simulation_card_controller.js](app/javascript/controllers/wallonie_simulation_card_controller.js#L62-L108)

**Problème**: Les slugs JavaScript **ne correspondent pas toujours** aux slugs en base de données

**Exemple problématique** (lignes 62-108):
```javascript
const cardToPrimesMap = {
  'wallonie_toiture_global': [
    'wallonie_toiture_remplacement_couverture',  // ✅ Existe en BD
    'wallonie_toiture_appropriation_charpente',  // ✅ Existe en BD
    'wallonie_toiture_evacuation_eaux_pluviales', // ✅ Existe en BD
    // MAIS les targets HTML ne correspondent pas toujours!
  ]
}

const slugToTargetMap = {
  'wallonie_toiture_remplacement_couverture': 'resultCouverture',
  // Mais dans le HTML, parfois c'est "resultToiture" ou autre...
}
```

**Impact**:
- ❌ Cartes affichent **0 €** même quand des données existent
- ❌ Inputs utilisateur **ne déclenchent pas de calcul**
- ❌ Mise à jour des totaux **partielle ou absente**

**Solution recommandée**:
1. **Documenter TOUS les mappings** dans un fichier central
2. **Vérifier la cohérence** entre slugs BD, slugs JS et targets HTML
3. Créer un test automatisé de cohérence

---

### 7. 💾 Persistance de données inconsistante

**Gravité**: 🟠 MAJEUR - **PERTE DE DONNÉES**

**Fichier**: [app/controllers/simulations_controller.rb](app/controllers/simulations_controller.rb#L1248-L1290)

**Problème**: Format de sauvegarde **≠** format de restauration

**Sauvegarde** (`save_wallonie_specific_data`, ligne 1284):
```ruby
existing_params['wallonie_toiture_remplacement'] = value  # Format PLAT
existing_params['calculated_amounts'] = { slug => amount }
```

**Restauration** (`restore_prime_inputs`, ligne 1150):
```ruby
if params_data["prime_cards"].present?
  params_data["prime_cards"].each do |category, data|
    # Attend format HIÉRARCHISÉ: prime_cards[category][primes][]
  end
end
```

**Impact**:
- ❌ Données Wallonie **anciennes non restaurées**
- ❌ Re-sauvegarde **écrase la structure**
- ❌ **Perte de données** lors de la navigation (retour sur simulation)
- ❌ Utilisateurs doivent **re-saisir leurs données** à chaque fois

**Solution recommandée**:
Utiliser le format `prime_cards` **partout** (cohérent avec Flandre/Bruxelles).

---

## 🟡 PROBLÈMES MINEURS (Limitations, code mort)

### 8. 🗑️ Méthodes orphelines dans WalloniePostLoginCalculatorService

**Gravité**: 🟡 MINEUR - **CODE MORT**

**Fichier**: [app/services/regions/wallonie/wallonie_post_login_calculator_service.rb](app/services/regions/wallonie/wallonie_post_login_calculator_service.rb#L457-L466)

**Problème**: `build_prime_data` existe mais **n'est jamais appelée**

**Impact**: Confusion, code mort en production

**Solution**: Supprimer ou intégrer correctement

---

### 9. 🎮 Contrôleurs JS dupliqués

**Gravité**: 🟡 MINEUR - **DUPLICATION**

**Fichiers**:
- [wallonie_prime_calcul_controller.js](app/javascript/controllers/wallonie_prime_calcul_controller.js) (ancien)
- [wallonie_simulation_controller.js](app/javascript/controllers/wallonie_simulation_controller.js) (nouveau)

**Problème**: Même tâche, deux implémentations différentes

**Solution**: Fusionner en un seul contrôleur

---

### 10-15. Autres problèmes mineurs

- Événement `wallonie:prime-updated` écouté mais jamais émis
- Cartes composites avec logique incomplète
- Manque de validation des données seeds
- Typos et commentaires de debug en production
- Méthode `calculate_amount_with_user_input` incomplète

---

## 🔧 Plan de Correction Recommandé

### 🚨 P0 - URGENCE IMMÉDIATE (Cette semaine)

1. **Implémenter `calculate_prime`** pour Wallonie
   - Copier de Flandre et adapter
   - Tester avec toutes les cartes

2. **Harmoniser les seuils de catégories**
   - Vérifier les seuils officiels Wallonie 2025
   - Aligner seeds ET service
   - Créer un test de non-régression

3. **Unifier la structure de retour des services**
   - Choisir UN format (recommandé: celui de `calculate_all_primes`)
   - Adapter le frontend si nécessaire

---

### ⚠️ P1 - SEMAINE 1

4. **Fusionner les deux systèmes de cartes**
   - Garder le **nouveau** (simulations)
   - Migrer le code de l'ancien
   - Supprimer l'ancien système

5. **Unifier le format de persistance**
   - Utiliser `prime_cards` partout
   - Migrer les anciennes données si nécessaire
   - Tester sauvegarde/restauration

6. **Documenter tous les mappings slugs**
   - Créer un fichier de référence
   - Vérifier la cohérence BD ↔ JS ↔ HTML

---

### 📋 P2 - SPRINT 2

7. **Implémenter les déductions fiscales manquantes**
   - Ajouter champs au modèle User
   - Implémenter logique (personnes 60+, grossesse)
   - Mettre à jour formulaire

8. **Ajouter validation des seeds**
   - Vérifier toutes les primes ont R1-R5
   - Valider les montants
   - Créer rake task de validation

9. **Nettoyer le code mort**
   - Supprimer méthodes orphelines
   - Supprimer contrôleurs JS inutilisés
   - Supprimer commentaires debug

---

## 📎 Fichiers à Corriger en Priorité

### Services (Backend)
1. [app/services/regions/wallonie/wallonie_post_login_calculator_service.rb](app/services/regions/wallonie/wallonie_post_login_calculator_service.rb)
2. [app/services/regions/wallonie/wallonie_category_service.rb](app/services/regions/wallonie/wallonie_category_service.rb)

### Contrôleurs
3. [app/controllers/simulations_controller.rb](app/controllers/simulations_controller.rb) (sections Wallonie)

### Seeds
4. [db/seeds/wallonie/categories.rb](db/seeds/wallonie/categories.rb)
5. [db/seeds/wallonie/primes.rb](db/seeds/wallonie/primes.rb) et sous-fichiers

### Frontend (JavaScript)
6. [app/javascript/controllers/wallonie_simulation_controller.js](app/javascript/controllers/wallonie_simulation_controller.js)
7. [app/javascript/controllers/wallonie_simulation_card_controller.js](app/javascript/controllers/wallonie_simulation_card_controller.js)

### Vues
8. [app/views/simulations/partials_wallonie/](app/views/simulations/partials_wallonie/) (toutes les cartes)

---

## 📊 Estimation de l'effort

| Phase | Effort | Risque |
|-------|--------|--------|
| P0 - Corrections critiques | **3-5 jours** | 🔴 Élevé (risque de régression) |
| P1 - Corrections majeures | **1-2 semaines** | 🟠 Moyen |
| P2 - Améliorations mineures | **1 semaine** | 🟡 Faible |
| **TOTAL** | **3-4 semaines** | - |

---

## ✅ Tests Recommandés

Après chaque correction:

1. **Test unitaire**: Vérifier `calculate_prime` avec différentes primes/catégories
2. **Test d'intégration**: Simulation complète Wallonie de bout en bout
3. **Test de régression**: Comparer avec Flandre (qui fonctionne)
4. **Test de persistance**: Sauvegarder → recharger → vérifier données
5. **Test utilisateur**: Catégories R1 à R5, vérifier montants corrects

---

## 📖 Références

- [STRATÉGIE_ÉVOLUTION_REN0VATE.md](STRATEGIE_EVOLUTION_REN0VATE.md)
- [WALLONIE_PERSISTANCE_SIMULATION_DATA.md](WALLONIE_PERSISTANCE_SIMULATION_DATA.md)
- Code Flandre (référence fonctionnelle):
  - [app/services/regions/flandre/flandre_post_login_calculator_service.rb](app/services/regions/flandre/flandre_post_login_calculator_service.rb)
  - [app/javascript/controllers/flandre_simulation_controller.js](app/javascript/controllers/flandre_simulation_controller.js)

---

## 🎯 Conclusion

Le simulateur Wallonie présente **15 problèmes identifiés**, dont **4 critiques** qui empêchent son fonctionnement correct. L'effort estimé pour corriger tous les problèmes est de **3-4 semaines**.

**Recommandation**: Prioriser les corrections P0 (critiques) avant tout déploiement en production.

---

**Dernière mise à jour**: 9 mars 2026
**Version**: 1.0

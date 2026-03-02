# Analyse des fichiers JavaScript Bruxelles à nettoyer

**Date:** 2 mars 2026
**Contexte:** Suite à la suppression des cartes RENOLUTION (4233 lignes de vues), analyse des fichiers JS à nettoyer.

## 📊 Inventaire des fichiers JavaScript Bruxelles

### Fichiers liés aux cartes RENOLUTION (À NETTOYER/SIMPLIFIER)

| Fichier | Lignes | Statut | Action recommandée |
|---------|--------|--------|-------------------|
| `bruxelles_simulation_controller.js` | 757 | 🔴 Gère les cartes A-Z supprimées | **Simplifier fortement** - Ne garder que la logique pour communales/monuments/patrimoine |
| `bruxelles_prime_calcul_controller.js` | 737 | 🔴 Calculs primes cartes | **Simplifier** - Retirer logique cartes A-Z |
| `bruxelles_prime_card_controller.js` | 685 | 🔴 Gestion cartes individuelles | **Évaluer utilité** - Peut-être supprimer si lié uniquement aux cartes |
| `bruxelles_simulation_card_controller.js` | 350 | 🟡 Cartes simulation | **Vérifier** - Si référence cartes A-Z, simplifier |

**Total à nettoyer:** ~2529 lignes

### Fichiers à CONSERVER (primes spécifiques)

| Fichier | Lignes | Usage |
|---------|--------|-------|
| `primes_communales_bruxelles_controller.js` | 324 | ✅ Primes communales |
| `petit_patrimoine_bruxelles_controller.js` | 124 | ✅ Petit patrimoine |
| `test_eligibilite_bruxelles_controller.js` | 751 | ✅ Tests d'éligibilité (à vérifier mentions RENOLUTION) |

**Total à conserver:** ~1199 lignes

### Fichiers VIDES (À SUPPRIMER)

| Fichier | Lignes | Action |
|---------|--------|--------|
| `bruxelles_eligibility_controller.js` | 0 | ❌ **SUPPRIMER** |
| `bruxelles_form_controller.js` | 0 | ❌ **SUPPRIMER** |

### Fichiers à EXAMINER

| Fichier | Lignes | Raison |
|---------|--------|--------|
| `bruxelles_aides_controller.js` | 391 | 🔍 Vérifier si lié aux cartes |
| `bruxelles_aides_estimation_controller.js` | 179 | 🔍 Vérifier estimation primes |

## 🎯 Plan de nettoyage recommandé

### Phase 1: Suppression immédiate (0 effort)
```bash
# Supprimer les fichiers vides
rm app/javascript/controllers/bruxelles_eligibility_controller.js
rm app/javascript/controllers/bruxelles_form_controller.js
```

### Phase 2: Simplification des contrôleurs (effort moyen)

**bruxelles_simulation_controller.js (757 → ~200 lignes estimées)**
- ❌ Retirer: Logique de gestion des cartes A-Z (carte_a_services, carte_b_installations, etc.)
- ❌ Retirer: Calculs pour chaque carte individuelle
- ✅ Garder: Logique de catégorie (Cat1, Cat2, Cat3)
- ✅ Garder: Gestion du total général
- ✅ Adapter: Pour les 3 sections (communales, monuments, patrimoine)

**bruxelles_prime_calcul_controller.js (737 → ~300 lignes estimées)**
- ❌ Retirer: Références aux primes A-Z
- ✅ Garder: Calculs génériques
- ✅ Adapter: Pour primes communales/monuments/patrimoine

**bruxelles_prime_card_controller.js (685 lignes)**
- 🔍 Analyser: Si uniquement pour cartes A-Z → SUPPRIMER
- 🔍 Si générique → Simplifier pour les 3 types de primes conservés

**bruxelles_simulation_card_controller.js (350 lignes)**
- 🔍 Vérifier utilité post-suppression des cartes
- ✅ Adapter si nécessaire pour communales/monuments/patrimoine

### Phase 3: Nettoyage des références textuelles

**Fichiers contenant "RENOLUTION":**
- `categorie_estimation_controller.js` - Ligne 204
- `test_eligibilite_bruxelles_controller.js` - Lignes 115, 132, 290, 456, 504
- `request_form_controller.js` - Ligne 148
- `bruxelles_prime_calcul_controller.js` - Ligne 164
- `eligibility_retester_controller.js` - Lignes 4, 24, 33, 35

**Action:** Remplacer "RENOLUTION" par "primes Bruxelles" ou "primes habitation" selon le contexte.

## 📈 Gains estimés

| Catégorie | Avant | Après | Gain |
|-----------|-------|-------|------|
| **Fichiers vides** | 2 fichiers (0 lignes) | 0 fichier | -2 fichiers |
| **Contrôleurs simplifiés** | ~2529 lignes | ~800 lignes | **-1729 lignes (-68%)** |
| **Références textuelles** | 13 mentions RENOLUTION | 0 mention | -13 références |

**Total estimé:** Réduction de ~1729 lignes de code JavaScript (68% de réduction sur les fichiers concernés)

## ✅ Checklist d'exécution

### Immédiat
- [ ] Supprimer `bruxelles_eligibility_controller.js` (vide)
- [ ] Supprimer `bruxelles_form_controller.js` (vide)

### Court terme (nécessite analyse détaillée)
- [ ] Analyser `bruxelles_simulation_controller.js` - Identifier code lié aux cartes A-Z
- [ ] Analyser `bruxelles_prime_calcul_controller.js` - Retirer logique cartes supprimées
- [ ] Analyser `bruxelles_prime_card_controller.js` - Vérifier si encore utile
- [ ] Analyser `bruxelles_simulation_card_controller.js` - Adapter ou supprimer

### Moyen terme
- [ ] Remplacer mentions "RENOLUTION" par terminologie appropriée
- [ ] Tester fonctionnement primes communales après nettoyage
- [ ] Tester fonctionnement monuments et sites après nettoyage
- [ ] Tester fonctionnement petit patrimoine après nettoyage

## 🔧 Autres fichiers simulation (hors Bruxelles)

| Fichier | Lignes | Note |
|---------|--------|------|
| `wallonie_simulation_controller.js` | 676 | ✅ Indépendant |
| `wallonie_simulation_card_controller.js` | 412 | ✅ Indépendant |
| `flandre_simulation_controller.js` | 1099 | ✅ Indépendant |
| `flandre_simulation_card_controller.js` | 446 | ✅ Indépendant |

**Note:** Les contrôleurs Wallonie et Flandre semblent indépendants du nettoyage Bruxelles.

---

**Prochaines étapes:**
1. Supprimer fichiers vides
2. Analyser en détail les 4 contrôleurs principaux
3. Créer une branche de test pour le nettoyage
4. Tester fonctionnement après chaque modification

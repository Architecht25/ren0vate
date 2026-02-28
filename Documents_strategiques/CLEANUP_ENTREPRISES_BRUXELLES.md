# 🧹 GUIDE DE NETTOYAGE : SUPPRESSION MODULE ENTREPRISES BRUXELLES

**Date** : 8 février 2026
**Décision stratégique** : Focus 100% B2C (particuliers) - Abandon B2B entreprises

---

## 🎯 **OBJECTIFS**

- ❌ Supprimer TOUT le code lié aux aides entreprises Bruxelles
- ✅ Conserver uniquement primes particuliers (Flandre, Wallonie, Bruxelles)
- 🧹 Réduire dette technique avant développement 3 killer features
- 💪 Simplifier architecture (1 cible claire = particuliers)

---

## 📋 **CHECKLIST COMPLÈTE**

### **1️⃣ SERVICES (À SUPPRIMER)**

```bash
# Services entreprises Bruxelles
rm app/services/entreprises/bruxelles_entreprises_eligibility_service.rb
rm app/services/entreprises/brussels_bce_import_service.rb

# Vérifier si dossier vide après suppression
rmdir app/services/entreprises/  # Si vide
```

**Impact** : ~200 lignes de code

---

### **2️⃣ SEEDS (À SUPPRIMER)**

```bash
# Seeds complètes aides entreprises Bruxelles
rm -rf db/seeds/entreprises/bruxelles/

# Structure à supprimer :
# db/seeds/entreprises/bruxelles/
# ├── aides.rb
# ├── aides/
# │   ├── transition_economique_mobilite.rb
# │   ├── investissements.rb
# │   ├── recrutement_formation.rb
# │   └── expertises_services_externes.rb
```

**Impact** : ~500+ lignes de données

---

### **3️⃣ TASKS RAKE (À SUPPRIMER)**

```bash
# Tasks import entreprises BCE Bruxelles
rm lib/tasks/bce_brussels.rake
rm lib/tasks/bce_sample.rake
rm lib/tasks/bce_test_50.rake
```

**Impact** : ~300 lignes de code

---

### **4️⃣ ROUTES (config/routes.rb)**

**Lignes à supprimer** :

```ruby
# Dans le bloc namespace :api do
# SUPPRIMER ces 3 lignes :

get 'entreprises/bruxelles/aides', to: 'entreprises#bruxelles_aides'
post 'entreprises/bruxelles/majorations', to: 'entreprises#calculate_bruxelles_majorations'
get 'entreprises/bruxelles/majorations-details', to: 'entreprises#get_majorations_details'
```

**Impact** : 3 routes API

---

### **5️⃣ CONTROLLERS (app/controllers/api/entreprises_controller.rb)**

**Méthodes à supprimer** :

```ruby
# SUPPRIMER ces méthodes :

def bruxelles_aides
  # ...
end

def calculate_bruxelles_majorations
  # ...
end

def get_majorations_details
  # ...
end
```

**⚠️ ATTENTION** : Vérifier si d'autres méthodes utiles (ex: BCE lookup pour verification entrepreneurs)

**À CONSERVER** (si existantes) :
- `bce_lookup` : Utilisé pour vérification entrepreneurs (feature collaboration)
- Méthodes génériques non-liées aux aides entreprises

---

### **6️⃣ JAVASCRIPT CONTROLLERS**

#### **app/javascript/controllers/aid_calculator_controller.js**

**Retirer** :
```javascript
// Ligne ~21
const response = await fetch('/api/entreprises/bruxelles/aides')
```

**Action** : Supprimer toute logique "entreprises" du calculateur d'aides.

---

#### **app/javascript/controllers/eligibility_checker_controller.js**

**Retirer** (2 occurrences) :
```javascript
// Lignes ~38 et ~77
const response = await fetch('/api/entreprises/bruxelles/aides')
```

**Action** : Adapter checker d'éligibilité pour particuliers uniquement.

---

#### **app/javascript/controllers/consultation_verification_controller.js**
#### **app/javascript/controllers/entrepreneur_verification_controller.js**

**⚠️ À CONSERVER** : Ces controllers utilisent `/api/entreprises/bce_lookup` pour **vérification entrepreneurs**, pas pour aides B2B.

**Action** : Aucune suppression ici (fonctionnalité légitime pour collaboration).

---

### **7️⃣ SEO & CONTENT (app/helpers/seo_helper.rb)**

**Nettoyer descriptions/keywords** :

```ruby
# Ligne ~48-49
# AVANT :
description: "... particuliers et entreprises. Isolation, chauffage..."
keywords: "primes bruxelles, ... entreprises bruxelles"

# APRÈS :
description: "... particuliers. Isolation, chauffage, audit énergétique."
keywords: "primes bruxelles, rénovation bruxelles, aides région bruxelloise, isolation bruxelles"
```

**Ligne ~60** : Retirer "entreprises" de la description homepage.

---

### **8️⃣ ROBOTS.TXT (public/robots.txt)**

**Retirer** :
```
Allow: /bruxelles-entreprises
```

**Ligne ~34** à supprimer.

---

### **9️⃣ VIEWS (À VÉRIFIER)**

```bash
# Chercher views liées entreprises
find app/views -name "*entreprise*" -o -name "*business*"
```

**Supprimer toutes views** :
- Formulaires entreprises
- Pages aides entreprises
- Simulations B2B

---

### **🔟 MODELS (À VÉRIFIER)**

```bash
# Chercher modèles entreprises
grep -r "class.*Enterprise" app/models/
grep -r "business_type" app/models/
```

**Analyser** :
- Y a-t-il des modèles `Enterprise`, `Company` ?
- Supprimer si uniquement liés aux aides entreprises
- Conserver si utilisés pour BCE lookup général

---

### **1️⃣1️⃣ MIGRATIONS DATABASE (SI NÉCESSAIRE)**

**Vérifier tables** :
```ruby
rails db:schema:dump
# Chercher tables : enterprises, companies, business_aids, etc.
```

**Si tables existantes** :
```bash
rails generate migration RemoveEnterpriseTables
```

```ruby
class RemoveEnterpriseTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :business_aids if table_exists?(:business_aids)
    drop_table :enterprises if table_exists?(:enterprises)
    # Etc.
  end
end
```

---

### **1️⃣2️⃣ TESTS (À NETTOYER)**

```bash
# Supprimer tests entreprises
rm -rf test/controllers/entreprises_*
rm -rf test/services/entreprises/
rm -rf test/fixtures/enterprises.yml
```

---

## 🧪 **VALIDATION POST-NETTOYAGE**

### **Tests manuels :**

1. **Serveur démarre** :
   ```bash
   rails server
   # Vérifier pas d'erreurs LoadError
   ```

2. **Routes API particuliers fonctionnent** :
   ```bash
   curl http://localhost:3000/api/flandre/calculate_prime
   # Doit répondre 200
   ```

3. **Recherche résiduelle** :
   ```bash
   grep -r "bruxelles_entreprises" .
   grep -r "brussels_business" .
   grep -r "entreprises/bruxelles/aides" .
   # Doit retourner 0 résultats (sauf ce fichier CLEANUP)
   ```

4. **Tests passent** :
   ```bash
   rails test
   # Tous verts
   ```

---

## 📊 **ESTIMATION IMPACT**

| Catégorie | Fichiers supprimés | Lignes de code |
|-----------|-------------------|----------------|
| Services | 2 | ~200 |
| Seeds | 5+ | ~500 |
| Tasks | 3 | ~300 |
| Routes | 3 routes | ~10 |
| Controllers | 3 méthodes | ~100 |
| JavaScript | 4 occurrences | ~50 |
| Views | À déterminer | ~200? |
| Tests | À déterminer | ~150? |
| **TOTAL** | **~20 fichiers** | **~1500 lignes** |

---

## ✅ **BÉNÉFICES**

- 🎯 **Focus clarté** : 1 seule cible = particuliers
- 🧹 **Dette technique** : -1500 lignes de code inutiles
- ⚡ **Performance** : Moins de routes, moins de logique conditionnelle
- 🛠️ **Maintenance** : Plus simple à maintenir et débugger
- 🚀 **Roadmap** : Base propre pour 3 killer features

---

## ⏱️ **TEMPS ESTIMÉ**

- **Suppression fichiers** : 30 min
- **Nettoyage routes/controllers** : 1h
- **Nettoyage JavaScript** : 1h
- **Validation & tests** : 1h
- **Review documentation** : 30 min

**TOTAL : 4h** (½ journée dev)

---

## 🚦 **PROCHAINES ÉTAPES**

1. ✅ Créer branche : `git checkout -b cleanup/remove-entreprises-bruxelles`
2. ✅ Exécuter suppressions de cette checklist
3. ✅ Tests validation
4. ✅ Commit : `git commit -m "Remove Brussels business aids (B2B) - Focus B2C only"`
5. ✅ Merge vers main
6. 🚀 Démarrer développement 3 killer features (base propre)

---

**Pro tip** : Garder ce fichier dans le repo comme documentation de la décision stratégique.

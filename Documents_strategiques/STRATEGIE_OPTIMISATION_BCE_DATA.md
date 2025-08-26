# 🏢 Stratégie d'Optimisation des Données BCE

## 📊 **Contexte et Problématique**

- **Volume données BCE** : 2.2GB (2M+ entreprises)
- **Contrainte GitHub** : Limite de stockage
- **Besoin** : Recherche rapide et complète d'entreprises
- **Application** : ren0vate (primes de rénovation)

## 🎯 **Stratégie Adoptée : Approche Progressive**

### **Phase 1 : Base Locale Sélective (1-2 semaines)**
Import intelligent des **50 000 entreprises les plus pertinentes**

### **Phase 2 : Optimisation Dynamique (1 mois d'observation)**
Enrichissement automatique basé sur l'usage réel

### **Phase 3 : Migration API (optionnelle)**
Basculement vers API BCE officielle quand approprié

---

## 🎯 **Critères de Sélection des 50K Entreprises**

### **1. Critères Métier (0-40 points)**
```
Secteurs Prioritaires ren0vate:
✅ Construction/Rénovation (NACE 41*, 42*, 43*) → +40 pts
✅ Énergie/Isolation (NACE 35*, 33.2*) → +40 pts
✅ Conseil énergétique (NACE 71.12, 74.90) → +30 pts
✅ Immobilier (NACE 68*, 69*) → +25 pts
✅ Services aux entreprises (NACE 82*) → +15 pts
```

### **2. Critères Viabilité (0-30 points)**
```
Entreprises Actives et Solides:
✅ Statut = 'AC' (Actif) → +10 pts
✅ Forme juridique SA/SPRL/SRL → +15 pts
✅ Adresse complète définie → +5 pts
✅ Date création < 2024 (maturité) → bonus
```

### **3. Critères Géographiques (0-20 points)**
```
Priorité Régionale:
✅ Région Bruxelles-Capitale (1***) → +20 pts
✅ Wallonie (4***, 5***, 6***, 7***) → +15 pts
✅ Flandre - grandes villes → +10 pts
```

### **4. Critères Activité (0-10 points)**
```
Indicateurs de Dynamisme:
✅ Plusieurs établissements → +5 pts
✅ Activités NACE multiples → +3 pts
✅ Contacts définis (email/tél) → +2 pts
```

---

## 📈 **Timeline de Mise en Place**

### **🚀 Semaine 1-2 : Développement**
- [ ] **Script de scoring** des entreprises CSV
- [ ] **Service d'import sélectif** (top 50K)
- [ ] **Adaptation contrôleurs** existants
- [ ] **Tests et validation**

### **📊 Semaines 3-4 : Déploiement et Monitoring**
- [ ] **Import en production** des 50K entreprises
- [ ] **Monitoring recherches** non trouvées
- [ ] **Métriques d'usage** et performance
- [ ] **Ajustements critères** si nécessaire

### **🔄 Mois 2+ : Optimisation Continue**
- [ ] **Import dynamique** entreprises recherchées
- [ ] **Enrichissement automatique** base locale
- [ ] **Préparation migration API** (optionnelle)

---

## 🏗️ **Architecture Technique**

### **Composants à Développer**
```
1. SmartBceImportService
   - Analyse et scoring des CSV
   - Import sélectif top 50K

2. BceSearchAnalyticsService
   - Tracking recherches manquées
   - Suggestions d'import dynamique

3. Extension EntreprisesController
   - Support recherche étendue
   - Fallback API si non trouvé
```

### **Base de Données**
```
Tables existantes utilisées:
- bce_enterprises (50K records)
- bce_denominations (~60K records)
- bce_addresses (~50K records)
- bce_activities (~150K records)

Stockage estimé: ~100MB (vs 2.2GB CSV)
```

---

## 📊 **Métriques de Succès**

### **Performance**
- [ ] Temps recherche < 200ms (95% cas)
- [ ] Taux trouvé > 85% (recherches courantes)
- [ ] Disponibilité > 99.5%

### **Couverture**
- [ ] 100% secteurs prioritaires couverts
- [ ] 90% entreprises Bruxelles/Wallonie actives
- [ ] Enrichissement automatique < 24h

### **Technique**
- [ ] Stockage GitHub < 200MB ajoutés
- [ ] RAM Heroku stable
- [ ] Zéro impact performance générale

---

## 🔧 **Plan de Contingence**

### **Si Problèmes Performance**
1. **Réduction à 30K entreprises** les plus critiques
2. **Optimisation index** base de données
3. **Cache Redis** pour recherches fréquentes

### **Si Couverture Insuffisante**
1. **Import ciblé** entreprises manquées populaires
2. **Ajustement scoring** critères métier
3. **Fallback API BCE** automatique

### **Si Contraintes Stockage**
1. **Migration PostgreSQL externe**
2. **Compression données** non critiques
3. **Archive entreprises** inactives

---

## 🚀 **Bénéfices Attendus**

### **Court Terme (1 mois)**
✅ **Recherche rapide** 85%+ entreprises pertinentes
✅ **Performance optimale** < 200ms
✅ **Zéro dépendance** externe
✅ **Coût maîtrisé** infrastructure

### **Moyen Terme (3-6 mois)**
✅ **Couverture 95%+** via enrichissement automatique
✅ **Analytics avancées** usage client
✅ **Base solide** pour fonctionnalités IA
✅ **Migration API** préparée si besoin

### **Long Terme (6+ mois)**
✅ **Avantage concurrentiel** données BCE
✅ **Monétisation** recherche entreprises
✅ **Expansion** autres régions/pays
✅ **Écosystème** services aux entreprises

---

## 📋 **Actions Immédiates**

### **Phase 1 - Cette Semaine**
1. **Analyser structure** fichiers CSV BCE
2. **Développer algorithme** de scoring
3. **Créer service** import sélectif
4. **Tester** sur échantillon 1K entreprises

### **Phase 2 - Semaine Prochaine**
1. **Import complet** 50K entreprises
2. **Déploiement production** avec monitoring
3. **Tests utilisateur** recherche avancée
4. **Optimisation** performance

---

**Document créé le** : 26 août 2025
**Auteur** : Équipe technique ren0vate
**Version** : 1.0 - Stratégie initiale
**Prochaine révision** : Après phase 1 (2 semaines)

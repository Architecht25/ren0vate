# 🏢 Stratégie d'Optimisation des Données BCE - Bruxelles

## 📊 **Contexte et Problématique**

- **Volume données BCE** : 2.2GB (2M+ entreprises)
- **Contrainte GitHub** : Limite de stockage
- **Besoin** : Recherche rapide et complète d'entreprises
- **Application** : ren0vate (primes de rénovation)

## 🎯 **Stratégie Adoptée : Focus Bruxelles**

### **Phase 1 : Base Bruxelles Complète (3-5 jours)**
Import de **144,902 entreprises** (personnes morales, siège social Bruxelles)

### **Phase 2 : Optimisation et Test (1 semaine)**
Tests de performance et amélioration de la recherche

### **Phase 3 : Extension Progressive (selon besoins)**
Extension à la Wallonie puis Flandre si nécessaire

---

## 🎯 **Données Bruxelles Sélectionnées**

### **Critères de Filtrage**
```
Base Brussels-Only:
✅ Codes postaux 1000-1210 (19 communes Bruxelles-Capitale)
✅ Type d'adresse = REGO (siège social uniquement)
✅ Personnes morales (numéros BCE commençant par "0")
✅ Situation juridique = "000" (normale/active)
✅ Total: 144,902 entreprises
```

### **Répartition par Code Postal**
```
Top 5 communes:
- 1000 Bruxelles-Ville: ~28k entreprises
- 1050 Ixelles: ~23k entreprises
- 1180 Uccle: ~16k entreprises
- 1030 Schaerbeek: ~13k entreprises
- 1070 Anderlecht: ~13k entreprises
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

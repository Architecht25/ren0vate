# 🏡 Roadmap Évolutions Wallonie - Ren0vate 2025-2026

**Date de création :** 2 septembre 2025
**Objectif :** Anticiper et accompagner les 6 évolutions des aides wallonnes
**Vision :** Transformer Ren0vate en plateforme complète de gestion de chantier

---

## 🎯 **CONTEXTE : 6 ÉVOLUTIONS WALLONNES ANNONCÉES**

### **1. 💰 Renforcement Rénopack & Articulation Primes**
> *Réorganisation des aides financières autour de prêts adaptés à la capacité des ménages et assorties de primes pour les ménages à revenus plus FAIBLES, avec une priorité donnée aux logements les plus ENERGIVORES.*

### **2. 🤝 Articulation Outils d'Accompagnement**
> *Un système intégré d'opérateurs d'accompagnement sur tout le territoire harmonisant les pratiques et mutualisant les outils pour garantir un service équitable aux ménages.*

### **3. 💸 Incitations Fiscales**
> *Mettre en place des leviers fiscaux en compléments des dispositifs existants.*

### **4. 📋 Modification du PEB**
> *Toute rénovation soutenue par le pouvoir public fasse l'objet d'une expertise énergétique avant et après les travaux, garantissant ainsi leur qualité et permettant un meilleur pilotage des politiques.*

### **5. ⚖️ Obligations de Rénovation**
> *Introduire des obligations progressives de rénovation énergétique en lien avec les moments clés de la vie d'un bâtiment soit la vente, la location, l'occupation.*

### **6. 🏛️ Autres Politiques Transversales**
> *La stratégie de rénovation s'appuiera sur d'autres politiques régionales (urbanisme, salubrité, innovation, formation, labellisation) pour lever les freins structurels et renforcer l'efficacité de la réforme.*

---

## 📊 **ANALYSE DE L'EXISTANT DANS REN0VATE**

### ✅ **Forces Actuelles**
- **Calculateur de primes wallonnes** complet et fonctionnel
- **Système de gestion projets/chantiers** avec suivi phases
- **Module documents** organisé par types
- **Intégration BCE** pour entrepreneurs
- **Dashboard propriétaires** avec analytics
- **IA conversationnelle** (Ren0Chat/Ren0Bot)
- **Multi-utilisateurs** avec gestion rôles
- **Interface trilingue** (FR/NL/EN)

### 🔄 **Opportunités d'Extension**
- Base de données primes → Extension capacité financière
- Gestion projets → Évolution vers project management complet
- Système documents → Organisation par phases métier
- BCE integration → Marketplace entrepreneurs qualifiés
- Dashboard → Intelligence business avancée

---

## 🚀 **SOLUTIONS STRATÉGIQUES PAR ÉVOLUTION**

### **1. 💰 MODULE "FINANCEMENT INTELLIGENT"**

#### **Objectif :** Simuler capacité + optimiser primes selon revenus

#### **Fonctionnalités à Développer :**
```
🎯 Évaluateur Capacité Financière
├── Input : Revenus ménage + charges existantes
├── Output : Capacité emprunt + catégorie éligibilité
└── Logic : Grilles wallonnes + algorithmes bancaires

📊 Matrice Primes vs Revenus vs Énergéticité
├── Input : Profil financier + classe énergétique bien
├── Output : Primes optimales + montants prévisionnels
└── Logic : Priorisation logements énergétivores

💰 Simulateur Rénopack (Prêt + Prime)
├── Input : Projet rénovation + profil financier
├── Output : Mix optimal prêt 0% + primes + reste à charge
└── Logic : Optimisation selon capacité remboursement

🔄 Optimiseur Timing Financement
├── Input : Plusieurs projets + contraintes temporelles
├── Output : Planning optimal demandes + réalisations
└── Logic : Maximisation aides + étalement charges
```

#### **Architecture Technique :**
- **Modèle :** `FinancialCapacityCalculator`
- **Contrôleur :** Extension `ProjectsController`
- **Vues :** Dashboard financement intégré
- **Jobs :** Mise à jour automatique grilles revenus

### **2. 🤝 MODULE "REN0VATE CONCIERGE"**

#### **Objectif :** Système intégré d'accompagnement harmonisé

#### **Fonctionnalités à Développer :**
```
👥 Marketplace Accompagnateurs Certifiés
├── Profils opérateurs avec certifications
├── Matching automatique selon localisation + besoins
├── Système évaluation + feedback clients
└── Formation continue via modules e-learning

📋 Planning Coordination Multi-Acteurs
├── Interface propriétaire + accompagnateur + entrepreneurs
├── Calendrier partagé avec jalons projet
├── Communication centralisée + notifications
└── Suivi avancement temps réel

🎓 Modules Formation Opérateurs
├── Contenu réglementaire mis à jour automatiquement
├── Certification continue avec examens
├── Partage bonnes pratiques entre opérateurs
└── Analytics performance accompagnement

📊 Dashboard Qualité Service Harmonisé
├── Métriques standardisées qualité accompagnement
├── Reporting performance par territoire
├── Identification axes amélioration
└── Benchmark inter-opérateurs
```

#### **Architecture Technique :**
- **Modèles :** `Operator`, `Certification`, `Training`
- **Marketplace :** Extension système BCE existant
- **Communication :** Intégration email + SMS
- **Analytics :** Dashboard admin étendu

### **3. 💸 MODULE "OPTIMISATION FISCALE"**

#### **Objectif :** Maximiser avantages fiscaux rénovation

#### **Fonctionnalités à Développer :**
```
📈 Simulateur Impact Fiscal Rénovation
├── Calcul économies impôts selon travaux
├── Simulation réductions/crédits futurs
├── Comparaison scénarios investissement
└── Projection gain fiscal pluriannuel

⏰ Optimiseur Calendar Fiscal
├── Planning optimal travaux selon année fiscale
├── Étalement charges pour optimisation
├── Alertes deadlines déclarations
└── Coordination avec exercices comptables

📄 Générateur Documents Fiscaux
├── Export automatique pour comptables
├── Récapitulatifs annuels par bien
├── Justificatifs prêts-à-joindre
└── Templates déclarations fiscales

🔔 Alertes Nouveaux Dispositifs
├── Veille automatique législation fiscale
├── Notifications opportunités nouvelles
├── Impact assessments sur projets en cours
└── Recommandations adaptations stratégie
```

### **4. 📋 MODULE "ENERGY INTELLIGENCE CENTER"**

#### **Objectif :** Expertise énergétique avant/après garantie qualité

#### **Fonctionnalités à Développer :**
```
🤖 IA Prédictive PEB (Avant/Après)
├── Algorithmes prédiction classe énergétique
├── Simulation impact travaux sur PEB
├── Validation faisabilité objectifs
└── Estimation coûts pour atteindre classe cible

👷 Quality Inspector IA (Validation Travaux)
├── Analyse photos avant/pendant/après
├── Détection non-conformités automatique
├── Scoring qualité exécution
└── Recommandations corrections

📊 Monitoring Performance Énergétique
├── Suivi consommations post-travaux
├── Validation gains énergétiques réels
├── Alertes écarts vs prévisions
└── Optimisations continues

🎯 Garantie Résultats Contractuelle
├── Engagement performance énergétique
├── Assurance résultats avec partenaires
├── Compensation si objectifs non atteints
└── Certification qualité travaux
```

### **5. ⚖️ MODULE "COMPLIANCE NAVIGATOR"**

#### **Objectif :** Tracker obligations + anticipation réglementaire

#### **Fonctionnalités à Développer :**
```
📅 Calendrier Obligations Légales
├── Timeline obligations par bien immobilier
├── Tracking événements déclencheurs (vente/location)
├── Planning anticipé mises en conformité
└── Coordination avec projets rénovation

🚨 Système Alertes Proactives
├── Notifications obligations approchantes
├── Rappels délais administratifs
├── Escalade selon criticité
└── Integration calendrier personnel

⚖️ Assistant Juridique IA
├── Questions-réponses réglementation
├── Interprétation textes législatifs
├── Conseils conformité personnalisés
└── Mise à jour automatique jurisprudence

📋 Checklist Conformité Automatique
├── Listes contrôle par type bien/situation
├── Validation étapes franchies
├── Documents requis par obligation
└── Suivi avancement conformité
```

### **6. 🏛️ MODULE "REGTECH HUB"**

#### **Objectif :** Centre réglementaire intégré multi-politiques

#### **Fonctionnalités à Développer :**
```
🔍 Veille Automatisée Multi-Secteurs
├── Monitoring réglementations (urbanisme, salubrité, etc.)
├── Analyse impact sur projets utilisateurs
├── Synthèse évolutions par territoire
└── Priorisation selon pertinence

📊 Impact Analyzer Réglementations
├── Simulation impact nouvelles règles
├── Évaluation coûts conformité
├── Recommandations adaptations
└── Timeline mise en conformité

🔄 Adaptation Automatique Calculateurs
├── Mise à jour règles calcul primes
├── Integration nouveaux dispositifs
├── Tests automatisés cohérence
└── Validation avant déploiement

🎓 Formation Continue Évolutions
├── Modules e-learning utilisateurs
├── Webinaires experts sectoriels
├── Documentation interactive
└── Certification knowledge updates
```

---

## 🏗️ **ÉVOLUTION VERS APP CENTRÉE CHANTIER**

### **Vision :** Transformer Ren0vate en "Construction Management Suite"

### **Phase 1 : PRÉPARATION CHANTIER (2-3 mois)**

#### **🏗️ EXISTANT DANS REN0VATE**
- ✅ Création bien immobilier
- ✅ Création chantier/projet
- ✅ Import documents
- ✅ Intégration BCE entrepreneurs

#### **🚀 AJOUTS PRÉVUS PAR UTILISATEUR**
- 🏛️ **Accès architecte** à l'app avec interface dédiée
- 👷 **Accès entrepreneurs** et corps de métiers multi-rôles
- 🔬 **Accès experts** (auditeurs, diagnostics, etc.)
- 🤖 **Analyse devis via IA** (validation, comparaison, optimisation)
- ⚡ **Création devis via IA** (innovation génération automatique)
- 📋 **Module suivi permis d'urbanisme** avec alertes
- 🧱 **Conseils matériaux** intelligents selon projet
- 💰 **Financement** intégré (primes + prêts + optimisation)
- 📞 **Annuaire corps de métier** qualifiés et certifiés

#### **💡 COMPLÉMENTS STRATÉGIQUES RECOMMANDÉS**

```
🔍 Diagnostic IA Complet
├── Analyse photos bien via computer vision
├── Détection automatique travaux nécessaires
├── Priorisation selon budget + ROI + réglementaire
├── Génération cahier charges automatique
└── 🆕 Audit conformité réglementaire automatique

🏛️ Interface Multi-Acteurs Collaborative
├── Dashboard architecte avec outils CAO light
├── Interface entrepreneur avec planning + facturation
├── Espace expert avec rapports + certifications
├── 🆕 Communication centralisée tous acteurs
└── 🆕 Gestion versions documents collaborative

🤖 IA Services Avancés
├── Analyse devis (prix, délais, qualité, conformité)
├── Génération devis selon specs + historiques
├── 🆕 Détection risques projet automatique
├── 🆕 Optimisation séquençage travaux
└── 🆕 Prédiction durées chantier selon complexité

� Module Permis & Autorisations
├── Suivi permis urbanisme avec statuts temps réel
├── Checklist documents requis par commune
├── 🆕 Pré-validation dossiers via IA
├── 🆕 Templates demandes selon type travaux
└── 🆕 Interface directe avec administrations

🧱 Conseil Matériaux Intelligent
├── Recommandations selon performance + budget
├── Comparateur prix fournisseurs locaux
├── 🆕 Calculateur impact environnemental
├── 🆕 Alertes promotions + disponibilités
└── 🆕 Système notation qualité matériaux

💰 Financement 360° Optimisé
├── Simulateur primes + prêts + avantages fiscaux
├── Matching automatique selon profil + projet
├── 🆕 Pré-qualification bancaire automatique
├── 🆕 Simulation scénarios financement multiples
└── 🆕 Négociation groupée taux avec partenaires

👥 Annuaire & Marketplace Qualifiés
├── Base entrepreneurs avec scoring + avis clients
├── Système certification continue
├── 🆕 Algorithme matching selon spécialités
├── 🆕 Gestion assurances + garanties décennales
└── 🆕 Plateforme notation post-chantier

🎯 Modules Complémentaires Critiques
├── 🆕 Gestionnaire planning global projet
├── 🆕 Simulateur impact énergétique prévisionnel
├── 🆕 Module gestion budget avec alertes dépassement
├── 🆕 Système backup/contingency automatique
├── 🆕 Compliance checker réglementaire temps réel
├── 🆕 Interface assurances (dommage-ouvrage, etc.)
├── 🆕 Module communication client automatisée
└── 🆕 Dashboard ROI prévisionnel vs réalisé
```

#### **🔥 INNOVATIONS DIFFÉRENCIANTES**

```
🚀 AI Project Assistant
├── Chatbot spécialisé préparation chantier
├── Recommandations personnalisées selon bien
├── Détection automatique oublis/risques
└── Coaching en temps réel propriétaire

📊 Business Intelligence Chantier
├── Analytics prédictives coûts + délais
├── Benchmarking performance entrepreneurs
├── Optimisation allocation budget
└── Prédiction ROI énergétique + financier

🔗 Intégrations Écosystème
├── APIs fournisseurs matériaux
├── Connexion logiciels architectes (AutoCAD, etc.)
├── Intégration calendriers entrepreneurs
└── Synchronisation banques + assureurs

🎯 Gamification & Engagement
├── Système points progression projet
├── Badges accomplissements étapes
├── Classement entrepreneurs partenaires
└── Rewards programme fidélité
```

### **Phase 2 : GESTION CHANTIER (3-4 mois)**
```
⏰ Timeline Prédictive Travaux
├── Planning automatique basé sur historiques
├── Prédiction durées selon complexité
├── Gestion dépendances entre corps métiers
└── Optimisation chemin critique

📱 App Mobile Suivi Chantier
├── Interface terrain entrepreneurs + propriétaires
├── Photos géolocalisées + horodatées
├── Reporting avancement temps réel
└── Communication centralisée chantier

👥 Coordination Multi-Corps de Métier
├── Planning partagé tous intervenants
├── Gestion conflits calendrier
├── Coordination livraisons matériaux
└── Suivi qualité inter-corps métiers

📊 Reporting Client Automatique
├── Dashboard avancement temps réel
├── Photos avant/pendant/après automatiques
├── Rapports hebdomadaires automatisés
└── Facturation progressive transparente

🔍 Quality Control IA
├── Validation qualité via photos
├── Détection non-conformités automatique
├── Scoring qualité global chantier
└── Recommandations améliorations

💰 Gestion Factures + Primes
├── Validation factures vs devis + avancement
├── Préparation dossiers primes automatique
├── Suivi paiements + trésorerie
└── Optimisation cash-flow chantier
```

### **Phase 3 : CLÔTURE & SUIVI (2-3 mois)**
```
✅ Validation Conformité PEB
├── Coordination audit final énergétique
├── Vérification atteinte objectifs
├── Certification performance réelle
└── Validation eligibilité primes

📄 Génération DOE Automatique
├── Dossier Ouvrages Exécutés complet
├── Compilation documents techniques
├── Garanties + certificats conformité
└── Manuel utilisation/maintenance

🎯 Mesure Performance Énergétique
├── Monitoring consommations post-travaux
├── Comparaison vs prévisions
├── Calcul ROI énergétique réel
└── Recommendations optimisations

📊 Rapport ROI Final
├── Bilan financier complet projet
├── Économies réalisées vs prévisions
├── Performance énergétique atteinte
└── Satisfaction client mesurée

🔄 Maintenance Prédictive
├── Planning entretien équipements
├── Alertes maintenance préventive
├── Optimisation durée vie installations
└── Suivi garanties constructeurs
```

---

## 💰 **NOUVEAU MODÈLE BUSINESS**

### **Tier Pricing Étendu :**

#### **🏠 REN0VATE CLASSIC (Actuel)**
- Fonctionnalités existantes
- Prix : Freemium + usage

#### **🏗️ REN0VATE CONTRACTOR (149€/mois)**
```
Target : Entrepreneurs + Bureaux d'études

Fonctionnalités spécifiques :
├── 🏗️ Gestion chantier complète
├── 👷 Interface corps de métier intégrée
├── 📋 Planning & coordination avancée
├── 📊 Reporting client automatique
├── 💰 Facturation intégrée
├── 📱 App mobile chantier
├── ⏰ Timeline prédictive
└── 🎯 Success fee réduit à 5%
```

#### **⚖️ REN0VATE COMPLIANCE (79€/mois)**
```
Target : Propriétaires multi-biens + Professionnels

Fonctionnalités spécifiques :
├── 📅 Tracker obligations légales
├── 🚨 Alertes conformité proactives
├── ⚖️ Assistant juridique IA
├── 📊 Dashboard compliance multi-biens
├── 🔔 Veille réglementaire automatique
├── 📋 Checklist conformité
└── 🎓 Formation continue réglementaire
```

#### **🤖 REN0VATE AI SUITE (199€/mois)**
```
Target : Investisseurs professionnels + Gestionnaires

Tout REN0VATE COMPLIANCE +
├── 🤖 IA Prédictive PEB
├── 🔍 Quality Inspector IA
├── 📊 Predictive Analytics marché
├── 💡 Recommandations investissement IA
├── 🎯 Optimisation portfolio automatique
├── 📈 Business Intelligence avancée
└── 👥 Account Manager dédié
```

### **Services Premium À la Carte :**
```
🏗️ PROJET MANAGEMENT :
├── Chef de projet dédié : 299€/mois
├── Coordination entrepreneurs : 199€/projet
├── Quality control visits : 89€/visite
└── Planning optimization IA : 49€/optimisation

📊 ANALYTICS & REPORTING :
├── Rapport fiscal personnalisé : 299€/an
├── Business intelligence custom : 149€/mois
├── Market analysis : 199€/trimestre
└── ROI certification : 99€/propriété

🎓 FORMATION & CONSULTING :
├── Masterclass rénovation : 199€/session
├── Coaching portfolio : 149€/heure
├── Networking events : 99€/event
└── Certification "Renovation Expert" : 299€
```

---

## 🔧 **FAISABILITÉ TECHNIQUE**

### ✅ **IMMÉDIATEMENT RÉALISABLE (90-95%)**
- Extensions calculateurs existants
- Modules gestion chantier avancés
- Système alertes & compliance
- Dashboard business intelligence
- Timeline prédictive travaux
- Optimisations fiscales
- Marketplace entrepreneurs étendue

### 🔄 **NÉCESSITE INTÉGRATIONS (70-80%)**
- APIs bancaires (réglementées)
- Données énergétiques temps réel
- Services IA avancés (OpenAI, Google Vision)
- Intégrations comptabilité
- Systèmes paiement avancés

### ⚠️ **DÉVELOPPEMENTS SPÉCIALISÉS (50-60%)**
- Modèles ML prédiction PEB propriétaires
- Computer vision quality inspection
- Monitoring IoT consommations
- Blockchain certifications
- Intelligence artificielle propriétaire

---

## 📅 **PLANNING DÉVELOPPEMENT RECOMMANDÉ**

### **🏃‍♂️ QUICK WINS (Octobre-Novembre 2025)**
1. **Module Financement Intelligent** (3 semaines)
2. **Dashboard Chantier Amélioré** (4 semaines)
3. **Système Alertes Compliance** (3 semaines)
4. **Timeline Prédictive** (4 semaines)

**Total Phase 1 :** 14 semaines | **ROI attendu :** +40% engagement utilisateurs

### **🚀 DÉVELOPPEMENTS MAJEURS (Décembre 2025 - Mars 2026)**
1. **Ren0vate Contractor Suite** (8 semaines)
2. **Compliance Navigator** (6 semaines)
3. **Energy Intelligence Center** (10 semaines)
4. **RegTech Hub** (6 semaines)

**Total Phase 2 :** 30 semaines | **ROI attendu :** +150% revenue/utilisateur

### **🎯 INNOVATIONS AVANCÉES (Avril-Septembre 2026)**
1. **IA Prédictive PEB** (12 semaines)
2. **Quality Inspector IA** (8 semaines)
3. **Marketplace Concierge** (10 semaines)
4. **Mobile App Native** (8 semaines)

**Total Phase 3 :** 38 semaines | **ROI attendu :** Position leader marché

---

## 💡 **AVANTAGES CONCURRENTIELS**

### **🎯 Positionnement Unique**
- **Seule plateforme** anticipant évolutions wallonnes 2026
- **Approche 360°** : Prep + Gestion + Clôture chantier
- **Intelligence artificielle** intégrée nativement
- **Écosystème complet** tous acteurs rénovation

### **🚀 Barrières à l'Entrée**
- **Data advantage :** Historique projets + performances
- **Network effects :** Marketplace entrepreneurs + accompagnateurs
- **Switching costs :** Intégration complète workflow clients
- **Regulatory moat :** Expertise réglementaire wallonne

### **🌟 Différenciateurs Clés**
- **Prédictif vs Réactif :** Anticipation obligations légales
- **Intelligent vs Statique :** IA dans tous les modules
- **Complet vs Fragmenté :** Gestion end-to-end projets
- **Proactif vs Passif :** Alertes + recommandations automatiques

---

## 🎯 **OBJECTIFS BUSINESS 2026**

### **📊 Métriques Cibles**
- **Utilisateurs actifs :** 2500 → 7500 (+200%)
- **Revenue mensuel :** 85K → 350K EUR (+312%)
- **LTV/CAC ratio :** 3.2 → 8.5 (+165%)
- **Market share Wallonie :** 15% → 45%

### **🏆 Positioning Visé**
> **"Ren0vate : L'iOS de la Rénovation Wallonne"**
>
> La seule plateforme qui transforme la complexité réglementaire en simplicité intelligente, accompagnant chaque Wallon de l'idée de rénovation jusqu'à la certification énergétique finale.

---

## 📋 **NEXT STEPS IMMÉDIATS**

### **Septembre 2025 :**
1. ✅ **Finaliser import primes** (priorité actuelle)
2. ✅ **Compléter gestion chantier** (base technique)
3. 📋 **Valider architecture** modules futurs
4. 💰 **Estimer budgets** développement par phase

### **Octobre 2025 :**
1. 🚀 **Démarrer Phase 1** (Quick Wins)
2. 🤝 **Identifier partenaires** (banques, auditeurs, entrepreneurs)
3. 📊 **Setup analytics** pour mesurer impact développements
4. 🎯 **Préparer campagnes** communication évolutions

### **Novembre 2025 :**
1. 📱 **Lancer beta** fonctionnalités Phase 1
2. 📈 **Analyser feedback** utilisateurs early adopters
3. 💰 **Valider modèle** pricing nouveau tiers
4. 🔄 **Itérer** selon retours terrain

---

**🎉 CONCLUSION**

Cette roadmap positionne Ren0vate comme **LE leader incontesté** de la rénovation énergétique wallonne, anticipant les évolutions réglementaires avec une plateforme intelligente, complète et différenciée.

**L'investissement développement estimé (500K EUR sur 18 mois) peut générer +2M EUR revenue annuel dès 2027 = ROI 400% ! 🚀💰**

---

*Document vivant - Mise à jour recommandée : Trimestrielle ou selon évolutions réglementaires*

**Créé le :** 2 septembre 2025
**Prochaine révision :** Décembre 2025
**Owner :** Équipe Ren0vate
**Statut :** 📋 Planning stratégique - Prêt pour développement

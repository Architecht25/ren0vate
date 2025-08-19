# Plan de Recrutement & Organisation - Ren0vate Scale-Up

**Date du document :** 19 août 2025
**Application :** Ren0vate - Plateforme de rénovation énergétique belge
**Objectif :** Gérer plusieurs milliers d'utilisateurs
**Stack actuel :** Rails 8.0.2, PostgreSQL, Heroku, Devise, I18n (FR/NL/EN)

## 📋 Analyse de l'Application Actuelle

### 🏗️ Architecture existante
```
Fonctionnalités développées :
├── 🔐 Authentification Devise (robuste)
├── 🌍 I18n trilingue (FR/NL/EN)
├── 🏠 Gestion propriétés & projets
├── 📊 Simulations énergétiques
├── 📋 Demandes de primes
├── 📄 Documents officiels
├── 🔔 Système notifications
├── 👤 Dashboard utilisateur
├── ⚙️ Panel admin basique
└── 🎯 Support multi-régions Belgique
```

### 📈 Volume prévu
- **Objectif :** Plusieurs milliers d'utilisateurs
- **Estimation réaliste :** 5 000 - 15 000 utilisateurs actifs
- **Croissance prévue :** Progression graduelle sur 2-3 ans
- **Pics d'activité :** Périodes de changements réglementaires

---

## 👥 **PARTIE 1 : PROFILS À RECRUTER**

### 🔧 **1. Équipe Technique (Priorité Immédiate)**

#### **DevOps / Infrastructure Engineer** ⭐⭐⭐
```
Missions :
├── Migration Heroku → infrastructure scalable
├── Monitoring & alertes (Datadog, NewRelic)
├── CI/CD robuste (GitHub Actions)
├── Backup & disaster recovery
├── Performance optimisation
└── Sécurité infrastructure

Profil :
├── Expérience AWS/GCP/Azure
├── Docker, Kubernetes
├── PostgreSQL scaling
├── Monitoring tools
└── 3-5 ans d'expérience

Salaire Belgique : 65K-85K EUR/an
```

#### **Senior Rails Developer** ⭐⭐⭐
```
Missions :
├── Optimisation performance app
├── Refactoring & code quality
├── Nouvelles fonctionnalités complexes
├── Architecture microservices
├── Mentoring junior developers
└── Code reviews & standards

Profil :
├── 5+ ans Rails expérience
├── Performance optimisation
├── PostgreSQL avancé
├── Test-driven development
├── Expérience scaling apps
└── Connaissance énergétique (bonus)

Salaire Belgique : 55K-75K EUR/an
```

#### **Frontend Developer (Vue.js/React)** ⭐⭐
```
Missions :
├── Interface utilisateur moderne
├── Progressive Web App (PWA)
├── Intégration APIs Rails
├── Responsive design
├── Performance frontend
└── Accessibilité (A11Y)

Profil :
├── Vue.js ou React expert
├── TypeScript
├── Stimulus.js (avantage)
├── Design systems
└── 3-5 ans expérience

Salaire Belgique : 45K-65K EUR/an
```

### 🎯 **2. Équipe Produit & Business (Priorité Haute)**

#### **Product Manager** ⭐⭐⭐
```
Missions :
├── Roadmap produit & priorisation
├── Analyse besoins utilisateurs
├── Coordination équipes tech/business
├── Métriques & KPIs produit
├── Veille réglementaire énergétique
└── Stratégie croissance

Profil :
├── Expérience produit tech B2C
├── Connaissance secteur énergétique
├── Analytics & data-driven
├── Gestion stakeholders
└── 4-6 ans expérience

Salaire Belgique : 50K-70K EUR/an
```

#### **UX/UI Designer** ⭐⭐
```
Missions :
├── Expérience utilisateur optimale
├── Design system cohérent
├── User research & testing
├── Prototypage interactions
├── Accessibilité design
└── Mobile-first approach

Profil :
├── Portfolio UX/UI solide
├── Figma, Adobe Creative Suite
├── User research methods
├── Responsive design
└── 3-5 ans expérience

Salaire Belgique : 40K-60K EUR/an
```

### 🛠️ **3. Équipe Support & Opérations (Priorité Moyenne)**

#### **Customer Success Manager** ⭐⭐⭐
```
Missions :
├── Support utilisateurs niveau 2-3
├── Formation nouveaux utilisateurs
├── Amélioration processus support
├── Feedback produit
├── Documentation utilisateur
└── Relations partenaires (entrepreneurs)

Profil :
├── Expérience customer success B2C
├── Trilingue FR/NL/EN (essentiel)
├── Connaissance rénovation énergétique
├── Outils support (Zendesk, Intercom)
└── 2-4 ans expérience

Salaire Belgique : 35K-50K EUR/an
```

#### **Data Analyst** ⭐⭐
```
Missions :
├── Analytics utilisateurs & business
├── Reporting automated
├── A/B testing
├── Insights produit
├── Dashboard business
└── Prédictions & recommandations

Profil :
├── SQL, Python/R
├── Google Analytics, Mixpanel
├── Visualisation (Tableau, PowerBI)
├── Business intelligence
└── 2-4 ans expérience

Salaire Belgique : 40K-55K EUR/an
```

### 📋 **4. Équipe Administrative & Légal (Selon croissance)**

#### **Compliance & Legal Officer** ⭐⭐
```
Missions :
├── Conformité RGPD
├── Réglementations énergétiques
├── Relations administrations
├── Contrats partenaires
├── Audit légal
└── Veille réglementaire

Profil :
├── Droit digital/RGPD
├── Connaissance secteur énergétique
├── Relations institutionnelles
├── Trilingue FR/NL/EN
└── 3-5 ans expérience

Salaire Belgique : 45K-60K EUR/an
```

#### **Content Manager** ⭐
```
Missions :
├── Contenu réglementaire à jour
├── Documentation utilisateur
├── Communication externe
├── SEO optimisation
├── Newsletters & marketing
└── Traductions FR/NL/EN

Profil :
├── Rédaction technique
├── Marketing digital
├── Trilingue FR/NL/EN
├── SEO/SEM
└── 2-3 ans expérience

Salaire Belgique : 30K-45K EUR/an
```

---

## 🔧 **PARTIE 2 : TÂCHES DE GESTION OPÉRATIONNELLE**

### 📊 **1. Gestion Technique Quotidienne**

#### **Infrastructure & Monitoring** (DevOps)
```
Tâches quotidiennes :
├── ☑️ Monitoring serveurs & performance
├── ☑️ Vérification logs erreurs
├── ☑️ Backups automatisés
├── ☑️ Updates sécurité
├── ☑️ Alertes incidents
└── ☑️ Optimisation ressources

Tâches hebdomadaires :
├── 📊 Rapport performance
├── 🔒 Audit sécurité
├── 💾 Test restore backups
├── 📈 Analyse utilisation ressources
└── 🔄 Déploiements production

Outils recommandés :
├── Monitoring : Datadog, NewRelic
├── Logs : Lograge, Papertrail
├── Erreurs : Sentry, Bugsnag
├── Uptime : Pingdom, UptimeRobot
└── Performance : Scout APM
```

#### **Développement & Maintenance** (Tech Lead)
```
Tâches quotidiennes :
├── ☑️ Code reviews équipe
├── ☑️ Résolution bugs prioritaires
├── ☑️ Vérification tests CI/CD
├── ☑️ Support technique équipe
└── ☑️ Architecture decisions

Tâches hebdomadaires :
├── 🎯 Sprint planning & reviews
├── 📋 Priorisation backlog technique
├── 🔍 Refactoring & debt technique
├── 📖 Documentation technique
└── 👥 Mentoring développeurs
```

### 👥 **2. Gestion Support Utilisateurs**

#### **Support Niveau 1** (Customer Success)
```
Volume estimé : 50-150 tickets/jour

Types de demandes :
├── 🔐 Problèmes connexion (25%)
├── ❓ Questions utilisation (35%)
├── 📄 Documents manquants (20%)
├── 💰 Calculs primes (15%)
└── 🐛 Bugs mineurs (5%)

Process support :
├── ⏱️ Réponse < 2h (heures ouvrables)
├── ✅ Résolution < 24h (simple)
├── 🔄 Escalade niveau 2 si complexe
├── 📊 Tracking satisfaction (CSAT)
└── 📝 Documentation FAQ automatique

Outils requis :
├── Support : Zendesk, Freshdesk
├── Chat : Intercom, Crisp
├── Télé : VoIP belgique FR/NL
├── Screenshare : TeamViewer, Zoom
└── KB : Notion, GitBook
```

#### **Support Niveau 2** (Product Manager + Dev)
```
Volume estimé : 10-30 tickets/jour

Types de demandes :
├── 🐛 Bugs complexes
├── 🔧 Problèmes techniques
├── 💡 Demandes fonctionnalités
├── 📊 Données incorrectes
└── 🏛️ Réglementations spécifiques

Process escalade :
├── ⚡ Assignation automatique
├── 🎯 Priorisation impact/urgence
├── 👥 Collaboration dev/product
├── 📈 Métriques résolution
└── 💬 Communication utilisateur
```

### 📈 **3. Gestion Business & Metrics**

#### **Analytics & Reporting** (Data Analyst)
```
Métriques quotidiennes :
├── 👥 Nouveaux utilisateurs
├── 💸 Simulations complétées
├── 📋 Demandes primes soumises
├── 🔄 Taux conversion
├── ⚡ Performance technique
└── 📞 Satisfaction support

Rapports hebdomadaires :
├── 📊 Dashboard executif
├── 🎯 KPIs produit détaillés
├── 💰 Revenue/cost analysis
├── 🔍 Funnel analysis
├── 🛡️ Incidents & downtime
└── 👥 Team productivity

Rapports mensuels :
├── 📈 Growth metrics
├── 💡 Product insights
├── 🎭 User behavior analysis
├── 🏆 Competitive analysis
└── 🔮 Prédictions tendances
```

#### **Relations Partenaires** (Product/Business)
```
Partenaires à gérer :
├── 🏛️ Administrations (BCE, IBGE, SPW)
├── 🔨 Entrepreneurs certifiés
├── 💼 Organismes de primes
├── 🏢 Fournisseurs matériaux
└── 🎓 Centres formation

Tâches régulières :
├── ✅ Validation nouvelle data
├── 🔄 Updates réglementaires
├── 📞 Calls coordination
├── 📊 Rapports d'usage
└── 🤝 Négociations contrats
```

---

## 📅 **PARTIE 3 : PLANNING DE RECRUTEMENT**

### **Phase 1 : Stabilisation (0-6 mois)**
```
Priorité absolue :
1. DevOps Engineer (mois 1)
2. Senior Rails Developer (mois 2)
3. Customer Success Manager (mois 3)

Budget estimé : 180K EUR/an
Impact : Infrastructure stable + support qualité
```

### **Phase 2 : Croissance (6-12 mois)**
```
Expansion équipe :
4. Product Manager (mois 7)
5. Frontend Developer (mois 8)
6. Data Analyst (mois 10)

Budget supplémentaire : 160K EUR/an
Impact : Produit optimisé + insights data
```

### **Phase 3 : Scale (12-24 mois)**
```
Professionnalisation :
7. UX/UI Designer (mois 14)
8. Compliance Officer (mois 16)
9. Content Manager (mois 20)

Budget supplémentaire : 135K EUR/an
Impact : Expérience utilisateur + conformité
```

### **Budget Total Équipe (2 ans)**
```
Salaires bruts annuels : 475K EUR
Charges sociales (35%) : 166K EUR
Infrastructure & tools : 50K EUR
Formation & events : 25K EUR

TOTAL : ~716K EUR/an en année 2
```

---

## 🛠️ **PARTIE 4 : ORGANISATION & PROCESS**

### **Structure Organisationnelle**
```
CEO/Founder
├── Tech Lead (Senior Rails Dev)
│   ├── DevOps Engineer
│   ├── Frontend Developer
│   └── Junior Developers (futurs)
├── Product Manager
│   ├── UX/UI Designer
│   ├── Data Analyst
│   └── Content Manager
└── Operations Manager
    ├── Customer Success Manager
    ├── Support Agents (futurs)
    └── Compliance Officer
```

### **Outils & Infrastructure Recommandés**

#### **Gestion Équipe**
```
Communication :
├── Slack (communication interne)
├── Zoom (calls & screenshare)
├── Notion (documentation)
├── GitHub (code & issues)
└── Figma (design collaboration)

Gestion projet :
├── Jira ou Linear (product management)
├── GitHub Projects (dev tracking)
├── Calendly (scheduling)
├── Harvest (time tracking)
└── 1Password (secrets management)
```

#### **Support Client**
```
Stack support :
├── Zendesk (tickets & knowledge base)
├── Intercom (chat en direct)
├── Calendly (rendez-vous support)
├── Loom (vidéos explicatives)
└── Typeform (feedback surveys)

Analytics :
├── Google Analytics 4
├── Mixpanel (events tracking)
├── Hotjar (heatmaps & recordings)
├── Sentry (error monitoring)
└── Metabase (business intelligence)
```

### **KPIs & Métriques de Performance**

#### **Équipe Support**
```
Métriques principales :
├── 📞 Response time < 2h (95%)
├── ✅ Resolution time < 24h (90%)
├── 😊 Customer satisfaction > 4.5/5
├── 🎯 First contact resolution > 70%
└── 📈 Escalation rate < 15%

Métriques équipe :
├── 💪 Tickets/agent/jour : 15-25
├── 🎓 Knowledge base usage : >60%
├── 📚 Agent training hours/mois : 8h
├── 🔄 Turnover < 10%/an
└── 💰 Cost per resolution < 15 EUR
```

#### **Équipe Technique**
```
Métriques performance :
├── ⚡ Uptime > 99.5%
├── 🚀 Page load < 2 secondes
├── 🐛 Bug escape rate < 5%
├── 🔒 Security incidents = 0
└── 📦 Deploy frequency : weekly

Métriques qualité :
├── 🧪 Test coverage > 85%
├── 👀 Code review coverage : 100%
├── 📊 Technical debt < 20%
├── 📖 Documentation coverage > 80%
└── 🎯 Sprint velocity stable
```

---

## 🎯 **PARTIE 5 : RECOMMANDATIONS STRATÉGIQUES**

### **Actions Immédiates (Mois 1-3)**

1. **Recruter DevOps en urgence**
   - Infrastructure critique pour scaling
   - Éviter downtime pendant croissance
   - Setup monitoring & alertes

2. **Documenter tout l'existant**
   - Architecture technique
   - Processus business
   - Onboarding utilisateur

3. **Implémenter support basique**
   - Chat widget sur site
   - FAQ automatisée
   - Process escalade défini

### **Investissements Technologiques Prioritaires**

```ruby
# Gems à ajouter rapidement pour le support
gem 'exception_notification'  # Alertes erreurs
gem 'bullet'                 # Performance queries
gem 'rack-mini-profiler'     # Profiling
gem 'lograge'               # Logs structurés
gem 'ahoy_matey'            # Analytics users

# Infrastructure à prévoir
- Redis pour cache & sessions
- Sidekiq pour jobs asynchrones
- CDN pour assets (CloudFront)
- Monitoring APM (Scout, NewRelic)
- Error tracking (Sentry)
```

### **Évolution Organisationnelle**

#### **Années 1-2 : Foundation**
- Focus stabilité & support
- Process manuels optimisés
- Équipe lean mais efficace

#### **Années 2-3 : Automation**
- Support automatisé
- Self-service utilisateur
- Scaling infrastructure

#### **Années 3+ : Innovation**
- IA pour support
- Analytics prédictives
- Expansion fonctionnalités

---

## 📊 **PARTIE 6 : MÉTRIQUES DE SUCCÈS**

### **Objectifs 6 mois**
```
Technique :
├── ✅ 99.5% uptime
├── ✅ <2s page load
├── ✅ 0 incident critique
└── ✅ Monitoring complet

Support :
├── ✅ <4h response time
├── ✅ >4/5 satisfaction
├── ✅ Process escalade fluide
└── ✅ FAQ complète trilingue

Business :
├── ✅ 2x croissance utilisateurs
├── ✅ <5% churn rate
├── ✅ Process onboarding optimisé
└── ✅ Feedbacks intégrés produit
```

### **Objectifs 12 mois**
```
Scale :
├── 🎯 5000+ utilisateurs actifs
├── 🎯 Infrastructure auto-scaling
├── 🎯 Support 24/7 (chat bot)
├── 🎯 Analytics avancées
├── 🎯 Mobile app (PWA)
└── 🎯 Partenariats solides
```

---

**Note finale :** Cette roadmap RH est adaptée à une croissance progressive et soutenable. Les priorités peuvent être ajustées selon le rythme réel de croissance et les contraintes budgétaires. L'important est de maintenir la qualité de service tout en scalant efficacement.

**Prochaine révision :** Trimestrielle selon métriques de croissance

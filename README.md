# 🏠 Ren0vate - Plateforme SaaS de Primes Énergie Belges

*Application Ruby on Rails pour la gestion des primes de rénovation énergétique en Belgique*

## 🎯 **Vue d'ensemble**

Ren0vate est une plateforme SaaS innovante qui simplifie l'accès aux primes de rénovation énergétique pour les propriétaires et professionnels en Belgique. La plateforme couvre les 3 régions (Flandre, Bruxelles, Wallonie) avec une intelligence artificielle spécialisée.

### ✨ **Fonctionnalités principales**
- 🧮 **Calculateur multi-régional** : Simulation primes pour Flandre, Bruxelles, Wallonie
- 🏠 **Gestion multi-propriétés** : Dashboard et analytics par bien
- 📊 **Tracking projets** : Suivi progression travaux par phases
- 📄 **Gestion documents** : Upload et organisation par type de prime
- 🔍 **Recherche BCE** : Intégration API officielle entreprises belges
- 🤖 **IA contextuelle** : Support intelligent et recommandations

## 🏗️ **Architecture Technique**

### 📦 **Stack Technology**
- **Backend** : Ruby on Rails 8.0, PostgreSQL
- **Frontend** : Turbo, Stimulus, SASS
- **Cloud** : Cloudinary (stockage), Stripe (paiements)
- **IA** : OpenAI GPT pour chatbot contextuel
- **Déploiement** : Kamal, Docker

### 🗂️ **Structure du Projet**
```
├── app/                    # Application Rails standard
├── config/                 # Configuration environnements
├── db/                     # Base de données et seeds
├── bin/                    # Scripts exécutables Rails
├── scripts/                # Scripts métier spécifiques
│   └── archive/           # Scripts temporaires archivés
├── docs/                   # Documentation organisée
│   ├── technical/         # Guides techniques (PDF, Email, etc.)
│   ├── deployment/        # Documentation déploiement
│   └── guides/            # Guides utilisateur
└── Documents_strategiques/ # Documentation business
    ├── strategy/          # Stratégies IA et business
    ├── architecture/      # Architecture technique
    ├── roadmap/           # Roadmaps et plannings
    ├── guides/           # Guides setup (Stripe, I18n)
    └── business/         # Valorisation et business model
```

## 🚀 **Installation & Développement**

### ⚡ **Quick Start**
```bash
# Clone et setup initial
git clone [repository]
cd ren0vate
bin/setup

# Configuration environnement
cp .env.example .env
# Remplir les credentials dans .env

# Base de données
rails db:create db:migrate db:seed

# Serveur développement
bin/dev  # ou rails server
```

### 🔑 **Variables d'environnement essentielles**
- `SECRET_KEY_BASE` : Clé secrète Rails
- `CLOUDINARY_*` : Credentials stockage fichiers
- `STRIPE_*` : Credentials paiements SaaS
- `BCE_*` : API officielle entreprises belges
- `OPENAI_API_KEY` : IA conversationnelle

## 📈 **Business Model & Pricing**

Modèle **SaaS freemium** avec 5 tiers :
- 🆓 **Freemium** : 1 propriété, simulations limitées
- 🌟 **Individual** (39€/mois) : 3 propriétés, IA support
- 🚀 **Portfolio** (89€/mois) : 10 propriétés, analytics avancées
- 🏢 **Professional** (149€/mois) : Multi-clients, API access
- 💎 **Enterprise** (299€/mois) : Unlimited, white-label

*Valorisation estimée : 25-50M€ d'ici 2027*

## 🧹 **Code Maintenance**

### ✅ **Nettoyage récent (Nov 2025)**
- ✅ Suppression fichiers test obsolètes (`test_*.html`)
- ✅ Archive scripts temporaires → `scripts/archive/`
- ✅ Organisation documentation par catégories
- ✅ Nettoyage logs volumineux (76M → 348K)
- ✅ Mise à jour `.gitignore` avec exclusions

### 📝 **Conventions de développement**
- **Scripts** : Les scripts temporaires/debug vont dans `scripts/archive/`
- **Documentation** : Classée par catégories dans `docs/` et `Documents_strategiques/`
- **Tests** : Fichiers de test dans `/test` uniquement, pas à la racine

## 🌍 **Déploiement & Production**

### 🚢 **Kamal Deploy**
```bash
# Déploiement production
kamal deploy

# Monitoring
kamal app logs
kamal app exec -i --reuse "rails console"
```

### 📊 **Environnements**
- **Development** : SQLite local + Cloudinary dev
- **Production** : PostgreSQL + Redis + Cloudinary pro

---

**📞 Support** : Consultez `docs/` pour la documentation technique et `Documents_strategiques/` pour les guides business.

*Dernière mise à jour : 29 novembre 2025*

# CLAUDE.md — Ren0vate

Fichier de contexte pour Claude Code. Lire avant toute session.

## Domaine métier

Application SaaS belge de **gestion de chantiers de rénovation**. Permet aux particuliers et professionnels de :
- Piloter leurs chantiers de rénovation de A à Z (devis, factures, PV, avancement)
- Gérer les entrepreneurs, contrats et documents liés aux travaux
- Uploader et faire analyser leurs factures, devis, PV de réception via OCR
- Accéder à un chatbot IA contextuel (Claude Anthropic) pour conseils et suivi
- Simuler les primes disponibles (fonctionnalité secondaire — Wallonie et Flandre uniquement)

**Régions supportées :** Wallonie, Flandre, Bruxelles (primes Renolution supprimées — `eligible: false`)

## Stack technique

| Composant | Version |
|-----------|---------|
| Ruby | 3.3.9 |
| Rails | 8.1.3 |
| DB production | PostgreSQL (Heroku) |
| DB développement | SQLite |
| Queue | Solid Queue 1.4.0 (in-process Puma) |
| Assets | Propshaft + ImportMap |
| CSS | Bootstrap 5 + SassC |
| Auth | Devise 5 |
| Forms | simple_form |
| PDF | Prawn + pdf-reader |
| OCR | RTesseract (Tesseract 5) + MiniMagick |
| IA | Claude Anthropic via HTTParty (pas de gem officielle) |
| Storage | Cloudinary (images/docs) |
| Paiements | Stripe |
| Deploy | Heroku (stack Heroku-24) |

## Commandes essentielles

```bash
# Développement
bin/dev                          # Démarrer le serveur local
bin/rails db:migrate             # Migrations
bin/rails db:seed                # Seeds

# Tests
bin/rails test                   # Tests unitaires
bin/rails test:system            # Tests système

# Production (Heroku)
git push heroku master           # Déployer (déclenche db:migrate via Procfile release)
heroku logs --tail --app ren0vate
heroku run rails console --app ren0vate
heroku config --app ren0vate

# Qualité
bin/brakeman                     # Sécurité
bin/rubocop                      # Linting
```

## Architecture

```
app/
  controllers/
    admin/           # Interface admin (users, dashboard)
    api/             # Endpoints JSON (chatbot, PDF preview, IA)
    users/           # Sessions Devise custom
  models/
    user.rb          # Devise + rôles (user/moderator/admin)
    property.rb      # Bien immobilier (appartient à user)
    project.rb       # Dossier de travaux (appartient à property)
    request.rb       # Demande de prime (appartient à project)
    simulation.rb    # Calcul de primes (appartient à property)
  services/
    contextual_bot_service.rb    # Contexte IA pour le chatbot
    bce_verification_service.rb  # Vérification TVA via VIES (API gratuite EU)
    facture_ocr_service.rb       # OCR factures
  jobs/
    facture_alert_job.rb         # Alertes factures (recurring: 9h daily + /6h)
    bce_verification_job.rb      # Vérification TVA asynchrone
  views/
    properties/                  # Formulaires par région (_form_wallonie/bruxelles/flandre)
    admin/users/                 # Interface admin utilisateurs
```

## Modèle de données clé

```
User → Properties → Projects → Requests → Factures/Devis
                             → Documents
                  → Simulations
```

- `User` : compte, revenus, situation familiale, région
- `Property` : bien immobilier, adresse, type_bien, **type_demandeur** (Particulier/Société/Syndic...)
- `Project` : dossier de travaux, entrepreneur (N° BCE), état d'avancement
- `Request` : demande de prime officielle, statut, montant
- `Simulation` : calcul estimatif des primes éligibles

## Conventions

- **Locale** : routes scopées `/:locale` (fr/nl/en). `I18n.locale` disponible partout.
- **Rôles** : `user`, `moderator`, `admin` — vérifier `current_user.admin?` pour accès admin
- **Strong params** : toujours explicites dans les controllers
- **Chiffrement** : `national_number` et `iban` chiffrés at-rest via `encrypts` (Active Record Encryption)
- **Formulaires** : `simple_form` avec `f.input` — ne pas mixer avec `form.text_field`
- **Migrations** : nommage `YYYYMMDDHHMMSS_description.rb`, jamais modifier une migration existante

## Variables d'environnement Heroku

```
DATABASE_URL          # PostgreSQL Heroku
ANTHROPIC_API_KEY     # Claude AI
CLOUDINARY_URL        # Storage fichiers
STRIPE_SECRET_KEY     # Paiements
STRIPE_WEBHOOK_SECRET # Webhooks Stripe
SMTP_*                # Envoi emails
SOLID_QUEUE_IN_PUMA=true  # Active Solid Queue dans le processus Puma
```

## Points d'attention

- **Bruxelles** : primes Renolution supprimées — `eligible: false` retourné par défaut
- **Solid Queue** : tourne in-process (pas de worker dyno séparé). Jobs persistés en DB.
- **`:confirmable` Devise** : colonnes présentes en DB mais module désactivé dans `user.rb` — ne pas activer sans d'abord confirmer les comptes existants (`User.where(confirmed_at: nil).update_all(confirmed_at: Time.now)`)
- **`config.assets.compile = true`** en production — warning Heroku connu, non bloquant
- **Ruby 3.3.9** sur Heroku (3.3.11 disponible — à upgrader)
- **BCE** : vérification via API VIES publique (`ec.europa.eu/taxation_customs/vies`) — gratuit, pas de clé

## Stripe — État au 27 avril 2026

- **Mode** : Live (clés `sk_live_` / `pk_live_` sur Heroku)
- **Webhook** : `POST /webhooks/stripe` — endpoint "ren0vate-production", 6 events configurés
- **CSP** : `form_action :self, "https://checkout.stripe.com"` — nécessaire car Chrome bloque les redirects 302 vers Stripe
- **Turbo** : désactivé sur le form checkout (`data: { turbo: false }`) — sinon fetch() intercepte et échoue CORS
- **API Stripe version** : `2026-04-22.dahlia` — `current_period_start/end` désormais dans `items.data[0].current_period`, pas au root de la subscription. Les handlers webhook convertissent l'objet Stripe en Hash via `JSON.parse(subscription.to_json)` avant d'utiliser `dig`.
- **Pricing** : `tax_behavior: 'inclusive'` — les prix affichés (39€, 89€…) sont TTC, TVA 21% incluse
- **Early adopters** : 124 comptes existants, 0 subscription active. Ne pas forcer les gates sur les données existantes avant communication.

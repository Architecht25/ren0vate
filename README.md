# Ren0vate

Plateforme SaaS belge de **gestion de chantiers de rénovation collaborative** : propriétaires, architectes et entrepreneurs pilotent ensemble un chantier, de la préparation jusqu'à la réception des travaux (devis, factures, PV, avancement, documents). Un accès **primes et financement** est intégré au parcours.

Application Ruby on Rails couvrant les trois régions : **Wallonie**, **Flandre** et **Bruxelles**.

## Fonctionnalités

- **Chantiers collaboratifs** : biens immobiliers, dossiers de travaux rattachés à chaque bien, suivi par phases et checklists.
- **Collaboration professionnelle** : un architecte ou un entrepreneur peut inviter son client (lien `/?ref=…`) et rejoindre un projet une fois l'accès activé. Les membres d'un projet (propriétaire, architecte, entrepreneur) ont chacun leur rôle.
- **Entrepreneurs et contrats** : vérification de la TVA des entrepreneurs via VIES (numéro BCE), contrats et documents liés aux travaux.
- **Documents et OCR** : upload de factures, devis et PV de réception, avec extraction automatique (Tesseract / MiniMagick, extraction par IA pour les devis et audits énergétiques).
- **Accès primes et financement** : simulateur de primes par région, sources de financement et suivi de dossiers de prêt (dont l'impact PEB sur le taux, en Wallonie).
- **Chatbot IA contextuel** : assistant basé sur Claude (Anthropic), qui tient compte du contexte du bien et du projet. Les quotas dépendent de l'offre.
- **Alertes et notifications** : rappels de factures, échéances, veille réglementaire et notifications par e-mail.
- **Paiements** : abonnements et achats via Stripe Checkout, mise à jour par webhooks.
- **Administration** : interface admin (utilisateurs, articles, sources réglementaires, tickets de support).

> Les primes Renolution (Bruxelles) ont été supprimées : `eligible: false` est retourné par défaut.

## Stack technique

| Composant | Choix |
|---|---|
| Langage / framework | Ruby 3.3.9, Rails 8.1 |
| Base de données | PostgreSQL (développement comme production) |
| Jobs asynchrones | Solid Queue (dyno worker dédié en production) |
| Front-end | Propshaft + ImportMap, Bootstrap 5, SassC, Turbo / Stimulus |
| Formulaires | simple_form |
| Authentification | Devise (rôles `user`, `moderator`, `admin`) |
| PDF | Prawn, pdf-reader |
| OCR | RTesseract (Tesseract 5), MiniMagick |
| IA | SDK officiel `anthropic` |
| Stockage fichiers | Cloudinary (migration vers S3 prévue, non connectée) |
| Paiements | Stripe |
| Sécurité | rack-attack (rate limiting), Brakeman |
| Monitoring | sentry-ruby / sentry-rails (production uniquement) |
| Hébergement | Heroku (stack Heroku-24) |

## Structure du projet

```
app/
  controllers/     # admin/, api/, users/ (sessions Devise), pro_referrals, invitations…
  models/          # User, Property, Project, ProjectMember, Request, Simulation, devis/, documents/…
  services/        # chatbot contextuel, OCR factures, vérification BCE, régions, décision hub…
  jobs/            # alertes factures, vérification TVA, extraction PEB/audit, relances, veille réglementaire…
  mailers/         # invitations projet, referral pro, notifications
  views/           # formulaires par région (properties/_form_wallonie|flandre|bruxelles), dashboards par profil…
config/
  locales/         # fr, nl, en, es (routes scopées /:locale)
  initializers/    # rack_attack.rb, sentry, Stripe…
db/
  seeds/           # données de référence (primes par région, produits, checklists…)
docs/              # documentation opérationnelle et commerciale
scripts/           # scripts ponctuels (nettoyage, extraction des primes wallonnes)
test/              # unit, integration (smoke tests), jobs, services, system
Documents_strategiques/  # documents d'affaires et de stratégie
```

Les fichiers de pilotage sont à la racine : `CLAUDE.md` (contexte pour Claude Code), `LAUNCH_CHECKLIST_OCT2026.md`, `BACKLOG_FONCTIONNALITES.md`, `TODO_ROADMAP.md`.

## Installation en local

### Prérequis

- Ruby 3.3.9 (voir `.ruby-version`)
- PostgreSQL
- Tesseract 5 (OCR) et les paquets listés dans `Aptfile`

### Mise en place

```bash
git clone <url-du-depot> ren0vate
cd ren0vate
bin/setup
```

Créez ensuite votre fichier de variables d'environnement (voir ci-dessous), puis lancez l'application :

```bash
bin/rails db:migrate
bin/rails db:seed     # données de référence (primes, produits, checklists)
bin/dev               # serveur web + assets (Procfile.dev)
```

Les seeds ne sont **pas** rejoués automatiquement au déploiement : après un changement dans `db/seeds/`, il faut les lancer à la main.

## Variables d'environnement

Les noms ci-dessous sont ceux lus par le code. Ne versionnez jamais leurs valeurs.

**Base et application**

- `DATABASE_URL` : connexion PostgreSQL
- `SECRET_KEY_BASE`
- `RAILS_MAX_THREADS`, `WEB_CONCURRENCY`, `PORT`

**Chiffrement at-rest** (Active Record Encryption, pour `national_number` et `iban`)

- `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`, `AR_ENCRYPTION_KEY_DERIVATION_SALT`
- `AR_ENCRYPTION_SUPPORT_UNENCRYPTED` (ne l'activer que pendant une migration)

**Services tiers**

- `ANTHROPIC_API_KEY` : chatbot et extraction IA
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` : stockage des fichiers (documents, images)
- `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `DEVISE_MAILER_SENDER`, `ADMIN_MAILER_FROM`
- `SENTRY_DSN` : monitoring (actif uniquement en production)
- `MAPBOX_ACCESS_TOKEN` : cartes de l'interface admin

**Divers**

- `ADMIN_EMAIL`, `ADMIN_MAILER_FROM`, `INTELLIGENCE_REPORT_EMAIL`, `PLAN_EXEMPT_EMAIL` : adresses d'administration et exemptions de plan
- `APP_URL` : domaine utilisé dans les liens des e-mails admin (défaut `https://ren0vate.be`)
- `AGENT_API_KEY` : clé de l'API agent (marketing drafts)
- `TESSDATA_PREFIX` : chemin des données Tesseract (OCR PDF page par page)

En production, les variables sont gérées avec `heroku config --app ren0vate`.

## Tests et qualité

```bash
bin/rails test          # tests unitaires et d'intégration
bin/rails test:system   # tests système (Chrome requis, exécutés en CI)
bin/rubocop             # style
bin/brakeman            # analyse de sécurité
```

La CI GitHub Actions (`.github/workflows/ci.yml`) lance Brakeman, RuboCop et la suite de tests (PostgreSQL 17, Chrome) sur chaque pull request et sur `master`.

Règle appliquée au projet : toute nouvelle vue ou action doit être accompagnée d'un test smoke minimal (`assert_response :success` sur son GET principal). Modèle de référence : `test/integration/simulation_smoke_test.rb`.

## Déploiement (Heroku)

```bash
git push heroku master
```

Le `Procfile` définit trois processus :

- `web` : le serveur Rails
- `worker` : `bin/jobs`, qui exécute Solid Queue
- `release` : `bin/rails db:migrate`, lancé à chaque déploiement

**Attention** : les jobs (envoi d'e-mails via `deliver_later`, alertes, extractions) ne sont traités que si le dyno `worker` tourne. S'il est absent ou à zéro, les jobs s'accumulent en base sans être exécutés. Pour vérifier :

```bash
heroku ps --app ren0vate
heroku run rails console --app ren0vate   # SolidQueue::Process.all, SolidQueue::Job.where(finished_at: nil).count
heroku logs --tail --app ren0vate
```

Ne réactivez pas Solid Queue dans le même process que Puma (`SOLID_QUEUE_IN_PUMA`) : le dyno web Basic (512 Mo) dépasse sa mémoire.

## Paiements et abonnements

Les offres sont définies dans `app/models/pricing_tier_catalog.rb`, qui reste la référence pour les prix et les quotas de chatbot :

| Offre | Prix mensuel TTC |
|---|---|
| Starter | Gratuit |
| Propriétaire | 39 € |
| Investisseur | 89 € |
| Pro | 99 € |
| Premium | 149 € |
| Entreprise | 299 € |

Les prix Stripe sont en `tax_behavior: 'inclusive'` (TVA 21 % incluse). Le webhook est exposé sur `POST /webhooks/stripe`. Stripe ne suit pas les redirections HTTP : l'endpoint doit répondre directement sur le domaine canonique, sans 301.

## Sécurité et données personnelles

- Rate limiting et protection brute-force via rack-attack (`config/initializers/rack_attack.rb`).
- Les numéros nationaux et IBAN sont chiffrés au repos et retirés des payloads Sentry (`before_send`).
- Authentification Devise. Le module `:confirmable` est présent en base mais **désactivé** : ne l'activez pas sans avoir confirmé les comptes existants.
- Les données de comptes inactifs suivent une politique de rétention (`DataRetentionJob`).

## Documentation

- `CLAUDE.md` : contexte métier, conventions et points d'attention pour le développement
- `docs/` : documentation opérationnelle (agents IA, checklists de lancement, présentations commerciales)
- `Documents_strategiques/` : stratégie, architecture et business model

---

*Dernière mise à jour : 3 octobre 2026*

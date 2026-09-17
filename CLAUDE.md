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
| Queue | Solid Queue 1.4.0 (dyno worker dédié depuis le 22/08/2026, voir Points d'attention) |
| Assets | Propshaft + ImportMap |
| CSS | Bootstrap 5 + SassC |
| Auth | Devise 5 |
| Forms | simple_form |
| PDF | Prawn + pdf-reader |
| OCR | RTesseract (Tesseract 5) + MiniMagick |
| IA | Claude Anthropic via le SDK officiel `anthropic` (migré depuis HTTParty le 10/09/2026) |
| Storage | Cloudinary (images/docs) |
| Paiements | Stripe |
| Sécurité | rack-attack (rate limiting/brute-force) + sentry-ruby/sentry-rails (error tracking, branché le 09/09/2026) |
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
    user.rb          # Devise + rôles (user/moderator/admin) + professional_type + referral_token
    property.rb      # Bien immobilier (appartient à user)
    project.rb       # Dossier de travaux (appartient à property)
    project_member.rb # Collaboration pro (architect/entrepreneur) sur un projet
    request.rb       # Demande de prime (appartient à project)
    simulation.rb    # Calcul de primes (appartient à property)
  controllers/
    pro_referrals_controller.rb  # Lien d'invitation pro → client (/pro/inviter-client)
    invitations_controller.rb    # Acceptation invitation token par les pros
  services/
    contextual_bot_service.rb    # Contexte IA pour le chatbot
    bce_verification_service.rb  # Vérification TVA via VIES (API gratuite EU)
    facture_ocr_service.rb       # OCR factures
  jobs/
    facture_alert_job.rb         # Alertes factures (recurring: 9h daily + /6h)
    bce_verification_job.rb      # Vérification TVA asynchrone
  mailers/
    pro_referral_mailer.rb       # Email invitation client par un pro
    project_mailer.rb            # Invitations projet + pro_referral_pending
  views/
    properties/                  # Formulaires par région (_form_wallonie/bruxelles/flandre)
    admin/users/                 # Interface admin utilisateurs
    pro_referrals/show.html.erb  # Page lien referral pro → client
    devise/registrations/new     # Formulaire inscription avec sélecteur de profil (4 cartes)
```

## Modèle de données clé

```
User → Properties → Projects → Requests → Factures/Devis
                             → Documents
                  → Simulations
```

- `User` : compte, revenus, situation familiale, région, **`professional_type`** (nil=propriétaire / architect / entrepreneur / intermediary), **`referral_token`** (unique, généré à la demande)
- `Property` : bien immobilier, adresse, type_bien, **type_demandeur** (Particulier/Société/Syndic...)
- `Project` : dossier de travaux, entrepreneur (N° BCE), état d'avancement
- `ProjectMember` : lien pro ↔ project (roles: owner/architect/entrepreneur, status: pending/active, invite_token)
- `Request` : demande de prime officielle, statut, montant
- `Simulation` : calcul estimatif des primes éligibles

## Flux compte professionnel (architecte / entrepreneur)

1. Inscription via `/inscription` → sélection profil → `professional_type` sauvegardé
2. Login → `professional_guest?` retourne `true` → redirect `member_projects_path`
3. Dashboard vide → CTA "Inviter un client" → `/pro/inviter-client`
4. L'archi copie/envoie son lien `/?ref=TOKEN`
5. Le client s'inscrit → crée son premier projet → `handle_referral_after_project_create` crée `ProjectMember(pending)`
6. Email envoyé au pro via `ProjectMailer#pro_referral_pending`
7. Le client active l'accès (via `pro_views#invite` ou manuellement) → archi rejoint le projet

**`professional_guest?`** : `true` si `professional_type.present? && properties.none?` OU `properties.none? && project_members.active.pros.any?`

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
SENTRY_DSN            # Error tracking (branché le 09/09/2026, actif en production uniquement)
```

## Points d'attention

- **Bruxelles** : primes Renolution supprimées — `eligible: false` retourné par défaut
- **Solid Queue** : tourne sur un **dyno worker dédié** (`worker: bundle exec bin/jobs` dans le Procfile, activé le 22/08/2026). Ne PAS repasser par `SOLID_QUEUE_IN_PUMA=true` (plugin Puma) : testé le 22/08/2026 sur le dyno web Basic (512 Mo), la RAM grimpait de 400→465 Mo en 1 minute à vide (Puma + Supervisor + Dispatcher + Worker + Scheduler dans le même process) — c'est cette config qui avait causé le R14 qui avait fait désactiver Solid Queue en premier lieu. Si le dyno worker est absent/scale à 0, les jobs (`deliver_later`, `FactureAlertJob`, etc.) s'accumulent silencieusement en base sans jamais s'exécuter — vérifier `SolidQueue::Process.all` et `SolidQueue::Job.where(finished_at: nil).count` en cas de doute.
- **`:confirmable` Devise** : colonnes présentes en DB mais module désactivé dans `user.rb` — ne pas activer sans d'abord confirmer les comptes existants (`User.where(confirmed_at: nil).update_all(confirmed_at: Time.now)`)
- **`config.assets.compile = true`** en production — warning Heroku connu, non bloquant
- **Ruby 3.3.9** sur Heroku (3.3.11 disponible — à upgrader)
- **BCE** : vérification via API VIES publique (`ec.europa.eu/taxation_customs/vies`) — gratuit, pas de clé
- **Sentry** : branché le 09/09/2026 (`sentry-ruby`/`sentry-rails`), actif uniquement en production (`config.enabled_environments = %w[production]`), 10% des transactions tracées (`traces_sample_rate = 0.1`, plan gratuit), `national_number`/`iban` retirés des payloads avant envoi (`before_send`), exceptions `RoutingError`/`RecordNotFound`/`Rack::Attack::Error`/`Encoding::CompatibilityError` exclues du bruit (dernier ajouté le 13/09/2026 — scans bot envoyant des `POST /` avec un corps en UTF-16LE, aucune route `POST` n'existe sur `root`)
- **rack-attack** : gem présente et middleware activé (`config/initializers/rack_attack.rb`) — pas encore documenté ailleurs dans ce fichier avant le 10/09/2026
- **DB développement réelle** : PostgreSQL local (pas SQLite malgré la ligne "DB développement" ci-dessus, jamais corrigée depuis un ancien setup — à vérifier via `config/database.yml` si doute)

## Responsivité mobile (sweep complet du 17/09/2026)

Audit + correction de toutes les vues de l'app (~35 modules) pour la responsivité smartphone. Règles à respecter pour tout nouveau développement de vue :

- **Anti-pattern n°1, de loin le plus répété** : une colonne Bootstrap avec seulement `col-lg-N`/`col-md-N`/`col-xl-N` et **pas de `col-12` de base** devient un flex-item "shrink-to-fit" en dessous du breakpoint au lieu de s'empiler en pleine largeur. Toujours écrire `col-12 col-md-6`, jamais `col-md-6` seul.
- **En-têtes de page** : `d-flex justify-content-between align-items-center` (sans wrap) déborde en mobile dès que le titre + les actions ne tiennent pas sur une ligne. Pattern correct : `d-flex flex-column flex-sm-row align-items-sm-center justify-content-sm-between gap-2`.
- **Rangées d'onglets/nav-pills** : utiliser la classe utilitaire partagée `.tabs-scroll-x` (définie dans `app/assets/stylesheets/pages/_properties.scss`, compilée globalement) pour un scroll horizontal propre au lieu d'un retour à la ligne moche ou d'un débordement.
- **Vues PDF/print** méritent la même vérification mobile que les vues normales (souvent oubliées).
- **Vérifications systématiques utiles en cas de bug 500 sur une vue** : (1) le nom du route helper existe-t-il vraiment (`rails routes | grep`), erreurs fréquentes de nommage type `property_dashboard_path` vs `dashboard_property_path` ; (2) toute variable d'instance utilisée dans la vue est-elle bien assignée dans **chaque** action du controller qui rend cette vue, pas seulement l'action "principale" ; (3) tout `has_many` déclaré sur un modèle a-t-il bien un fichier modèle correspondant (Zeitwerk collapse peut masquer l'absence d'un fichier sans erreur au boot — ex. `ChantierAnalyse` manquait totalement alors que la table et les usages existaient, cassait `/analytics` et le job `ChantierVisionJob` silencieusement).
- **Couverture de tests quasi nulle** : seuls 6 fichiers `test/integration/*_smoke_test.rb` existaient avant le 17/09/2026, couvrant une fraction minime des routes. Chrome/Selenium indisponible en local (mais présent en CI, `.github/workflows/ci.yml` installe `google-chrome-stable`) → préférer étendre le pattern `ActionDispatch::IntegrationTest` léger existant plutôt que d'écrire des System Tests non vérifiables localement. Pattern de référence : `test/integration/simulation_smoke_test.rb` (`Devise::Test::IntegrationHelpers`, fixtures explicites, `Property.create!(..., skip_onboarding_validation: true)` pour bypasser les validations régionales à l'onboarding).
- **Règle** : toute nouvelle vue/action ajoutée à l'app doit s'accompagner d'un test smoke minimal (`assert_response :success` sur son GET principal) avant merge — c'est ce filet qui a permis de repérer 2 bugs `AbstractController::ActionNotFound` (Rails 7.1 `raise_on_missing_callback_actions`, silencieux au boot) sur `notifications` et `admin/articles` le 18/09/2026.
- **En-tête de page standardisé** : `app/views/shared/_page_header.html.erb` (utilisé en `render layout: "shared/page_header", locals: { title:, icon:, subtitle: } do ... end`, le bloc contient les actions) — à utiliser pour toute nouvelle page listing/index avec un header simple (icône + titre + actions). Adopté sur `properties#index`, `projects#index`, `notifications#index`, `categories#index` le 18/09/2026 ; les pages avec un header plus riche (badges inline, dropdown mobile dédié — ex. `properties#dashboard`, `projects#show`) gardent leur markup bespoke, ne pas forcer le partial dessus.
- **Widgets dupliqués** : `app/views/dashboard/_notification_widget.html.erb` factorise le widget cloche flottant (desktop uniquement) qui était copié-collé identique dans `dashboard/index|pro|architecte|entrepreneur|intermediaire.html.erb` — si un 6ᵉ variant de dashboard apparaît, réutiliser ce partial plutôt que recopier.

## Stripe — État au 27 avril 2026

- **Mode** : Live (clés `sk_live_` / `pk_live_` sur Heroku)
- **Webhook** : `POST /webhooks/stripe` — endpoint "ren0vate-production", 6 events configurés
- **CSP** : `form_action :self, "https://checkout.stripe.com"` — nécessaire car Chrome bloque les redirects 302 vers Stripe
- **Turbo** : désactivé sur le form checkout (`data: { turbo: false }`) — sinon fetch() intercepte et échoue CORS
- **API Stripe version** : `2026-04-22.dahlia` — `current_period_start/end` désormais sur `items.data[0]` directement (champs plats `current_period_start`/`current_period_end`, **pas** nichés sous un sous-objet `current_period`), plus au root de la subscription. Les handlers webhook convertissent l'objet Stripe en Hash via `JSON.parse(subscription.to_json)` avant d'utiliser `dig('items', 'data', 0, 'current_period_start')`.
- **Webhooks vs redirection canonique** : `WebhooksController` doit `skip_before_action :redirect_old_heroku_host` — Stripe ne suit jamais les redirections HTTP, une 301 fait échouer silencieusement toute livraison de webhook. L'URL de l'endpoint Stripe doit pointer directement sur `https://www.ren0vate.be/webhooks/stripe` (pas le domaine Heroku brut).
- **Pricing** : `tax_behavior: 'inclusive'` — les prix affichés (39€, 89€…) sont TTC, TVA 21% incluse
- **Early adopters** : 108 comptes actifs, 1 abonnement payant actif (souscrit en annuel — 3 sept. 2026). Ne pas forcer les gates sur les données existantes avant communication.

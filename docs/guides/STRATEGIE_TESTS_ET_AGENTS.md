# Stratégie tests & agents IA — Ren0vate

## Contexte

App en phase de commercialisation. ~429 vues, 50+ contrôleurs.
Objectif : couverture utile, pas exhaustive. Protéger ce qui casse, pas tester du code stable.

---

## Partie 1 — Stratégie de tests "haute valeur"

### Règle de base

Ne pas rattraper le retard d'un coup. Écrire des tests rétroactifs pour les vues et contrôleurs CRUD est une perte de temps — Rails les garantit lui-même.

**3 couches seulement, dans cet ordre de priorité.**

---

### Couche 1 — Tests de revenus (priorité absolue)

Ce qui casse ici = perte de clients et de revenus réels.

| Cible | Fichier test à créer | Ce qu'on vérifie |
|-------|---------------------|-----------------|
| Checkout Stripe | `test/controllers/webhooks_controller_test.rb` | `checkout.session.completed` met à jour le tier |
| Webhook payment_failed | idem | downgrade ou flag `payment_failed` sur le user |
| Webhook subscription.created | idem | user passe de freemium → tier actif |
| Gate `property_limit` | `test/models/user_test.rb` | freemium=1, individual=3, portfolio=10, enterprise=∞ |
| Gate `simulation_limit` | idem | freemium=1, autres=∞ |

**Stack :** Minitest (déjà en place) + `stripe-ruby-mock` ou fixtures JSON raw pour simuler les payloads webhook.

```ruby
# Exemple structure test webhook
test "checkout.session.completed upgrades user tier" do
  user = users(:freemium_user)
  payload = stripe_fixture("checkout_session_completed", user_id: user.id, tier: "individual")
  post webhooks_stripe_path, params: payload, headers: stripe_headers(payload)
  assert_equal "individual", user.reload.subscription_tier
end
```

---

### Couche 2 — Tests des services métier critiques

Ce qui casse ici = crédibilité commerciale et promesse produit.

| Service | Fichier test à créer | Cas critiques |
|---------|---------------------|--------------|
| `FlandreEligibilityService` | `test/services/regions/flandre_eligibility_service_test.rb` | Isolation thermique éligible, PEB D → prime X, PEB A → 0 |
| `WallonieEligibilityService` | `test/services/regions/wallonie_eligibility_service_test.rb` | Revenus modestes → prime majorée, revenus élevés → prime de base |
| `BruxellesEligibilityService` | `test/services/regions/bruxelles_eligibility_service_test.rb` | Retourne `eligible: false` (Renolution supprimé) |
| `FactureOcrService` | `test/services/facture_ocr_service_test.rb` | Fixture PDF → montant extrait correct, PDF illisible → nil sans crash |

**Stack :** Minitest pur, pas de HTTP réel — mocker Cloudinary et Tesseract avec `stub`.

```ruby
# Exemple structure test eligibilité
test "type_demandeur Société exclut certaines primes Flandre" do
  property = properties(:flandre_societe)
  result = FlandreEligibilityService.new(property).call
  assert result[:primes].none? { |p| p[:reserved_particuliers] }
end
```

---

### Couche 3 — Smoke tests de parcours (non-régression)

Un test de bout en bout par région qui vérifie que le wizard de simulation ne plante pas. Pas besoin de tester chaque champ.

| Parcours | Fichier test à créer | Assertion minimale |
|----------|---------------------|-------------------|
| Simulation Flandre | `test/system/simulation_flandre_test.rb` | Wizard complété → page résultats affichée (status 200) |
| Simulation Wallonie | `test/system/simulation_wallonie_test.rb` | idem |
| Simulation Bruxelles | `test/system/simulation_bruxelles_test.rb` | Affiche message "primes non disponibles" |

**Stack :** Capybara + Selenium (déjà dans Gemfile).

---

### Ce qu'on ne teste PAS

- Tests de vues (`.html.erb`)
- Tests de mailers
- Tests des contrôleurs CRUD basiques (`index`, `show`, `new`, `create` standard)
- Tests des helpers

---

### Effort estimé

| Couche | Fichiers | Jours |
|--------|----------|-------|
| Revenus (Stripe) | ~3 fichiers, ~20 tests | 1 jour |
| Services métier | ~4 fichiers, ~30 tests | 1 jour |
| Smoke tests système | ~3 fichiers, ~9 tests | 0.5 jour |
| **Total** | **~10 fichiers, ~60 tests** | **~2.5 jours** |

---

## Partie 2 — Agents à lancer (ordre de priorité)

### 1. `/security-review` — Avant tout lancement public

**Pourquoi maintenant :** l'app gère des données très sensibles en production.
- IBAN et numéro national chiffrés at-rest (`encrypts`)
- Revenus fiscaux via OCR (`AerOcrService`)
- Paiements Stripe avec webhooks publics
- Interface admin sans 2FA

**Action :** lancer `/security-review` sur la branche `master` actuelle, avant d'acquérir des clients réels.

---

### 2. `claude-api` skill — Optimisation coûts IA

**Pourquoi :** l'app consomme Claude Sonnet + Haiku sur plusieurs agents avec quotas mensuels par tier. Le prompt caching d'Anthropic peut réduire les coûts de **60-80%** sur les agents à prompts système répétitifs.

**Agents concernés par ordre d'impact :**
| Agent | Service | Gain attendu |
|-------|---------|-------------|
| Ren0chat | `contextual_bot_service.rb` | Élevé — prompt système long, appelé fréquemment |
| PermisPredicator | `permis_predicator_service.rb` | Élevé — contexte réglementaire volumineux |
| ChantierVision | `chantier_vision_service.rb` | Moyen |

**Action :** charger le skill `claude-api`, implémenter `cache_control: { type: "ephemeral" }` sur les blocs système longs.

---

### 3. `Plan` agent — Plan d'implémentation des tests

**Pourquoi :** plutôt que de démarrer les tests dans le vide, le Plan agent produit un plan concret : quels fichiers créer, quels services mocker, dans quel ordre — en analysant le code existant.

**Input à fournir au Plan agent :**
- La stratégie couches 1-2-3 de ce document
- Les services cibles : `FlandreEligibilityService`, `WallonieEligibilityService`, `WebhooksController`
- Contrainte : Minitest (pas RSpec), pas de FactoryBot (non dans Gemfile)

---

### 4. `/review` — Sur chaque PR de fonctionnalité commerciale

À activer systématiquement sur les PRs qui touchent : onboarding, pricing page, Stripe checkout, limites de tier.

---

### 5. `fewer-permission-prompts` — Confort quotidien Claude Code

Scanne l'historique des sessions et génère un allowlist dans `.claude/settings.json`. À faire après `/security-review` pour ne pas allowlister des patterns à risque.

---

## Ordre d'exécution recommandé

```
Semaine 1 : /security-review  →  corrections éventuelles
Semaine 1 : claude-api skill  →  prompt caching Ren0chat + PermisPredicator
Semaine 2 : Plan agent        →  plan tests généré
Semaine 2-3 : implémentation tests (couches 1→2→3)
En continu : /review sur PRs features
Après stabilisation : fewer-permission-prompts
```

---

## Chantier infrastructure — Migration Cloudinary → Cloud européen

### Contexte & état actuel (avril 2026)

| Métrique Cloudinary | Valeur |
|---------------------|--------|
| Stockage | 7,15 GB |
| Fichiers | 8 354 ressources (11 979 avec dérivés) |
| Bande passante (mois) | ~2,97 GB |
| Transformations (mois) | 2 189 |
| Crédits utilisés | 12,3 / 25 (49%) — **plan gratuit** |

**Déclencheur économique :** le plan payant Cloudinary commence à $89/mois. À 7,15 GB sur Scaleway/OVH, le coût serait ~0,07€/mois de stockage pur.

### Complexité réelle

Le code n'utilise pas uniquement Active Storage — il appelle le SDK Cloudinary directement en 93 endroits :

| Fichier | Usage direct |
|---------|-------------|
| `app/helpers/cloudinary_helper.rb` | Transformations (resize, crop, qualité) |
| `app/services/cloudinary_pdf_service.rb` | Previews PDF |
| `app/models/document.rb` | `cloudinary_url` + `cloudinary_preview_url` |
| `app/controllers/documents_controller.rb` | Construction d'URLs directes |

### Alternatives européennes recommandées

| Provider | Siège | Compatibilité | Prix stockage | Avantage |
|----------|-------|---------------|--------------|----------|
| **Scaleway Object Storage** | France (Amsterdam) | S3 ✅ | ~0,01€/GB/mois | Recommandé — RGPD natif, S3-compatible |
| OVHcloud Object Storage | France (infras BE) | S3 ✅ | ~0,01€/GB/mois | Présence belge |
| Hetzner Object Storage | Allemagne | S3 ✅ | ~0,006€/GB/mois | Le moins cher |

**Recommandation : Scaleway Object Storage (région nl-ams, Amsterdam)** — meilleur équilibre souveraineté/coût/simplicité pour une app belge. Le `storage.yml` est déjà pré-câblé pour S3 (commenté, région eu-west-1 à adapter).

### Plan de migration en 3 phases

**Phase 1 — Swapper le backend Active Storage** (~1 journée)
- Modifier `storage.yml` pour pointer vers Scaleway (S3-compatible)
- Les nouveaux uploads vont sur Scaleway ; l'existant reste sur Cloudinary

**Phase 2 — Migrer les fichiers existants** (~2h)
- Script Ruby itérant sur tous les `ActiveStorage::Blob`
- Recopie vers le nouveau provider via l'API S3
- Cloudinary reste en lecture pendant la transition

**Phase 3 — Remplacer les appels SDK Cloudinary directs** (~2-3 jours)
- Transformations images (`cloudinary_helper`) → Active Storage variants + `image_processing` (déjà dans le Gemfile)
- Previews PDF (`cloudinary_pdf_service`) → Active Storage previews natifs (Rails 8 + poppler ou mupdf sur le dyno)
- Nettoyage des 93 références restantes

### Timing recommandé

Migrer **avant le lancement commercial**, pendant que le volume est gérable (7,15 GB). Attendre = migrer 50+ GB sous pression avec des clients actifs.

### Actions déjà réalisées (avril 2026)

- [x] Clé `OPENAI_API_KEY` supprimée de Heroku (v806) et révoquée côté OpenAI — migration vers Claude complète, aucun appel résiduel dans le code

---

## Plan d'implémentation — 3 tunnels d'onboarding

### Vue d'ensemble architecturale

Onboarding en mini-wizard **serveur-side** piloté par Turbo Drive (navigation page entière entre étapes), sans gem additionnelle. État de progression via `session[:onboarding]`. Après la dernière étape, l'utilisateur arrive sur son dashboard métier.

```
POST /users/inscription (Devise)
  └─> after_sign_up_path_for → /onboarding/profil
        └─> POST choisit "proprietaire" / "architecte" / "entrepreneur"
              ├─> /onboarding/proprietaire/bien
              │     └─> /onboarding/proprietaire/projet
              │           └─> dashboard_path
              ├─> /onboarding/architecte/profil-pro
              │     └─> dashboard_path
              └─> /onboarding/entrepreneur/invitation
                    └─> member_projects_path
```

---

### Migration à créer

**Fichier :** `db/migrate/TIMESTAMP_add_user_profile_to_users.rb`

Colonnes à ajouter :
- `user_profile:integer, default: 0` — enum `proprietaire(0) / architecte(1) / entrepreneur(2)`
- `onboarding_completed_at:datetime` — nil = onboarding non fait
- `nom_cabinet:string` — pour les architectes
- `num_bce:string` — pour les entrepreneurs/architectes (optionnel)
- Index sur `user_profile`
- **Backfill obligatoire** : `User.update_all(onboarding_completed_at: Time.current)` pour les anciens comptes

---

### Fichiers à créer / modifier

| Fichier | Action | Rôle |
|---------|--------|------|
| `db/migrate/TIMESTAMP_add_user_profile_to_users.rb` | Créer | Migration + backfill |
| `app/models/user.rb` | Modifier | Ajouter enum `user_profile` + `onboarding_done?` |
| `app/controllers/onboarding_controller.rb` | Créer | 9 actions (sélection + 2 par tunnel) |
| `app/controllers/application_controller.rb` | Modifier | `after_sign_up/in_path_for` → `onboarding_profile_selection_path` |
| `app/controllers/users/sessions_controller.rb` | Modifier | Idem (surcharge Devise) |
| `app/controllers/dashboard_controller.rb` | Modifier | `ensure_onboarding_done` before_action |
| `config/routes.rb` | Modifier | Bloc `namespace :onboarding` dans `scope "(:locale)"` |
| `app/views/layouts/onboarding.html.erb` | Créer | Layout épuré sans sidebar |
| `app/views/onboarding/profile_selection.html.erb` | Créer | 3 cartes cliquables |
| `app/views/onboarding/proprietaire_bien.html.erb` | Créer | Formulaire simplifié (rue + région uniquement) |
| `app/views/onboarding/proprietaire_projet.html.erb` | Créer | Nom chantier + type |
| `app/views/onboarding/architecte_profil.html.erb` | Créer | nom_cabinet + num_bce (optionnel) |
| `app/views/onboarding/entrepreneur_invitation.html.erb` | Créer | Token invitation + "passer" |
| `app/javascript/controllers/onboarding_profile_controller.js` | Créer | Animation sélection carte (facultatif) |

---

### Ordre d'implémentation (4 jours)

**Jour 1 — Socle**
1. Migration (colonnes + backfill + rollback safe)
2. Enum `user_profile` + `onboarding_done?` dans `User`
3. Routes `namespace :onboarding`
4. Layout `onboarding.html.erb`

**Jour 2 — Contrôleur + redirections**
5. `OnboardingController` (9 actions + strong params)
6. `after_sign_up/in_path_for` dans `ApplicationController` ET `Users::SessionsController`
7. `ensure_onboarding_done` dans `DashboardController`

**Jour 3 — Vues**
8. `profile_selection.html.erb` (étape 1 commune)
9. Vues tunnel Propriétaire (étapes 2 et 3)
10. Vue tunnel Architecte (étape 2)
11. Vue tunnel Entrepreneur (étape 2)

**Jour 4 — Intégration + tests manuels**
12. Factoriser la logique token invitation (`InvitationAcceptor` service)
13. Stimulus controller animation (facultatif)
14. Badge profil dans `shared/_sidebar.html.erb`
15. Parcours des 3 tunnels complets + reconnexion + anciens comptes

---

### Points d'attention critiques

**1. Double surcharge `after_sign_up_path_for`**
Définie dans `ApplicationController` ET `Users::SessionsController` — modifier les **deux** ou extraire en concern `OnboardingRedirection`.

**2. Locale dans les helpers de routes**
Les routes sont dans `scope "(:locale)"`. Utiliser `locale: I18n.locale` explicitement dans les redirections post-inscription si le locale n'est pas inféré automatiquement.

**3. Validations Property trop strictes**
`Property` valide des champs régionaux non collectés dans l'onboarding simplifié. Ajouter `attr_accessor :skip_onboarding_validation` sur `Property` et conditionner les validations régionales dessus.

**4. Anciens comptes sans `onboarding_completed_at`**
Le backfill dans la migration est **obligatoire** pour éviter de rediriger tous les utilisateurs existants vers l'onboarding au prochain déploiement.

**5. Abandon à l'étape 3 (propriétaire)**
Si l'utilisateur crée le bien mais abandonne avant le projet, il a une `Property` orpheline. À la reconnexion, `after_sign_in_path_for` doit inspecter `current_user.properties.none?` pour reprendre à la bonne étape.

**6. Token invitation entrepreneur déjà traité**
Factoriser la logique de `InvitationsController#accept` en service réutilisable — ne pas dupliquer le code.

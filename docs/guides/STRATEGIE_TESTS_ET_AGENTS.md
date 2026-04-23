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

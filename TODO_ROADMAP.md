# TODO — Ren0vate Roadmap

*Dernière mise à jour : 27 avril 2026*
*Synthèse des tâches restantes extraite de tous les MDs du projet.*

---

## Légende
- 🔴 Bloquant lancement / critique
- 🟠 Priorité haute (avant ou juste après lancement)
- 🟡 Priorité normale (< 3 mois post-lancement)
- 🔵 Roadmap V2 (fonctionnalités futures)
- ✅ Fait

---

## 1. 🔐 Sécurité & Authentification

| # | Tâche | Priorité | Source |
|---|-------|----------|--------|
| 1.1 | **2FA pour comptes admin et Expert/Platform** — via `devise-two-factor` ou OTP email | 🟡 | `ANALYSE_CYBERSECURITE.md §A07` |
| 1.2 | **Confirmation email `:confirmable` Devise** — réactiver + configurer SMTP correctement avant lancement | 🟠 | `EMAIL_SETUP_COMPLETE_GUIDE.md` |
| 1.3 | **SMTP définitif** — configurer SendGrid/Postmark sur Heroku et activer `:confirmable` (ne pas migrer sans `User.where(confirmed_at: nil).update_all(confirmed_at: Time.now)` pour les comptes existants) | 🟠 | `EMAIL_SETUP_COMPLETE_GUIDE.md`, `CLAUDE.md` |
| 1.4 | **`unsafe-eval` CSP** — surveiller Turbo 2.x qui supprime ce besoin, migrer dès dispo | 🟡 | `ANALYSE_CYBERSECURITE.md §5` |
| 1.5 | **Restreindre clé Mapbox par domaine** — console Mapbox → ajouter `https://ren0vate.be/*` | 🟡 | `ANALYSE_CYBERSECURITE.md §8` |
| 1.6 | **Ruby 3.3.9 → 3.3.11** — upgrade Heroku | 🟡 | `CLAUDE.md` |

---

## 2. 💳 Stripe / Paiements

| # | Tâche | Priorité | Source |
|---|-------|----------|--------|
| 2.1 | ✅ **Basculer en mode Live Stripe** — clés live injectées sur Heroku (v808) | ✅ | `STRIPE_INTEGRATION_GUIDE.md` |
| 2.2 | ✅ **Webhook production configuré** — URL `/webhooks/stripe`, 6 events, `STRIPE_WEBHOOK_SECRET` injecté | ✅ | `STRIPE_INTEGRATION_GUIDE.md` |
| 2.3 | ✅ **Flux complet testé** — Checkout Stripe fonctionnel, webhook `subscription.created` sauvé en DB, page success OK | ✅ | `STRIPE_INTEGRATION_GUIDE.md` |
| 2.4 | ✅ **Fix CSP `form-action`** — `checkout.stripe.com` autorisé (v815), Turbo désactivé sur form (v814) | ✅ | — |
| 2.5 | ✅ **Fix webhook Stripe API 2026-04-22.dahlia** — conversion objet → Hash, `current_period` dans items (v819) | ✅ | — |
| 2.6 | ✅ **Gate `property_limit`** — freemium=1 / individual=3 / portfolio=10 / enterprise=∞ (en place dans `properties_controller.rb`) | ✅ | — |
| 2.7 | ✅ **Gate `simulation_limit`** — freemium=1 / autres=∞ (en place dans `simulations_controller.rb`) | ✅ | — |
| 2.8 | **Stratégie early adopters** — 124 comptes existants (4 avec >1 propriété, 8 avec >1 simulation). Contacter avant d'appliquer les gates sur les données existantes. Option : freemium étendu jusqu'à fin 2026 + 20% de remise pour fidélisation | 🟠 | — |
| 2.9 | **Portail client Stripe** — permettre aux abonnés de gérer/annuler leur abonnement via `Stripe::BillingPortal::Session` | 🟠 | `STRIPE_INTEGRATION_GUIDE.md` |

---

## 3. ⚖️ RGPD & Légal

| # | Tâche | Priorité | Source |
|---|-------|----------|--------|
| 3.1 | **Transférer compte Anthropic vers ArchiTecht SRL** — email à privacy@anthropic.com ou créer nouveau compte + update `ANTHROPIC_API_KEY` Heroku | 🔴 | `ANALYSE_JURIDIQUE.md §5.1` |
| 3.2 | **DPA Anthropic** — automatique une fois le compte transféré vers ArchiTecht (Commercial Terms effectif 24/02/2025) | 🔴 | `ANALYSE_JURIDIQUE.md §5.1` |
| 3.3 | **Notice à l'upload AER** — informer l'utilisateur que le revenu imposable extrait sera utilisé dans les prompts IA | 🟠 | `ANALYSE_JURIDIQUE.md §5.2` |
| 3.4 | **Information RGPD dans ChantierVision** — avertir avant upload photo que les images sont envoyées à Anthropic USA | 🟠 | `ANALYSE_JURIDIQUE.md §5.2` |
| 3.5 | **Nommer un DPO** ou désigner une personne de contact RGPD et la déclarer à l'APD belge si requis | 🟠 | `ANALYSE_JURIDIQUE.md §5.1` |
| 3.6 | **Registre des activités de traitement** (art. 30 RGPD) — document interne obligatoire | 🟡 | `ANALYSE_JURIDIQUE.md §5.3` |
| 3.7 | **AIPD / DPIA** sur traitements AER + données fiscales (art. 35 RGPD) | 🟡 | `ANALYSE_JURIDIQUE.md §5.3` |
| 3.8 | **Politique suppression données inactives** — automatique après 2 ans sans connexion | 🟡 | `ANALYSE_JURIDIQUE.md §5.3` |
| 3.9 | **Médiation consommateur** — s'affilier à un organisme agréé ODR belge (ex. CPMA) | 🟡 | `ANALYSE_JURIDIQUE.md §5.3` |
| 3.10 | **Validation par un avocat RGPD** — avant lancement commercial officiel | 🟠 | `ANALYSE_JURIDIQUE.md §8` |

---

## 4. 🧪 Tests

| # | Tâche | Fichier cible | Priorité |
|---|-------|---------------|----------|
| 4.1 | **Webhooks Stripe** — `checkout.session.completed` upgrade tier, `payment_failed` downgrade, `subscription.created` | `test/controllers/webhooks_controller_test.rb` | 🟠 |
| 4.2 | **`FlandreEligibilityService`** — isolation éligible, PEB D → prime X, société exclue | `test/services/regions/flandre_eligibility_service_test.rb` | 🟠 |
| 4.3 | **`WallonieEligibilityService`** — revenus modestes → prime majorée | `test/services/regions/wallonie_eligibility_service_test.rb` | 🟠 |
| 4.4 | **`BruxellesEligibilityService`** — retourne `eligible: false` | `test/services/regions/bruxelles_eligibility_service_test.rb` | 🟠 |
| 4.5 | **`FactureOcrService`** — PDF → montant extrait correct, PDF illisible → nil sans crash | `test/services/facture_ocr_service_test.rb` | 🟠 |
| 4.6 | **Smoke tests tunnels Propriétaire/Architecte/Entrepreneur** — inscription → profil → dashboard | `test/system/onboarding_*_test.rb` | 🟠 |
| 4.7 | **Smoke tests simulations** — Flandre/Wallonie/Bruxelles wizard complet | `test/system/simulation_*_test.rb` | 🟡 |
| 4.8 | **Gates freemium** — `property_limit` et `simulation_limit` | `test/models/user_test.rb` | 🟠 |

---

## 5. 🎨 Design & Go-to-Market

| # | Page / Tâche | Fichier | Priorité |
|---|--------------|---------|----------|
| 5.1 | **Landing page** — hero fort, social proof, CTA above fold, tone belge rénovation | `app/views/pages/home.html.erb` | 🔴 |
| 5.2 | **Pricing page** — toggle mensuel/annuel, plan mis en avant, bullets iconifiés, FAQ | `app/views/pricing/index.html.erb` | 🔴 |
| 5.3 | **Page checkout/select** — sticky récap plan, réassurance Stripe, étapes claires | `app/views/pricing/select.html.erb` | 🔴 |
| 5.4 | **Tunnels d'onboarding ×3** — propriétaire / architecte / entrepreneur | `app/views/onboarding/` | 🔴 |
| 5.5 | **Dashboards ×3 variantes** — un par profil (ne pas refaire le générique avant) | `app/views/dashboard/` | 🟠 |
| 5.6 | **Vue entrepreneur mobile-first** — 860 lignes à coordonner avec tunnel Entrepreneur | `app/views/pro_views/show.html.erb` | 🟠 |
| 5.7 | **Dashboard IA** — col-4 biens + col-8 Expert IA (clic bien → charge chat) | `app/views/dashboard/index.html.erb` | 🟡 |
| 5.8 | **Micro-animations AOS.js** sur landing | `layouts/application.html.erb` | 🟡 |
| 5.9 | **Navbar glassmorphism au scroll** | `assets/stylesheets/layout/_navbar.scss` | 🟡 |

---

## 6. 📱 PWA / Mobile

| # | Tâche | Priorité |
|---|-------|----------|
| 6.1 | Transitions de page fluides (Turbo + CSS) | 🟡 |
| 6.2 | Splash screen iOS/Android (meta tags + SVG) | 🟡 |
| 6.3 | Pull-to-refresh natif | 🟡 |
| 6.4 | Swipe back gesture (Stimulus) | 🟡 |
| 6.5 | Pages offline enrichies (service worker cache strategy) | 🟡 |
| 6.6 | Mobile-first refactor vues principales (dashboard, projects/index) | 🟡 |

---

## 7. 🤖 IA — Optimisation & Coûts

| # | Tâche | Priorité |
|---|-------|----------|
| 7.1 | **Prompt caching Anthropic** — `cache_control: { type: "ephemeral" }` sur `ContextualBotService`, `PermisPredicatorService`, `ChantierVisionService` → économie 60-80% | 🟡 |
| 7.2 | **Optimisation `ContextualBotService`** — prompt système long, appelé fréquemment | 🟡 |

---

## 8. ✅ Roadmap V2 — Fonctionnalités livrées

Ces fonctionnalités sont documentées dans `STRATEGIE_EVOLUTION_REN0VATE.md`.

| # | Fonctionnalité | Description courte | Statut |
|---|----------------|--------------------|--------|
| 8.1 | **Estimateur Budget IA** | Estimation 30 sec basée sur historique chantiers | ✅ |
| 8.2 | **Détection Progression IA** | Analyse photos chantier → % avancement réel vs déclaré | ✅ |
| 8.3 | **Score Santé Projet /10** | KPIs budget + planning + comm + qualité + docs | ✅ |
| 8.4 | **Prédicteur Permis IA** | Besoin permis + délai + documents requis | ✅ |
| 8.5 | **Assistant Primes/Prêts IA** | Optimisation combinaisons travaux pour max primes | ✅ |
| 8.6 | **Benchmark Marché IA** | Comparaison devis vs marché (n projets similaires) | ✅ |
| 8.7 | **Comparateur Matériaux IA** | Isolants / châssis / chaudières / PV — prix, perf, ROI, primes | ✅ |
| 8.8 | **Écosystème 3-parties** | Invitation architecte + entrepreneur par le client, espace collaboratif partagé | ✅ |

---

## 9. 📧 Emails & Notifications

| # | Tâche | Priorité |
|---|-------|----------|
| 9.1 | **SMTP définitif Heroku** — SendGrid ou Postmark configuré + domaine `ren0vate.be` validé | 🔴 |
| 9.2 | **Réactiver `:confirmable` Devise** — après SMTP OK + confirmer comptes existants | 🔴 |
| 9.3 | **Tracking email ActionMailbox** — valider config Postmark inbound + sous-domaine `tracking.ren0vate.be` en production | 🟠 |

---

## Ordre de traitement recommandé

```
Avant 1er client payant :
  → 9.1 SMTP · 9.2 confirmable · ✅ Stripe Live (2.1-2.7) · 3.1-3.2 Anthropic DPA
  → 5.1-5.4 Design pages critiques · 1.2-1.3 Auth email · 2.8 Stratégie early adopters

Dans le mois :
  → 4.1-4.8 Tests · 2.4-2.6 Stripe gates · 3.3-3.5 RGPD
  → 5.5-5.6 Dashboards + Vue entrepreneur

Dans les 3 mois :
  → 1.1 2FA · 1.4-1.6 Infra · 7.1-7.2 Prompt caching
  → 6.x PWA · 3.6-3.9 RGPD avancé

V2 (selon traction) :
  → 8.x Features IA avancées
```

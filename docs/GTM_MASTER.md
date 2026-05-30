# GTM MASTER — Ren0vate
*Document de référence unique · Mis à jour le 30 mai 2026 (v2)*
*Remplace : TODO_ROADMAP.md · AGENTS-CONTEXT.md · sections roadmap de STRATEGIE_EVOLUTION_REN0VATE.md*

---

## Contexte rapide

**Situation au 30 mai 2026** : Le produit est largement au-delà de ce que les roadmaps prévoyaient — la quasi-totalité des features Q2–Q4 2026 a été livrée en avril–mai. 124 comptes existants, 0 abonnement payant actif. Infrastructure live (Heroku, Stripe, Cloudinary). Lancement commercial cible : **octobre 2026** après 4 mois de tests (juin → septembre).

---

## 1. CE QUI EST EN PLACE

### Produit

| Domaine | Statut | Notes |
|---------|--------|-------|
| Multi-propriétés + projets CRUD | ✅ | |
| Devis estimatif (43 travaux, 7 catégories) | ✅ | |
| Comparateur devis multi-entrepreneurs OCR | ✅ | Score composite, anomalie prix, confiance OCR |
| Upload factures + OCR extraction | ✅ | |
| Suivi chantier (5 phases, galerie photos, validation horodatée) | ✅ | |
| Collaboration 3-parties (ProjectMember, invitations, rôles) | ✅ | Architecte, entrepreneur, intermédiaire |
| Flux referral Pro → Client | ✅ | Token unique, `/?ref=TOKEN` |
| PV réception (tokens 3-parties, page signing, PDF) | ✅ | |
| Punch list réserves + annotations sur plans | ✅ | |
| Checklists d'inspection (4 templates, 43 items) | ✅ | |
| Timeline Gantt visuelle | ✅ | |
| Tracker permis d'urbanisme (stepper horodaté) | ✅ | |
| Expert IA chatbot 24/7 (ContextualBotService) | ✅ | Prompt caching activé |
| Agent Subsides (SubsidyBotService) | ✅ | Enrichissement terrain encodé |
| BudgetEstimatorService (rule-based, narrative IA) | ✅ | |
| ChantierVisionService (Claude Vision, analyse async) | ✅ | |
| PermisPredicatorService (30+ types, 3 régions) | ✅ | |
| Score santé projet /10 | ✅ | |
| Assistant primes/prêts IA | ✅ | |
| Comparateur matériaux IA | ✅ | |
| Assistant juridique v1 (garanties, checklist contrat) | ✅ | |
| BCE vérification (VIES API) | ✅ | Badge "Partenaire vérifié" |
| Upsell contextuel + frictions rétention | ✅ | #5 à #9 livrés |
| PWA (manifest, service worker, offline, install prompt) | ✅ | Lighthouse > 90 |
| Stripe Live (checkout, webhooks 6 events, subscriptions DB) | ✅ | TVA 21% inclusive |
| Gates freemium (property\_limit, simulation\_limit) | ✅ | |
| Email nurturing (N+14 / N+30 / N+60) | ✅ | |
| Blog admin (EasyMDE, SEO, catégories, slug) | ✅ | |
| Articles blog #1 et #2 en ligne | ✅ | 6 articles restants à produire (#3 à #8) |
| Notifications in-app (admin, segmentées) | ✅ | |
| Email de lancement aux 124 early adopters | ✅ | |
| Offre early adopter à durée limitée | ✅ | |
| ActionMailbox (tracking@ren0vate.be) | ✅ | Code complet — à activer en prod (task H5) |
| Trial 14j Pro | ✅ | |

### Pages & Design

| Page | Statut | Notes |
|------|--------|-------|
| Landing page (`home.html.erb`) | ✅ | 11/05/2026 — hero, social proof, AOS.js |
| Pricing page (toggle mensuel/annuel, plan highlighted) | ✅ | |
| Checkout/summary (sticky résumé, réassurance Stripe, étapes 1→2→3→4) | ✅ | |
| Tunnels onboarding ×4 | ✅ | Propriétaire / Architecte / Entrepreneur / Intermédiaire |
| Dashboard propriétaire (cockpit KPIs financiers, Expert IA) | ✅ | 11/05/2026 |
| Dashboard architecte, entrepreneur, intermédiaire | ✅ | 11/05/2026 |
| Vue entrepreneur mobile-first (`pro_views/show.html.erb`) | ✅ | |
| Navbar glassmorphism + AOS.js | ✅ | 27/04/2026 |

### Infrastructure & Sécurité

| Élément | Statut | Notes |
|---------|--------|-------|
| Sprint sécurité complet (rate limiting, CSP, chiffrement at-rest, audit log) | ✅ | 6 mai 2026 |
| 2FA admin (OTP email, cookie 30j) | ✅ | 18 mai 2026 |
| `:confirmable` Devise activé | ✅ | 18 mai 2026 — 120+ comptes confirmés automatiquement |
| SMTP prod (Resend, domaine `ren0vate.be`) | ✅ | |
| Tests (60 runs, 164 assertions, 0 failures) | ✅ | 4 mai 2026 |
| RGPD complet (DPIA, registre, DPA, CGU, CPMA, cookie consent) | ✅ | Légal 100% |
| Sentry, Plausible Analytics, UptimeRobot | ✅ | À configurer comptes externes (code déjà en prod) |
| Heroku-24, PostgreSQL, Solid Queue, Cloudinary, Stripe Live | ✅ | |
| Prompt caching Anthropic (~90% réduction coûts API) | ✅ | |

---

## 2. CE QUI RESTE À FAIRE

### 🟠 Acquisition — les 3 items qui bloquent le 100% marketing

| # | Tâche | Détail |
|---|-------|--------|
| A1 | **LinkedIn page entreprise + posts de lancement** | Indispensable B2B — séquence connexion studios architecture, posts hebdo |
| A2 | **Vidéo démo Loom (3–4 min)** | Indispensable SaaS B2C — parcours complet propriétaire, à mettre sur landing et en cold outreach |
| A3 | **Programme Ambassadors** | 20 architectes → accès Pro gratuit en échange de 3 recommandations/mois — test démarré semaine du 19/05 |

### 🟡 Contenu & croissance (juin–octobre 2026)

| # | Tâche | Détail |
|---|-------|--------|
| C1 | **Articles SEO #3 à #8** | 6 restants — rythme 1–2/semaine — voir `docs/articles_blog/` |
| C2 | **Groupe Facebook** | "Rénovation Belgique avec Ren0vate" — 80 000+ membres potentiels |
| C3 | **Partenariats prescripteurs** | ⚠️ Au point mort — définir approche directe : notaires/agences, fournisseurs énergie, banques |
| C4 | **Premiers témoignages clients** | Vidéo 60s × 3 — après premières conversions bêta |
| C5 | **ActionMailbox prod** | DNS : `MX tracking.ren0vate.be → inbound.postmarkapp.com` + variables env Heroku |

### 🔵 Post-lancement (août–décembre 2026)

| # | Tâche | Détail |
|---|-------|--------|
| P1 | **Migration Cloudinary → Scaleway** | Compte ouvert fin août, trial 750 GB gratuit sept/oct/nov — code prêt |
| P2 | **Ruby 3.3.9 → 3.3.11** | Upgrade Heroku — non bloquant |
| P3 | **Restreindre clé Mapbox** | Console Mapbox → domaine `ren0vate.be` |
| P4 | **Notifications push ActionCable** | Activer Solid Cable quand ~500 users actifs avec collaboration quotidienne |
| P5 | **Export UBL/Billit** | Facturation électronique B2B — concernera les premiers clients entreprises |
| P6 | **Google Ads / Meta Ads** | Budget 2 000€/mois — activer octobre 2026 |

### 🔵 Roadmap V2 (selon traction — Q4 2026+)

| Fonctionnalité | Prérequis |
|----------------|-----------|
| IA #7 Benchmark Marché (médiane régionale) | 300–500 projets avec devis/factures réelles |
| ML training BudgetEstimator (RandomForest) | 5 000+ projets réels |
| Marketplace entrepreneurs certifiés | 500+ entrepreneurs actifs |
| Notifications push ActionCable | ~500 users actifs avec collaboration quotidienne |
| Export UBL/Billit (facturation électronique B2B) | Obligation depuis 01/01/2026 |
| Batibouw 2027 — stand démonstration | Février/mars 2027 |
| Agents autonomes juridiques (analyseur contrats, valideur devis, générateur PV autonome) | Post 1 000 users |

---

## 3. CALENDRIER GTM

```
Juin 2026 — Activation bêta + contenu
  → A1     : LinkedIn page entreprise + premiers posts
  → A2     : Vidéo démo Loom tournée et publiée
  → A3     : Programme Ambassadors — 5 premiers architectes activés
  → C1     : Articles #3 + #4 publiés
  → C5     : ActionMailbox prod activé (DNS + Heroku vars)
  Objectif fin juin : 200 Freemium, 10 payants

Juillet 2026 — Montée en puissance contenu
  → C1     : Articles #5 + #6 publiés
  → C2     : Groupe Facebook lancé
  → C4     : Premiers témoignages vidéo (après retours bêta)
  → C3     : Plan d'action partenariats défini + 1er contact
  Objectif fin juillet : 350 Freemium, 30 payants, 1 500€ MRR

Août 2026 — Consolidation
  → C1     : Articles #7 + #8 publiés (blog complet)
  → P1     : Compte Scaleway ouvert (trial 750 GB)
  Objectif fin août : 500 Freemium, 75 payants, 3 000€ MRR

Septembre 2026 — Accélération pré-lancement
  → P6     : Google Ads activés (budget 2 000€/mois)
  → Programme parrainage activé
  → 1 accord co-marketing signé
  → Webinaire architectes/entrepreneurs
  Objectif fin sept. : 1 000 Freemium, 150 payants, 8 000€ MRR

Octobre 2026 — Lancement commercial
  → Communication officielle (Trends, L'Echo, De Tijd)
  → Code promo launch2026 (-30% premier mois)
  → P1     : Migration Cloudinary → Scaleway finalisée
  Objectif : 2 000 Freemium, 350 payants, 20 000€ MRR
```

---

## 4. PRICING EN PRODUCTION

```
B2C
  Starter      0€/mois   — 1 bien, 1 simulation
  Propriétaire 39€/mois  — 1–3 biens, illimité
  Investisseur 89€/mois  — 4–10 biens, analytics avancé
  Premium      149€/mois — multi + pro mixte

B2B
  Pro          99€/mois  — architectes, entrepreneurs (trial 14j)
  Entreprise   299€/mois — syndics, promoteurs

Tous les prix TTC, TVA 21% inclusive (Stripe tax_behavior: inclusive)
Annuel : -20% (Individual 375€/an, Investisseur 855€/an)
```

---

## 5. KPIs CIBLES

### Acquisition

| Métrique | Fin juin | Fin sept. | Lancement oct. |
|----------|----------|-----------|----------------|
| Freemium/mois | 200 | 1 000 | 2 000 |
| Payants cumulés | 30 | 150 | 350 |
| MRR | 1 500€ | 8 000€ | 20 000€ |
| Trafic organique/mois | 2 000 | 6 000 | 15 000 |

### Rétention (alarmes)

| Métrique | Cible | Alarme |
|----------|-------|--------|
| Churn mensuel | < 4% | > 6% |
| NPS | > 45 | < 30 |
| DAU/MAU | > 35% | < 20% |
| Sessions/mois/user | > 6 | < 3 |

---

## 6. AGENTS IA — ARCHITECTURE ACTUELLE

*Décisions actées (mai 2026)*

**Deux agents embarqués dans Ren0vate (en prod) :**
- **Agent Rénovation** (ContextualBotService) : conseils projets, matériaux, coûts, pros — nourri par expertise terrain encodée
- **Agent Subsides** (SubsidyBotService) : primes 3 régions, 15 ans d'expertise terrain — se connecte à Agent Rénovation

**Hub agents autonomes (~/agents-hub/) :**
- Architecture décidée, implémentation post-traction (Q4 2026)
- Budget estimé : ~$35–55/mois avec prompt caching
- Brief matin à 7h (acquisition + rétention)
- HQ dashboard : 4ème app après les agents

**Hors scope actuellement :**
- Primes-Services : déprioritisé (marché sait que primes se terminent)
- Agents autonomes juridiques (Analyseur contrats, Gestionnaire garanties, Valideur devis, Générateur PV) : roadmap V2 post 1 000 users

---

## 7. MESSAGES COMMERCIAUX CLÉS

```
Tagline : "Rénover coûte plus cher, prend plus de temps, et les aides diminuent.
           Ren0vate est la réponse."

Pour propriétaires :
  "39€/mois pour récupérer 40 heures. Calculez votre ROI en 30 secondes."

Pour investisseurs :
  "Gérez 10 biens comme si vous en aviez 1."

Pour pros (architectes/entrepreneurs) :
  "Vos clients organisés. Votre chantier traçable. Votre temps recentré."

Argument primes :
  "Ne pas utiliser Ren0vate, c'est laisser de l'argent sur la table."
```

---

## 8. FICHIERS STRATÉGIQUES — STATUT

| Fichier | Statut |
|---------|--------|
| `GTM_MASTER.md` (ce fichier) | ✅ Source de vérité pilotage GTM |
| `docs/GTM_CHECKLIST.md` | ✅ Checklist état produit/légal/infra/marketing — la plus à jour (18/05) |
| `docs/CHECKLIST_LANCEMENT.md` | ✅ Opérations jour J (Sentry, UptimeRobot, RGPD APD) |
| `docs/PITCH_DECK_PROS.md` | ✅ Deck commercial pros |
| `docs/PRESENTATION_COMMERCIALE_PROS.md` | ✅ Présentation commerciale pros |
| `Documents_strategiques/STRATEGIE_COMMERCIALISATION_MARKETING.md` | 🟡 Conserver — détail canaux, messages, partenariats, KPIs |
| `Documents_strategiques/STRATEGIE_EVOLUTION_REN0VATE.md` | 🟡 Conserver — encyclopédie produit, specs IA, roadmap V2 |
| `Documents_strategiques/STRIPE_INTEGRATION_GUIDE.md` | ✅ Référence technique Stripe |
| `Documents_strategiques/insights_terrain_mai2026.md` | 🟡 À alimenter au fil des appels clients |
| `docs/AGENTS_IA.md` | ✅ Référence des deux agents en prod (Agent Rénovation + Agent Primes) |
| `docs/guides/STRATEGIE_DESIGN_GTM.md` | 🔴 Archiver — entièrement réalisé (✅ 11/05/2026) |
| `docs/guides/STRATEGIE_TESTS_ET_AGENTS.md` | 🔴 Archiver — entièrement réalisé (✅ mai 2026) |
| `TODO_ROADMAP.md` | 🔴 Archiver — remplacé par ce fichier |
| `AGENTS-CONTEXT.md` | 🔴 Archiver — synthétisé dans §6 ci-dessus |

---

*Révision suivante : fin juin 2026*

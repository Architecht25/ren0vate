# Checklist de lancement — Ren0vate, 1ère semaine d'octobre 2026

*Rédigé le 19/07/2026. Audit du code réel + confrontation aux docs stratégiques existants — aucune modification de code effectuée dans le cadre de ce document.*

**Mise à jour du 19/08/2026** — les items marqués 🆕 ci-dessous ont été traités depuis l'audit initial, à l'occasion d'une session de comparaison entre le simulateur Wallonie et un article du Vif (30/07/2026, "Un soutien à la rénovation plus lisible, mais toujours myope") qui détaille pour la première fois le barème officiel complet du nouveau régime, ainsi que d'un diagnostic de l'erreur R14 observée en production. Contrairement au reste du document, ces mises à jour reflètent des modifications de code réellement effectuées (et déployées en production, Heroku v936/v940) — pas seulement un audit.

**Mise à jour du 22/08/2026** — croisement avec la source officielle wallonie.be (décision gouvernementale du 16/07/2026, qui détaille le barème et les plafonds réels — la comparaison à l'article du Vif du 19/08 s'appuyait sur une reformulation de presse, pas le texte source) : plafond copropriété (parties communes) précisé, correction de l'éligibilité des propriétaires-bailleurs/syndics au Rénoprêt. Démarrage de la construction du process complet (préparation de la demande → suivi → clôture), en réutilisant le phasage existant de `primes_hub` (Estimation → Préparation technique → Formulaires → Suivi) plutôt qu'un nouveau parcours — voir item dédié en section 1. Correction également du test d'intégration onboarding (comportement intentionnel, pas une régression — voir section 2).

---

## 0. Note de cadrage — lire avant tout le reste

**Sur la pause.** Ren0vate a été mis en pause le 16/07/2026 (adoption nulle + flou réglementaire primes — voir feuille de route de reprise du 16/07). Cette checklist part du principe que la demande de Robin de préparer un lancement en octobre constitue la décision de sortir de la pause, avec un modèle révisé : audience chaude Primes-Services (~15 000 contacts), funnel simulation-puis-découverte, abonnement SaaS pur (pas de commission). Ce n'est pas la relance B2C froide que les docs de mai décrivaient — plusieurs items de ces docs sont donc **hors scope** pour octobre (section 8).

**Sur la fiabilité des docs existants.** Trois documents (`docs/GTM_MASTER.md`, `docs/GTM_CHECKLIST.md`, `Documents_strategiques/STRATEGIE_COMMERCIALISATION_MARKETING.md`) affichent un statut "100% ✅" sur Légal, Infra, Support, Analytics daté du 18–30 mai 2026. Deux choses ont changé depuis et ne sont **pas répercutées** dans ces scores :
1. Le commit `ff4e7ce` (chore: désactiver tous les jobs récurrents — fermeture progressive) a coupé quasiment tous les jobs automatiques en juin. Seul `IntelligenceReportJob` (veille) a été réactivé le 17/07. Tout ce qui dépend d'un job récurrent — nurturing, onboarding email, alertes dormance, rappels d'invitation, alertes factures, SLA, purge RGPD — est donc **actuellement à l'arrêt en production**, quel que soit le "✅" affiché dans les docs de mai.
2. La réforme primes Wallonie/Bruxelles a bougé (analyse du 16/07) et une partie du code a déjà été adaptée début juillet (commits `7a04bf3` à `80a7e87`), mais ce travail est postérieur aux docs de mai et n'y figure pas.

**Méthode de cette checklist.** Chaque item ci-dessous a été vérifié dans le code réel (fichier:ligne cité) plutôt que déduit du statut déclaré dans les docs. Là où je n'ai pas pu vérifier (comptes externes Heroku/Sentry/Stripe Dashboard/assureur), c'est indiqué explicitement comme "non vérifiable depuis le repo".

---

## 1. Moteurs de calcul primes/prêts (3 régions)

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| Wallonie — nouveau régime prêt bonifié (calcul) | ✅ **Réel et fonctionnel**, pas une façade. `WallonieRegimeRouter` (`app/services/regions/wallonie/wallonie_regime_router.rb`), `PretReduction::EligibilityService` (critère PEB bloquant), `TrancheService` (seuils 28 900/41 100/67 100/122 800€, taux 50/40/15/0%), `CalculatorService` (calcul réel sur revenu utilisateur). 🆕 **Mis à jour le 19/08/2026** suite à comparaison avec l'article du Vif (30/07/2026) qui publie pour la première fois le barème officiel détaillé : (1) plafond d'emprunt désormais différencié selon le bien — 75 000€ maison unifamiliale / 60 000€ appartement-studio — au lieu d'un plafond fixe à 75 000€ quel que soit le type de bien (gap non détecté par l'audit du 19/07) ; (2) ajout de la majoration écomatériaux (+5 points de réduction du solde) ; (3) ajout de la modélisation du taux d'intérêt du prêt (0% jusqu'à 67 100€ de revenu ajusté, taux réduit non quantifié au-delà, fixé par la SWCS). Non implémenté : majoration de 60 000€/logement pour les parties communes d'un immeuble à logements multiples — la donnée "nombre de logements de l'immeuble" n'existe pas sur `Property`. Déployé en production (Heroku v936). Vue `_pret_reduction_card.html.erb` affiche un avertissement "enveloppe non fixée avant conclave rentrée 2026" — honnête. Tests régions : 43 runs/85 assertions, 0 failure (mis à jour). | — | — | — |
| 🔴 **Bug — date de bascule du régime wallon incorrecte** | `WallonieRegimeRouter::REFORME_DATE = Date.new(2026, 7, 17)` (déjà passée) au lieu du **01/10/2026** légal. Conséquence : **toute simulation Wallonie créée aujourd'hui reçoit déjà le nouveau régime "prêt bonifié"**, alors qu'il n'entre en vigueur que le 1er octobre — les propriétaires qui rénovent avant octobre voient un dispositif qui ne leur est pas encore applicable. | 🔴 Bloquant | Trivial (1 ligne) | Aucune |
| Wallonie — ancien régime (primes cash, simulations antérieures) | ✅ Conservé intentionnellement dans `WallonieCategoryService` (seuils R1-R5 originaux) pour les simulations déjà créées avant bascule — comportement voulu, documenté dans `simulations_controller.rb:1026-1027`. | — | — | — |
| Wallonie — validation métier du critère PEB (label G) | 🆕 **✅ Résolu le 19/08/2026.** L'article du Vif (30/07/2026, tableau "Quels prêts et quelles aides pour quels ménages ?") confirme explicitement les labels éligibles : **E, F et G** — et exclut le label **D**, qui n'ouvre désormais droit à aucune aide à la rénovation. Le code contenait en réalité deux erreurs symétriques (`LABELS_ELIGIBLES = %w[D E F]` : D accepté à tort, G rejeté à tort), corrigées dans `pret_reduction/eligibility_service.rb`. Déployé en production. | — | — | — |
| 🆕 **Wallonie — plafond copropriété et éligibilité bailleurs/syndics (22/08/2026)** | Croisement avec wallonie.be (décision gouvernementale du 16/07/2026) : plafond des parties communes de copropriété précisé (600.000€ si <20 lots, 750.000€ si ≥20 lots — nouveau champ `nombre_lots_copropriete` sur `Property`, branché sur `profil_demandeur == "syndic_copropriété"`). Correction d'un vrai bug : `EligibilityService` exigeait une résidence principale dans les 24 mois pour tous les profils, alors que le texte officiel ouvre explicitement le Rénoprêt aux propriétaires-bailleurs, associations et syndics — ces profils ne sont plus exclus à tort. | — | — | — |
| 🆕 **Wallonie — suivi du dossier de prêt (préparation → dépôt → clôture) (22/08/2026)** | Nouveau modèle `PretWallonieDossier` (statuts : préparation, dossier déposé, en instruction, accepté/refusé, travaux en cours, clôturé) — auto-déclaré par l'utilisateur, pas d'intégration API SWCS/AppiCrédit (aucune n'existe publiquement). Réutilise le `Document` model existant pour les pièces justificatives (audit, devis, attestation de conformité, factures, PEB après travaux) plutôt que de dupliquer un système de suivi de documents. Intégré au phasage existant de `primes_hub` (nouvelle carte "Wallonie — Prêt bonifié", sans toucher aux cartes Formulaires/Suivi historiques qui restent valables pour les primes cash des autres régions). Construit en assumant que le process SWCS documenté aujourd'hui (Écopack/Rénopack) reste largement valable pour le nouveau régime — **à ajuster une fois l'arrêté d'exécution publié** (pièces exigées, délais exacts non garantis). | 🟡 Normal (v1 fonctionnelle, à affiner) | — | Arrêté d'exécution officiel (non publié à ce jour) |
| Bruxelles — moteur | ✅ Stub honnête et volontaire : vérifie seulement le code postal bruxellois, retourne toujours "aucune prime générale ouverte" (Renolution supprimé), sans montant ni catégorie. Cohérent avec la réalité (Plan social climat pas encore chiffré/validé, rien avant 2027 pour les propriétaires occupants classiques). **Ne rien construire de plus avant publication des modalités.** | — | — | Attente gouvernement bruxellois (hors main de Robin) |
| Flandre — restrictions cat. 1-2 + retrait prime PEB | ✅ Effectivement appliqué au runtime (`flandre_post_login_calculator_service.rb:463-464` filtre par `eligible_categories`, pas juste de la donnée décorative). "Déjà à jour" confirmé. | — | — | — |
| Risque réglementaire résiduel Wallonie | Réforme validée en 1ère lecture seulement ; montant/enveloppe fixés au conclave budgétaire de rentrée (~sept. 2026) ; régime transitoire fév. 2025 contesté au Conseil d'État (risque de rétropédalage ~500M€, arrêté définitif attendu 1er semestre 2027). Le code est prêt à encaisser un ajustement de paramètres (seuils/taux/plafond isolés dans `TrancheService`/`CalculatorService`) mais **pas** un retour en arrière total. | 🟡 Normal (à surveiller) | — | Conclave budgétaire wallon (~sept. 2026) |

---

## 2. Tests utilisateurs (entrepreneurs + architectes)

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| Tunnels onboarding ×4 (Propriétaire/Architecte/Entrepreneur/Intermédiaire) | ✅ Vues réelles et distinctes dans `app/views/onboarding/`. | — | — | — |
| 🆕 **✅ Tranché et corrigé le 22/08/2026** — Test d'intégration onboarding en échec | Confirmé : comportement intentionnel, pas une régression. `OnboardingController#create_proprietaire_projet` redirige volontairement vers `project_path(tab: :preparation)` (bonne UX — éviter un dashboard générique vide juste après la création du 1er projet) plutôt que vers `/dashboard`. Le test attendait l'ancien comportement ; mis à jour pour refléter le comportement actuel. | — | — | — |
| Retours terrain pros (architectes/entrepreneurs) | ⚠️ `Documents_strategiques/insights_terrain_mai2026.md` est un **template vide** — zéro insight réel consigné, malgré la mention dans les docs de mai d'un "Programme Ambassadors — test démarré semaine du 19/05 avec 1 cabinet d'architecture". Aucune preuve dans le repo qu'un test réel avec des pros ait eu lieu ou produit un retour exploitable. | 🔴 Bloquant | Élevé (nécessite du temps humain, pas du code) | Robin doit solliciter des pros pilotes réels avant octobre |
| Vue entrepreneur mobile-first (`pro_views/show.html.erb`) | Non re-vérifiée dans cet audit (dernière confirmation : docs de mai). À revalider visuellement avant octobre, l'écart entre doc et code s'est déjà avéré significatif ailleurs. | 🟡 Normal | Faible (vérification) | — |
| Couverture de tests globale | 89 runs/208 assertions (vs. "60 runs/164 assertions" documenté en mai — la base de tests a grossi, cohérent avec le travail de juillet sur les primes). | — | — | — |

---

## 3. Migration/onboarding audience Primes-Services (15 000 contacts)

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| 🔴 Infra d'envoi de masse | **Inexistante.** Aucun ESP marketing (Mailchimp/Brevo/Sendgrid marketing) dans le Gemfile. Le seul canal email est Resend en usage transactionnel un-à-un (`ActionMailer`/`deliver_later`), non conçu pour un envoi ponctuel à 15 000 destinataires externes (risque de réputation/délivrabilité, pas de gestion de désabonnement de masse). L'email "de lancement" envoyé en mai concernait les 124 comptes **déjà inscrits sur Ren0vate**, pas la liste Primes-Services — ne pas confondre les deux campagnes. | 🔴 Bloquant | Élevé (choix d'un ESP + import + design campagne) | Décision d'outil (section 9) |
| 🔴 Base légale RGPD pour la réutilisation de la liste Primes-Services | **Absente.** `RGPD_REGISTRE_ACTIVITES.md` ne couvre que les traitements internes à Ren0vate ; aucune ligne "prospection commerciale base tierce Primes-Services", aucune base légale documentée (intérêt légitime vs. consentement déjà obtenu par l'entité Primes-Services), aucune traçabilité de provenance/date de collecte. Envoyer un email à 15 000 personnes sans base légale documentée expose à un risque APD réel dès le premier envoi — canal chaud à ne pas griller par un premier contact non conforme. | 🔴 Bloquant | Moyen (rédaction + décision juridique) | Avocat RGPD (déjà identifié comme tâche dans TODO_ROADMAP §3.10) |
| Funnel "simulation d'abord, découverte ensuite" — partie pré-connexion | ✅ Existe pour Wallonie/Flandre : routes publiques sans authentification (`pages_controller.rb`, `config/routes.rb:573-582`). Bruxelles correctement désactivée avec message honnête. | — | — | — |
| 🟠 Funnel — rupture entre simulation et inscription | **Aucune persistance de session.** Le résultat de simulation pré-connexion n'est sauvegardé nulle part (pas de `session[:simulation]`, rien dans `registrations_controller.rb`). Le seul pont est un lien texte statique "Se connecter / créer un compte" — l'utilisateur qui s'inscrit après avoir simulé doit **tout refaire**. C'est directement le funnel que Robin décrit dans sa demande ("estime d'abord... puis découvre") — actuellement cassé à l'étape critique. | 🟠 Important | Moyen (persister en session + réafficher post-inscription) | — |
| Code promo / parrainage / réduction partenaire | **Aucun système de coupon Stripe dans le code** (`grep coupon/promo_code` : zéro résultat), malgré `docs/GTM_MASTER.md` qui annonce "Code promo launch2026 (-30% premier mois)" pour octobre et `STRATEGIE_COMMERCIALISATION_MARKETING.md` qui détaille parrainage/partenaire/association. Ces mécaniques sont purement documentaires. | 🟠 Important si une offre de lancement est voulue | Moyen (Stripe Coupons/Promotion Codes API) | Décision : y a-t-il une offre de lancement pour la liste Primes-Services ? (section 9) |
| Referral Pro → Client existant | ✅ Fonctionnel (`ProjectMember(pending)` auto-créé, token `/?ref=TOKEN`) — mécanisme différent, déjà en place, réutilisable si des architectes/entrepreneurs de l'ancienne base sont invités en tant que pros. | — | — | — |

---

## 4. Facturation Stripe (abonnement mensuel)

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| Mode Live, clé via ENV | ✅ `config/initializers/stripe.rb:14` — `ENV['STRIPE_SECRET_KEY']`, fallback dummy dev uniquement. | — | — | — |
| Webhooks (checkout, subscription, invoice) | ✅ `WebhooksController#stripe` gère les 6 events documentés, signature vérifiée via `Stripe::Webhook.construct_event`. | — | — | — |
| 🆕 **✅ Corrigé le 19/08/2026** — `Subscription#sync_with_stripe!` lisait une API Stripe obsolète | `app/models/subscription.rb:64-69` lisait `stripe_subscription.current_period_start/end` à la racine, alors que l'API `2026-04-22.dahlia` a déplacé ces champs dans `items.data[0].current_period`. Aligné sur le pattern déjà utilisé dans les webhooks (`JSON.parse` + `dig` avec fallback `nil`). Déployé en production (Heroku v936). | — | — | — |
| Gates freemium (property_limit / simulation_limit) | ✅ Cohérents avec le pricing documenté (`app/models/user.rb:261-299`). | — | — | — |
| Modèle 100% abonnement, zéro commission sur prime | ✅ Confirmé — aucune logique de commission trouvée dans le code Stripe/pricing. | — | — | — |
| Pricing mensuel affiché | ✅ `PricingController#pricing_tiers_data` — 39/89/149/99/299€/mois, TVA 21% inclusive, cohérent avec la doc. | — | — | — |
| 🔴 Jobs récurrents liés à la conversion/rétention payante — désactivés | `NurturingSequenceJob` (relance freemium J+14/30/60), `OnboardingSequenceJob` (J+1/3/7), `DormantProjectAlertJob`, `PendingInvitationReminderJob`, `FactureAlertJob`, `PebConformiteAlertJob` sont tous commentés dans `config/recurring.yml` depuis la fermeture de juin. Sans eux : pas de conversion freemium→payant automatisée, pas d'onboarding email, pas d'alerte de perte de prime pour les payants. **À réactiver sélectivement avant le lancement**, pas en bloc — certains logiques/seuils datent d'avant la pause et méritent une relecture rapide avant réactivation. | 🔴 Bloquant | Faible par job (décommenter + relire la logique) | Décision : lesquels réactiver, et avec quel contenu (voir Bruxelles PEB, cohérence avec réforme primes) |
| 🆕 **✅ Diagnostiqué et corrigé le 19/08/2026** — Memory quota Heroku (R14) | Confirmé en production le 19/08 : dyno Basic (512 Mo) constamment au-dessus du quota (110-144%, `Error R14` en continu toutes les ~20s). Cause principale identifiée : aucun réglage d'allocateur mémoire (malloc glibc par défaut, fragmentation élevée sur un process Ruby multi-threadé avec Solid Queue in-process). Fix appliqué : buildpack jemalloc + `MALLOC_ARENA_MAX=2` + `JEMALLOC_ENABLED=true` (config vars, gratuit, réversible). Confirmé : plus aucune occurrence de R14 sur la fenêtre d'observation post-fix, dyno resté en Basic (aucun changement de plan payant). | 🟡 Normal (à surveiller) | — | Si le pic d'envoi aux 15 000 contacts en octobre fait remonter du R14 malgré le fix, upgrade `Standard-2x` (~25$/mois) en filet de sécurité |

---

## 5. Juridique / RGPD

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| Pages légales (CGU, privacy, mentions légales, DPA) | ✅ Réelles et substantielles (602/470/133/284 lignes), aucun placeholder trouvé. | — | — | — |
| Chiffrement at-rest IBAN / numéro national | ✅ Présent (`encrypts ..., support_unencrypted_data: true`). ⚠️ Le défaut dans le code (`config/application.rb:42`) est `true` (permissif) tant que la variable Heroku `AR_ENCRYPTION_SUPPORT_UNENCRYPTED=false` n'est pas positionnée — c'était fait suite au sprint sécurité de mai selon mémoire, mais **non re-vérifiable depuis le repo**, à confirmer sur Heroku. | 🟠 Important | Trivial si déjà fait (vérif Heroku) | Accès Heroku |
| Notices RGPD upload AER + photos ChantierVision | ✅ **Existent réellement dans le code**, contrairement à ce qu'une roadmap antérieure indiquait comme "à faire" — `documents/new.html.erb:67-81` et modal de consentement `_vision_analysis.html.erb:38-70` (mention transfert USA, SCC, non-conservation par Anthropic). Les docs stratégiques ne sont simplement pas à jour sur ce point précis. | — | — | — |
| DPIA | ⚠️ `RGPD_DPIA.md` existe et est structuré (137 lignes, 4 risques) mais **s'auto-qualifie explicitement d'"ébauche initiale — à compléter avant 250 utilisateurs actifs"** — contredit le "Légal 100% ✅" affiché dans `GTM_MASTER.md`. | 🟠 Important | Moyen | Avocat RGPD |
| Registre des traitements | ✅ Existe et est détaillé pour les traitements internes (`RGPD_REGISTRE_ACTIVITES.md`, 7 traitements) — mais voir le trou spécifique "liste Primes-Services" en section 3. | — | — | — |
| 🔴 Transfert compte Anthropic → ArchiTecht SRL | Email envoyé le 11 mai, relance le 30 mai 2026 — **aucune confirmation écrite retrouvée dans le repo**, et la pause de juillet a probablement interrompu tout suivi actif. Tant que ce transfert n'est pas confirmé, le DPA Anthropic n'est pas formellement effectif pour ArchiTecht SRL. | 🔴 Bloquant avant 1er client payant | Faible (relance email) | Réponse d'Anthropic |
| Déclaration DPO/contact RGPD à l'APD belge | Toujours non fait (case non cochée dans `docs/CHECKLIST_LANCEMENT.md`, aucune preuve de complétion). | 🟠 Important | Faible (formulaire en ligne) | — |
| Inscription médiation consommateur (CPMA/mediationconsommateur.be, ~150€/an) | Toujours non fait — **obligation légale avant d'accepter des consommateurs B2C**, donc bloquant si le plan inclut des particuliers (ce qui est le cas : Propriétaire/Investisseur/Premium). | 🔴 Bloquant B2C | Faible (inscription + paiement) | — |
| Assurances RC Pro + Cyber | Non vérifiable depuis le repo (démarche externe). Case ouverte dans `docs/CHECKLIST_LANCEMENT.md`, pas de trace de progression depuis. | 🔴 Bloquant | Moyen (courtier) | Contact courtier |
| Purge RGPD données inactives (art. 5.1.e) | `DataRetentionJob` existe mais est **désactivé** depuis juin — aucune anonymisation en cours actuellement. Risque de conformité pur, indépendant du lancement mais à corriger en même temps que la réactivation des jobs (section 4). | 🟠 Important | Faible (réactiver + vérifier logique) | — |

---

## 6. Communication / emailing base de contacts

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| Contenu blog | 2 articles réellement publiés (`Article.count == 2`), ~7 fichiers de brouillon non publiés dans `Documents_strategiques/articles_blog/`. Pipeline de production à l'arrêt depuis la pause. | 🟡 Normal | Moyen (relecture + publication) | — |
| Agent Veille + Agent Marketing (contenu automatisé) | ✅ Réactivés le 17/07/2026 (`IntelligenceReportJob` → `MarketingDraftJob` enchaîné, `config/recurring.yml:12-16`). Peut alimenter la production de contenu pour la communication de rentrée si Robin valide les livrables. | — | — | Validation humaine (règle absolue du pipeline — jamais de publication automatique) |
| Séquence email post-inscription / nurturing | Code présent (`OnboardingSequenceJob`, `NurturingSequenceJob`) mais **désactivé** — cf. section 4. Nécessaire dès que la base Primes-Services commence à s'inscrire. | 🔴 Bloquant | Faible (réactivation) | — |
| Campagne de lancement dédiée à la liste Primes-Services | À concevoir entièrement — ce n'est pas la même campagne que l'email aux 124 early adopters (mai 2026), qui visait les comptes Ren0vate existants. Contenu, séquencement, et CTA vers le funnel simulation restent à écrire. | 🔴 Bloquant | Élevé | Infra d'envoi de masse (section 3), base légale RGPD (section 3) |
| Cohérence des messages commerciaux existants | Les messages/objections/promesses par segment dans `STRATEGIE_COMMERCIALISATION_MARKETING.md` restent globalement réutilisables (ROI, "39€/mois pour récupérer 40h", argumentaire primes) — pas à jeter, juste à recontextualiser pour une audience qui connaît déjà Robin/Primes-Services plutôt qu'une audience froide. | 🟡 Normal | Faible (adaptation de ton) | — |

---

## 7. Support et monitoring post-lancement

| Item | Statut réel constaté | Priorité | Effort | Dépendances |
|---|---|---|---|---|
| Sentry | Code prêt (`Gemfile` gem `sentry-ruby`/`sentry-rails`, `config/initializers/sentry.rb`, `set_sentry_user`). **`SENTRY_DSN` sur Heroku non vérifiable depuis le repo** — à confirmer. | 🟠 Important | Trivial si déjà fait | Accès Heroku |
| UptimeRobot | Endpoint `/up` existe. Compte externe non vérifiable depuis le repo. | 🟡 Normal | Trivial | Compte externe |
| Plausible Analytics | Non re-vérifié dans cet audit (dernière confirmation en mai) — à re-contrôler que le script est toujours injecté en prod. | 🟡 Normal | Trivial (vérification) | — |
| 🔴 `SlaAlertJob` (SLA support) — désactivé | Le SLA "Pro/Entreprise" annoncé (4h/99,9%) documenté comme "défini ✅" n'est **plus surveillé opérationnellement** puisque le job d'alerte est coupé depuis juin. Ne pas communiquer un SLA qu'on ne surveille pas. | 🔴 Bloquant si SLA annoncé publiquement | Faible (réactivation) | — |
| `PebConformiteAlertJob` (alertes PEB F/G Bruxelles) | Désactivé — feature réglementaire bruxelloise à l'arrêt, à réactiver en cohérence avec la reprise du moteur Bruxelles. | 🟡 Normal | Faible | — |
| Migration Cloudinary → Scaleway | **Aucune trace dans le code** malgré la mention "code prêt à activer" dans les docs de mai — zéro fichier, zéro config Scaleway trouvé. Cloudinary reste le seul storage câblé. Cette tâche n'est pas "prête", elle est à faire entièrement si on veut la lancer avant/pendant octobre. | 🟡 Normal (post-lancement, non bloquant) | Élevé (à refaire, pas juste "activer") | — |
| Ruby 3.3.9 → 3.3.11 | Toujours en 3.3.9 (`.ruby-version`, `Gemfile`). Non bloquant, cohérent avec la doc. | 🟡 Normal | Faible | — |

---

## 8. Obsolète / hors scope pour octobre 2026 (à retirer ou reporter)

Ces items visaient une acquisition B2C froide et ne correspondent plus à la stratégie décrite par Robin (audience chaude Primes-Services, pas d'acquisition froide) :

- **Google Ads / Meta Ads** (`docs/GTM_MASTER.md` P6, budget 2 000€/mois activé en octobre) — acquisition payante froide, sans objet pour un lancement sur liste chaude. À reporter à une phase ultérieure si la traction Primes-Services est validée.
- **Groupe Facebook "Rénovation Belgique"**, forums/communautés (Immoweb, Reddit) — acquisition organique froide à volume, hors scope immédiat.
- **Partenariats Tier 1/2/3** (banques, fournisseurs d'énergie, notaires, fédérations professionnelles, fournisseurs de matériaux) — motions de vente B2B longues (mois), aucun lien avec une semaine de lancement en octobre. À conserver comme piste moyen terme, pas comme item de checklist de lancement.
- **Programme Ambassadors** (20 architectes, accès Pro gratuit contre recommandations) — jamais implémenté en code (aucun mécanisme de tracking/récompense trouvé), et conçu pour une logique d'acquisition B2B différente. À trancher explicitement (garder l'idée pour plus tard vs. l'abandonner) plutôt que de le laisser traîner comme "à faire".
- **Campagne TV/Radio, Batibouw 2027, expansion Flandre NL** (Phase 3 du GTM) — déjà correctement classés "2027+" dans les docs existants, rien à changer.
- **Vidéo démo Loom** — probablement toujours utile (crédibilité produit), mais n'est plus un item "bloquant acquisition" puisque l'acquisition ne repose plus sur du trafic froid. À reclasser en nice-to-have.
- **LinkedIn page entreprise** — utile pour la crédibilité B2B pros, mais pas un bloquant pour contacter une liste email existante. Nice-to-have.

---

## 9. Questions ouvertes / décisions à prendre par Robin

1. **Confirmation de sortie de pause.** Cette checklist part du principe que la demande d'aujourd'hui vaut décision de reprendre le chantier GTM d'octobre. Si ce n'est qu'une réflexion préparatoire, le traitement des jobs recurring et des campagnes email doit rester en "veille", pas en exécution.
2. **Outil d'envoi de masse pour les 15 000 contacts.** Aucune infra n'existe. Il faut choisir un ESP (Brevo, Sendgrid Marketing, Mailchimp...) et décider s'il s'intègre à Ren0vate/ArchiTecht ou reste un outil externe piloté manuellement pour ce seul envoi.
3. **Base légale RGPD pour réutiliser la liste Primes-Services.** À trancher avec l'avocat RGPD déjà identifié (`TODO_ROADMAP.md §3.10`) avant tout envoi — intérêt légitime documenté ? Consentement historique de Primes-Services suffisant pour promouvoir un produit d'une autre entité juridique (ArchiTecht SRL) ?
4. **Offre de lancement.** Le GTM d'octobre prévoyait un code promo -30% — vaut-il la peine de le construire (Stripe Promotion Codes) pour cette audience chaude, ou l'argument primes/temps suffit-il sans réduction de prix ?
5. ~~**PEB label G en Wallonie.**~~ 🆕 **Résolu le 19/08/2026** — confirmé par l'article du Vif (30/07/2026) : labels E/F/G éligibles, D exclu. Code corrigé et déployé (voir section 1).
6. **Quels jobs récurrents réactiver, et dans quel ordre ?** Réactiver les 8 jobs désactivés en bloc n'est probablement pas souhaitable (certains contenus/seuils datent d'avant la pause). Robin doit prioriser : nurturing/onboarding avant l'envoi à la liste, ou après les premiers retours ?
7. **SLA support annoncé (4h/99,9%) mais non surveillé actuellement** — le maintenir tel quel, l'assouplir publiquement jusqu'à réactivation de `SlaAlertJob`, ou ne pas encore le communiquer ?
8. **Programme Ambassadors et partenariats Tier 1-3** — abandonner définitivement (cohérent avec le pivot vers l'audience chaude) ou mettre en pause explicite pour une reprise après la traction initiale ?
9. **Assurances RC Pro + Cyber et inscription médiation consommateur** — statut d'avancement réel non vérifiable depuis le repo ; à confirmer directement avec Robin plutôt que supposé "en cours".
10. **Fenêtre réelle du 1er octobre.** La feuille de route de reprise du 16/07 dit explicitement que Robin est ok de prendre plus de temps sur la Phase 3 (moteurs) plutôt que de viser le 1er octobre à tout prix — mais le brief d'aujourd'hui vise textuellement "la première semaine d'octobre 2026". Ces deux signaux se contredisent légèrement : à clarifier si le 1er octobre reste une cible dure ou indicative.

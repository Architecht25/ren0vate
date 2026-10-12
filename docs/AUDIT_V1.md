# Audit du dépôt V1 — en vue de ren0vate V2

Date : 2026-10-12. Périmètre : code sous `app/`, `config/`, `db/`, `test/`, `.github/workflows/`, à la racine du dépôt principal (branche `master`, commit `6855216c`).

Lecture de référence : `ren0vate-v2-cahier-des-charges.md` (racine du dépôt principal — absent de ce worktree, lu depuis `/home/obinduarc/code/Architecht25/ren0vate/`).

---

## 1. Résumé

La V1 est une application **centrée sur la simulation de primes régionales** (Wallonie/Flandre/Bruxelles) à laquelle un module de **suivi de chantier mono-propriétaire** a été ajouté par itérations successives (voir `project_history_pivots.md` en mémoire : subsides → reconfiguration réglementaire → gestion de chantier). La V2 inverse cet ordre : le chantier multi-intervenants avec base documentaire commune devient l'objet central, les primes deviennent un module parmi d'autres.

Conséquence structurante pour l'audit : il n'existe **aucune** des briques d'infrastructure que le cahier des charges rend non négociables pour la V2 — autorisation par policy, visibilité par document, versionnage de document, journal d'audit générique, règles de primes versionnées en données, stockage objet UE, embeddings/pgvector. Ce sont des **lots de fondation**, pas des ajustements. En revanche, le **savoir métier** (barèmes de primes, services IA, OCR, conformité) est substantiel et réutilisable à l'intérieur de nouvelles interfaces.

| Catégorie | Verdict |
|---|---|
| Moteur de primes (barèmes, règles d'éligibilité) | **Logique métier réutilisable, structure à refaire** (passage de code à données versionnées) |
| Intégrations (Claude, Cloudinary, Stripe, VIES, Sentry, rack-attack) | **Réutilisables en l'état ou avec adaptation mineure** |
| Agents IA (bots OCR/Claude) | **Logique de prompt/extraction réutilisable**, couche d'abstraction à construire autour |
| Pages publiques (marketing, pricing, blog, SEO) | **Réutilisables, portage de vue uniquement** |
| Modèle de données chantier/documents/collaboration | **Point de départ correct, lacunes structurelles sur versionnage/visibilité/lots** |
| Autorisations | **Inexistant en tant que couche** — à construire entièrement (Pundit) |
| Tests | **Quasi nul** (46 fichiers, couvre une fraction des 67 tables et ~70 contrôleurs) |

---

## 2. Ce qui est réutilisable tel quel ou presque

### 2.1 Moteur de primes — logique métier, pas la structure

`app/services/regions/{wallonie,flandre,bruxelles}/` contient la connaissance réglementaire la plus précieuse du dépôt : critères d'éligibilité région par région (âge du logement, statut d'occupant, revenus, PEB, type de travaux), calcul des tranches (`household_income_calculator.rb`, `tranche_service.rb`), routage de régime (`wallonie_regime_router.rb` pour le nouveau prêt à taux 0% vs primes cash), primes communales (`regions/primes_communales/*`), volet prêt (`pret_reduction/*`).

- **Réutilisable** : les seuils, les cas d'exclusion (ex. non-résidentiel Flandre corrigé le 03/09/2026, `project_flandre_non_residentiel_exclusion_fix.md`), les formules de calcul — c'est un capital métier accumulé sur plusieurs réformes (`project_reforme_primes_2026.md`).
- **À refaire** : tout est **codé en dur dans des classes Ruby** (`Regions::BaseService` + sous-classes), avec des `Rails.logger.info` de debug en production et des accès directs à `@user`/`property`/`project` passés en paramètres plutôt qu'un objet de contexte propre. Le cahier des charges V2 exige des `SubsidyRule` **versionnées et datées en base**, pas en code — une réforme ne doit plus déclencher un déploiement. C'est une réécriture de la couche de règles, en conservant les valeurs et la logique de décision comme spécification.
- Le modèle `Subsidies::Simulation` distingue déjà *mode simulation* (`Simulation`) vs *mode dossier* (`Request`/`RequestProgress`), ce qui correspond à la distinction `SubsidyCase` demandée au §9 du cahier des charges — **le découpage conceptuel est bon, la persistance est à refondre** (pas de `SubsidyRule`, pas de suite de tests de référence par région — seuls `test/services/regions/*` existent et couvrent une fraction des cas).
- `app/services/subsidies/peb_politique_regionale.rb`, `peb_rate_impact_estimator_service.rb`, `budget_estimator_service.rb`, `product_comparator_service.rb` : logique de calcul autonome, pas de dépendance structurelle lourde, portage direct possible.

### 2.2 Intégrations tierces

- **Claude/Anthropic** (`app/services/bots/claude_chat_client.rb` + les N services `*_claude_service.rb`) : migré vers le SDK officiel le 10/09/2026, gère déjà le cache d'historique de conversation, le timeout, les erreurs typées (`Anthropic::Errors::APITimeoutError`/`APIError`), et applique une **minimisation RGPD par tranches de montants** (`amount_bracket`) avant envoi à l'API — ce patron est directement réutilisable comme brique basse de la future couche unique `Ai::Client` demandée au §8. Il manque : journalisation structurée (`AiRun`), choix de modèle par fonction, budget/rate-limit par projet, sortie validée par schéma JSON — tout cela est à construire autour, mais le **client HTTP et sa gestion d'erreur n'ont pas besoin d'être réécrits**.
- **Cloudinary** (stockage fichiers) : fonctionnel, mais c'est l'inverse du choix V2 (Scaleway S3-compatible, UE, URLs signées courtes). Migration de stockage nécessaire — voir §4.
- **Stripe** : intégration mûre et documentée (CLAUDE.md § Stripe), webhooks fonctionnels, CSP ajustée, gestion de l'API 2026-04-22. Le modèle `User::Subscription` et les webhooks sont réutilisables quasi tels quels pour la facturation V2 (formules à ajuster, §13 cahier des charges).
- **VIES/BCE** (`projects/bce_verification_service.rb` + job async) : service simple, gratuit, sans clé — réutilisable sans changement pour vérifier les entrepreneurs.
- **Sentry** : branché proprement (PII retirée avant envoi, bruit filtré) — modèle direct pour le monitoring V2.
- **rack-attack** : middleware actif, réutilisable.
- **Geocoder, http_accept_language** : utilitaires transverses réutilisables sans changement.

### 2.3 OCR et extraction de documents

`app/services/ocr/*` (Tesseract + MiniMagick) couvre déjà : factures, devis, PEB, AER, RIB, attestations, bordereaux châssis, labels énergétiques. `app/jobs/{peb,audit_energ,devis_contenu,email_document}_extraction_job.rb` confirment un **pattern déjà établi et correct** : bascule en job asynchrone (Solid Queue) après deux incidents H12 Heroku en traitement synchrone (`project_audit_energ_claude_extraction.md`, `project_peb_scan_async_job.md`). Ce pattern — extraction lourde toujours en job, jamais en requête HTTP — **doit être repris tel quel** dans l'ingestion intelligente V2 (§8.1 du cahier des charges), qui est structurellement le même besoin (OCR + classification + extraction à l'upload) appliqué à un type de document plus large.

Point de vigilance repéré dans le code existant : la validation magic-bytes (`Document#file_magic_bytes_validation`) est désactivée (`return`) dès que le service de stockage est Cloudinary, faute de range request fiable — **à corriger dans la migration de stockage** plutôt qu'à reproduire.

### 2.4 Pages publiques et SEO

`app/controllers/site/*` (pages marketing, blog, pricing, sitemap, robots, PWA, health) — contenu et logique indépendants du modèle de données chantier, **portables sans réécriture** vers la V2 (adaptation de layout seulement). Le module `business_intelligence/*` (veille réglementaire, scraping, rapports — `app/services/business_intelligence/`) est un sous-système autonome, séparable, à ne pas bloquer par le reste de la migration.

### 2.5 CI

`.github/workflows/ci.yml` : Brakeman + Rubocop + tests (Postgres de service, Chrome headless pour les system tests) — **directement réutilisable**, c'est une fondation saine à garder sur la branche `v2`.

---

## 3. Ce qui doit être refait

### 3.1 Autorisations — absence totale de couche policy

Il n'y a **ni Pundit ni CanCanCan** dans le Gemfile. Les droits sont dispersés : des méthodes ad hoc sur `User` (`professional_guest?`, `architect_access?`, `entrepreneur_access?`), des `before_action` par contrôleur, et des scopes `where(user: current_user)` copiés-collés dans chaque contrôleur (le fix IDOR du 11/09/2026 sur `Property.all` non scopé dans une vue `edit.html.erb` dupliquée — `project_idor_property_select_fix.md` — illustre directement le risque : **ce pattern n'est pas détectable par la structure du code, seulement à la revue**). Le cahier des charges V2 exige une matrice rôle × action × visibilité testée exhaustivement (§3, §14) — c'est une réécriture complète, non un portage.

`ProjectMember` (rôles `owner/entrepreneur/architect/intermediary`, statuts `pending/active`, token d'invitation à expiration) est le **meilleur point de départ existant** pour `ProjectParticipant` : la mécanique d'invitation (token, expiration à 7 jours, `accept!`) est saine et réutilisable. Il lui manque la dimension clé du cahier des charges : le **périmètre de lots** (§3 : « un intervenant est invité par chantier, avec un rôle et un périmètre de lots ») — `ProjectMember` n'a aucune notion de lot, car `Lot` n'existe pas en V1.

### 3.2 Modèle `Document` — monolithe sans versionnage ni visibilité

`Document` (538 lignes) centralise un type d'énumération énorme (40+ `type_document`), une pièce jointe unique (`has_one_attached :file`, pas de versions), un statut `pending/approved/rejected` **sans historique ni commentaire ancré**, et neuf `belongs_to` optionnels différents (`property`, `request`, `project`, `simulation`, `lease`...) qui expriment en dur ce que le cahier des charges veut résoudre via `project_id` systématique + `lot_id` + `phase_id`. Il n'y a :
- Aucune notion de **version** : un nouveau fichier remplace l'ancien, perte de valeur probante (le cahier des charges exige empreinte SHA-256 + jamais d'écrasement, §4 et §6).
- Aucune **visibilité** (`private/lot/all/custom`) — tout document lié à un projet est visible par tout `ProjectMember` actif sans granularité.
- Aucun **commentaire ancré** ni **avis structuré** (`DocumentReview`) — seul un champ `notes` texte libre, utilisé en plus comme conteneur de résultat OCR (`has_ocr_content?` parse `notes` par recherche de sous-chaîne — fragile).

Le pattern de classification par type (`DocumentPhase`, `DocumentPhase.find_phase_for_document_type`, `document_phase_calculator_service.rb`) est une bonne idée à conserver **conceptuellement** (association type de document ↔ phase), mais câblée aujourd'hui sur la liste figée de `Property` (rénovation mono-propriétaire), pas sur des `Lot`/`Phase` dynamiques par chantier comme l'exige le §4.

### 3.3 Modèle `Project` — pas de notion de lot, financier en champs épars

`Project` (361 lignes) mélange : identité du chantier, champs figés pour un seul architecte et un seul entrepreneur principal (`architecte_nom`, `contractor_devis_montant`...), listes JSON sérialisées pour les corps de métier (`corps_metiers` en JSON texte, pas une table), et une logique financière calculée à la volée en Ruby (`total_devis_montant`, `architecte_factures_total`...) plutôt que des tables `Quote`/`Invoice`/`BudgetLine` normalisées comme l'exige le §4. Le multi-intervenant (`ProjectMember`) a été ajouté par-dessus ce socle mono-architecte/mono-entrepreneur — **cohabitation de deux modèles de collaboration dans le même objet**, à trancher en V2 (un seul modèle, celui multi-intervenants avec lots).

Positif à conserver : la validation de défense en profondeur `property_belongs_to_user` (indépendante du scoping des vues) est une bonne pratique à généraliser, pas à abandonner.

### 3.4 Finances — pas de structure `Quote`/`Invoice`/`BudgetLine`

`Facture` (modèle unique couvrant devis **et** factures via `type_facture`), pas de `QuoteLine` par poste, pas d'`Amendment` tracé, pas de `PaymentSchedule`. `Quotes::Calculator` et `Devis::Quote`/`QuoteItem` existent mais sont **un système de devis en doublon partiel** du système OCR de factures (`app/models/devis/quote.rb` vs `app/models/documents/facture.rb` type `devis`) — à auditer en détail en Lot 0 pour choisir lequel sert de base, ou fusionner. C'est tout le module C du cahier des charges (§5.C) à construire sur des fondations neuves.

### 3.5 Stockage de fichiers — Cloudinary, pas d'objet UE S3-compatible

Le cahier des charges exige Active Storage sur Scaleway (UE, S3-compatible, URLs signées courtes, jamais d'URL publique permanente). `config/storage.yml` n'a que `cloudinary` (production) et `Disk` (dev/test) — aucun service S3 configuré, même en commentaire d'exemple AWS (pas Scaleway). C'est une **migration de service de stockage complète**, avec migration de données (voir §5 risques).

### 3.6 Front-end — Bootstrap/SassC, pas Tailwind

Stack CSS actuelle : Bootstrap 5 + SassC-rails, JS en Stimulus (déjà présent, bon point) mais organisé par domaine métier V1 (`controllers/wallonie`, `/flandre`, `/bruxelles`, `/subsidies`...). Le cahier des charges demande Tailwind — **portage de design system complet**, pas une bascule de classes CSS mécanique vu le volume de vues (~35 modules selon le sweep mobile de septembre). Un travail de design à part, pas un simple remplacement de framework.

### 3.7 Recherche sémantique — absente

Pas de `pgvector`, pas d'embedding stocké où que ce soit. L'assistant conversationnel sur dossier (§8.7, RAG filtré par droits) est **à construire de zéro**, y compris la dépendance PostgreSQL (`pgvector` extension) côté infra Heroku.

### 3.8 Journal d'audit — existe seulement pour l'admin

`Admin::AdminAuditLog` couvre exclusivement les actions d'impersonation/modification admin (6 actions listées en dur). Le §6 du cahier des charges demande un journal **append-only générique** sur toute validation, avenant, paiement, changement de droits, accès à un document sensible — structure différente (table polymorphe `AuditEvent` avant/après), à construire, en conservant éventuellement `AdminAuditLog` comme cas spécifique ou en le fusionnant dedans.

### 3.9 Tests — couverture quasi nulle

46 fichiers de test pour 67 tables et ~70 contrôleurs. Le pattern `ActionDispatch::IntegrationTest` léger (`test/integration/simulation_smoke_test.rb`) est correct et à **réutiliser comme gabarit** (fixtures explicites, `Devise::Test::IntegrationHelpers`, `skip_onboarding_validation: true`), mais la couverture réelle est marginale : deux bugs `AbstractController::ActionNotFound` silencieux au boot ont été trouvés en production en septembre faute de tests systématiques. Le §14 du cahier des charges (« aucun lot terminé sans tests verts ») ne peut pas s'appuyer sur l'existant — c'est reconstruire la discipline de test en même temps que le code, pas juste porter les 46 fichiers.

---

## 4. Dette technique repérée (hors écarts de cahier des charges)

- **Duplication Quote/Facture** pour les devis (§3.4) — à trancher avant toute migration de données.
- **Désactivation silencieuse de la validation magic-bytes** sur Cloudinary (§2.3) — risque de sécurité (upload de fichier dont le contenu ne correspond pas au type déclaré) à ne pas reproduire sur Scaleway.
- **`notes` comme conteneur de résultat OCR parsé par regex** sur `Document` (§3.2) — fragile, à remplacer par des colonnes structurées dans `DocumentVersion`.
- **JSON sérialisé en colonne texte** (`corps_metiers`, `architecte_specialites`, `entrepreneur_principal_certifications`, `garanties_travaux`) au lieu de tables relationnelles — empêche toute requête structurée (ex. « quels entrepreneurs ont telle certification sur tous les chantiers »), à corriger par un vrai modèle `ProjectParticipant`/lot en V2.
- **Deux modèles d'analyse chantier qui se chevauchent** : `Project::ChantierAnalyse` et `Project::ChantierAnalysis` (orthographe FR/EN différente) coexistent dans `app/models/project/` — à clarifier/fusionner en Lot 0, sous peine de porter une confusion existante dans la V2.
- **Logging de debug verbeux en production** dans les validations de modèle (`Document#file_size_limit_debug`, loggé à chaque sauvegarde) — à nettoyer, pas à porter.
- **Pas de Pundit/CanCanCan** (§3.1) — déjà couvert, mentionné ici car c'est la dette la plus coûteuse à porter si elle ne l'est pas corrigée avant d'écrire le reste du code V2.
- **`config.assets.compile = true` en production** (connu, non bloquant selon CLAUDE.md) — non pertinent pour V2 si Propshaft est conservé, à vérifier une fois la stack figée.
- **Confirmable Devise désactivé** malgré colonnes présentes — décision à reconfirmer explicitement pour la V2 (comptes migrés doivent-ils être confirmés d'office ?).

---

## 5. Risques de migration des données V1 → V2

1. **Changement de grain de l'autorisation** : en V1, un document appartient à un `project_id` et est visible par tout membre actif ; en V2, chaque document doit porter une **visibilité** et un **lot**. Les ~N documents existants n'ont **aucune donnée de lot** (le concept n'existe pas en V1) — tout document migré devra recevoir un lot par défaut (`"non classé"` ou dérivé de `type_document` via la table `DocumentPhase` existante, qui donne un signal exploitable) et une visibilité par défaut à définir explicitement (proposition prudente : `all` pour ne rien cacher par erreur, puis resserrement manuel) — **décision produit à valider**, voir `docs/QUESTIONS_OUVERTES.md`.
2. **Versionnage rétroactif impossible** : les documents V1 n'ont qu'un seul fichier, pas d'historique de versions. La migration crée mécaniquement **une `DocumentVersion` unique par `Document`** — c'est correct comme point de départ mais il faut décider si l'empreinte SHA-256 est calculée rétroactivement à la migration (téléchargement + hash de chaque fichier Cloudinary) ou seulement pour les nouveaux dépôts V2.
3. **Changement de service de stockage (Cloudinary → Scaleway)** : migration de fichiers avec risque de corruption/perte, et incompatibilité du `resource_type` Cloudinary (`raw` vs `image`, résolu dynamiquement) avec un stockage S3-compatible plus simple. À faire par script rejouable testé (exigence explicite du cahier des charges, règle 4), avec vérification de l'intégrité (comparaison de hash avant/après transfert) avant toute suppression côté Cloudinary.
4. **`Project` mono-architecte/mono-entrepreneur vs multi-intervenants par lot** : les champs figés (`architecte_nom`, `contractor_devis_montant`...) doivent être rejoués comme des `ProjectParticipant`/`Quote` initiaux à la migration — logique de transformation non triviale, notamment pour les montants déjà payés/facturés qu'il faut répartir sans double-compter (cf. `total_devis_vs_factures_difference` actuellement calculé à la volée, à matérialiser).
5. **Règles de primes codées en dur → `SubsidyRule` versionnées** : il n'existe aujourd'hui aucune trace de "quelle règle était active à quelle date" au-delà des commentaires de commit et des dates mentionnées dans `CLAUDE.md`/mémoire. Reconstituer l'historique de versions de règles pour les simulations déjà enregistrées est **optionnel et risqué** (effort élevé, valeur incertaine) — proposition prudente : ne pas rejouer l'historique, matérialiser uniquement la **règle active au jour de la migration** comme version 1, et conserver les simulations V1 déjà calculées en lecture seule (archive), sans tenter de les recalculer avec le nouveau moteur. À valider.
6. **Compte unique multi-chantiers, multi-rôles** : en V1, `professional_type` est un champ **global sur `User`** (un utilisateur est "architecte" ou "entrepreneur" pour tout le système) ; le cahier des charges V2 (§3) demande un rôle **par chantier** via `ProjectParticipant`/`Membership`, un même compte pouvant être propriétaire d'un chantier et architecte invité sur un autre. `ProjectMember` existe déjà en V1 et porte un rôle par projet — il faut vérifier au cas par cas que `professional_type` (global) et le rôle porté par chaque `ProjectMember` ne se contredisent pas pour les comptes pro existants avant de les migrer vers le modèle V2 sans ce champ global.
7. **Comptes bêta** : la purge de ~50 comptes bêta sans retour (prévue mi-septembre, voir mémoire `project_purge_comptes_beta_sept2026.md`) — vérifier son état réel avant de lancer un script de migration sur l'ensemble de la base pour ne pas migrer des comptes qui devaient être supprimés.
8. **Abonnements Stripe actifs** : 108 comptes actifs dont 1 abonnement payant annuel (souscrit 3 septembre 2026, mémoire `project_launch_checklist...`/Stripe) — toute migration de modèle de facturation doit préserver cet abonnement en cours sans le casser (webhooks, `current_period_start/end` sur `items.data[0]`), et la règle CLAUDE.md « ne pas forcer les gates sur les données existantes avant communication » s'applique directement à la bascule V2.
9. **Confirmable Devise** : si la V2 réactive ce module (plausible, la V1 ne l'a jamais activé), les comptes existants migrés doivent être confirmés d'office au moment de la migration, sans quoi ils seront bloqués à la prochaine connexion — point de vigilance explicite déjà noté dans CLAUDE.md V1, à ne pas perdre en V2.

---

## 6. Ce que l'audit ne tranche pas (volontairement)

Conformément à la consigne « pas de dépendance ni de choix structurant non prévu sans signalement », les décisions suivantes sont **proposées** dans `docs/PLAN_V2.md` §Décisions techniques mais pas prises** ici : Rails 8 vs version actuelle 8.1.4 (déjà au-delà de « dernière version stable » demandée, à confirmer), Pundit vs alternative, Sidekiq vs Solid Queue (le cahier des charges autorise les deux), portée exacte de la coexistence V1/V2 pendant la transition (lecture seule V1 ou arrêt total avant bascule).

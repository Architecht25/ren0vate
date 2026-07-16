# Feuille de route — Reprise Ren0vate

*Rédigé : 16 juillet 2026*

---

## Principe directeur

Ren0vate est actuellement **en pause** (adoption utilisateur nulle + flou réglementaire primes). Cette feuille de route prépare la reprise, elle ne la déclenche pas — aucune de ces phases ne démarre sans décision explicite de Robin.

**⚠️ Séquencement révisé le 16/07/2026 — décision de Robin.**

Robin penche pour l'instant vers une vente/licence du **moteur réglementaire** à un acquéreur institutionnel (banque, opérateur Rénopack/Rénoprêt) plutôt qu'une relance B2C — mais **ce choix (Thèse A relance B2C vs Thèse B vente du moteur) reste explicitement ouvert et sera tranché après la Phase 3**, pas avant. L'action concrète immédiate ne dépend pas de ce choix : mettre à jour les 3 moteurs primes est utile dans les deux cas.

**Nouveau séquencement :**

1. **Phase 3 — Refonte des 3 moteurs primes/prêts/calculateurs** — avec tout le matériel disponible (2 articles L'Echo, réforme Flandre mars 2026, exploration du code existant). **Fenêtre cible : d'ici fin août/septembre 2026**, sans urgence artificielle — Robin est ok de prendre le temps nécessaire pour bien faire plutôt que de viser l'échéance du 1er octobre à tout prix.
2. **Décision Thèse A vs Thèse B** — une fois la Phase 3 terminée, pas avant
3. **Phase 1 — Simplification documentaire** — ensuite
4. **Phase 2 — Simplification gestion de chantier** — ensuite
5. **Préparation vente 2027** — fil rouge transverse, pertinent seulement si Thèse B est retenue

**Pourquoi ce changement :** un teaser envoyé à une banque en prétendant avoir "le moteur prêt pour la réforme" alors qu'aucune des 3 régions ne reflète encore les nouvelles règles ne survivrait pas 48h de due diligence. Se mettre à jour d'abord, démarcher ensuite.

---

## Phase 1 — Simplifier la gestion documentaire

### État actuel du code

- Un seul modèle `Document` (`app/models/document.rb`) avec ~35 valeurs de `type_document`, imbriqué sous `properties`/`projects`/`requests`/`simulations`/`leases` (`config/routes.rb:151,238,264,499,542`)
- **L'utilisateur doit toujours choisir le `type_document` avant l'upload** (`presence: true` validé sur `Document`) — aucun point d'entrée "dépôt en vrac"
- Infra IA déjà solide et sous-exploitée : `DocumentsController#create` dispatch automatiquement vers des services Claude (`CLAUDE_TYPES = facture, devis, bordereau_chassis`) ou OCR classiques (`OCR_TYPES = aer, rib, certificat_peb_avant/apres, rapport_audit_energetique, attestation_conformite, certificat_label`) — mais uniquement pour **extraire les données**, pas pour **deviner le type lui-même**
- Fragmentation : upload spécialisé dispersé sur `factures_controller#upload_facture`, `pv_receptions_controller`, `pv_visites_controller`, `pro_views_controller#upload_facture_pro/upload_photo_pro/upload_document_pro`, `request_progresses_controller#upload_document` — en plus du `DocumentsController` générique
- **Décision architecturale déjà validée (v922, juin 2026)** : `/properties/:id/documents` reste une consultation read-only pure, **jamais d'upload à cet endroit**. Tout upload de chantier reste contextuel aux onglets `/projects/:id` (Préparation/Suivi/Réception).

### ⚠️ Point de vigilance sur "upload à l'entrée"

L'idée d'un upload centralisé peut sembler contredire la décision ci-dessus. Interprétation recommandée : **pas** un dépôt sur la fiche du bien, mais une **zone de dépôt batch dans l'onglet Préparation d'un projet** — l'utilisateur dépose plusieurs fichiers sans présélectionner le type, et le système étend la classification déjà utilisée par `FactureClaudeService`/`DevisClaudeService` pour **deviner** `type_document` (et la phase suggérée via `DocumentPhase.find_phase_for_document_type`) avant de router chaque fichier. Ça respecte le workflow guidé par phase existant tout en supprimant la friction "je dois savoir ranger avant de déposer".

### Recommandations

1. Prototyper la drop-zone batch avec auto-classification dans l'onglet Préparation — extension de l'infra Claude existante, pas une refonte
2. Consolider les 5 endpoints d'upload spécialisés vers un composant unique réutilisé (réduit la dette technique — pertinent pour la Phase vente)

---

## Phase 2 — Simplifier les actions de gestion de chantier

### État actuel du code

- `Project` : `statut` par défaut `preparation`, `PHASES_CHANTIER` figées (`preparation, demolition, installation, finitions, reception`), avancement dans un JSON `phases_avancement` + agrégat `avancement_global_pct`
- `projects_controller.rb` expose une **vingtaine d'actions membres distinctes** : `gantt`, `edit_budget`, `edit_professionals`, `fin_chantier`, `scan_peb_apres`, `scan_audit_energ`, `reception_chantier`, `scan_attestation_conformite`, `garanties`, `check_contrat`, `carnet_entretien`, `roi_calculator`, `analyze_photos`, `vision_status`, `score_sante`, `validate_phase`, `compare_devis`, `upload_pv_externe`... — richesse fonctionnelle réelle, mais parcours utilisateur fragmenté en de nombreux écrans isolés
- `ProjectMember` (`ROLES = owner, entrepreneur, architect, intermediary`) + `ProjectPermissions` : droits déjà granulaires (`can_upload_quote?`, `can_validate_step?`, `can_manage_permis?`, `full_financial_access?`...) — pas un problème de modèle, un problème d'exposition UI

### Recommandations

1. **Audit UX avec un pro pilote** (architecte ou entrepreneur actif) avant de toucher au code — même méthode que l'analyse Permis & Plans de mai 2026 : lister ce qui est réellement utilisé vs ce qui ajoute de la charge cognitive
2. Candidats probables à fusionner ou masquer par défaut : `analyze_photos` / `vision_status` / `score_sante` semblent viser un même objectif ("état de santé visuel du chantier") — à vérifier avant de fusionner
3. Aucune refonte de modèle nécessaire : `PHASES_CHANTIER` et `phases_avancement` sont une base saine, le travail est côté parcours/UI

---

## Phase 3 — Intégrer la réalité primes/aides/prêts à taux 0 pour les 3 régions

Détail complet dans [`ANALYSE_REFORME_PRIMES_WALLONIE_BRUXELLES_2026.md`](ANALYSE_REFORME_PRIMES_WALLONIE_BRUXELLES_2026.md).

- **Wallonie** : nouveau régime prêts bonifiés dès le 01/10/2026, mais enveloppe réelle connue seulement après le conclave budgétaire de rentrée (~septembre 2026) — ne pas construire le calcul final avant cette date
- **Bruxelles** : retour ciblé (ménages vulnérables + bailleurs AIS) via le Plan social climat, modalités "encore à fixer", rien de concret avant 2027 — ne rien développer avant publication des modalités
- **Flandre** : pas d'actualité récente, dispositif stable — aucune action requise ici

**Ce qui est actionnable dès maintenant, indépendamment du calendrier politique :**
- Capturer le PEB pour la Wallonie (critère bloquant de la réforme, absent de `wallonie_eligibility_service.rb`) en réutilisant l'OCR PEB déjà construit pour Bruxelles (`#btn-scan-peb-bruxelles`)
- Concevoir le futur module de calcul wallon (`wallonie_pret_bonifie_calculator_service.rb`) **en parallèle** de l'existant (`wallonie_category_service.rb`), pas en remplacement

---

## Fil rouge — Préparation à la vente 2027

Rappel des 3 pistes déjà identifiées dans `strategie_passeport_numerique_EPBD.md` : agrément régional (prioritaire), partenariat Fednot/banques, levée de fonds seed sur le narratif EPBD.

**Ce que chaque phase apporte à la valorisation :**

| Phase | Contribution à la vente |
|---|---|
| 1-2 (simplification) | Rétention/usage réel — le critère n°1 qu'un acquéreur vérifie, et le point faible actuel (124 comptes dormants) |
| 3 (primes 3 régions) | Alignement réglementaire défendable, différenciateur commercial |
| Légal/Infra (déjà fait) | 100% conformité, monitoring, sécurité — base saine déjà acquise (sprint sécurité mai 2026) |

**Prérequis avant toute discussion de vente sérieuse :** reconstituer un signal d'usage réel. Sans rétention démontrable, aucune des 3 pistes stratégiques n'est crédible face à un acquéreur ou un investisseur — d'où la priorité donnée aux phases 1-2 sur la phase 3.

---

## Prochaines étapes concrètes

1. Sortir de la pause reste une décision explicite de Robin — cette feuille de route ne présume pas d'un calendrier
2. Si/quand la reprise est décidée : lancer en parallèle un audit UX chantier (Phase 2) avec un pro pilote et un prototype de drop-zone batch (Phase 1)
3. Revisiter la Phase 3 après le conclave budgétaire wallon de rentrée 2026 — pas de date fixe connue à ce stade, à surveiller dans l'actualité

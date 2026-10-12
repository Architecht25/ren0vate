# Plan de livraison V2

Fondé sur `docs/AUDIT_V1.md` et `ren0vate-v2-cahier-des-charges.md` §12. Reprend la structure de lots du cahier des charges, affinée avec l'ordre interne, l'estimation relative et les décisions à valider avant de coder quoi que ce soit.

**Branche** : `v2`, staging Heroku séparé (règle 4 du cahier des charges — ne jamais toucher à la prod V1). Aucune ligne de code tant que ce plan n'est pas validé.

Estimation relative : **S / M / L / XL**, relative entre lots de ce plan uniquement (pas une estimation en jours — l'audit n'a pas mandat pour chiffrer en temps).

---

## Ordre et dépendances

```
Lot 0 (fondations) ─┬─► Lot 1 (projet + documents) ─┬─► Lot 2 (IA + budget) ──► Lot 3 (primes) ──► Lot 4 (exécution)
                     │                                │
                     │                                └─► Lot 5 (RAG/assistant) [dépend aussi de Lot 2]
                     └─► (CI, staging, policies) ────────► Lot 6 (conformité/coffre-fort) [dépend de Lot 1 et 4]
                                                           Lot 7 (après-chantier) [dépend de tout, hors MVP]
```

Lots 1→3 forment le MVP (conforme §12 du cahier des charges). Lot 4/5 peuvent être réordonnés entre eux selon retour utilisateur (indépendants l'un de l'autre, tous deux dépendants de Lot 1-2).

---

## Lot 0 — Audit et fondations

**Estimation : M.** Pas de fonctionnalité visible, mais bloque tout le reste.

- `docs/AUDIT_V1.md`, `docs/PLAN_V2.md`, `docs/QUESTIONS_OUVERTES.md` (ce livrable).
- Branche `v2` + app Heroku de staging séparée + variables d'environnement dédiées.
- CI reprise de `.github/workflows/ci.yml` (Brakeman, Rubocop, tests Postgres) — réutilisable directement.
- Modèle de données validé (schéma §4 du cahier des charges, affiné avec les retours du Lot 0) : `User`, `Organization`, `Membership`, `Property`, `Project`, `Phase`, `Lot`, `ProjectParticipant`, `AuditEvent` au minimum — le reste peut arriver au fil des lots fonctionnels qui en ont besoin, pas tout d'un bloc.
- Couche d'autorisation : introduction de Pundit (ou alternative retenue — voir Décisions techniques), structurée dès ce lot car tous les lots suivants en dépendent. Matrice rôle × action × visibilité (§3) écrite et testée **avant** le premier contrôleur Lot 1.
- `AuditEvent` (table polymorphe append-only) posée en Lot 0 : les lots suivants l'alimentent au fil de l'eau plutôt que de la rattraper après coup.
- Décision de stockage de fichiers tranchée et configurée (Scaleway, URLs signées) — pas de contenu réel à migrer encore, juste l'infrastructure prête pour Lot 1.
- *Critère de fin* (reprend §12) : plan validé par toi, CI verte sur `v2`, matrice de permissions écrite et testée sur un projet factice minimal (sans UI).

## Lot 1 — Projet et base documentaire (MVP)

**Estimation : XL.** Le plus gros lot, c'est la colonne vertébrale du cahier des charges (§1 : « une base documentaire commune... en est la colonne vertébrale »).

- `Property`, `Project`, `Phase`, `Lot` (modèles pré-remplis, personnalisables), `ProjectParticipant` (role + périmètre de lots + statut d'invitation) — **en partant de `ProjectMember` V1** pour la mécanique d'invitation (token, expiration), étendu avec le périmètre de lots qui manque aujourd'hui.
- `Document` + `DocumentVersion` + `DocumentComment` + `DocumentReview` — réécriture complète du `Document` V1 (538 lignes, monolithique) en séparant fichier/version/statut/commentaire. Le catalogue de types et l'association type↔phase (`DocumentPhase` V1) sont la meilleure base de départ, à généraliser sur des `Phase`/`Lot` dynamiques au lieu de la liste figée V1.
- Upload en vrac, versionnage, restauration, aperçu intégré (le service `Documents::PdfPreviewService` V1 est réutilisable), export ZIP.
- Visibilité par document (`private/lot/all/custom`), journal d'audit de consultation/modification/validation (alimente `AuditEvent` du Lot 0).
- Tableau de bord chantier minimal (avancement, documents à valider) — version simplifiée, le tableau de bord riche vient avec Lot 2 (budget) et Lot 4 (planning).
- Migration de données V1 : scripts rejouables et testés pour `Property`/`Project`/documents existants (voir risques §5 de l'audit — lot par défaut, visibilité par défaut, SHA-256 rétroactif à trancher dans Questions ouvertes).
- *Critère de fin* (reprend §12) : un propriétaire, un architecte et deux entrepreneurs travaillent sur un chantier de test ; chacun ne voit que son périmètre (testé exhaustivement) ; aucune version de document perdue.

## Lot 2 — Ingestion IA et budget (MVP)

**Estimation : L.**

- `Ai::Client` : couche d'abstraction unique, construite **autour** du `Bots::ClaudeChatClient` V1 (client Anthropic, gestion d'erreurs, minimisation RGPD par tranches de montant — à conserver tel quel) en y ajoutant ce qui manque : choix de modèle par fonction, cache, limites de débit, budget de coût par projet/mois, journalisation `AiRun`, sorties validées par schéma JSON.
- Ingestion intelligente (§8.1) : OCR + classification + extraction à l'upload, en job asynchrone — reprend directement le pattern établi en V1 (`PebExtractionJob`, `AudioEnergExtractionJob`, bascule async après deux incidents H12 Heroku documentés). Les services OCR V1 (`app/services/ocr/*`) sont le socle d'extraction, à faire passer dans la nouvelle classification par `Lot`/`Phase` du Lot 1.
- `Quote`/`QuoteLine` structurés : à trancher d'abord entre `Devis::Quote` et `Documents::Facture` (type `devis`) V1, qui font doublon partiel (voir audit §3.4) — ne pas porter les deux.
- Comparateur de devis (`Devis::DevisComparateurIaService` V1 réutilisable comme point de départ de prompt), budget prévisionnel/devisé/facturé/payé (`BudgetLine`), avenants (`Amendment`) avec validation tracée.
- *Critère de fin* (reprend §12) : classification ≥ 90% de justesse sur un jeu de test déposé en vrac ; écarts budgétaires calculés et tracés.

## Lot 3 — Moteur de primes (MVP)

**Estimation : L.**

- `SubsidyRule` versionnée et datée, `SubsidyCase`, `SubsidyDocumentRequirement`. Réécriture structurelle (code → données) en **conservant les barèmes et la logique d'exclusion des services `Regions::*` V1 comme spécification** (seuils, cas particuliers déjà corrigés lors de réformes passées — ne pas redériver ces règles depuis zéro).
- Mode simulation (public, sans compte) et mode dossier (rattaché au chantier, recalculé à chaque changement de devis/facture) — correspond déjà conceptuellement à la distinction V1 `Simulation`/`Request`, à reconstruire sur les nouvelles tables.
- Suite de tests de référence par région (Bruxelles/Wallonie/Flandre), cas types avec résultat attendu — à construire, `test/services/regions/*` V1 n'en couvre qu'une fraction.
- Décision explicite sur les simulations V1 déjà enregistrées : archivées en lecture seule, pas recalculées avec le nouveau moteur (proposition de l'audit, à valider — voir Questions ouvertes).
- *Critère de fin* (reprend §12) : cas de référence verts pour les trois régions ; changement de règle sans modification de code applicatif (test de non-régression explicite : modifier une date de validité en base doit suffire).

## Lot 4 — Exécution (V2.1)

**Estimation : L.**

- Planning par lot avec dépendances (`ScheduleItem`) — `Projects::GanttBuilder` V1 est un point de départ exploitable pour la logique de rendu.
- Journal de chantier (photos datées/géolocalisées), réunions + PV automatiques (le service `Devis::EtatAvancementPdfService` et les modèles `PvVisite`/`PvReception` V1 couvrent déjà une partie de ce besoin, à adapter au multi-intervenants par lot plutôt qu'au mono-chantier).
- Réserves (`Project::Reserve` V1 directement réutilisable comme modèle de départ, déjà structuré : description/photo/lot/responsable/statut/échéance).
- Messagerie par lot, notifications (le `Notifications::NotificationService` V1 est réutilisable comme moteur d'envoi, à reconnecter aux nouveaux événements).

## Lot 5 — Assistant sur dossier (V2.1)

**Estimation : L.** Dépend du Lot 2 (`Ai::Client` doit exister).

- Extension PostgreSQL `pgvector` (à ajouter sur le staging Heroku, inexistante en V1).
- Embeddings par document/version, RAG filtré par droits **avant** la recherche vectorielle (règle de sécurité non négociable du §8, test automatisé obligatoire : un entrepreneur ne doit jamais obtenir via l'assistant un document qu'il ne peut pas ouvrir).
- Citations de sources, traduction (FR/NL/ES/EN), rédaction assistée (brouillons).
- Risque spécifique à documenter en test : la visibilité par document doit être strictement respectée dans l'index vectoriel lui-même, pas seulement au moment de l'affichage du résultat.

## Lot 6 — Conformité et coffre-fort (V2.2)

**Estimation : M.** Dépend du Lot 1 (documents) et du Lot 4 (réception).

- Checklists par région (le concept `Project::ChecklistTemplate`/`ProjectChecklistItem` V1 est un point de départ correct, déjà par-projet).
- Garanties et rappels (`Warranty`), réception provisoire/définitive (`PvReception` V1 à étendre), coffre-fort final exportable/transmissible.

## Lot 7 — Après-chantier (V3)

**Estimation : XL, hors périmètre du MVP actuel.** Entretien, module locatif (V1 a déjà `Property::Lease`/`Tenant`/`RentPayment` — base de départ correcte, à reconnecter au nouveau modèle), vente, ouverture FR/ES.

---

## Décisions techniques à valider avant Lot 0

Conformément à la règle 5 du cahier des charges (pas de choix structurant sans signalement), voici les points sur lesquels il faut ton accord explicite avant d'écrire du code :

1. **Autorisation : Pundit.** Pas d'alternative sérieuse proposée (CanCanCan ferait aussi bien mais Pundit est plus simple à tester exhaustivement par policy, ce qui est l'exigence explicite du §3). *Recommandation : Pundit.*
2. **Jobs asynchrones : Solid Queue, pas Sidekiq.** La V1 tourne déjà sur Solid Queue avec un dyno worker dédié, configuration déjà validée en production (incident R14 résolu le 22/08/2026, documenté dans CLAUDE.md). Changer pour Sidekiq ajouterait une dépendance Redis sans bénéfice identifié. *Recommandation : garder Solid Queue.*
3. **Front-end : Tailwind (imposé par le cahier des charges) vs effort de portage.** La V1 est en Bootstrap 5 + Stimulus (~35 modules de vues, sweep mobile complet fait en septembre). Passer à Tailwind veut dire un nouveau design system construit de zéro, pas une bascule de classes CSS. *Point à trancher : ce travail de design démarre-t-il en parallèle du Lot 1 (vues neuves directement en Tailwind) ou attend-il un design system validé séparément avant tout Lot 1 ?*
4. **Stockage objet : Scaleway (imposé par le cahier des charges).** Aucune configuration S3-compatible n'existe en V1 (Cloudinary uniquement). À mettre en place dès le Lot 0 comme infrastructure, sans contenu à migrer encore.
5. **Coexistence V1/V2 pendant la transition.** Deux options : (a) la V1 continue de tourner en production pour les clients existants pendant toute la durée du développement V2, bascule finale en une migration ponctuelle one-shot ; (b) la V1 passe en lecture seule dès qu'un chantier commence à migrer, double-run limité dans le temps. *Recommandation prudente : (a)*, cohérente avec la règle 4 (« ne jamais casser la production V1 ») et avec le fait qu'il n'y a qu'1 abonnement payant actif à ce jour — le risque d'une bascule ponctuelle bien testée est faible comparé à la complexité d'une double-écriture pendant la transition.
6. **Modèle `Quote` V1 à conserver : `Devis::Quote` ou `Documents::Facture` type `devis` ?** Les deux existent en V1 et se chevauchent partiellement (audit §3.4). *Nécessite un examen de code plus poussé que ce que permet cet audit haut niveau — à trancher en ouverture du Lot 2, pas avant.*
7. **Confirmable Devise en V2.** La V1 a les colonnes mais le module désactivé. *Point ouvert, voir `docs/QUESTIONS_OUVERTES.md`.*
8. **Ruby/Rails : rester sur Ruby 3.3.9/Rails 8.1.4 (versions V1 actuelles) ou upgrader en ouvrant la branche `v2` ?** Le cahier des charges demande « la dernière version stable » — Rails 8.1.4 est déjà la dernière version majeure stable utilisée. *Recommandation : rester sur ces versions, upgrade Ruby 3.3.11 mineur possible sans risque, à faire en Lot 0.*

---

## Ce que ce plan ne couvre pas

Hors périmètre explicite du MVP (§13 du cahier des charges, rappelé ici pour mémoire) : signature électronique qualifiée, paiement intégré entre intervenants, application mobile native, module locatif/vente avant Lot 7, pays hors Belgique avant Lot 7, marketplace d'entrepreneurs.

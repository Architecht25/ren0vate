# Questions ouvertes — V2

Conformément à la règle 6 du cahier des charges : chaque point ci-dessous liste l'hypothèse la plus prudente retenue par défaut, clairement marquée, pour que le travail puisse avancer sans bloquer sur une réponse. À confirmer ou corriger avant que le Lot concerné ne commence réellement.

---

## Migration de données

**Q1. Visibilité par défaut des documents migrés depuis V1.**
V1 n'a aucune notion de visibilité par document — tout document d'un projet est visible par tout membre actif. La V2 introduit `private/lot/all/custom`.
→ **Hypothèse retenue : `all`** pour tout document migré (ne rien cacher par erreur à quelqu'un qui le voyait déjà en V1), resserrement manuel possible ensuite par le propriétaire. L'alternative (`private` par défaut) romprait silencieusement l'accès que les intervenants avaient déjà en V1.

**Q2. Lot par défaut des documents migrés.**
Le concept de `Lot` n'existe pas en V1.
→ **Hypothèse retenue** : dérivation automatique depuis `type_document` via la table `DocumentPhase` V1 existante (association type ↔ phase déjà en place) quand elle donne un signal exploitable ; sinon lot générique `"non classé"`, à trier manuellement.

**Q3. Empreinte SHA-256 rétroactive sur les documents déjà déposés en V1.**
Calculer un hash a posteriori implique de retélécharger chaque fichier depuis Cloudinary.
→ **Hypothèse retenue** : ne pas le faire en masse pendant la migration initiale (coût élevé, valeur probante rétroactive faible puisque le fichier n'était de toute façon pas protégé par hash au moment du dépôt original) ; calculer le hash uniquement à partir du premier nouvel upload/version créé en V2. À confirmer si une valeur probante rétroactive est jugée importante (ex. litige en cours sur un chantier existant).

**Q4. Simulations de primes V1 déjà enregistrées : recalcul avec le nouveau moteur ou archivage figé ?**
Le nouveau moteur `SubsidyRule` versionné n'aura pas d'historique de « quelle règle était active quand » pour les simulations anciennes.
→ **Hypothèse retenue** : archivage en lecture seule des simulations V1, pas de recalcul automatique. Le risque d'un recalcul qui change silencieusement un montant déjà communiqué à un utilisateur semble plus coûteux que la perte de cohérence d'un historique figé.

**Q5. Comptes bêta en attente de purge.**
La mémoire projet indique une purge prévue mi-septembre 2026 (~50 comptes bêta sans retour) dont le statut d'exécution n'a pas été vérifié dans cet audit (hors périmètre code).
→ **Hypothèse retenue** : vérifier l'état réel de cette purge avant de lancer un script de migration complet, pour ne pas migrer des comptes qui devaient être supprimés. Ne pas supposer qu'elle a eu lieu.

**Q6. `professional_type` global (V1) vs rôle par chantier (V2).**
Un compte pro V1 porte un rôle unique pour tout le système ; la V2 porte le rôle par `ProjectParticipant`.
→ **Hypothèse retenue** : à la migration, chaque `ProjectMember` V1 existant devient un `ProjectParticipant` avec son propre rôle (déjà porté par chantier en V1 via `ProjectMember`) ; le champ global `professional_type` n'est conservé que comme méta-donnée d'affichage ("type de compte principal"), jamais comme source de vérité d'autorisation. Si un compte a des rôles contradictoires entre `professional_type` et un `ProjectMember` existant, le rôle par projet prévaut — à vérifier au cas par cas pendant la migration (nombre de cas a priori faible).

---

## Décisions produit

**Q7. Confirmable Devise en V2.**
V1 a les colonnes (`confirmed_at`...) mais le module désactivé — jamais activé depuis la mise en prod.
→ **Hypothèse retenue** : laisser désactivé en V2 également, sauf si une obligation RGPD/sécurité explicite impose la confirmation d'email (le §6 du cahier des charges mentionne l'authentification forte 2FA mais pas la confirmation d'email comme exigence). Si activé malgré tout, tous les comptes migrés devront être confirmés d'office au moment de la migration (`update_all(confirmed_at: Time.now)`), sans quoi ils seraient bloqués à la connexion suivante.

**Q8. Formules d'abonnement (Starter/Propriétaire/Investisseur/Premium/Pro/Entreprise, §1 du cahier des charges).**
Le cahier des charges dit « à conserver ou ajuster » sans trancher.
→ **Hypothèse retenue** : conserver la structure actuelle de `User::Subscription`/Stripe telle que documentée (CLAUDE.md § Stripe) à l'identique pour le MVP V2, et ne rouvrir la question des formules qu'une fois le modèle chantier multi-intervenants stabilisé — changer le pricing et le modèle de données en même temps rendrait les deux risques difficiles à isoler. Ne pas casser l'abonnement payant actif en cours (3 septembre 2026, paiement annuel).

**Q9. Coexistence V1/V2 pendant la transition — portée exacte.**
Couvert comme décision technique n°5 dans `docs/PLAN_V2.md` (recommandation : V1 continue en prod jusqu'à bascule one-shot testée). Listé ici aussi parce que la réponse détermine si un **export/import V1 doit rester disponible en continu** pendant tout le développement V2 (si bascule différée projet par projet) ou une seule fois à la fin (si bascule globale).
→ **Hypothèse retenue** : bascule globale unique en fin de développement, pas de double-écriture continue — cohérent avec la recommandation du plan.

**Q10. Front-end Tailwind — calendrier du portage de design.**
Couvert comme décision technique n°3 dans `docs/PLAN_V2.md`. Question distincte : le design Tailwind est-il élaboré par toi en parallèle (maquettes/design system fourni), ou Claude Code doit-il proposer un design system de zéro au fil du Lot 1 ?
→ **Hypothèse retenue** : en l'absence de maquette fournie, Claude Code proposera un design system minimal (tokens de couleur, composants de base) au fil du Lot 1, à valider avant généralisation — pas de proposition de design complet avant d'avoir du contenu réel à habiller.

---

## Technique, à confirmer tôt (bloque le Lot 0/1 sinon)

**Q11. Choix final entre `Devis::Quote` et `Documents::Facture` (type `devis`) comme base du modèle `Quote` V2.**
Signalé dans l'audit §3.4 — nécessite un examen de code plus poussé qu'un audit haut niveau (usages dans les vues, volume de données réelles de chaque table).
→ **Hypothèse retenue** : reporté explicitement à l'ouverture du Lot 2, pas tranché ici — aucun travail de Lot 0/1 n'en dépend directement.

**Q12. Extension `pgvector` sur Heroku.**
Nécessaire pour le Lot 5 (RAG). Heroku Postgres supporte `pgvector` sur certains plans — à vérifier sur le plan actuellement souscrit avant d'arriver au Lot 5.
→ **Statut au 12/10/2026** : vérifié disponible et activé sur Postgres **local** (extension `vector` 0.6.0). **Toujours à vérifier sur le plan Heroku réel** avant tout déploiement de la branche `v2` — pas testé en dehors de cet environnement local.

**Q13. Tarifs Anthropic utilisés pour le budget IA (`Ai::Client::PRICING_CENTS_PER_MILLION_TOKENS`).**
Le Lot 2 introduit un plafond de coût IA par projet/mois (cahier des charges §8). Le mécanisme de plafond fonctionne, mais les prix par modèle (cents par million de tokens input/output) codés dans `Ai::Client` sont des valeurs placeholder, pas la grille tarifaire réelle d'Anthropic au moment de l'écriture.
→ **Hypothèse retenue** : le plafond par défaut (`AI_MONTHLY_BUDGET_CENTS`, 5000 cents = 50€/mois/projet) reste approximatif jusqu'à confirmation. À corriger avec les tarifs réels avant de communiquer ce budget à un client ou de s'appuyer sur lui pour une décision financière.

**Q14. Montants du moteur de primes V2 (`amount_formula` des `SubsidyRule` seedées au Lot 3).**
Le Lot 3 porte fidèlement les CONDITIONS d'éligibilité Wallonie/Flandre depuis les services V1 lus pendant l'audit (`Regions::Wallonie::WallonieEligibilityService`, `Regions::Flandre::FlandreEligibilityService`), mais seulement UNE règle par région (démonstration du mécanisme, pas le catalogue complet), et les MONTANTS (taux, plafonds) sont des placeholders non vérifiés avec le barème officiel — le fichier source lu pendant l'audit s'arrêtait avant la partie calcul du montant.
→ **Hypothèse retenue** : ne jamais citer ces montants à un client ou les utiliser comme base d'une simulation réelle avant vérification complète du barème. Le mécanisme (règles versionnées, recalcul sans déploiement) est fonctionnel et testé ; son contenu chiffré ne l'est pas encore. Porter le reste du catalogue de primes (toutes les primes existantes de `Regions::*`, pas seulement une par région) est un travail distinct, non commencé.

**Q15. Fournisseur d'embeddings pour le RAG (`Ai::EmbeddingClient`) — RÉSOLU le 12/10/2026.**
Anthropic ne fournit pas d'API d'embeddings. Décidé avec Robin : Voyage AI (partenaire officiellement recommandé par Anthropic), modèle `voyage-3`.
→ **Statut** : clé `VOYAGE_API_KEY` fournie par Robin le 12/10/2026, testée avec un appel réel — modèle et dimension du vecteur (1024) confirmés en conditions réelles, pipeline complet (ingestion → chunking → embedding → recherche filtrée par droits → synthèse Claude avec citation) vérifié de bout en bout. Plus une hypothèse — à considérer comme acquis, sous réserve d'ajouter `VOYAGE_API_KEY` aux variables d'environnement Heroku avant tout déploiement (actuellement seulement dans le `.env` local).

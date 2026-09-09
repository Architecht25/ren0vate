# Insights terrain — Septembre 2026

Suite de `insights_terrain_mai2026.md` (resté vide — aucun retour pro réel consigné depuis mai malgré la
mention d'un Programme Ambassadors démarré le 19/05). Ce fichier démarre avec le premier test utilisateur
pro réel prévu début septembre : l'architecte d'un client existant, sollicitée pour parcourir l'app.
Protocole utilisé : voir `protocole_test_utilisateur_pro.md`.

Format court (issu d'appels/emails ponctuels) :

```
- [DATE] · [Source : prospect / testeur / client PS / autre] · [Besoin exprimé] · [Priorité : haute / moyenne / faible]
```

---

## Sessions de test utilisateur structurées

### 09/09/2026 · Architecte — h.delmee@loftandpartners.com (Loft & Partners) · rôle sur le projet : architect

**Contexte :** Chantal Verbaere (cliente Primes-Services devenue user Ren0vate), projet "Mon chantier"
(Waterloo, Wallonie, project #514) ; son architecte parcourt l'app en conditions réelles sur ce dossier,
en session live avec Robin.

**Grille d'observation** (depuis `protocole_test_utilisateur_pro.md` §3) :

| # | Tâche | Réussi sans aide ? | Friction observée | Verbatim / détail |
|---|-------|---------------------|--------------------|----------|
| 0 | Ouverture de la vue projet (pro_view) | ❌ puis ✅ | **Bug bloquant en direct** : erreur 500 (`NoMethodError: undefined method 'filename' for Document` — `rails_blob_path` appelé sur l'enregistrement `Document` au lieu de `Document#file`, 5 occurrences). Corrigé et déployé en live (v984) pendant la session. | — |
| 1 | Consulter les devis/métrés (section préparation) | ⚠️ Partiel | N'affiche que le **dernier devis produit** (toiture), pas l'ensemble des devis estimatifs générés par le user. | "je ne vois que le devis toiture, pas les autres" |
| 2 | Consulter les documents de permis | ✅ | Aucune friction — tout ce qu'a encodé le user côté permis apparaît correctement côté architecte. | "c'est bon" |
| 3 | Consulter les photos de chantier par phase | ⚠️ Partiel | Photos affichées trop petites ; l'architecte ne peut que les visionner, pas en charger lui-même (à trancher : garder en lecture seule ou ouvrir l'upload aux archis). | — |
| 4 | Valider une phase de chantier (bouton) | ❌ | **Aucune réaction au clic**, ou pas d'indication claire que la validation de l'archi seule ne suffit pas — il manque un signal que user + entrepreneur doivent aussi valider. Probable gap UX (pas de déroulé d'état) plutôt qu'un bug isolé — à vérifier si même classe de bug que les 2 corrigés aujourd'hui (script inline / pas de réaction JS). | — |
| 5 | PV de réception de chantier | ✅ (adopté) | L'archi produit son PV en Word (process interne du cabinet), mais a accepté de tester l'encodage des données dans Ren0vate **en plus**, en tant que double vérification que toutes les étapes chantier ont été passées en revue. | — |

**Synthèse :**
- Deux bugs bloquants trouvés et corrigés en direct pendant la session (pro_view 500, puis "aucune réaction" sur la création de simulation côté user — hors périmètre archi mais découvert dans la même session).
- Les permis fonctionnent bien de bout en bout — rien à faire.
- Deux frictions réelles côté suivi de chantier (devis partiels, boutons de phase sans feedback clair) — candidats à investiguer/corriger en priorité, pas juste des nice-to-have.
- Le PV de réception est adopté comme complément (pas remplacement) du process interne du cabinet — signal positif de traction, l'architecte a accepté de tester volontairement.
- Avis de Robin : "nous sommes sur le bon chemin".

**Frictions → priorité (à reporter aussi dans le format court ci-dessous) :**
- Devis : seul le dernier devis affiché en préparation, pas tous les devis estimatifs → **haute** (perte d'info directe pour l'archi)
- Boutons de validation de phase : pas de réaction / pas de signal multi-parties (user + entrepreneur) → **haute** (bloque potentiellement le workflow de validation)
- Photos de chantier trop petites, upload archi non permis → **moyenne** (décision produit à trancher, pas juste un bug)
- Intégration APROPLAN (dépôt du PV produit par Aproplan dans Ren0vate au lieu de l'envoyer par email ; classement lot par lot) → **moyenne**, outil bien implanté chez les architectes selon ce retour — piste d'intégration/partenariat à creuser plutôt qu'un développement immédiat

---

## Insights (format court, au fil des appels)

<!-- Ajouter ici au fil des appels -->

- 09/09/2026 · Testeur (architecte, session live) · Devis : seul le dernier devis affiché en préparation, pas tous les devis estimatifs du user · haute
- 09/09/2026 · Testeur (architecte, session live) · Boutons de validation de phase : pas de réaction ou pas de signal que user + entrepreneur doivent aussi valider · haute
- 09/09/2026 · Testeur (architecte, session live) · Photos de chantier trop petites + upload réservé au user, archi en lecture seule uniquement · moyenne
- 09/09/2026 · Testeur (architecte, session live) · Souhait d'intégration APROPLAN (dépôt PV Aproplan dans Ren0vate au lieu d'email, classement lot par lot) — outil déjà bien implanté chez les architectes · moyenne
- 09/09/2026 · Testeur (architecte, session live) · PV de réception : l'archi a accepté de tester l'encodage Ren0vate en complément de son PV Word habituel (double vérification du process interne du cabinet) — signal positif · haute (traction)
- 09/09/2026 · Constat (pas remonté par l'architecte, repéré par Robin en comparant au certificat PEB papier) · Le PEB extrait en base pour le projet de Chantal Verbaere est "C", alors que le certificat réel affiche "F" (Espec 498 kWh/m².an) → erreur d'extraction OCR, pas encore investiguée en profondeur (mise en pause pour rester concentré sur le retour architecte) · haute — impact direct sur l'éligibilité réelle au nouveau régime wallon (C exclu, F éligible)

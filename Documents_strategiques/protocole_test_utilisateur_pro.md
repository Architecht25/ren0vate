# Protocole de test utilisateur — comptes pro (architecte / entrepreneur)

Réutilisable pour chaque session de test avec un pro réel (architecte ou entrepreneur).
Objectif : sortir de la case "⚠️ template vide" du launch checklist (§2, item bloquant "Retours terrain pros")
avec un retour exploitable, pas une visite libre non structurée.

Durée cible : 30-40 min. À faire en partage d'écran ou en présentiel sur son mobile (privilégier le mobile
si le pro consulte principalement en déplacement — cf. item "Vue entrepreneur mobile-first" du même audit).

---

## 0. Avant l'appel

- [ ] Créer (ou utiliser) un vrai projet client avec des données réalistes : au moins un devis avec quote_items,
      1-2 photos par phase, un statut de permis renseigné si architecte.
- [ ] Vérifier que le pro a bien un `ProjectMember` actif sur ce projet (role `architect` ou `entrepreneur`),
      pas juste une invitation `pending` — sinon il tombera sur un dashboard vide au lieu de la vue projet.
- [ ] Préparer l'accès : lien direct `pro_view_project_path` ou repartir du login + `member_projects_path`
      pour aussi observer le chemin d'entrée réel.
- [ ] Ne rien pré-expliquer sur l'interface avant de lancer — le but est d'observer, pas de guider.

## 1. Consigne d'ouverture (à dire au pro)

> "Je vais te laisser naviguer librement sur le dossier de [client]. Dis-moi à voix haute ce que tu comprends,
> ce que tu chercherais à faire, et si quelque chose te bloque ou te surprend. Il n'y a pas de mauvaise réponse —
> je cherche justement les frictions."

## 2. Scénario — tâches à faire réaliser (sans les nommer techniquement)

Adapter selon le rôle du pro testé.

### Architecte
1. Retrouver l'état d'avancement global du chantier depuis l'accueil de sa vue.
2. Consulter/déposer un plan et un document de permis d'urbanisme.
3. Mettre à jour le statut du permis (stepper à_déposer/en_cours/obtenu).
4. Déposer ou consulter le métré.
5. Valider une phase de chantier (préparation, démolition…).
6. Ouvrir l'assistant IA et poser une question métier réelle (ex : "quelles primes pour ce chantier ?").
7. Créer ou consulter un PV de réception.

### Entrepreneur
1. Retrouver l'état d'avancement global du chantier depuis l'accueil de sa vue.
2. Envoyer un devis (upload PDF + montant).
3. Ajouter une photo de chantier liée à une phase (idéalement depuis son mobile, via l'appareil photo).
4. Ajouter une facture/acompte/solde.
5. Créer un état d'avancement.
6. Valider une phase de chantier.
7. Ouvrir l'assistant IA et poser une question (ex : "délais légaux de paiement en Belgique ?").

## 3. Grille d'observation (à remplir pendant/juste après la session)

| # | Tâche | Réussi sans aide ? | Temps ressenti (rapide/normal/long) | Friction observée | Verbatim marquant |
|---|-------|---------------------|--------------------------------------|--------------------|--------------------|
| 1 |       |                     |                                      |                    |                    |
| 2 |       |                     |                                      |                    |                    |
| … |       |                     |                                      |                    |                    |

## 4. Questions ouvertes de clôture

- Qu'est-ce qui t'a semblé le plus utile dans ce que tu viens de voir ?
- Qu'est-ce qui te manque pour que ça remplace vraiment ton usage actuel (mail/WhatsApp/Excel/autre) ?
- Est-ce que tu l'utiliserais sur mobile, sur desktop, ou les deux ? Dans quel contexte ?
- Sur une échelle de 1 à 5, quelle est la probabilité que tu recommandes ça à un client ou un confrère ?
- Y a-t-il une fonctionnalité que tu attendais et qui n'existe pas ?

## 5. Après l'appel

- [ ] Reporter chaque friction/insight dans `insights_terrain_*.md` (une ligne par insight, priorité estimée).
- [ ] Si un bug bloquant est identifié, l'ouvrir immédiatement comme item séparé — ne pas attendre la
      synthèse globale du programme Ambassadors.
- [ ] Mettre à jour le statut de l'item "Retours terrain pros" du launch checklist avec la date et le nom
      (anonymisé si besoin) du pro testé.

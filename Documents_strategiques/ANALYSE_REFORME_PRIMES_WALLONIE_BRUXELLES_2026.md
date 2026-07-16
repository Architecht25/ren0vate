# Analyse — Réforme des primes Wallonie & retour partiel des primes Bruxelles (2026)

*Rédigé : 16 juillet 2026 — sources : 2 articles L'Echo (Wallonie, non daté explicitement mais publié le jour de rédaction ; Bruxelles, 07/07/2026)*

---

## Contexte

Ren0vate est actuellement **en pause** (adoption utilisateur nulle + flou réglementaire post-arrêt des primes). Ce document ne relance pas le projet : c'est une reconnaissance destinée à préparer une éventuelle mise à jour des services de gestion de primes, à activer seulement une fois les paramètres définitifs connus.

**Point clé à retenir : rien n'est figé.** La Wallonie n'a validé qu'une *première lecture*, l'enveloppe budgétaire réelle n'est fixée qu'au conclave de rentrée (~septembre 2026), et le régime transitoire fait l'objet d'un contentieux avec le Conseil d'État. À Bruxelles, les primes ne sont même pas encore un dispositif défini — juste une intention budgétaire dépendant de l'aval de la Commission européenne.

---

## 1. Wallonie — remplacement des primes cash par des prêts bonifiés

### Ce qui change

| Aspect | Avant (système actuel) | Après (dès le 01/10/2026) |
|---|---|---|
| Nature de l'aide | Prime versée cash après travaux | Réduction du solde à rembourser sur un prêt |
| Organismes | Direct (SPW) | Rénopack (taux 0%) ou Rénoprêt (taux préférentiel, revenus faibles + bailleurs) |
| Calcul | Poste par poste (par type de travaux) | Sur le projet de rénovation global |
| Plafond | 60 000€ | 75 000€ (maison unifamiliale) |
| Éligibilité logement | Pas de critère PEB actuellement modélisé | **PEB E ou F** (viser D min.) ou **PEB D** (viser C min.) — nouveau critère bloquant |
| Budget | — | Enveloppe **fermée**, fixée annuellement par le gouvernement |

### Nouveau barème de réduction (remplace les 5 catégories R1-R5)

| Revenu | Réduction sur le montant emprunté |
|---|---|
| ≤ 28 900€ | 50% |
| 28 900,01€ – 41 100€ | 40% |
| 41 100,01€ – 67 100€ | 15% |
| 67 100,01€ – 122 800€ | Taux variable, **0% de réduction** sur le solde |

À comparer à l'ancien système (catégories R1-R5, seuil global 114 400€) : le plafond global monte légèrement (122 800€) mais le nombre de tranches passe de 5 à 4, et surtout la logique change de nature — ce n'est plus "combien de cash je reçois par poste de travaux" mais "de combien mon emprunt est réduit, sur un projet global".

### Ce qui reste incertain

- **Enveloppe budgétaire réelle** : pas chiffrée, décision au conclave budgétaire de la rentrée 2026.
- **Régime transitoire (14-28 février 2025)** : critiqué par le Conseil d'État, risque budgétaire de ~500M€. Le gouvernement penche pour un réexamen permettant à de nouveaux bénéficiaires de profiter des anciens montants — mais rien n'est acté. Arrêté définitif attendu **1er semestre 2027**.
- Le passage en vigueur du 1er octobre concerne le *nouveau régime PEB E/F/D* ; le sort du régime transitoire est une question séparée et non tranchée.

---

## 2. Bruxelles — signal de retour, mais rien de concret

Le gouvernement bruxellois a adopté le volet régional du **Plan social climat** (fonds européens, 226,5M€ sur 2026-2032, 75% financés par l'UE), qui doit encore :
1. s'intégrer dans un plan national plus large,
2. être validé par la Commission européenne.

**Ce qui est prévu (sous réserve) :**
- ~70M€ pour des primes rénovation énergétique, mais **ciblées exclusivement** : ménages à revenus faibles + propriétaires-bailleurs passant par une agence immobilière sociale (AIS/SVK)
- 19M€ pour des prêts à taux zéro, **à partir de 2027 seulement**, même public cible
- **Modalités du système "encore à fixer"** — aucun montant, aucun barème, aucun calendrier précis pour l'instant

**Ce qui ne change pas à court terme :**
- Aucune aide à la rénovation entre le 1er janvier 2025 et la mise en place du nouveau dispositif (donc a minima jusqu'à 2027 pour les prêts, statut des primes non daté)
- 56M€ dégagés uniquement pour clôturer les dossiers Renolution déjà en attente de paiement depuis mai 2025 — sujet purement administratif, sans lien avec de nouveaux dossiers

**Conclusion Bruxelles :** le public visé (ménages vulnérables + bailleurs AIS) est structurellement différent du profil actuel des utilisateurs Ren0vate (propriétaires occupants classiques). Même une fois le dispositif défini, l'intérêt produit pour Ren0vate est probablement plus limité qu'en Wallonie.

---

## 3. État actuel du code Ren0vate — ce qui devra bouger

Exploration du code (juillet 2026) :

- **Seuils de revenus Wallonie codés en dur à 3 endroits**, tous synchronisés sur le système R1-R5 actuel (25 400 / 36 200 / 51 800 / 79 000 / 114 400€) :
  - `app/services/regions/wallonie/wallonie_category_service.rb` (constante `ELIGIBILITY_THRESHOLD` + méthode de calcul de catégorie)
  - `app/controllers/simulations_controller.rb:1316` (`check_wallonie_real_eligibility`, seuil dupliqué en dur)
  - `db/seeds/wallonie/categories.rb`
- **`wallonie_eligibility_service.rb`** vérifie région, % habitation, propriétaire, résidence principale, âge du logement — **pas de critère PEB**. C'est le trou le plus important à combler pour la réforme : le PEB devient un critère bloquant et n'est aujourd'hui pas exploité pour l'éligibilité wallonne.
- **Formulaire `_form_wallonie.html.erb`** ne capture pas le PEB — contrairement à `_form_bruxelles.html.erb` qui a déjà un scan OCR PEB fonctionnel (`#btn-scan-peb-bruxelles`). Cette brique existe donc déjà côté Bruxelles et est réutilisable.
- **Bruxelles** : à vérifier — `contextual_bot_service.rb:206` documente "eligible: false" pour Bruxelles (Renolution supprimé), mais le code réel de `simulations_controller.rb` (`check_real_eligibility`, cas `'bruxelles'`) renvoie `{ eligible: true }` avec une note que seul Monuments & Sites reste actif. Écart doc/code à clarifier indépendamment de la réforme.
- **Modèle `Simulation`** : champs `region`, `category`, `parameters` (JSON), `total_simule` — la structure supporte déjà une logique par région/catégorie, donc un nouveau module wallon post-réforme peut s'y greffer sans refonte du modèle.

---

## 4. Recommandations

**Ne rien casser maintenant.** L'ancien système R1-R5 reste juridiquement valide jusqu'au 30/09/2026 au moins, et le calendrier définitif dépend encore d'arbitrages politiques (conclave rentrée) et juridiques (Conseil d'État). Modifier `wallonie_category_service.rb` aujourd'hui reviendrait à coder sur des seuils qui peuvent encore bouger.

**Par ordre de priorité, une fois la pause levée et le conclave budgétaire passé (donc pas avant fin septembre 2026) :**

1. **Capturer le PEB pour la Wallonie** — étendre le composant OCR déjà construit pour Bruxelles (`_form_bruxelles.html.erb`) au formulaire wallon. C'est la seule brique à valeur immédiate et indépendante des montants encore incertains : le critère PEB E/F/D est acquis dans la réforme, peu importe l'enveloppe finale.
2. **Construire le nouveau module de calcul en parallèle**, pas en remplacement de l'existant — un service `wallonie_pret_bonifie_calculator_service.rb` distinct, activé seulement à partir du 1er octobre 2026 (ou de la date effective confirmée). Garder l'ancien système actif pour les dossiers antérieurs / régime transitoire tant que l'arrêté définitif (attendu 2027) n'est pas publié.
3. **Mettre à jour le contexte du chatbot** (`contextual_bot_service.rb`) et la bannière "Expert Subsides Agent" pour refléter la réforme en cours plutôt que d'afficher des montants qui deviendront faux au 1er octobre — messaging "réforme en cours, montants définitifs non connus avant la rentrée" plutôt qu'un chiffre.
4. **Bruxelles : ne rien développer.** Revisiter seulement quand les modalités du Plan social climat seront publiées (probablement pas avant 2027). Corriger en revanche dès que possible l'incohérence documentaire CLAUDE.md ("eligible: false") vs code réel (`eligible: true` avec Monuments & Sites) — indépendant de la réforme.

**Point de vigilance transverse :** vu la pause actuelle de Ren0vate (adoption nulle), il serait risqué d'investir du temps de dev sur les primes wallonnes avant d'avoir un signal clair que (a) le conclave de rentrée confirme des montants concrets et (b) Robin décide de sortir de la pause. Ce document sert de base prête à l'emploi pour ce moment-là, pas un chantier à lancer immédiatement.

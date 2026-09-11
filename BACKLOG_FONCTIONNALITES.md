# Backlog fonctionnalités — Ren0vate

*Créé le 11 septembre 2026, suite à investigation de code (pas de suppositions — chaque point cite fichier + ligne). Distinct de `TODO_ROADMAP.md` (roadmap lancement/sécurité/légal, daté du 26/04/2026) : ce document couvre des lacunes produit identifiées sur le cœur métier (collaboration pro, simulateurs primes, catalogue travaux).*

*Mise à jour le 11/09/2026 : points 2, 3 et 4 traités et testés localement (181 tests, 0 régression). Détail des correctifs et des points restants dans chaque section.*

## Légende

- 🔴 Bloquant / promesse déjà faite au client
- 🟠 Priorité haute
- 🟡 Priorité normale
- 🔵 Amélioration structurelle / long terme

---

## 1. 🔴 Messagerie de projet — à créer entièrement

**État actuel : absente.** Aucun modèle `Message`/`ProjectMessage`, aucune migration, aucun controller, aucune vue de fil de discussion.

- `ProjectPermissions#can_post_message?` ([app/models/concerns/project_permissions.rb:20-22](app/models/concerns/project_permissions.rb#L20-L22)) existe mais n'est appelée **nulle part** ailleurs dans le code — permission jamais câblée depuis son introduction (commit `bdcce13`, 27/03/2026).
- Le seul mécanisme de communication réel est **`ProViewsController#notify_client`** ([app/controllers/pro_views_controller.rb:78-100](app/controllers/pro_views_controller.rb#L78-L100)) : envoi à sens unique pro → propriétaire, qui crée une `Notification` (pas un message de conversation). Pas de fil consultable, pas de réponse possible depuis le compte propriétaire. Câblé uniquement côté vue pour le rôle intermédiaire (`app/views/dashboard/intermediaire.html.erb`).
- La promesse "Communiquer via la messagerie du projet" a été retirée le 11/09/2026 de l'email d'invitation pro (`app/views/project_mailer/invitation.html.erb`) en attendant que la fonctionnalité existe réellement.

**À construire :**
1. Modèle `ProjectMessage` (belongs_to project, user ; contenu, timestamps) + migration.
2. Controller + routes (créer/lister par projet, scope aux `ProjectMember` actifs du projet).
3. Vue fil de discussion dans `pro_views/show.html.erb` et dans la vue projet côté propriétaire.
4. Notification email à la création d'un message (réutiliser le pattern `Notification`/`NotificationMailer` existant).
5. Une fois livré : remettre la ligne "Communiquer via la messagerie du projet" dans les 3 blocs de rôle de l'email d'invitation.

---

## 2. ✅ Simulateur de primes Flandre — traité le 11/09/2026

**État actuel : le moins mûr des 3 services régionaux**, mais fonctionnellement correct et déjà maintenu activement (plusieurs correctifs ciblés récents en septembre 2026 : exclusion non-résidentiel réforme 01/03/2026, double comptage `nb_charges`, détection "autre bien", plafonds de groupe murs — **ne pas re-proposer ces points, déjà traités**).

Fichiers concernés : `app/services/regions/flandre/flandre_eligibility_service.rb` (629 lignes), `flandre_category_service.rb` (317 lignes), `flandre_post_login_calculator_service.rb` (861 lignes), `app/controllers/api/flandre_calculations_controller.rb`.

**Lacunes concrètes :**

1. **Incohérence de seuil `habitation_percentage`** entre éligibilité et catégorie — [flandre_eligibility_service.rb:237-241](app/services/regions/flandre/flandre_eligibility_service.rb#L237-L241) accepte tout bien avec `habitation_percentage > 0`, alors que [flandre_category_service.rb:168-169](app/services/regions/flandre/flandre_category_service.rb#L168-L169) exclut tout bien `< 100%`. Un bien à 60% d'habitation passe l'éligibilité puis se fait rejeter à l'étape catégorie.
2. **`sera_domicilie?` dupliquée avec des règles différentes** — [flandre_eligibility_service.rb:468-501](app/services/regions/flandre/flandre_eligibility_service.rb#L468-L501) reconnaît 4 variantes de champ (`residence_principale`, `hoofdverblijfplaats`, `domicilie_flandre`, `adresse_principale`) ; [flandre_category_service.rb:185-199](app/services/regions/flandre/flandre_category_service.rb#L185-L199) n'en reconnaît que 2. Résultat incohérent pour la même donnée `occupation`.
3. **~250 lignes de code mort** dans `FlandrePostLoginCalculatorService` — au moins 9 méthodes privées jamais appelées (`calculate_dynamic_prime`, `calculate_forfait_prime`, `calculate_surface_prime`, `calculate_facture_prime`, `calculate_montant_prime`, `calculate_montant_facture_prime`, `calculate_montant_variable_m2_prime`, `build_prime_data`, `determine_category_key`), plus `apply_group_ceiling` (lignes 105-109) qui est un no-op gardé "par compatibilité".
4. **Aucun test sur `FlandrePostLoginCalculatorService`** — le service qui calcule les montants réellement affichés à l'utilisateur n'a aucune couverture (plafonds de groupe, prime Amiante, cas limites catégorie 1/2 vs 3/4).
5. **Logique métier hardcodée en Ruby plutôt qu'en config/DB** — plafonds de groupe, tarifs Amiante (8€/12€/4€ au m²), seuils de revenu par catégorie : toute évolution réglementaire nécessite un déploiement plutôt qu'une mise à jour de données.
6. **`check_eligibility_post_login` : méthode de ~140 lignes**, 15 vérifications séquentielles, seulement 5 couvertes par les tests actuels (`travaux_isolation_chauffage?`, `possede_autre_bien?`, `certificat_peb_e_f?`, `est_client_protege?` non testées isolément).

**Traité (commit `fee1c06`, mergé le 11/09/2026) :**
1. ✅ `Regions::Flandre::CommonEligibilityChecks` extrait, `sera_domicilie?` unifiée. **Corrige au passage un bug réel** : `FlandreCategoryService` cherchait un champ `domicile_principal` qui n'a jamais existé (faux ami avec `domicilie_flandre`, le champ réellement soumis par le formulaire) — ce garde-fou était inopérant en pratique.
2. ✅ ~250 lignes de code mort supprimées dans `FlandrePostLoginCalculatorService` (confirmé par grep exhaustif y compris `send`/`public_send`). La vraie logique de plafonnement par groupe (`plafonds_par_groupe`, `apply_group_ceilings_to_all`) n'a pas été touchée — seul le stub no-op `apply_group_ceiling` (singulier) a été retiré.
3. ✅ Tests ajoutés : `test/services/regions/flandre_post_login_calculator_service_test.rb` (10 tests — plafonds de groupe, prime Amiante, cas limite catégories 1-2 vs 3-4).
4. ✅ Incohérence `habitation_percentage` corrigée : rejetée dès l'étape éligibilité (pas seulement à l'étape catégorie), avec le bon message de réforme.
5. 🔵 Non fait (reste en backlog, moindre priorité) : migrer seuils/plafonds hardcodés (Amiante, revenus par catégorie) vers une config pilotable sans déploiement.

**Bonus traité le même jour — doublon Property/Project sur la question démolition/TVA 6%** (commit `3e2b3bb`) : `Property#reconstruit` et `Project#reconstruction_demolition`/`tva_reduit_6_pourcent` posaient la même question à deux endroits. Seul le champ Project alimentait le calcul d'éligibilité réel — et **2 biens en prod avaient des réponses contradictoires** entre les deux (Property "oui" / Project "false"), corrigés manuellement en base (Project #524, #532). La question n'est plus posée qu'au niveau du projet ; la colonne `properties.reconstruit` est conservée (historique) mais retirée de tout usage actif.

**Reste ouvert** : `usage_non_residentiel?` reste dupliquée entre `flandre_eligibility_service.rb` et `flandre_category_service.rb` (candidate naturelle pour une future extraction dans le même concern partagé).

---

## 3. ✅ Persistance des simulations de financement — Bruxelles traité le 11/09/2026

**Wallonie : complet.** `SimulationsController#perform_primes_calculation`/`#update_prime_inputs` (branche `wallonie`) et `save_wallonie_specific_data` persistent `total_simule` **et** le détail (`parameters['prime_cards']`, saisies, montants calculés). `restore_prime_inputs` sait relire pour repeupler l'UI après reload. Le régime `reduction_pret` (post 01/10/2026) a son propre pipeline, également complet.

**Flandre : complet.** Même schéma : `save_flandre_specific_data` persiste `prime_cards`, `peb_data`, `amiante_data`. `restore_prime_inputs` a sa branche dédiée.

**Bruxelles : partiel — le plus faible des trois.**
- Seul le **total agrégé** est persisté via `SimulationsController#save_total` ([simulations_controller.rb:510-524](app/controllers/simulations_controller.rb#L510-L524)), en debounce côté client.
- `perform_category_determination` a un garde explicite `return unless … ['wallonie', 'flandre'].include?(region)` ([simulations_controller.rb:870](app/controllers/simulations_controller.rb#L870)) — la catégorisation n'est jamais déclenchée pour Bruxelles.
- `update_prime_inputs` a bien une branche `bruxelles` (lignes 345-377) qui appelle `BruxellesPostLoginCalculatorService#calculate_all_primes`, mais elle ne fait que `update!(total_simule: ...)` — **aucun `save_bruxelles_specific_data`** équivalent à Wallonie/Flandre, alors que le service renvoie déjà `prime_results` structuré (donnée disponible, juste jamais écrite).
- Sur les 4 cartes Bruxelles, seule **"Communes"** persiste sa sélection (via `bruxelles_communales`). **Petit Patrimoine** et **Monuments & Sites** ne sauvegardent ni ne restaurent rien — au reload, tous leurs champs repartent à zéro, seul le total agrégé reste (orphelin, sans composition retrouvable).
- Conséquence visible : `Simulation#primes_count` ne lit que `parameters['prime_cards']`, jamais alimenté pour Bruxelles → **le badge "X primes" de la page "Mes simulations" affiche toujours 0 pour Bruxelles**, même avec un total non nul.
- Code mort associé : `partials_bruxelles/_category_step.html.erb` et `_eligibility_step.html.erb` ne sont jamais rendus (commentaire explicite dans `_region_content.html.erb:37`) ; cible Stimulus `data-bruxelles-simulation-target` sans contrôleur JS correspondant.

**Traité (commit `e114a35`, mergé le 11/09/2026) :**
1. ✅ `save_bruxelles_specific_data` ajoutée (symétrique Wallonie/Flandre), appelée depuis `update_prime_inputs` avec `result[:prime_results]` — construit `parameters['prime_cards']` au même format que les 2 autres régions.
2. ✅ Inputs Petit Patrimoine et Monuments & Sites désormais persistés et restaurés (extension de `save_total`, même mécanisme que Communes).
3. ✅ Branche `bruxelles` ajoutée dans `restore_prime_inputs`.
4. ✅ Code mort supprimé : `_category_step.html.erb`/`_eligibility_step.html.erb` (jamais rendus, confirmé par grep), cible Stimulus orpheline `data-bruxelles-simulation-target` retirée.
5. 🔵 Non fait (reste en backlog) : remplacer le blob `parameters` par une structure normalisée pour les 3 régions.

**⚠️ Bug pré-existant découvert en cours de route, non corrigé (hors périmètre persistance) :** `Regions::Bruxelles::BruxellesPostLoginCalculatorService#calculate_amount_with_user_input`/`#calculate_precise_amount` appellent `prime.type_calcul`, colonne qui **n'existe pas** sur la table `primes` (seul `type_de_valeur` existe). Tout `Prime` réel avec `valeurs_par_categorie` renseigné pour la catégorie demandée ferait planter `calculate_all_primes` en `NoMethodError`. Ne se déclenche pas aujourd'hui car les primes Renolution sont décommissionnées (`eligible: false`), mais **à corriger avant toute UI Bruxelles générique** (le circuit `update_prime_inputs`/cartes génériques n'est d'ailleurs pas câblé côté vue actuellement — seules Communes/Petit Patrimoine/Monuments & Sites, en dur, le sont).

---

## 4. ✅ Compléter les `work_type` — traité le 11/09/2026

**État actuel :** `app/models/work_type.rb` — pas un modèle ActiveRecord, une classe PORO avec catalogue en dur (`CATALOGUE_BELGIQUE`, 8 catégories / 31 postes), + un doublon quasi-identique `CATALOGUE_ESPAGNE` maintenu manuellement en parallèle.

**Catalogue actuel :**
- **Toiture** : isolation, remplacement, charpente, couverture, étanchéité, collecte eaux pluie, velux, échafaudage
- **Murs & Façades** : isolation ext/int/coulisse, enduits, ravalement
- **Châssis & Ouvertures** : PVC/alu/bois, store isolant, porte d'entrée
- **Sol & Structure** : isolation plancher, structure sol, carrelage, parquet, assèchement sous-sol
- **Énergie & Chauffage** : PAC air-eau/air-air, chaudière condensation, chauffe-eau thermo, plancher chauffant, radiateurs, panneaux solaires, batterie stockage, poêle à pellets
- **Ventilation** : type C, C+, double flux, carte régulation
- **Pièces de vie** : salle de bain, cuisine, peinture, faux plafond
- **Technique** : électricité conformité, plomberie, escalier, désamiantage, détection incendie, retrait citerne mazout

**Catégories entièrement absentes :**
- Gros-œuvre / structure : démolition, extension/agrandissement, surélévation, murs porteurs, fondations
- Extérieur / aménagements : terrasse, allée, clôture/portail, garage/carport, jardin, piscine
- Accessibilité PMR : rampe d'accès, monte-escalier, ascenseur privatif
- Assainissement : fosse septique, raccordement égouts
- Domotique / mobilité électrique : maison connectée, borne de recharge véhicule électrique (IRVE)
- Audit énergétique/PEB en tant que poste facturable (aujourd'hui seulement source de données pour `BudgetEstimatorService`, pas un item de devis)

**Postes manquants dans des catégories existantes :** portes intérieures, volets roulants/battants (distinct du store isolant), cheminée/insert bois, climatisation split, gouttières/zinguerie en poste dédié, isolation acoustique, aménagement combles/cave en espace habitable.

**Point d'attention important — travail en parallèle nécessaire :**
- `Quotes::Calculator`, `QuoteItem`/`Quote`, `QuotesController` + vues lisent le catalogue **dynamiquement** — aucune modification requise pour eux.
- **`BudgetEstimatorService` n'itère pas le catalogue** : ses règles (PEB, âge bâtiment, regex description) référencent des `work_type_key` codés en dur (`add(s, 'isolation_toiture', ...)`). Ajouter un poste à `CATALOGUE_BELGIQUE` ne le fera **jamais** apparaître dans les suggestions automatiques sans règle de détection dédiée.
- **`BudgetOptimiseurService`** a une liste séparée en dur `ITEMS_PETROLIERS` (postes sensibles au pétrole) à mettre à jour manuellement pour tout nouveau poste concerné.
- **Aucun simulateur de primes régional ne référence `WorkType`** — le catalogue ne sert qu'aux devis/estimation budgétaire, pas à l'éligibilité primes. Pas d'impact simulateurs, mais à garder en tête si on veut un jour relier les deux mondes.

**Checklist pour tout ajout de work_type :**
1. Ajouter dans `CATALOGUE_BELGIQUE`
2. Ajouter le miroir dans `CATALOGUE_ESPAGNE` (sinon `WorkType.find` renvoie `nil` côté Espagne et casse silencieusement les devis espagnols)
3. Nouvelle catégorie → entrée dans `CATEGORIES`
4. Règle de détection dans `BudgetEstimatorService` si suggestion automatique voulue
5. Entrée dans `ITEMS_PETROLIERS` (`BudgetOptimiseurService`) si poste sensible aux cours pétroliers

**Traité (commit `b4ce3e5`, mergé le 11/09/2026) :** 28 nouveaux postes ajoutés (BE + ES en miroir) — les 5 nouvelles catégories et les 10 postes complémentaires listés ci-dessus. `BudgetEstimatorService` étendu avec des règles de détection par description pour les postes pertinents. `BudgetOptimiseurService::ITEMS_PETROLIERS` complété (`isolation_acoustique`).

**⚠️ Écart pré-existant repéré en cours de route, non corrigé (hors périmètre) :** la catégorie `ventilation` est totalement absente de `CATALOGUE_ESPAGNE` (`ventilation_type_c`, `ventilation_c_plus`, `carte_regulation_ventilation` n'existent qu'en Belgique), et `ventilation_double_flux` y est classée par erreur sous `'energie'` au lieu de `'ventilation'`. À corriger si un vrai miroir strict BE/ES est nécessaire pour les devis espagnols.

---

## Ordre de traitement suggéré

```
Fait le 11/09/2026 : 2. Flandre · 3. Bruxelles (persistance) · 4. work_type
  + bonus : doublon Property/Project démolition-TVA 6% (2 biens en prod corrigés)

Reste ouvert :
  → ⚠️ Bug Bruxelles prime.type_calcul (point 3) — à corriger avant toute UI Bruxelles
    générique, même si non déclenché aujourd'hui (primes Renolution décommissionnées)
  → 1. Messagerie — MVP (fil simple + email) quand priorisé
  → 🔵 Long terme : blob `parameters` → structure normalisée (3 régions)
  → 🔵 Long terme : seuils/plafonds Flandre hardcodés → config pilotable sans déploiement
  → Écart catalogue Espagne ventilation (point 4) — mineur, à corriger si devis ES actifs
```

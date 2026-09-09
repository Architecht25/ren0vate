# Checklist — Jour du lancement commercial

Opérations à effectuer le jour de la mise en vente (commercialisation publique).

---

## Monitoring & Observabilité

### Sentry (tracking d'erreurs)
- [x] ✅ Résolu le 09/09/2026 — compte créé sous `robin@architecht.be`, région EU/Allemagne (`ingest.de.sentry.io`, aucun transfert hors UE). `SENTRY_DSN` configuré sur Heroku (`heroku releases`: v983). Testé via `Sentry.capture_message` (`heroku run`) : event visible dans le dashboard (`RUBY-RAILS-1`) et email d'alerte reçu — chaîne complète validée. Ajouté au registre RGPD (`RGPD_REGISTRE_ACTIVITES.md`, Traitement 9).

### Plausible Analytics (trafic cookieless)
- [ ] Créer un compte sur [plausible.io](https://plausible.io)
- [ ] Ajouter le site `ren0vate.be`
- [ ] Aucune action Heroku — le script est déjà injecté en production (data-domain="ren0vate.be")

### UptimeRobot (monitoring uptime)
- [ ] Créer un compte sur [uptimerobot.com](https://uptimerobot.com) — plan gratuit (50 monitors, check /5 min)
- [ ] **Add New Monitor** :
  - Type : HTTP(s)
  - Friendly Name : `Ren0vate Production`
  - URL : `https://ren0vate.be/up`
  - Interval : 5 minutes
- [ ] Ajouter une Alert Contact → email `robin@architecht.be`
- [ ] (Optionnel) Activer la **Status Page** publique pour partager aux utilisateurs en cas d'incident

---

## Infrastructure

### Ruby upgrade
- [ ] Mettre à jour rbenv : `rbenv update` puis `rbenv install 3.3.11`
- [ ] Mettre à jour `.ruby-version` : remplacer `3.3.9` par `3.3.11`
- [ ] Mettre à jour `Gemfile` : `ruby "3.3.11"`
- [ ] `bundle install` puis tester localement
- [ ] Déployer sur Heroku

---

## RGPD — Conformité administrative

### DPO / Contact RGPD → APD belge
- [~] En cours le 09/09/2026 — inscription volontaire sur le portail pro de l'APD, gestion d'un dossier DPO en cours par Robin
  - Nom : Robin du Parc *(corrigé — "Robin Dupont" était une erreur dans cette doc depuis mai 2026)*
  - Email : robin@architecht.be
  - Entité : ArchiTecht SRL — BCE BE 1020.345.473
  - *(Pas d'obligation stricte art. 37 à ce stade, mais faite sur base volontaire)*
  - **Précision RGPD (confirmée le 09/09/2026)** : il n'existe **aucune obligation générale de déclaration des traitements auprès de l'APD** depuis le RGPD (2018) — c'était le régime de l'ancienne Commission de la Vie Privée, aboli. Le RGPD fonctionne en *accountability* (conformité démontrable en interne, contrôle a posteriori de l'APD), pas en enregistrement préalable. Le seul point réel est la **notification à l'APD des coordonnées du DPO**, obligatoire uniquement si un DPO est désigné (art. 37 — cas non applicable à Ren0vate : pas de suivi systématique à grande échelle ni de traitement à grande échelle de données sensibles) — et c'est bien cette notification-là, faite volontairement, qui est en cours ci-dessus. Aucune autre "déclaration APD" à faire.

### Médiation consommateur (Service de Médiation pour le Consommateur)
- **Précision confirmée le 09/09/2026** : le chiffre "~150€/an" ci-dessous était erroné — origine tracée par `git blame` à une session Claude du 11/05/2026 (commit `536e1a2`, non sourcé), probablement une confusion avec le système français (marché de médiateurs privés payants type CM2C/CNPM, qui n'existe pas en Belgique). En Belgique il n'y a **pas de frais d'adhésion annuelle** : le Service de Médiation pour le Consommateur (SMC, entité publique résiduaire) est gratuit à l'inscription, coût uniquement par dossier traité (100€ à partir du 5ᵉ dossier clos/an, 200€ à partir du 20ᵉ, montants indexés). Aucun médiateur sectoriel privé (SaaS/rénovation) identifié parmi les entités qualifiées belges — le SMC est donc compétent par défaut, sans démarche payante.
- [x] ✅ Confirmé le 09/09/2026 — pas de démarche d'adhésion payante requise. L'obligation légale réelle (Livre XVI Code de droit économique) est d'**informer le client** du service de médiation compétent, coordonnées visibles dans les CGU/CGV et sur le site.
- [x] Lien ODR (`https://ec.europa.eu/consumers/odr/`) et coordonnées du Service de Médiation belge présents dans les CGU (`terms.html.erb` — confirmé le 04/09/2026)

### Anthropic — transfert compte
- [x] ✅ Résolu le 09/09/2026 — vérifié directement dans Claude Console (Paramètres → Organisation) : organisation "ArchiTECHt", adresse ArchiTecht SRL, TVA BE1020345473. Transfert effectif, plus de trace Primes-Services. Pas de confirmation écrite d'Anthropic reçue en réponse aux relances du 11/30 mai 2026, mais la vérification directe est suffisante.

---

## Assurances

**Cadrage confirmé le 09/09/2026** : les deux couvertures se complètent — la RC Pro couvre les dommages causés à un client par une erreur/négligence du service (ex. calcul de prime erroné qui fait perdre une subvention à un utilisateur), la cyber couvre une fuite de données ou une attaque (rançongiciel, piratage de comptes) — particulièrement pertinent puisque Ren0vate stocke des données personnelles et documents sensibles (revenus, composition de ménage, IBAN, numéro national).

- RC Pro **pas légalement obligatoire** pour une SaaS (pas une profession réglementée comme architecte/comptable), mais quasi systématiquement exigée par les clients B2B et fortement recommandée en B2C vu les enjeux financiers pour les utilisateurs.
- Budget indicatif petite structure tech en Belgique : RC Pro seule ~300-800€/an, cyber seule ~200-600€/an, ou contrat combiné RC Pro + Cyber packagé tech (plafonds modulables, de 100k€ à plusieurs millions).
- Chercher un courtier avec une pratique **tech/cyber** plutôt qu'un généraliste : Vanbreda Risk & Benefits et Aon ont des départements dédiés (plutôt PME/grandes structures) ; Yago propose des devis en ligne pour un profil starter/PME ; BECI (réseau bruxellois d'entreprises) peut orienter vers un courtier local.
- **À clarifier avec le courtier** : quelle entité assurer — ArchiTecht SRL, qui porte l'IP et exploite commercialement Ren0vate.

- [ ] Contacter un courtier spécialisé Tech/SaaS (Vanbreda, Aon, Yago, ou via BECI) pour souscrire :
  - **RC Professionnelle** — extension "conseils et informations erronés", plafond ≥ 1 M€ si possible dans le budget indicatif ci-dessus
  - **Cyber assurance** — notification APD, frais juridiques, restauration données, plafond ≥ 500 k€
  - ⚠️ Mentionner explicitement le traitement de données AER (revenus fiscaux) dans le dossier de souscription — obligatoire sous peine de nullité de la garantie
  - Préciser qu'ArchiTecht SRL est l'entité à assurer

---

## Notes
- Le health-check endpoint `/up` est déjà en prod — UptimeRobot peut être configuré dès maintenant si souhaité
- Plausible est entièrement prêt côté code, il attend juste son compte externe
- Sentry : ✅ résolu le 09/09/2026 — compte créé, DSN configuré sur Heroku, testé de bout en bout (dashboard + email d'alerte)
- Transfert compte Anthropic → ArchiTecht SRL : ✅ résolu le 09/09/2026 (vérifié directement dans Claude Console, pas via confirmation écrite d'Anthropic)

---

## Post-lancement (hors scope octobre 2026)

- **Export UBL/Billit** (facturation électronique B2B belge) — concerne uniquement les clients B2B assujettis TVA. Majoritairement B2C au lancement, à intégrer quand les premiers clients entreprises arrivent.
- Ruby 3.3.11 — upgrade mineur, non bloquant
- LogRocket — session replay, après stabilisation
- **Google Ads / Meta Ads** — à activer au lancement octobre 2026, une fois la base utilisateurs et le contenu établis.
- **Partenariats (Ordre des Architectes, EMBUILD, CIB)** — prospection à lancer octobre 2026.

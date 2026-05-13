# Analyse juridique Ren0vate — Lancement commercial
**Date de l'analyse : 11 mai 2026** *(mise à jour)*
**Rédigée par : GitHub Copilot / Claude Sonnet (IA), à valider par un conseiller juridique humain)**
**Société : ArchiTecht SRL — BCE BE 1020.345.473**

---

## 1. Identité légale officielle

| Champ | Valeur |
|---|---|
| Dénomination | ArchiTecht SRL |
| BCE | BE 1020.345.473 |
| N° TVA | BE1020345473 (actif depuis 01/03/2025) |
| Siège social | Clos Charles Bailly 16, 1310 La Hulpe |
| Administrateur | Robin du Parc Locmaria |
| Date de constitution | 24/02/2025 |
| Forme juridique | SRL (Besloten Vennootschap) |
| Juridiction compétente | Tribunaux de l'arrondissement judiciaire du Brabant wallon (La Hulpe) |

---

## 2. Fichiers légaux — état après mise à jour

### 2.1 Mentions légales (`/app/views/pages/legal.html.erb`)
✅ **Complété** — v5.1 (mai 2026) — 10 articles couvrant :
- Identité complète de l'éditeur (BCE, TVA, siège, administrateur)
- Hébergeur : Heroku (Salesforce) — Irlande (Dublin)
- Disclaimer IA — alerte rouge : les agents IA ne sont pas des avocats
- Section AI Act : classification système IA à haut risque (secteur immobilier/financier)
- Compétence : tribunaux du Brabant wallon
- Droit applicable : droit belge
- **§3 mis à jour (mai 2026)** : mention de l'espace collaboratif intermédiaires/courtiers, système de referral token, tableau de bord multi-client professionnel

### 2.2 Politique de confidentialité (`/app/views/pages/privacy.html.erb`)
✅ **Complétée** — v5.1 (mai 2026) — 14 sections couvrant :
- Responsable du traitement (ArchiTecht SRL, coordonnées complètes)
- Table des finalités avec base légale (art. 6 RGPD) par traitement
- **Section 5.2 — données réellement envoyées à Anthropic** (voir §4 ci-dessous)
- Table des sous-traitants : Heroku EU, Stripe (DPF), Anthropic (SCC), AWS EU
- Transferts hors UE — SCC Anthropic et Stripe
- Profilage et décision automatisée (art. 22 RGPD)
- Droits des personnes (accès, rectification, effacement, opposition, portabilité)
- Cookies Stripe
- Rétention granulaire par catégorie de données
- Contact DPO : robin@architecht.be
- **Mises à jour mai 2026** :
  - §2.1 : ajout de `professional_type`, N° BCE/TVA (vérification VIES), `referral_token` dans les données collectées
  - §3 table : 2 nouvelles lignes (vérification BCE/VIES, gestion invitations ProjectMember)
  - §5.2 (d) : section "Assistant IA Professionnel" — contexte portefeuille sans données personnelles client, jamais d'AER/revenus/IBAN
  - §10 : mis à jour pour couvrir le flux referral et l'accès bidirectionnel pro ↔ client

### 2.3 Conditions générales de vente (`/app/views/pages/terms.html.erb`)
✅ **v1.2** (mai 2026) — 17 articles couvrant :

**Plans tarifaires :**
| Segment | Plan | Prix TTC/mois |
|---|---|---|
| B2C | Starter | 0 € |
| B2C | Propriétaire | 39 € |
| B2C | Investisseur | 89 € |
| B2C | Premium | 149 € |
| B2B | Pro | 99 € |
| B2B | Entreprise | 299 € |

**Contenu :**
- Droit de rétractation 14 jours (B2C) + formulaire type annexé
- Résiliation et export des données (délai 30 jours)
- **Article 10 — Intelligence Artificielle** (6 sous-sections) : disclaimer conseil non-avocat, alerte rouge, limites de responsabilité IA
- Licences Contenu Utilisateur
- SLA 99,5 % disponibilité
- Médiation consommateur
- **Art. 3bis (ajouté mai 2026) — Comptes Professionnels** :
  - §3bis.1 : inscription et `professional_type` (architect/entrepreneur/intermediary)
  - §3bis.2 : système de referral token — génération, utilisation, lien d'invitation client
  - §3bis.3 : périmètre d'accès du pro (projets acceptés uniquement, sans données financières client)
  - §3bis.4 : responsabilité du professionnel vis-à-vis de ses clients
- **Définitions enrichies** : Compte Professionnel, Intermédiaire/Courtier en primes, Lien d'invitation Pro, ProjectMember

### 2.4 Routes et contrôleur
✅ Route ajoutée : `GET /conditions-generales → pages#terms`
✅ Action `terms` ajoutée dans `pages_controller.rb`

### 2.5 Footer `home.html.erb`
✅ Corrections :
- Titres des colonnes en `text-arch-orange` (couleur identitaire de l'app)
- `text-muted` → `text-light` / `text-white` (lisibilité sur fond sombre)
- `text-white-50` → `text-white` (régions)
- Lien CGV ajouté dans la colonne "Informations légales"
- Copyright mis à jour : `© 2026 Ren0vate — ArchiTecht SRL`

---

## 3. Infractions préexistantes corrigées

| Infraction | Gravité | Statut |
|---|---|---|
| Absence totale de CGV | 🔴 Critique | ✅ Corrigé |
| Absence de BCE / TVA dans les mentions légales | 🔴 Art. VI.8 CDE | ✅ Corrigé |
| Fausse déclaration "aucun transfert hors UE" | 🔴 Art. 13 RGPD | ✅ Corrigé |
| OpenAI mentionné comme sous-traitant (faux) | 🟠 Erreur factuelle | ✅ Corrigé |
| Agents IA présentés sans disclaimer juridique | 🟠 Risque exercice illégal du droit | ✅ Corrigé |
| Droit de rétractation absent | 🟠 Directive 2011/83/UE | ✅ Corrigé |
| Données de profilage non déclarées (art. 22) | 🟠 RGPD | ✅ Corrigé |

---

## 4. Constat critique — Données envoyées à Anthropic (USA)

### 4.1 Ce qui est réellement transmis dans chaque prompt Claude

Le service `ContextualBotService` envoie à chaque message le contexte complet suivant :

**Données d'identification :**
- Prénom, nom, email, téléphone, adresse postale complète, région

**Données fiscales (très sensibles) :**
- `revenu_demandeur` — revenu imposable individuel
- `revenu_conjoint` — revenu imposable du conjoint
- `revenu_imposable_global` extrait du **document AER officiel** (avertissement-extrait de rôle)
- `annee_revenus` — année fiscale de référence
- `type_declaration` — isole / couple / isole_avec_enfant

**Données sociales :**
- `bim` / `ris` — statut bénéficiaire intervention majorée / revenu d'intégration
- `client_protege_bruxelles`
- `nombre_enfants`, `femme_enceinte`, `personnes_60_ans_et_plus`
- `situation_familiale`

**Données financières :**
- IBAN belge (7 premiers caractères + masque `****`)
- Valeur d'achat du bien, dates de facturation, montants de devis et factures

**Données immobilières :**
- Adresse, PEB, EAN, numéro cadastral, type de bien, surface, chauffage
- Données des chantiers : architectes, entrepreneurs, N° TVA, certifications
- Résultats de simulations de primes (montants, éligibilité, catégories)

**Historique :**
- Jusqu'à 20 messages conservés 2h dans `Rails.cache`

### 4.2 Ce qui protège actuellement
- HTTPS TLS en transit ✅
- API Anthropic : les données ne servent pas à entraîner les modèles (API usage policy) ✅
- Historique effacé automatiquement après 2h ✅
- Sessions authentifiées uniquement ✅

### 4.3 Ce qui manque (risques ouverts)

| Risque | Gravité | Action requise |
|---|---|---|
| Pas de DPA signé avec Anthropic (art. 28 RGPD) | 🔴 Critique | Signer avant lancement |
| Pas de consentement explicite utilisateur pour l'envoi AER/revenus à Anthropic | 🔴 Art. 13 + 7 RGPD | Checkbox activation chatbot |
| Données non pseudonymisées avant envoi | 🟠 Bonne pratique RGPD | Implémenter tranches de revenus |
| Photos de chantier avec personnes identifiables envoyées à Anthropic | 🟠 Art. 9 (données biométriques potentielles) | Information utilisateur |
| Absence de mention spécifique dans le formulaire de collecte AER | 🟠 Art. 13 RGPD | Ajouter notice à l'upload AER |

---

## 5. Actions restantes avant lancement commercial

> **Synthèse (mai 2026)** — Le transfert Anthropic est le seul vrai bloquant dur avant le premier client payant. La notice AER est simple à ajouter (une ligne dans le formulaire d'upload). Le DPO peut être l'administrateur (Robin) dans un premier temps — à formaliser avant de dépasser ~250 clients actifs.

### 5.1 Priorité immédiate (bloquant lancement)

- [~] **Transférer le compte Anthropic vers ArchiTecht SRL** — Email envoyé à privacy@anthropic.com le 11 mai 2026 — ⏳ *En attente de confirmation écrite à conserver dans le dossier conformité*
- [ ] **Nommer un DPO / contact RGPD + déclaration APD belge** — à faire le jour de la commercialisation (voir `docs/CHECKLIST_LANCEMENT.md`)

### 5.2 Priorité haute (avant ou juste après lancement)

- [x] **Pseudonymiser les données avant envoi à Anthropic** ✅ *Implémenté dans `contextual_bot_service.rb`*
  - Revenus exacts → tranches calées sur seuils belges (9 tranches de `< 15 000 €` à `> 80 000 €`)
  - Montants travaux/devis/factures → tranches `amount_bracket` (11 tranches de `< 1 000 €` à `> 250 000 €`)
  - IBAN → boolean `Oui/Non` uniquement
  - Nom complet + email + téléphone → supprimés (prénom seul + ID hash SHA256)
  - Adresse exacte → code postal + commune uniquement
  - EAN + numéro cadastre → `Renseigné/Non renseigné`
  - Noms architecte/entrepreneur → `Renseigné` + certifications uniquement
  - N° TVA entrepreneur → boolean `Enregistrée: Oui/Non`
- [x] **Checkbox consentement chatbot** ✅ *Implémentée dans `_contextual_bot.html.erb` + `contextual_bot_controller.js`* — panneau de consentement affiché à la première ouverture, consentement stocké en `localStorage` (`rn0_ia_consent_v1`).
- [x] **Notice à l'upload AER** ✅ *Implémentée dans `documents/new.html.erb`* — l'utilisateur est informé que le revenu extrait sera utilisé en tranche anonymisée dans l'assistant IA, avec lien vers la politique de confidentialité.
- [x] **Avertissement avant upload photo ChantierVision** ✅ *Modal de consentement ajouté dans `_vision_analysis.html.erb`* — affiché à la première analyse, consentement stocké en `localStorage` (`rn0_vision_consent_v1`), information sur le transfert USA + SCC.

### 5.3 Priorité normale (dans les 3 mois post-lancement)

- [x] **Registre des activités de traitement** (art. 30 RGPD) ✅ *Rédigé dans `Documents_strategiques/RGPD_REGISTRE_ACTIVITES.md`* — 7 traitements documentés.
- [x] **Analyse d'impact (AIPD / DPIA)** (art. 35 RGPD) ✅ *Ébauche initiale dans `Documents_strategiques/RGPD_DPIA.md`* — à réviser avant 250 utilisateurs actifs.
- [x] **Politique de conservation et suppression automatique** ✅ *`DataRetentionJob` créé* — anonymisation trimestrielle des comptes inactifs > 2 ans (1er janv., avr., juil., oct. à 3h).
- [ ] Audit de sécurité annuel (OWASP Top 10 — déjà partiellement couvert par Brakeman)
- [ ] Affiliation organisme de médiation consommateur (CPMA / ODR belge)

---

## 6. Architecture IA — récapitulatif des flux de données

```
Utilisateur (propriétaire)
    │
    ├─ Chat IA ──────────────────────► Anthropic API (Claude Haiku/Sonnet)
    │   Données : profil complet,      USA — SCC — données pseudonymisées ✅
    │   AER, revenus, BIM, IBAN        (tranches revenus, hash ID, CP seul)
    │
    ├─ Photos chantier ──────────────► Anthropic API (Claude Sonnet Vision)
    │   Données : photos brutes        USA — SCC — max 6 photos
    │   (personnes potentiellement
    │   identifiables)
    │
    ├─ Hub de décision ──────────────► Anthropic API (Claude Sonnet)
    │   Données : simulation primes,   USA — SCC
    │   revenus, catégorie éligibilité
    │
    ├─ Budget estimator ─────────────► Aucun envoi externe
    │   (purement algorithmique)       Calcul local Rails ✅
    │
    └─ Paiements ────────────────────► Stripe (EU-US DPF)
        Données : identité, facturation  Infrastructure UE disponible

Utilisateur professionnel (architect / entrepreneur / intermediary)
    │
    └─ Chat IA Pro ──────────────────► Anthropic API (Claude Haiku/Sonnet)
        Données : portefeuille projets  USA — SCC — ⚠️ JAMAIS de données
        acceptés (état avancement,      personnelles client (pas d'AER,
        types de travaux, communes),    pas de revenus, pas d'IBAN)
        professional_type, N° BCE       Contexte limité au niveau projet
        ✅ Séparation stricte : le pro ne voit jamais les données financières
           ou fiscales des clients via le chatbot
```

---

## 7. Risques résiduels à surveiller

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Fuite via API Anthropic | Faible | Très élevé | DPA + pseudonymisation ✅ |
| Plainte APD (données AER sans consentement explicite) | Faible | Élevé | Checkbox consentement chatbot ✅ |
| Exercice droit d'effacement par utilisateur | Modérée | Modéré | Procédure documentée (30j) |
| Photos avec personnes identifiables (art. 9) | Modérée | Élevé | Avertissement avant upload |
| Non-conformité clause médiation | Faible | Modéré | Affiliation organisme ODR |

---

## 8. Références réglementaires appliquées

- **RGPD** (UE 2016/679) — art. 6, 7, 13, 17, 21, 22, 28, 30, 35, 44–49
- **Code de droit économique belge** — art. VI.8 (mentions obligatoires site web)
- **Directive 2011/83/UE** — droit de rétractation 14 jours B2C
- **AI Act** (UE 2024/1689) — systèmes IA à haut risque (Annexe III — immobilier/crédit)
- **Décision SCC** 2021/914/UE — clauses contractuelles types transferts hors UE
- **EU-US Data Privacy Framework** — décision d'adéquation 10 juillet 2023 (Stripe)
- **Loi belge du 30 juillet 2018** — protection des données à caractère personnel

---

---

## 9. Historique des mises à jour

| Date | Auteur | Modifications |
|---|---|---|
| 8 avril 2026 | GitHub Copilot (IA) | Création initiale — mentions légales, CGV, privacy, RGPD IA |
| 18 avril 2026 | GitHub Copilot (IA) | Mise à jour statuts : pseudonymisation Anthropic ✅, checkbox consentement ✅, flux IA corrigé, risques mis à jour |
| 11 mai 2026 | Claude Sonnet (IA) | CGV v1.2 — Art. 3bis (comptes pro), tarifs B2B corrects (Pro 99€ / Entreprise 299€), noms plans B2C corrigés ; RGPD v5.1 — données BCE/VIES, referral_token, Pro chatbot section 5.2(d) ; Mentions légales v5.1 — §3 intermédiaires/courtiers ; §6 flux IA Pro ajouté (portefeuille sans PII client) |

---

*Document à mettre à jour à chaque évolution majeure de l'architecture IA ou des traitements de données.*
*À faire valider par un avocat spécialisé RGPD avant le lancement commercial officiel.*

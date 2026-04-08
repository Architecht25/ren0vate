# Analyse juridique Ren0vate — Lancement commercial
**Date de l'analyse : 8 avril 2026**
**Rédigée par : GitHub Copilot (IA), à valider par un conseiller juridique humain)**
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
✅ **Complété** — 10 articles couvrant :
- Identité complète de l'éditeur (BCE, TVA, siège, administrateur)
- Hébergeur : Heroku (Salesforce) — Irlande (Dublin)
- Disclaimer IA — alerte rouge : les agents IA ne sont pas des avocats
- Section AI Act : classification système IA à haut risque (secteur immobilier/financier)
- Compétence : tribunaux du Brabant wallon
- Droit applicable : droit belge

### 2.2 Politique de confidentialité (`/app/views/pages/privacy.html.erb`)
✅ **Complétée** — 14 sections couvrant :
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

### 2.3 Conditions générales de vente (`/app/views/pages/terms.html.erb`)
✅ **Créées de zéro** — 16 articles couvrant :
- Table des 5 plans tarifaires (Freemium 0€ / Propriétaire 39€ / Investisseur 89€ / Expert 149€ / Platform 299€ TTC)
- Droit de rétractation 14 jours (B2C) + formulaire type annexé
- Résiliation et export des données (délai 30 jours)
- **Article 10 — Intelligence Artificielle** (6 sous-sections) : disclaimer conseil non-avocat, alerte rouge, limites de responsabilité IA
- Licences Contenu Utilisateur
- SLA 99,5 % disponibilité
- Médiation consommateur

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

### 5.1 Priorité immédiate (bloquant lancement)

- [ ] **Transférer le compte Anthropic vers ArchiTecht SRL** ⚠️ *Situation actuelle : le compte console Anthropic est enregistré au nom de "Primes-Services", pas d'ArchiTecht SRL. Le DPA Anthropic lie l'entité signataire — donc actuellement Primes-Services est le controller déclaré, pas ArchiTecht. En cas de contrôle APD ou de litige client, ce décalage est une vulnérabilité.*
  - **Option A (recommandée)** : envoyer un email à privacy@anthropic.com pour demander le transfert du compte vers ArchiTecht SRL (BCE BE 1020.345.473) — conserver la confirmation écrite dans le dossier conformité
  - **Option B** : créer un nouveau compte console Anthropic au nom d'ArchiTecht SRL, générer une nouvelle clé API et mettre à jour `ANTHROPIC_API_KEY` dans les credentials Rails / variables Heroku
  - À faire **avant le premier client payant** — risque faible en pratique mais réel en cas de contrôle
- [ ] **DPA Anthropic — vérification** — le DPA est automatiquement inclus dans les Commercial Terms of Service Anthropic (effectif 24/02/2025) pour tout compte enregistré au nom d'une société. Une fois le transfert vers ArchiTecht effectué, le DPA s'applique de plein droit sans démarche supplémentaire.
- [ ] **Checkbox consentement chatbot** ✅ *Implémentée dans `_contextual_bot.html.erb` + `contextual_bot_controller.js`* — panneau de consentement affiché à la première ouverture, consentement stocké en `localStorage` (`rn0_ia_consent_v1`).
- [ ] **Nommer un DPO** ou au minimum désigner une personne de contact RGPD interne et la déclarer auprès de l'APD belge si le volume de traitement l'exige.

### 5.2 Priorité haute (avant lancement ou rapidement après)

- [x] **Pseudonymiser les données avant envoi à Anthropic** ✅ *Implémenté dans `contextual_bot_service.rb`*
  - Revenus exacts → tranches calées sur seuils belges (9 tranches de `< 15 000 €` à `> 80 000 €`)
  - Montants travaux/devis/factures → tranches `amount_bracket` (11 tranches de `< 1 000 €` à `> 250 000 €`)
  - IBAN → boolean `Oui/Non` uniquement
  - Nom complet + email + téléphone → supprimés (prénom seul + ID hash SHA256)
  - Adresse exacte → code postal + commune uniquement
  - EAN + numéro cadastre → `Renseigné/Non renseigné`
  - Noms architecte/entrepreneur → `Renseigné` + certifications uniquement
  - N° TVA entrepreneur → boolean `Enregistrée: Oui/Non`
- [ ] **Notice à l'upload AER** — informer l'utilisateur au moment du dépôt du document que le revenu imposable extrait sera utilisé dans les prompts IA
- [ ] **Information RGPD dans ChantierVision** — avertir avant l'upload photo que les images sont envoyées à Anthropic USA

### 5.3 Priorité normale (3 mois après lancement)

- [ ] Registre des activités de traitement (art. 30 RGPD) — document interne obligatoire
- [ ] Analyse d'impact (AIPD / DPIA) sur le traitement des données AER et fiscales (art. 35 RGPD — données financières à grande échelle)
- [ ] Politique de conservation et suppression automatique des données inactives (> 2 ans sans connexion)
- [ ] Audit de sécurité annuel (OWASP Top 10 — déjà partiellement couvert par Brakeman)
- [ ] Médiation consommateur — s'affilier à un organisme agréé (ex. : CPMA / ODR belge)

---

## 6. Architecture IA — récapitulatif des flux de données

```
Utilisateur
    │
    ├─ Chat IA ──────────────────────► Anthropic API (Claude Haiku/Sonnet)
    │   Données : profil complet,      USA — SCC — données NON pseudonymisées
    │   AER, revenus, BIM, IBAN
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
```

---

## 7. Risques résiduels à surveiller

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Fuite via API Anthropic | Faible | Très élevé | DPA + pseudonymisation |
| Plainte APD (données AER sans consentement explicite) | Modérée | Élevé | Checkbox consentement chatbot |
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

*Document à mettre à jour à chaque évolution majeure de l'architecture IA ou des traitements de données.*
*À faire valider par un avocat spécialisé RGPD avant le lancement commercial officiel.*

# Analyse d'Impact relative à la Protection des Données (AIPD / DPIA)
**Art. 35 RGPD — Ren0vate / ArchiTecht SRL**

| Champ | Valeur |
|-------|--------|
| Responsable du traitement | ArchiTecht SRL — BCE BE 1020.345.473 |
| Contact RGPD | Robin Dupont — robin@architecht.be |
| Traitement concerné | Données fiscales et financières des utilisateurs (AER, revenus, IBAN) |
| Date d'évaluation | Mai 2026 |
| Statut | Ébauche initiale — à compléter avant 250 utilisateurs actifs |

---

## 1. Nécessité de l'AIPD

L'art. 35 RGPD impose une AIPD lorsqu'un traitement est **susceptible d'engendrer un risque élevé**. Ren0vate remplit plusieurs critères :

| Critère CNIL/EDPB | Applicable ? | Justification |
|-------------------|-------------|---------------|
| Données sensibles à grande échelle | **Oui** | Revenus imposables, situation familiale, numéro national |
| Traitement innovant (IA) | **Oui** | Pseudonymisation + envoi à Claude (Anthropic USA) |
| Personnes vulnérables | Partiel | Ménages à faibles revenus, bénéficiaires de primes sociales |
| Transferts hors UE | **Oui** | Anthropic USA (SCC) |
| Profilage | Non | Pas de profilage automatisé à effet juridique |

**Conclusion : AIPD requise avant traitement à grande échelle.**

---

## 2. Description du traitement

### 2.1 Nature des données
- Revenus imposables (bruts ou nets selon formulaire AER)
- Situation familiale (célibataire, cohabitant, chef de ménage)
- Nombre de personnes à charge, personnes âgées, grossesse
- IBAN (pour versement de primes — optionnel)
- Numéro national (optionnel, pour certaines primes)

### 2.2 Flux de données
```
Utilisateur upload AER
    ↓ OCR (local, serveur Heroku EU)
    ↓ Extraction revenu imposable
    ↓ Pseudonymisation → tranche (ex: "30 000 € – 40 000 €")
    ↓ Insertion dans prompt contextuel
    ↓ Envoi à Anthropic API (USA — SCC)
    ↓ Réponse texte IA → affichée à l'utilisateur
    (pas de conservation du prompt côté Anthropic)
```

### 2.3 Finalité
Personnalisation des conseils d'éligibilité aux primes de rénovation (Wallonie, Flandre).

---

## 3. Évaluation des risques

### Risque 1 — Accès non autorisé aux données fiscales

| Facteur | Évaluation |
|---------|-----------|
| Vraisemblance | Faible — données isolées par compte, chiffrées at-rest |
| Gravité | Élevée — données fiscales sensibles |
| **Risque résiduel** | **Modéré** |

**Mesures :** Active Record Encryption (IBAN, numéro national), TLS en transit, authentification Devise, isolation par `user_id` en base.

### Risque 2 — Réidentification via les prompts IA

| Facteur | Évaluation |
|---------|-----------|
| Vraisemblance | Très faible — pseudonymisation préalable complète |
| Gravité | Élevée si réidentification possible |
| **Risque résiduel** | **Faible** |

**Mesures :** `ContextualBotService` remplace systématiquement : revenus exacts → tranches, montants → tranches, IBAN → booléen, nom/email/adresse → supprimés, adresse → code postal seul. Vérification par audit de code (tests unitaires sur `ContextualBotService`).

### Risque 3 — Transfert USA (Anthropic) non conforme

| Facteur | Évaluation |
|---------|-----------|
| Vraisemblance | Faible si SCC correctement mis en œuvre |
| Gravité | Élevée — sanction APD jusqu'à 4% CA mondial |
| **Risque résiduel** | **Modéré → Faible après transfert compte** |

**Mesures :** SCC incluses dans les Commercial ToS Anthropic (effectif 24/02/2025). **Condition : compte Anthropic enregistré au nom d'ArchiTecht SRL** (transfert en cours — §5.1 ANALYSE_JURIDIQUE).

### Risque 4 — Conservation excessive

| Facteur | Évaluation |
|---------|-----------|
| Vraisemblance | Faible |
| Gravité | Modérée |
| **Risque résiduel** | **Faible** |

**Mesures :** `DataRetentionJob` — anonymisation trimestrielle des comptes inactifs > 2 ans.

---

## 4. Mesures de minimisation

| Mesure | Statut |
|--------|--------|
| Pseudonymisation avant envoi IA | ✅ Implémenté (`ContextualBotService`) |
| Chiffrement at-rest IBAN + numéro national | ✅ Active Record Encryption |
| Consentement explicite avant usage IA | ✅ Modal chatbot + modal ChantierVision |
| Information à l'upload AER | ✅ Notice dans le formulaire d'upload |
| SCC Anthropic | ✅ Commercial ToS (conditionné au transfert de compte) |
| Politique de rétention automatisée | ✅ `DataRetentionJob` trimestriel |
| Pas de conservation des prompts | ✅ Anthropic API — usage policy |
| Accès restreint aux données fiscales (admin uniquement) | ✅ `can_access_admin?` |

---

## 5. Consultation préalable APD

Selon l'art. 36 RGPD, une consultation préalable de l'APD belge est nécessaire si les risques résiduels restent **élevés** malgré les mesures.

**Évaluation :** Après application des mesures ci-dessus, aucun risque résiduel n'est évalué comme élevé. La consultation préalable n'est **pas obligatoire** à ce stade.

Si le volume de traitement dépasse **~5 000 utilisateurs actifs** ou si de nouvelles catégories de données sensibles sont traitées, une réévaluation est requise.

---

## 6. Révisions planifiées

| Événement déclencheur | Action |
|----------------------|--------|
| Nouveau traitement IA | Mise à jour AIPD avant déploiement |
| > 5 000 utilisateurs actifs | Réévaluation complète + consultation APD possible |
| Incident de sécurité | Révision immédiate |
| Révision annuelle | Janvier de chaque année |
| Changement de sous-traitant USA | Mise à jour §3 risque 3 + vérification SCC |

---

*Document établi conformément aux lignes directrices WP248 rev.01 du Comité Européen de Protection des Données. À conserver dans le dossier de conformité ArchiTecht SRL.*

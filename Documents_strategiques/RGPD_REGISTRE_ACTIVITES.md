# Registre des activités de traitement — Ren0vate
**Art. 30 RGPD — Document interne obligatoire**

| Champ | Valeur |
|-------|--------|
| Responsable du traitement | ArchiTecht SRL — BCE BE 1020.345.473 |
| Contact RGPD / DPO | Robin Dupont — robin@architecht.be |
| Date de création | Mai 2026 |
| Dernière mise à jour | Mai 2026 |

---

## Traitement 1 — Gestion des comptes utilisateurs

| Champ | Détail |
|-------|--------|
| **Finalité** | Création et gestion des comptes, authentification, facturation |
| **Base légale** | Art. 6(1)(b) — exécution d'un contrat |
| **Catégories de personnes** | Propriétaires, architectes, entrepreneurs |
| **Catégories de données** | Nom, prénom, email, téléphone, adresse, profil utilisateur, données de connexion |
| **Destinataires** | Heroku EU (hébergement), Stripe EU (facturation) |
| **Transferts hors UE** | Stripe USA — DPF UE-USA |
| **Durée de conservation** | Durée du compte + 2 ans d'inactivité, puis anonymisation automatique (`DataRetentionJob`) |
| **Mesures de sécurité** | Chiffrement TLS, bcrypt passwords, Active Record Encryption pour IBAN/numéro national |

---

## Traitement 2 — Gestion des dossiers de rénovation

| Champ | Détail |
|-------|--------|
| **Finalité** | Pilotage des chantiers, suivi des travaux, gestion documentaire |
| **Base légale** | Art. 6(1)(b) — exécution d'un contrat |
| **Catégories de personnes** | Propriétaires |
| **Catégories de données** | Adresse du bien, type de travaux, devis, factures, photos, PV, attestations |
| **Destinataires** | Heroku EU, Cloudinary (stockage fichiers) |
| **Transferts hors UE** | Cloudinary — SCC |
| **Durée de conservation** | Durée du compte + 2 ans |
| **Mesures de sécurité** | Contrôle d'accès par compte, isolation par `user_id` |

---

## Traitement 3 — Données fiscales et de revenus (AER)

| Champ | Détail |
|-------|--------|
| **Finalité** | Calcul d'éligibilité aux primes de rénovation (Wallonie, Flandre) |
| **Base légale** | Art. 6(1)(b) — exécution d'un contrat + art. 6(1)(a) consentement explicite pour usage IA |
| **Catégories de personnes** | Propriétaires |
| **Catégories de données** | Revenus imposables (extrait AER), situation familiale, numéro national (chiffré at-rest) |
| **Destinataires** | Anthropic USA (tranche de revenu anonymisée uniquement, dans les prompts IA) |
| **Transferts hors UE** | Anthropic USA — SCC art. 46 RGPD. Anthropic ne conserve pas les données après traitement (API usage policy) |
| **Durée de conservation** | Durée du compte. Les tranches anonymisées envoyées à Anthropic ne sont pas conservées |
| **Mesures de sécurité** | Pseudonymisation préalable (tranches de revenus), chiffrement at-rest (Active Record Encryption), information à l'upload (notice RGPD dans le formulaire) |

---

## Traitement 4 — Assistant IA contextuel (Ren0chat)

| Champ | Détail |
|-------|--------|
| **Finalité** | Conseils personnalisés sur la rénovation, primes, et suivi de chantier |
| **Base légale** | Art. 6(1)(a) — consentement (panneau affiché à la première ouverture) |
| **Catégories de personnes** | Propriétaires, professionnels |
| **Catégories de données** | Contexte anonymisé : tranches de revenus, types de travaux, code postal + commune, état avancement projet. Jamais : nom, email, adresse exacte, montants exacts, IBAN |
| **Destinataires** | Anthropic USA |
| **Transferts hors UE** | Anthropic USA — SCC art. 46 RGPD |
| **Durée de conservation** | Pas de conservation des prompts (session uniquement, pas d'historique en base) |
| **Mesures de sécurité** | Pseudonymisation complète avant envoi (`ContextualBotService`), consentement `localStorage` (`rn0_ia_consent_v1`) |

---

## Traitement 5 — Analyse photos de chantier (ChantierVision)

| Champ | Détail |
|-------|--------|
| **Finalité** | Estimation automatique de l'avancement des travaux par analyse d'image IA |
| **Base légale** | Art. 6(1)(a) — consentement explicite (modal avant chaque première utilisation) |
| **Catégories de personnes** | Propriétaires |
| **Catégories de données** | Photos de chantier (pouvant contenir des personnes identifiables) |
| **Destinataires** | Anthropic USA (Claude Vision API) |
| **Transferts hors UE** | Anthropic USA — SCC art. 46 RGPD. Max 6 photos par analyse. Anthropic ne conserve pas les images |
| **Durée de conservation** | Photos stockées sur Cloudinary (durée du compte). Résultats d'analyse en base (durée du projet) |
| **Mesures de sécurité** | Consentement modal avec information RGPD (`rn0_vision_consent_v1`), limite de 6 photos, information sur transfert USA |

---

## Traitement 6 — Hub de décision IA

| Champ | Détail |
|-------|--------|
| **Finalité** | Recommandations contextuelles (permis, devis, phase de chantier) |
| **Base légale** | Art. 6(1)(b) — exécution d'un contrat |
| **Catégories de données** | Simulation de primes (anonymisée), type de travaux, catégorie d'éligibilité |
| **Destinataires** | Anthropic USA |
| **Transferts hors UE** | Anthropic USA — SCC |
| **Durée de conservation** | Pas de conservation des prompts |

---

## Traitement 7 — Paiements et abonnements

| Champ | Détail |
|-------|--------|
| **Finalité** | Gestion des abonnements SaaS et facturation |
| **Base légale** | Art. 6(1)(b) — exécution d'un contrat |
| **Catégories de données** | Email, nom, stripe_customer_id, historique de paiements |
| **Destinataires** | Stripe (EU + USA — DPF) |
| **Transferts hors UE** | Stripe USA — DPF UE-USA |
| **Durée de conservation** | 10 ans (obligation légale comptable) |

---

## Transferts hors UE — récapitulatif

| Sous-traitant | Pays | Base légale transfert | DPA signé |
|---------------|------|-----------------------|-----------|
| Heroku (Salesforce) | UE (Dublin) | Pas de transfert | Oui |
| Cloudinary | USA | SCC (art. 46 RGPD) | Oui |
| Anthropic | USA | SCC (art. 46 RGPD) | Oui (inclus dans Commercial ToS Anthropic — après transfert compte vers ArchiTecht SRL) |
| Stripe | USA | DPF UE-USA + SCC | Oui |
| Resend (SMTP) | USA | SCC | Oui |

---

*Ce registre doit être tenu à jour à chaque nouvelle fonctionnalité traitant des données personnelles. Révision annuelle recommandée.*

# Vision UX — Scan · Chat · Action
*Ren0vate — Route évolutive post-stratégie*
*Rédigée le 12 avril 2026*

---

## Contexte & Insight de départ

Les utilisateurs ont pris l'habitude de poser leurs questions directement en chat (ChatGPT, Claude, Gemini) plutôt que de naviguer sur le web. Le paradigme de recherche d'information a basculé. Parallèlement, le marché des applications est saturé et très peu percent : la friction d'usage reste le principal facteur d'abandon.

La réponse de Ren0vate n'est pas de réduire les fonctionnalités — l'objectif est d'être **de plus en plus complet**. La réponse est de **simplifier radicalement l'accès** à cette complétude via deux interfaces convergentes : le **chat IA** et le **scan documentaire**.

---

## La Vision : modèle Scan → Chat → Action

Quand un utilisateur ouvre l'app Ren0vate sur smartphone, il doit avoir **le moins de choses à faire possible** :

1. **Scanner un document** (facture, devis, certificat PEB, rapport amiante, attestation...)
2. L'app **reconnaît automatiquement** le type de document et **en extrait la matière** pertinente
3. Le document est **envoyé au bon endroit** (section factures, devis, primes, travaux...)
4. L'utilisateur peut **chater avec son chantier** pour poser des questions, obtenir des synthèses, déclencher des actions

> L'IA navigue la complexité à la place de l'utilisateur. Ce n'est pas une simplification des features, c'est une simplification de l'accès.

---

## Les deux interfaces convergentes

### 1. Chat IA depuis le Dashboard

- Interface principale à la connexion
- Accès au contexte complet du chantier : devis, factures, artisans, primes, documents
- Questions naturelles et immédiates :
  - *"Combien j'ai dépensé depuis janvier ?"*
  - *"Mon devis de plomberie est toujours en attente ?"*
  - *"Quelles primes puis-je encore demander pour ce bien ?"*
- L'Expert IA charge le contexte selon le bien sélectionné
- La richesse des données accumulées dans l'app est la **moat concurrentielle** — elle grandit avec l'usage

### 2. Scan OCR + Classification automatique

- Upload depuis l'app mobile (photo ou fichier)
- Reconnaissance du type de document :
  - Facture d'entrepreneur
  - Devis
  - Certificat PEB
  - Rapport amiante / attestation sol
  - Facture énergie (EAN, consommations)
  - Attestation d'assurance
- Extraction des données structurées : montants, TVA, dates, parties, EAN, références
- Proposition de destination avec **confirmation rapide** avant envoi (*"C'est bien une facture Electrabel pour le bien Rue de la Loi ?"*)
- Envoi automatique à la bonne section de l'app

**Killer feature belge identifiée** : scanner un certificat PEB ou rapport amiante pour **pré-remplir automatiquement une demande de prime**. Aucune app de l'écosystème belge ne fait ça aujourd'hui.

---

## Principes de conception UX mobile

| Principe | Application concrète |
|---|---|
| Minimum de saisie | Scan remplace la saisie manuelle |
| Confirmation rapide | Validation en 1 tap, pas de formulaire |
| Chat en langue naturelle | Aucun menu à naviguer pour obtenir une info |
| Contexte automatique | L'IA sait sur quel chantier on travaille |
| Fonctions core indépendantes | Consulter devis/factures reste accessible sans IA (résilience) |

---

## Risques à anticiper

### Fiabilité de la classification OCR
La classification doit être quasi parfaite. Deux erreurs de reconnaissance et l'utilisateur abandonne la feature. Le step de confirmation rapide post-scan est **non négociable**.

### Dépendance aux APIs IA externes
Les endpoints OpenAI / Gemini / Anthropic peuvent tomber ou changer de prix. Les fonctions core de l'app (consulter, créer, modifier devis/factures) doivent **rester pleinement opérationnelles sans IA**.

### Qualité des scans mobiles
Mauvaise lumière, document froissé, PDF scanné = résultats dégradés. Prévoir un fallback manuel élégant + indicateur de confiance de la lecture.

---

## Séquence d'implémentation recommandée

```
Phase 1 — Dashboard Chat IA (en cours)
  └── Chat expert par bien depuis le dashboard
  └── Contexte : devis, factures, travaux, primes du bien

Phase 2 — Upload + OCR de base
  └── Upload photo/PDF depuis mobile
  └── Lecture GPT-4o Vision
  └── Classification + confirmation 1 tap
  └── Envoi à la bonne section

Phase 3 — Extraction de données structurées
  └── Montants, TVA, dates → pré-remplissage devis/factures
  └── EAN, consommations → pré-remplissage primes énergie
  └── Certif PEB → pré-remplissage demande de prime automatique

Phase 4 — Assistant de chantier conversationnel
  └── Mémoire documentaire complète par bien
  └── Questions naturelles sur l'historique complet
  └── Actions déclenchées depuis le chat (créer, archiver, envoyer)
```

---

## Positionnement final

À terme, Ren0vate mobile devient un **assistant de chantier conversationnel avec mémoire documentaire**.

Ce positionnement est **structurellement difficile à copier** : la valeur est dans les données accumulées projet par projet, document par document, par chaque utilisateur. Il ne s'agit pas d'une feature, mais d'un effet réseau individuel — plus l'utilisateur utilise l'app, plus l'assistant est pertinent pour lui.

---

*Ce document sert de boussole UX pour les itérations post-implémentation de la stratégie d'évolution V2.0.*

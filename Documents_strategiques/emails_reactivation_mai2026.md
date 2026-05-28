# Emails de réactivation — Mai 2026

Deux segments · À envoyer via `/notifications/new_admin`
Prérequis : vérifier `primes_services_client = true` sur les 75 clients en production (`heroku run rails runner "puts User.where(primes_services_client: true).count" --app ren0vate`)

---

## Email 1 — Clients primes-services (75 personnes)

**Destinataires :** Clients Primes-Services ⭐ (`primes_services_client = true`)
**Lien d'action :** `/dashboard`

---

**Objet :** Ce que j'ai construit pour vous après nos dossiers de primes

---

Bonjour,

Je me permets de revenir vers vous au sujet de Ren0vate, outil que nous avons utilisé ensemble dans le cadre de la gestion de votre dossier de primes.

J'ai bien conscience que vous avez fait appel à Primes-Services pour ne pas avoir à vous occuper de votre dossier. Sauf que vous faites malgré vous partie des premiers utilisateurs de l'app 😄

Alors voilà pourquoi je vous écris.

Depuis nos premiers échanges, Ren0vate est devenu une plateforme de gestion de patrimoine immobilier : suivi de chantier, gestion des devis et factures, DIU exportable, gestion locative — avec un assistant IA qui vous aide à chiffrer des travaux, comparer des devis ou trouver des alternatives de matériaux sans toujours devoir demander l'avis de votre entrepreneur.

Ce sont 15 années d'expertise et plus de 10 000 chantiers accompagnés que nous avons mis en boîte.

Ce que j'attends de vous : 5 à 10 minutes pour un retour d'expérience. Voir si ce dont vous auriez eu besoin s'y trouve.

Votre compte est gratuit, stockage inclus. Commencez par la checklist DIU — vous serez surpris de ce que vous avez déjà 😉

À très vite,\
Robin

*PS : Si vous avez un ami ou voisin qui rénove en ce moment, je serais heureux que vous lui parliez de l'outil.*

---

## Email 2 — Utilisateurs organiques (50 personnes)

**Destinataires :** Non Primes-Services (`primes_services_client = false`)
**Lien d'action :** `/dashboard`

---

**Objet :** Ren0vate — honnêtement, qu'est-ce qui s'est passé ?

---

Bonjour,

Vous vous êtes inscrit sur Ren0vate il y a quelques semaines. Depuis, plus de nouvelles.

Je ne vous en veux pas. Mais j'aimerais vraiment comprendre pourquoi.

Vous faites partie des 50 premières personnes à avoir découvert l'outil par vous-même. Quelque chose vous a bloqué ? L'outil ne correspondait pas à ce que vous cherchiez ? Il manquait quelque chose d'évident ?

15 minutes par téléphone ou visio, ou simplement une réponse à cet email — pas de démo, pas de pitch. Juste une conversation.

À très vite,\
Robin\
Fondateur de Ren0vate

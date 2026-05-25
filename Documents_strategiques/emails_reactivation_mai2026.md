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

Bonjour [prénom],

Vous vous souvenez peut-être de nos échanges autour de vos primes de rénovation. J'ai vu de près à quel point gérer un chantier en Belgique pouvait être épuisant — les documents à rassembler, les délais à respecter, les entrepreneurs à coordonner.

C'est exactement pour résoudre ça que j'ai construit Ren0vate.

Ren0vate, c'est une plateforme qui centralise tout ce dont vous avez besoin pour piloter votre rénovation : suivi de chantier, gestion des devis et factures, simulation des primes disponibles, et un assistant IA qui répond à vos questions en temps réel.

Depuis nos premiers échanges, la plateforme a évolué bien au-delà du chantier. Vos travaux réalisés constituent déjà une partie de votre Dossier d'Intervention Ultérieure — le document légalement requis lors d'une vente. Ren0vate le construit automatiquement, et vous permet aussi de préparer une mise en vente ou de gérer une location si votre situation change.

Vous faites déjà partie des premiers utilisateurs. Votre compte est actif sur ren0vate.be.

Ce que j'attends de vous en ce moment, c'est simple : utilisez-le, et dites-moi ce qui manque. Pas d'abonnement, pas de carte de crédit — c'est gratuit pour vous pendant cette phase de test.

À très vite,
Robin

*PS : Si vous avez un ami ou voisin qui rénove en ce moment, je serais heureux que vous lui parliez de l'outil.*

---

## Email 2 — Utilisateurs organiques (50 personnes)

**Destinataires :** Non Primes-Services (`primes_services_client = false`)
**Lien d'action :** `/dashboard`

---

**Objet :** Vous êtes parmi les 128 premiers sur Ren0vate

---

Bonjour [prénom],

Vous vous êtes inscrit sur Ren0vate il y a quelques semaines. Je voulais prendre un moment pour vous écrire personnellement.

Vous faites partie des 128 premières personnes à avoir créé un compte. Ce n'est pas anodin — vous avez découvert l'outil par vous-même, sans campagne publicitaire, et ça compte beaucoup pour moi.

Ren0vate est encore en phase de test, mais ce n'est plus une simple app de rénovation. L'idée est de centraliser toute la vie de votre logement en un seul endroit : devis, factures, primes, suivi de chantier, assistant IA — mais aussi le Dossier d'Intervention Ultérieure (obligatoire à la vente), la préparation à la mise en vente, et la gestion locative. Ce que les Belges appellent bientôt un "passeport numérique du logement" — c'est ce que Ren0vate construit pour vous, dès maintenant.

Ce que je vous demande : explorez l'outil, et si quelque chose vous manque ou vous bloque, répondez directement à cet email. Je lis tout.

Le lancement officiel est prévu pour l'automne. D'ici là, votre accès est entièrement gratuit.

Merci d'être là,
Robin
Fondateur de Ren0vate

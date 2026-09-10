# Idées de slash commands Claude Code — à créer

Note de suivi (10/09/2026), suite à l'audit stack cross-repo des 5 apps Rails
(ren0vate, borbolla, patrimoine, numerostrat, primes-services.ia) + 2 agents
(confiture-agent, shinrin-yoku-agent). Objectif : factoriser les vérifications
répétitives plutôt que refaire un audit manuel à chaque fois.

Chaque commande ci-dessous est un fichier `.claude/commands/<nom>.md` à créer
(dans chaque repo Rails, ou centralisé dans un plugin privé — voir la
recommandation "plugin local multi-repos" de la session du 10/09).

## 1. `/audit-rails`
Lance Brakeman + Rubocop + `bundle-audit` (si dispo) sur le repo courant,
résume les findings par priorité (sécurité > fiabilité > style). S'appuie sur
l'agent `rails-stack-auditor` (`~/.claude/agents/rails-stack-auditor.md`,
créé le 10/09/2026) plutôt que de redéfinir la logique dans la commande.

## 2. `/deploy-check`
Checklist pré-déploiement pour une app Rails : `Procfile` a bien `release:`
et `worker:` (Solid Queue), pas de `SOLID_QUEUE_IN_PUMA=true` actif sur un
dyno web contraint en RAM, pas de config Kamal orpheline si Heroku est la
cible choisie, migrations en attente (`rails db:migrate:status`). Trouvé
nécessaire suite au bug patrimoine du 10/09 (aucun job ne tournait sur Heroku).

## 3. `/security-sweep`
Sweep cross-repo : variables d'env orphelines (présentes dans `.env`/`.env.example`
mais plus référencées dans le code — cf. reliquats IA morts sur primes-services.ia),
secrets en clair dans des fichiers *versionnés* (jamais dans `.env` local, ça
c'est normal), parité Sentry/rack-attack entre les apps (primes-services.ia et
ren0vate en ont, borbolla/patrimoine/numerostrat non — à harmoniser si souhaité).

## 4. `/agent-health`
Pour les agents légers (confiture-agent, shinrin-yoku-agent, et futurs) :
vérifie que le cron CI tourne bien (dernière exécution réussie), que le SDK
officiel Anthropic est bien utilisé (pas de HTTP brut), que le README décrit
des fonctionnalités réellement implémentées (aurait attrapé
`monitoring_agent.py` vide sur confiture-agent), que le store JSON ne grossit
pas sans purge.

## 5. `/repo-hygiene`
Sweep fichiers obsolètes réutilisable (celui fait manuellement le 10/09) :
backups (`*.bak`/`*.orig`/`~`), scripts de diagnostic oubliés, dossiers vides
versionnés, doublons de lockfiles/venvs, README restés au template par défaut,
docs obsolètes (ex. `docs/Archives/`). Produit une liste de candidats à valider
— ne supprime jamais rien automatiquement.

---

**Pourquoi centraliser plutôt que dupliquer dans chaque repo** : les 5 apps
Rails ont une stack quasi identique (Rails 8.1, Solid Queue, Devise, Rubocop
omakase, Brakeman). Un plugin local (`~/.claude/plugins/...` ou équivalent,
voir doc Claude Code officielle pour la structure exacte — à vérifier avant
de s'appuyer sur les détails, la réponse obtenue le 10/09 contenait des
éléments non confirmés) éviterait de recréer ces 5 commandes + l'agent
`rails-stack-auditor` dans chaque repo.

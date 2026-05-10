# Checklist — Jour du lancement commercial

Opérations à effectuer le jour de la mise en vente (commercialisation publique).

---

## Monitoring & Observabilité

### Sentry (tracking d'erreurs)
- [ ] Créer un compte sur [sentry.io](https://sentry.io) — plan gratuit (5k erreurs/mois)
- [ ] Créer un projet → choisir **Ruby on Rails**
- [ ] Copier le DSN (format `https://xxx@oyyy.ingest.sentry.io/zzz`)
- [ ] Activer sur Heroku :
  ```bash
  heroku config:set SENTRY_DSN=<ton_dsn> --app ren0vate
  ```
  Le dyno redémarre automatiquement. Aucune autre action — le code est déjà en prod.

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

## Notes
- Le health-check endpoint `/up` est déjà en prod — UptimeRobot peut être configuré dès maintenant si souhaité
- Sentry et Plausible sont entièrement prêts côté code, ils attendent juste leurs comptes externes

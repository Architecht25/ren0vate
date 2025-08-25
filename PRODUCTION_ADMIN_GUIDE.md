# Guide de Déploiement en Production

## Configuration des Droits d'Administrateur

### 🎯 Objectif
S'assurer que Robin (robin@primes-services.be) dispose des droits d'administrateur en production.

### 🚀 Déploiement Rapide

#### Option 1: Script Automatisé (Recommandé)
```bash
# Depuis la racine du projet
./bin/ensure_admin_production.sh
```

#### Option 2: Commandes Manuelles
```bash
# 1. Migration de la base de données
RAILS_ENV=production bundle exec rails db:migrate

# 2. Compilation des assets
RAILS_ENV=production bundle exec rails assets:precompile

# 3. Assurer les droits d'admin
RAILS_ENV=production bundle exec rails production:ensure_admin

# 4. Vérifier les rôles
RAILS_ENV=production bundle exec rails production:show_roles
```

### 🔧 Commandes de Maintenance

#### Vérification des Rôles
```bash
RAILS_ENV=production bundle exec rails production:show_roles
```

#### Promotion d'Administrateur
```bash
RAILS_ENV=production bundle exec rails production:ensure_admin
```

#### Console Rails en Production
```bash
RAILS_ENV=production bundle exec rails console
```

### 🛡️ Sécurité

1. **Unique Administrateur**: Robin est configuré comme l'unique administrateur
2. **Vérification Automatique**: Les scripts vérifient automatiquement les droits
3. **Logging**: Toutes les opérations sont loggées pour audit

### 🔍 Vérifications Post-Déploiement

1. **Connexion Admin**:
   - Se connecter avec robin@primes-services.be
   - Vérifier l'accès au dashboard admin
   - Tester les fonctionnalités de sécurité

2. **Rôles Utilisateurs**:
   - Vérifier que seul Robin a le rôle admin
   - Confirmer que les autres utilisateurs sont 'user' par défaut

3. **Interface Sécurisée**:
   - Boutons sécurité fonctionnels
   - SweetAlert2 opérationnel
   - CSP headers configurés

### 📊 Monitoring

#### Variables d'Environnement Importantes
```bash
RAILS_ENV=production
RAILS_LOG_LEVEL=info
```

#### Logs à Surveiller
```bash
# Logs d'application
tail -f log/production.log

# Logs d'erreur
grep ERROR log/production.log
```

### 🆘 Dépannage

#### Problème: Robin n'est pas admin
```bash
RAILS_ENV=production bundle exec rails production:ensure_admin
```

#### Problème: Assets manquants
```bash
RAILS_ENV=production bundle exec rails assets:clobber
RAILS_ENV=production bundle exec rails assets:precompile
```

#### Problème: Migration échouée
```bash
RAILS_ENV=production bundle exec rails db:migrate:status
RAILS_ENV=production bundle exec rails db:migrate
```

### 📋 Checklist de Déploiement

- [ ] Base de données migrée
- [ ] Assets compilés
- [ ] Robin promu administrateur
- [ ] Rôles utilisateurs vérifiés
- [ ] Dashboard admin accessible
- [ ] Fonctionnalités sécurité testées
- [ ] Logs vérifiés

### 🔗 Liens Utiles

- Dashboard Admin: `/admin/dashboard`
- Console Rails: `RAILS_ENV=production bundle exec rails console`
- Logs: `tail -f log/production.log`

---

**Note**: Ce guide assure que Robin dispose des droits d'administrateur nécessaires pour gérer l'application en production de manière sécurisée.

# Guide de Configuration des Emails pour Ren0vate

## Problème Résolu ✅

Le problème de création de comptes était causé par :
1. **Variables d'environnement SMTP manquantes** sur Heroku
2. **Module `:confirmable` activé** sans configuration email fonctionnelle
3. **Erreurs silencieuses** lors de l'envoi d'emails de confirmation

## Solution Temporaire Implémentée ✅

- Désactivation du module `:confirmable` dans le modèle User
- Suppression du callback `after_create :auto_confirm_user`
- Mise à jour du message d'information pour les utilisateurs
- **Résultat**: Les utilisateurs peuvent maintenant créer des comptes sans problème

## Configuration Définitive pour les Emails (À faire)

### 1. Configurer SendGrid sur Heroku

```bash
# Ajouter l'addon SendGrid
heroku addons:create sendgrid:starter --app ren0vate

# Les variables seront automatiquement configurées :
# SENDGRID_API_KEY
# SENDGRID_USERNAME
# SENDGRID_PASSWORD
```

### 2. Configurer les variables d'environnement

```bash
heroku config:set SMTP_ADDRESS=smtp.sendgrid.net --app ren0vate
heroku config:set SMTP_PORT=587 --app ren0vate
heroku config:set SMTP_DOMAIN=ren0vate.be --app ren0vate
heroku config:set SMTP_USERNAME=$SENDGRID_USERNAME --app ren0vate
heroku config:set SMTP_PASSWORD=$SENDGRID_PASSWORD --app ren0vate
heroku config:set DEVISE_MAILER_SENDER=no-reply@ren0vate.be --app ren0vate
```

### 3. Réactiver la confirmation par email

Dans `app/models/user.rb` :
```ruby
# Réactiver le module confirmable
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable, :confirmable
```

### 4. Tester la configuration

```ruby
# Via rails console en production
ActionMailer::Base.mail(
  from: 'no-reply@ren0vate.be',
  to: 'votre-email@example.com',
  subject: 'Test SMTP',
  body: 'Test de configuration SMTP'
).deliver_now
```

## Alternative : Utiliser un autre service

### Avec Mailgun
```bash
heroku addons:create mailgun:starter --app ren0vate
```

### Avec Postmark
```bash
heroku addons:create postmark:10k --app ren0vate
```

## Notes Importantes

- ⚠️ **Ne pas réactiver `:confirmable` sans configuration SMTP complète**
- 📧 Vérifier que le domaine `ren0vate.be` est configuré dans le service d'email
- 🔐 Les credentials SMTP ne doivent jamais être committés dans le code
- 🧪 Toujours tester en staging avant production

## Statut Actuel

✅ Création de comptes fonctionnelle (sans confirmation email)
⏳ Configuration email définitive à implémenter
📋 Guide de migration prêt

Date: 2025-11-13

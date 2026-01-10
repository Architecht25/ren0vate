# 📧 Système de Notifications pour les Dépôts de Documents

Ce guide explique le système de notifications par email mis en place pour informer l'administrateur lorsqu'un utilisateur dépose des documents dans ren0vate.

## 🎯 Fonctionnalités

Le système envoie automatiquement un email à l'administrateur dans les cas suivants :

1. **Documents généraux** - Lorsqu'un utilisateur upload des documents via le système de gestion documentaire
2. **Documents de suivi** - Lorsqu'un utilisateur dépose un document de suivi administratif (PDF ou photo)
3. **Réponses aux demandes de complément** - Lorsqu'un utilisateur répond à une demande de complément avec des documents

## 📝 Configuration

### Variables d'environnement requises

Ajoutez ces variables dans votre fichier `.env` :

```bash
# Email de l'administrateur qui recevra les notifications
ADMIN_EMAIL=robin@primes-services.be

# Email d'expédition pour les notifications admin (optionnel)
ADMIN_MAILER_FROM=noreply@ren0vate.be

# URL de l'application pour les liens dans les emails
APP_URL=https://ren0vate.be
```

### Configuration SMTP

Assurez-vous que votre configuration SMTP est correcte dans `config/environments/production.rb` ou `.env` :

```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=votre_email@gmail.com
SMTP_PASSWORD=votre_mot_de_passe_application
SMTP_DOMAIN=ren0vate.be
```

## 🔧 Implémentation Technique

### AdminMailer

Le mailer `AdminMailer` gère toutes les notifications administrateur :

```ruby
# app/mailers/admin_mailer.rb
class AdminMailer < ApplicationMailer
  default from: ENV.fetch('ADMIN_MAILER_FROM', 'noreply@ren0vate.be'),
          to: ENV.fetch('ADMIN_EMAIL', 'robin@primes-services.be')

  def document_uploaded(user, documents, context = {})
    # Notification pour upload de documents généraux
  end

  def tracking_document_uploaded(user, request_progress)
    # Notification pour documents de suivi administratif
  end

  def complement_response_uploaded(user, complement_request)
    # Notification pour réponses aux demandes de complément
  end
end
```

### Points d'intégration

#### 1. DocumentsController

Lors de l'upload de documents via le contrôleur principal :

```ruby
# app/controllers/documents_controller.rb
def create
  # ... code d'upload ...

  if errors.empty? && created_documents.any?
    AdminMailer.document_uploaded(
      current_user,
      created_documents,
      { property: @property, project: @project, request: @request }
    ).deliver_later
  end
end
```

#### 2. RequestProgressesController

Pour les documents de suivi administratif :

```ruby
# app/controllers/request_progresses_controller.rb
def upload_document
  # ... code d'upload ...

  if document_uploaded
    AdminMailer.tracking_document_uploaded(
      current_user,
      @request_progress
    ).deliver_later
  end
end
```

#### 3. ComplementRequestsController

Pour les réponses aux demandes de complément :

```ruby
# app/controllers/complement_requests_controller.rb
def respond
  # ... code de réponse ...

  if documents_uploaded
    AdminMailer.complement_response_uploaded(
      current_user,
      @complement_request
    ).deliver_later
  end
end
```

## 📨 Contenu des Emails

### Email 1: Documents généraux

**Sujet:** 📄 Nouveaux documents déposés par {email_utilisateur}

**Contenu:**
- Email de l'utilisateur
- Date et heure du dépôt
- Contexte (propriété, projet, demande)
- Liste des documents par type
- Nom et taille de chaque fichier
- Lien vers l'interface admin

### Email 2: Documents de suivi

**Sujet:** 📧 Document de suivi déposé - {titre_prime}

**Contenu:**
- Email de l'utilisateur
- Date et heure du dépôt
- Prime concernée
- Type de document (PDF ou photo)
- Lien vers le suivi

### Email 3: Réponse à demande de complément

**Sujet:** 📎 Réponse à demande de complément - {email_utilisateur}

**Contenu:**
- Email de l'utilisateur
- Date et heure de la réponse
- Demande concernée
- Nombre de documents
- Message de réponse (si présent)
- Lien vers la demande

## 🛡️ Gestion des Erreurs

Le système est conçu pour être résilient :

- Les notifications sont envoyées en **background** via `deliver_later` (ActiveJob)
- Si l'envoi d'email échoue, l'erreur est **loguée** mais n'empêche pas l'upload
- L'utilisateur n'est **pas impacté** par les erreurs d'envoi de notification

```ruby
begin
  AdminMailer.document_uploaded(...).deliver_later
rescue => e
  Rails.logger.error "Erreur notification admin: #{e.message}"
  # L'application continue normalement
end
```

## 🧪 Test en Développement

Pour tester les notifications en développement :

1. Configurez `letter_opener` dans `config/environments/development.rb` :

```ruby
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

2. Ajoutez la gem au Gemfile (groupe development) :

```ruby
gem 'letter_opener', group: :development
```

3. Les emails s'ouvriront automatiquement dans votre navigateur

## 📊 Surveillance

### Logs

Les logs des notifications sont disponibles dans :
- `log/production.log` (production)
- `log/development.log` (développement)

Recherchez les lignes contenant "notification admin" pour le debugging.

### ActiveJob

Si vous utilisez Sidekiq ou un autre backend pour ActiveJob, surveillez la queue des jobs pour détecter les emails en attente ou en erreur.

## 🔐 Sécurité

- Les emails contiennent uniquement des **métadonnées** (pas de contenu sensible des documents)
- Les liens pointent vers l'interface **admin sécurisée**
- L'adresse email admin est stockée dans les **variables d'environnement**
- Utilisez **HTTPS** pour tous les liens dans les emails

## 🚀 Déploiement

### Checklist

- [ ] Vérifier que `ADMIN_EMAIL` est configuré en production
- [ ] Tester l'envoi d'un email de notification
- [ ] Vérifier la configuration SMTP
- [ ] S'assurer qu'ActiveJob est configuré (Sidekiq recommandé)
- [ ] Monitorer les logs pour les erreurs d'envoi

### Commandes utiles

```bash
# Tester la configuration email en console Rails
rails c
AdminMailer.document_uploaded(User.first, Document.last(3), {}).deliver_now

# Vérifier les jobs en attente (avec Sidekiq)
Sidekiq::Queue.new.size
```

## 🔄 Évolutions Futures

Améliorations possibles :

1. **Digest quotidien** - Regrouper les notifications en un seul email journalier
2. **Filtres personnalisés** - Permettre à l'admin de choisir les types de notifications
3. **Notifications Slack/Discord** - Intégrer d'autres canaux de notification
4. **Dashboard admin** - Interface web pour voir toutes les notifications
5. **Notifications par type d'utilisateur** - Router vers différents admins selon le contexte

## 🆘 Support

En cas de problème :

1. Vérifier les logs Rails
2. Tester manuellement l'envoi d'email en console
3. Vérifier la configuration SMTP
4. S'assurer que les variables d'environnement sont chargées

Pour plus d'informations, contactez l'équipe technique.

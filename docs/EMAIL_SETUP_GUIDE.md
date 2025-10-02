# Configuration pour envoyer de vrais emails en développement

## Option 1 : Utiliser Mailcatcher (Recommandé pour les tests)

Mailcatcher est maintenant installé et configuré. Pour l'utiliser :

1. Démarrer Mailcatcher : `mailcatcher`
2. Interface web : http://127.0.0.1:1080
3. SMTP local : localhost:1025

## Option 2 : Utiliser un service SMTP réel (Gmail, SendGrid, etc.)

Pour utiliser Gmail par exemple, modifiez `config/environments/development.rb` :

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'gmail.com',
  user_name: 'votre-email@gmail.com',
  password: 'votre-mot-de-passe-app', # Utilisez un mot de passe d'application
  authentication: 'plain',
  enable_starttls_auto: true
}
```

## Option 3 : Utiliser SendGrid (Service professionnel)

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: 587,
  domain: 'ren0vate.be',
  user_name: 'apikey',
  password: ENV['SENDGRID_API_KEY'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

## Configuration actuelle

La configuration actuelle utilise Mailcatcher sur localhost:1025.
Les emails sont interceptés et visibles sur http://127.0.0.1:1080

## Test rapide

Pour tester l'envoi d'email :

```bash
cd /home/obinduarc/code/Architecht25/ren0vate
bundle exec rails runner "RequestProgress.last.test_full_email_cycle('robin@primes-services.be')"
```

Puis vérifiez l'interface Mailcatcher pour voir les emails.
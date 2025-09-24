# Guide de Configuration du Système de Tracking Email

## 📧 Vue d'ensemble

Le système de tracking email automatise le suivi des demandes de primes en recevant et analysant les emails de l'administration envoyés aux adresses de tracking générées automatiquement.

Format des adresses: `{region}-{property_id}-{project_id}-{timestamp}@tracking.ren0vate.be`

## 🏗️ Architecture

```
Email Administration → Postmark → ActionMailbox → TrackingMailbox → EmailDocumentExtractionJob
                                                        ↓
                        RequestProgress ← EmailDocumentExtractionService
                                ↓
                        UserMailer (notification utilisateur)
```

## ⚙️ Configuration Production

### 1. Configuration DNS

```bash
# Ajouter les enregistrements DNS pour tracking.ren0vate.be
MX    tracking.ren0vate.be    10 inbound.postmarkapp.com
TXT   tracking.ren0vate.be    "v=spf1 include:spf.mtasv.net ~all"
```

### 2. Configuration Postmark

1. Créer un serveur Postmark pour les emails entrants
2. Configurer le webhook pour ActionMailbox:
   - URL: `https://votre-app.herokuapp.com/rails/action_mailbox/postmark/inbound_emails`
   - HTTP Method: POST

### 3. Variables d'environnement

```bash
# Production
POSTMARK_INBOUND_WEBHOOK_SECRET=your_webhook_secret_here
ACTION_MAILBOX_INGRESS=postmark

# Pour les extractions de documents (optionnel)
TESSERACT_PATH=/usr/bin/tesseract
PDF_READER_ENABLED=true
```

### 4. Configuration Rails Production

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :postmark

# config/credentials.yml.enc (utilisez rails credentials:edit)
postmark:
  inbound_webhook_secret: your_webhook_secret_here
```

## 🔧 Installation des dépendances

### Pour l'extraction PDF
```bash
# Ajouter au Gemfile
gem 'pdf-reader'

# Ubuntu/Debian
sudo apt-get install poppler-utils

# macOS
brew install poppler
```

### Pour l'OCR d'images
```bash
# Ubuntu/Debian
sudo apt-get install tesseract-ocr tesseract-ocr-fra

# macOS
brew install tesseract tesseract-lang

# Optionnel: gem Ruby pour Tesseract
gem 'rtesseract'
```

## 🧪 Test en développement

1. **Test avec le script inclus:**
   ```bash
   cd /path/to/ren0vate
   ruby scripts/test_email_tracking.rb
   ```

2. **Test manuel via console Rails:**
   ```ruby
   # Créer un RequestProgress de test
   rp = RequestProgress.first

   # Simuler un email via ActionMailbox::TestHelper
   receive_inbound_email_from_mail do
     to rp.email_suivi
     from "admin@bruxelles.be"
     subject "Votre demande - Dossier BXL-2024-1234"
     body "Votre demande a été acceptée. Montant accordé: 2500€"
   end
   ```

3. **Vérifier les logs:**
   ```bash
   tail -f log/development.log | grep -E "(📧|🔍|✅|❌)"
   ```

## 📊 Monitoring et maintenance

### Vérification de l'état du système
```ruby
# Console Rails
# Vérifier les emails récents
ActionMailbox::InboundEmail.last(10).pluck(:id, :status, :created_at)

# Vérifier les extractions en échec
RequestProgress.extraction_failed.count

# Vérifier les emails non traités
ActionMailbox::InboundEmail.pending.count
```

### Logs importants à surveiller
- ❌ Adresses de tracking non reconnues
- 🔍 Échecs d'extraction de documents
- 📧 Volume d'emails entrants anormal

## 🔍 Débogage

### Problèmes courants

1. **Email non routé vers TrackingMailbox**
   - Vérifier `app/mailboxes/application_mailbox.rb`
   - Pattern: `/@tracking\.ren0vate\.be$/i`

2. **RequestProgress non trouvé**
   - Vérifier que `email_suivi` correspond exactement
   - Cas de la casse importante

3. **Extraction de documents échoue**
   - Vérifier l'installation de `tesseract` et `poppler-utils`
   - Logs dans `log/production.log`

4. **Webhook Postmark échoue**
   - Vérifier `POSTMARK_INBOUND_WEBHOOK_SECRET`
   - URL du webhook correcte
   - Certificats SSL valides

### Commandes utiles
```bash
# Reprocesser un email échoué
rails runner "ActionMailbox::InboundEmail.find(123).route"

# Nettoyer les anciens emails traités
rails runner "ActionMailbox::InboundEmail.where('created_at < ?', 30.days.ago).destroy_all"

# Statistiques rapides
rails runner "puts RequestProgress.group(:document_extraction_status).count"
```

## 🚀 Déploiement

1. Déployer le code avec les nouvelles migrations
2. Configurer les variables d'environnement
3. Tester avec un email de test
4. Monitorer les logs pendant 24h
5. Configurer les alertes de monitoring

## 📈 Métriques à surveiller

- Taux de succès de traitement des emails
- Temps de traitement moyen
- Taux d'extraction de données réussie
- Volume d'emails par jour/semaine

## 🔒 Sécurité

- ✅ Validation des signatures webhook Postmark
- ✅ Authentification des emails entrants
- ✅ Nettoyage automatique des anciens emails
- ✅ Logs sécurisés (pas de données sensibles)

---

Pour toute question technique, consulter:
- Documentation ActionMailbox: https://guides.rubyonrails.org/action_mailbox_basics.html
- Documentation Postmark: https://postmarkapp.com/developer

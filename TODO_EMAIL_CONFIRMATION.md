# TODO - Correction Email de Confirmation

## Problème
Le système d'email de confirmation Devise ne fonctionne pas actuellement à cause d'un conflit entre :
- Les routes Devise (en dehors du scope de locale)
- Le helper `DeviseUrlHelper` personnalisé
- Le `UserMailer` personnalisé

**Erreur :** `Could not find a valid mapping for User`

## Solution Temporaire Implémentée ✅
- Auto-confirmation des utilisateurs à la création via `after_create :auto_confirm_user`
- Notification dans la vue d'inscription informant les utilisateurs
- Les comptes sont activés immédiatement sans email

## Solution Définitive à Implémenter
1. **Option A :** Déplacer les routes Devise dans le scope de locale
2. **Option B :** Corriger complètement le `DeviseUrlHelper` et `UserMailer`
3. **Option C :** Simplifier en retirant les customisations et utiliser Devise standard

## Fichiers Modifiés (Temporairement)
- `app/models/user.rb` - Ajout de `auto_confirm_user`
- `app/views/devise/registrations/new.html.erb` - Notification temporaire
- `config/initializers/devise.rb` - Utilisation de `Devise::Mailer`

## Action Requise
⚠️ **Corriger le système d'email de confirmation avant la mise en production**

Date: 2025-11-12

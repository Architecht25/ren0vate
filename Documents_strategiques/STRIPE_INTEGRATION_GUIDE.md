# 💳 Guide de configuration Stripe pour Ren0vate

## 🎯 **Workflow SaaS implémenté :**

```
1. PRICING PAGE (/pricing)
   ↓ [Sélection tier B2C Individual, Portfolio, etc.]
2. SUBSCRIPTION SUMMARY (/pricing/summary/:tier)
   ↓ [Confirmation + cycle facturation]
3. STRIPE CHECKOUT (Hosted)
   ↓ [Paiement sécurisé]
4. WELCOME PAGE (/pricing/success)
```

## ⚙️ **Configuration Stripe :**

### 1. Créer un compte Stripe
- Allez sur https://stripe.com
- Créez votre compte business
- Activez le mode test pour développement

### 2. Récupérer les clés API
```bash
# Dans votre dashboard Stripe > Developers > API keys
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
```

### 3. Configurer les webhooks
- URL endpoint : `https://votre-domaine.com/webhooks/stripe`
- Events à écouter :
  - `checkout.session.completed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_succeeded`
  - `invoice.payment_failed`

### 4. Variables d'environnement
```bash
# Copiez .env.example vers .env et configurez :
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
STRIPE_SECRET_KEY=sk_test_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

## 🏗️ **Architecture technique :**

### Modèles créés :
- **Subscription** : Gère les abonnements utilisateurs
- **User** : Enrichi avec méthodes d'abonnement

### Contrôleurs :
- **PricingController** : Gestion du workflow pricing
- **WebhooksController** : Traitement des events Stripe

### Fonctionnalités :
- ✅ Checkout Session Stripe automatique
- ✅ Gestion des abonnements récurrents
- ✅ Webhooks pour sync temps réel
- ✅ Calcul automatique TVA (21% Belgique)
- ✅ Support cycles mensuel/annuel
- ✅ Pages success/cancel
- ✅ Recommandations intelligentes par profil

## 🧪 **Pour tester :**

1. **Mode test Stripe :**
   ```bash
   # Cartes de test Stripe
   4242 4242 4242 4242  # Succès
   4000 0000 0000 0002  # Échec
   ```

2. **Workflow complet :**
   - `/pricing` → Sélectionner tier
   - `/pricing/summary/individual` → Confirmer
   - Stripe Checkout → Payer avec carte test
   - `/pricing/success` → Confirmation

3. **Vérifier webhook :**
   ```bash
   # Logs Rails pour voir les events
   tail -f log/development.log | grep -i stripe
   ```

## 🚀 **Déploiement production :**

1. **Stripe Live mode :**
   - Activer le compte Stripe
   - Remplacer par clés Live (`pk_live_...`, `sk_live_...`)

2. **Webhook en production :**
   - Configurer URL publique
   - Tester les événements

3. **Monitoring :**
   - Dashboard Stripe pour transactions
   - Logs Rails pour erreurs webhook

## 💰 **Tiers disponibles :**

| Tier | Prix | Cible | Fonctionnalités |
|------|------|-------|-----------------|
| **Freemium** | 0€ | Découverte | 1 propriété, 1 simulation |
| **Individual** | 39€ | B2C Particuliers | 3 propriétés, Ren0Chat |
| **Portfolio** | 89€ | B2C Investisseurs | 10 propriétés, Ren0Bot, Decision Hub |
| **Professional** | 149€ | B2B Experts | Illimité, API access |
| **Enterprise** | 299€ | B2B Platform | Solutions personnalisées |

## 🎯 **Prochaines étapes :**

1. **Tests en mode Stripe test**
2. **Configuration webhooks production**
3. **Intégration emails transactionnels**
4. **Dashboard utilisateur pour gérer abonnement**
5. **Analytics revenue et conversions**

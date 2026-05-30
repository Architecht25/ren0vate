# 💳 Guide de configuration Stripe pour Ren0vate

**État au 27 avril 2026 : ✅ LIVE — intégration complète et testée en production (v819)**

## 🎯 **Workflow SaaS implémenté :**

```
1. PRICING PAGE (/pricing)
   ↓ [Sélection tier B2C Individual, Portfolio, etc.]
2. SUBSCRIPTION SUMMARY (/pricing/summary/:tier)
   ↓ [Confirmation + cycle facturation]
3. STRIPE CHECKOUT (Hosted)
   ↓ [Paiement sécurisé — redirect via form_with turbo: false]
4. WELCOME PAGE (/pricing/success)
   ↓ [Webhook customer.subscription.created → Subscription sauvée en DB]
```

## ⚙️ **Configuration en production (Heroku) :**

### Variables d'environnement actives
```bash
STRIPE_SECRET_KEY=sk_live_51TQj8aF3aA7ttws4...   # Clé secrète LIVE
STRIPE_PUBLISHABLE_KEY=pk_live_51TQj8aF3aA7ttws4... # Clé publiable LIVE
STRIPE_WEBHOOK_SECRET=whsec_oQ36L5z59PPcN7...       # Secret webhook LIVE
```

### Webhook configuré
- **Endpoint** : `https://ren0vate-630b5136c442.herokuapp.com/webhooks/stripe`
- **Nom** : "ren0vate-production"
- **6 events** :
  - `checkout.session.completed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_succeeded`
  - `invoice.payment_failed`

## ⚠️ **Points techniques importants :**

### CSP — form-action
Chrome applique `form-action` aux redirects 302 aussi. Sans cette ligne, la redirection vers Stripe est bloquée :
```ruby
# config/initializers/content_security_policy.rb
policy.form_action :self, "https://checkout.stripe.com"
```

### Turbo — désactivé sur le form checkout
Sans `data: { turbo: false }`, Turbo intercepte le POST comme un fetch() → erreur CORS car fetch() ne suit pas les redirects cross-origin :
```erb
<%= form_with url: pricing_checkout_path, method: :post, data: { turbo: false } do |form| %>
```

### API Stripe 2026-04-22.dahlia — `current_period`
Depuis cette version, `current_period_start/end` sont dans les items, pas au root de la subscription. Le webhook convertit l'objet Stripe en Hash avant d'utiliser `dig` :
```ruby
def handle_subscription_created(subscription)
  subscription = JSON.parse(subscription.to_json)  # ← obligatoire
  period_start = subscription['current_period_start'] ||
                 subscription.dig('items', 'data', 0, 'current_period', 'start')
  ...
end
```

### Pricing TTC (tax_behavior: inclusive)
Les prix affichés (39€, 89€…) sont TTC, TVA 21% incluse :
```ruby
price_data: {
  unit_amount: (prix * 100).to_i,
  tax_behavior: 'inclusive',  # Prix TTC
  ...
}
automatic_tax: { enabled: true }
```

## 🏗️ **Architecture technique :**

### Modèles :
- **`Subscription`** : `stripe_subscription_id`, `tier`, `status`, `current_period_start/end`, `user_id`
- **`User`** : enrichi avec `stripe_customer_id`, `subscription_tier`, `property_limit`, `simulation_limit`

### Contrôleurs :
- **`PricingController`** : workflow pricing, expose `stripe_configured?` comme `helper_method`
- **`WebhooksController`** : 6 handlers, conversion Hash systématique

### Gates freemium (en place) :
- `properties_controller.rb` : bloque création si `property_limit` atteint
- `simulations_controller.rb` : bloque création si `simulation_limit` atteint

## 🧪 **Pour tester en mode test :**

```bash
# 1. Basculer sur clés test sur Heroku
heroku config:set STRIPE_SECRET_KEY=sk_test_... STRIPE_PUBLISHABLE_KEY=pk_test_... STRIPE_WEBHOOK_SECRET=whsec_test_... --app ren0vate

# 2. Carte de test
4242 4242 4242 4242  # Succès — expiry 12/28 CVC 123

# 3. Remettre les clés live après test
heroku config:set STRIPE_SECRET_KEY=sk_live_... STRIPE_PUBLISHABLE_KEY=pk_live_... STRIPE_WEBHOOK_SECRET=whsec_live_... --app ren0vate
```

## 💰 **Tiers disponibles :**

| Tier | Prix TTC | Propriétés | Simulations | Cible |
|------|----------|------------|-------------|-------|
| **Freemium** | 0€ | 1 | 1 | Découverte |
| **Individual** | 39€/mois | 3 | ∞ | B2C Particuliers |
| **Portfolio** | 89€/mois | 10 | ∞ | B2C Investisseurs |
| **Professional** | 149€/mois | ∞ | ∞ | B2B Experts |
| **Enterprise** | 299€/mois | ∞ | ∞ | B2B Platform |

## 🎯 **Prochaines étapes :**

1. **Stratégie early adopters** (2.8) — 124 comptes existants, 4 avec >1 propriété, 8 avec >1 simulation. Communiquer avant d'appliquer les gates. Option : freemium étendu jusqu'à fin 2026 + 20% remise
2. **Portail client Stripe** (2.9) — `Stripe::BillingPortal::Session` pour que les abonnés gèrent/annulent eux-mêmes
3. **Emails transactionnels** — SMTP définitif (Postmark/SendGrid) avant de déclencher `welcome_premium` et `payment_failed`
4. **Tests unitaires webhooks** (4.1) — couvrir les 6 handlers

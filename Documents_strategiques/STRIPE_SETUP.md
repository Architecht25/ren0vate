# 🔧 Configuration Stripe pour Ren0vate

## 🎯 **État actuel :**
- ✅ Workflow SaaS complet implémenté
- ✅ Mode démo fonctionnel (sans clés Stripe)
- ⚠️ Clés Stripe à configurer pour paiements réels

## 🚀 **Configuration rapide :**

### 1. Créer un compte Stripe Test
```bash
# 1. Allez sur https://stripe.com
# 2. Créez un compte
# 3. Activez le mode Test
# 4. Récupérez vos clés dans Developers > API keys
```

### 2. Configurer les variables d'environnement
```bash
# Créez un fichier .env dans le dossier racine :
touch .env

# Ajoutez vos clés Stripe :
echo "STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here" >> .env
echo "STRIPE_SECRET_KEY=sk_test_your_key_here" >> .env
echo "STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret" >> .env
```

### 3. Redémarrer le serveur
```bash
# Arrêter le serveur
pkill -f puma

# Redémarrer avec les nouvelles variables
bin/rails server -p 3000
```

## 🧪 **Test du workflow :**

### Mode démo (actuel) :
1. `http://localhost:3000/pricing` → Sélectionner un tier
2. `http://localhost:3000/pricing/summary/individual` → Voir le résumé
3. Cliquer "Simuler le paiement" → Redirige vers success
4. `http://localhost:3000/pricing/success` → Confirmation

### Mode Stripe (avec vraies clés) :
1. Même workflow mais avec vraie session Stripe
2. Formulaire de paiement hébergé par Stripe
3. Cartes de test Stripe :
   - `4242 4242 4242 4242` → Succès
   - `4000 0000 0000 0002` → Échec

## 🔍 **Vérification de l'état :**

```bash
# Vérifier si Stripe est configuré :
rails runner "puts PricingController.new.send(:stripe_configured?)"

# true  → Stripe configuré
# false → Mode démo
```

## 📊 **Format des clés Stripe :**
```bash
# Format des clés Stripe (remplacez par vos vraies clés) :
STRIPE_PUBLISHABLE_KEY=pk_test_[votre_clé_publique_ici]
STRIPE_SECRET_KEY=sk_test_[votre_clé_secrète_ici]
```

## 🎯 **Prochaines étapes :**
1. Configurer vraies clés Stripe test
2. Tester paiements avec cartes test
3. Configurer webhooks en production
4. Monitoring des transactions

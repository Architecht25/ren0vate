# Stripe configuration for SaaS subscriptions
require 'stripe'

Rails.application.configure do
  # Configuration de Stripe
  config.stripe = {
    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
    secret_key: ENV['STRIPE_SECRET_KEY'],
    webhook_secret: ENV['STRIPE_WEBHOOK_SECRET']
  }
end

# Configuration globale de Stripe
Stripe.api_key = ENV['STRIPE_SECRET_KEY'] || 'sk_test_dummy_key_for_development'

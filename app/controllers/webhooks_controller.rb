class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def stripe
    payload = request.body.read
    signature_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.stripe_webhook_secret || ENV['STRIPE_WEBHOOK_SECRET']

    begin
      event = Stripe::Webhook.construct_event(
        payload, signature_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error "❌ Webhook error while parsing basic request: #{e.message}"
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "❌ Webhook signature verification failed: #{e.message}"
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    # Handle the event
    case event['type']
    when 'checkout.session.completed'
      handle_checkout_session_completed(event['data']['object'])
    when 'customer.subscription.created'
      handle_subscription_created(event['data']['object'])
    when 'customer.subscription.updated'
      handle_subscription_updated(event['data']['object'])
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event['data']['object'])
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event['data']['object'])
    when 'invoice.payment_failed'
      handle_payment_failed(event['data']['object'])
    else
      Rails.logger.info "🔔 Unhandled event type: #{event['type']}"
    end

    render json: { received: true }, status: 200
  end

  private

  def handle_checkout_session_completed(session)
    Rails.logger.info "✅ Checkout session completed: #{session['id']}"

    user_id = session['metadata']['user_id']
    tier = session['metadata']['tier']

    if user_id && tier
      user = User.find_by(id: user_id)
      if user
        Rails.logger.info "👤 Creating subscription for user #{user.email} - tier: #{tier}"

        # La subscription sera créée/mise à jour via l'event subscription.created
        # Ici on peut juste logger ou envoyer une notification

        # Envoyer email de bienvenue
        # UserMailer.welcome_premium(user, tier).deliver_later
      end
    end
  rescue => e
    Rails.logger.error "❌ Error handling checkout session: #{e.message}"
  end

  def handle_subscription_created(subscription)
    Rails.logger.info "🆕 Subscription created: #{subscription['id']}"

    customer_id = subscription['customer']
    stripe_customer = Stripe::Customer.retrieve(customer_id)

    # Trouver l'utilisateur par email
    user = User.find_by(email: stripe_customer.email)
    return unless user

    # Extraire le tier des metadata ou du nom du produit
    tier = extract_tier_from_subscription(subscription)

    # Créer ou mettre à jour la subscription
    user_subscription = user.subscriptions.find_or_initialize_by(
      stripe_subscription_id: subscription['id']
    )

    user_subscription.assign_attributes(
      tier: tier,
      status: subscription['status'],
      current_period_start: Time.at(subscription['current_period_start']),
      current_period_end: Time.at(subscription['current_period_end'])
    )

    if user_subscription.save
      Rails.logger.info "✅ Subscription saved for user #{user.email}"
    else
      Rails.logger.error "❌ Failed to save subscription: #{user_subscription.errors.full_messages}"
    end

  rescue => e
    Rails.logger.error "❌ Error handling subscription created: #{e.message}"
  end

  def handle_subscription_updated(subscription)
    Rails.logger.info "🔄 Subscription updated: #{subscription['id']}"

    user_subscription = Subscription.find_by(stripe_subscription_id: subscription['id'])
    return unless user_subscription

    user_subscription.update!(
      status: subscription['status'],
      current_period_start: Time.at(subscription['current_period_start']),
      current_period_end: Time.at(subscription['current_period_end'])
    )

    Rails.logger.info "✅ Subscription updated for user #{user_subscription.user.email}"

  rescue => e
    Rails.logger.error "❌ Error handling subscription updated: #{e.message}"
  end

  def handle_subscription_deleted(subscription)
    Rails.logger.info "🗑️ Subscription deleted: #{subscription['id']}"

    user_subscription = Subscription.find_by(stripe_subscription_id: subscription['id'])
    return unless user_subscription

    user_subscription.update!(status: 'canceled')

    Rails.logger.info "✅ Subscription canceled for user #{user_subscription.user.email}"

  rescue => e
    Rails.logger.error "❌ Error handling subscription deleted: #{e.message}"
  end

  def handle_payment_succeeded(invoice)
    Rails.logger.info "💰 Payment succeeded for invoice: #{invoice['id']}"

    subscription_id = invoice['subscription']
    return unless subscription_id

    user_subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
    return unless user_subscription

    # Sync avec Stripe pour mettre à jour les dates
    user_subscription.sync_with_stripe!

    Rails.logger.info "✅ Payment processed for user #{user_subscription.user.email}"

  rescue => e
    Rails.logger.error "❌ Error handling payment succeeded: #{e.message}"
  end

  def handle_payment_failed(invoice)
    Rails.logger.error "💸 Payment failed for invoice: #{invoice['id']}"

    subscription_id = invoice['subscription']
    return unless subscription_id

    user_subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
    return unless user_subscription

    # Notifier l'utilisateur de l'échec du paiement
    # UserMailer.payment_failed(user_subscription.user).deliver_later

    Rails.logger.info "📧 Payment failure notification sent to #{user_subscription.user.email}"

  rescue => e
    Rails.logger.error "❌ Error handling payment failed: #{e.message}"
  end

  def extract_tier_from_subscription(subscription)
    # Essayer d'extraire le tier des metadata d'abord
    metadata_tier = subscription.dig('metadata', 'tier')
    return metadata_tier if metadata_tier

    # Sinon, essayer depuis les items de la subscription
    line_items = subscription['items']['data']
    return 'individual' unless line_items.any?

    # Examiner le nom du produit pour déterminer le tier
    product_name = line_items.first.dig('price', 'product')
    if product_name.is_a?(String)
      stripe_product = Stripe::Product.retrieve(product_name)
      product_name = stripe_product.name
    end

    case product_name.to_s.downcase
    when /propriétaire|individual/i then 'individual'
    when /investisseur|portfolio/i then 'portfolio'
    when /expert|professional/i then 'professional'
    when /platform|enterprise/i then 'enterprise'
    else 'individual' # fallback
    end
  rescue
    'individual' # fallback en cas d'erreur
  end
end

class Users::RegistrationsController < Devise::RegistrationsController
  def create
    # Honeypot anti-bot : champ caché "website" que seuls les bots remplissent.
    # On simule un succès sans jamais créer le compte, pour ne pas signaler au bot que le champ est surveillé.
    if params.dig(:user, :website).present?
      Rails.logger.warn("[Honeypot] Tentative d'inscription bot bloquée — IP: #{request.remote_ip}")
      redirect_to root_path, notice: I18n.t("devise.registrations.signed_up")
      return
    end

    super
  end

  def destroy
    # Annuler l'abonnement Stripe actif avant suppression du compte
    cancel_stripe_subscription_if_active

    super
  end

  private

  def cancel_stripe_subscription_if_active
    return unless ENV["STRIPE_SECRET_KEY"].present?

    subscription = current_user.current_subscription
    return unless subscription&.stripe_subscription_id.present?

    begin
      Stripe::Subscription.cancel(subscription.stripe_subscription_id)
    rescue Stripe::StripeError => e
      Rails.logger.error("[AccountDeletion] Stripe cancellation failed for user #{current_user.id}: #{e.message}")
      # On continue la suppression même si Stripe échoue
    end
  end
end

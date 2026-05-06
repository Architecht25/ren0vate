class Users::RegistrationsController < Devise::RegistrationsController
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

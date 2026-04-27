# Gère le lien de parrainage pro → client.
# Un architecte ou entrepreneur copie son lien unique et l'envoie à son client.
# Quand le client s'inscrit via ce lien (?ref=TOKEN), il est associé au pro
# et invité à rejoindre son premier projet dès sa création.
class ProReferralsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_professional!

  # GET /pro/inviter-client
  def show
    @referral_url = new_user_registration_url(ref: current_user.referral_token!)
    @referral_token = current_user.referral_token
  end

  # POST /pro/inviter-client  (envoi email d'invitation)
  def create
    client_email = params[:client_email].to_s.strip.downcase
    unless client_email.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to pro_referral_path, alert: "Adresse email invalide."
    end

    referral_url = new_user_registration_url(ref: current_user.referral_token!)
    ProReferralMailer.invite_client(current_user, client_email, referral_url).deliver_later
    redirect_to pro_referral_path, notice: "Invitation envoyée à #{client_email}."
  end

  private

  def require_professional!
    unless current_user.professional_guest? || current_user.professional_type.present?
      redirect_to dashboard_path, alert: "Accès réservé aux professionnels."
    end
  end
end

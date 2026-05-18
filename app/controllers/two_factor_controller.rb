class TwoFactorController < ApplicationController
  skip_before_action :require_admin_2fa

  before_action :authenticate_user!
  before_action :require_admin_role

  OTP_EXPIRY = 10.minutes

  def show
    send_otp unless otp_pending?
  end

  def verify
    provided = params[:otp_code].to_s.gsub(/\s/, '')
    stored   = session[:admin_otp_code]
    sent_at  = session[:admin_otp_sent_at]

    if stored.present? && provided == stored && sent_at.present? && Time.zone.parse(sent_at.to_s) > OTP_EXPIRY.ago
      session.delete(:admin_otp_code)
      session.delete(:admin_otp_sent_at)

      if params[:remember_device] == '1'
        cookies.signed[:admin_2fa_verified] = {
          value:    current_user.id.to_s,
          expires:  30.days.from_now,
          httponly: true,
          secure:   Rails.env.production?,
          same_site: :lax
        }
      end

      redirect_to after_sign_in_path_for(current_user), notice: "Identité vérifiée."
    else
      flash.now[:alert] = "Code invalide ou expiré. Veuillez réessayer."
      render :show, status: :unprocessable_entity
    end
  end

  def resend
    send_otp(force: true)
    redirect_to admin_two_factor_path, notice: "Un nouveau code a été envoyé à #{current_user.email}."
  end

  private

  def require_admin_role
    redirect_to root_path, alert: "Accès non autorisé." unless current_user.admin?
  end

  def otp_pending?
    session[:admin_otp_code].present? && session[:admin_otp_sent_at].present? &&
      Time.zone.parse(session[:admin_otp_sent_at].to_s) > OTP_EXPIRY.ago
  end

  def send_otp(force: false)
    return if otp_pending? && !force

    code = SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')
    session[:admin_otp_code]    = code
    session[:admin_otp_sent_at] = Time.current.iso8601
    TwoFactorMailer.otp(current_user, code).deliver_later
  end
end

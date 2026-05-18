class TwoFactorMailer < ApplicationMailer
  def otp(user, code)
    @user = user
    @code = code
    @expires_in = "10 minutes"
    mail(to: user.email, subject: "[Ren0vate] Code de vérification admin : #{code}")
  end
end

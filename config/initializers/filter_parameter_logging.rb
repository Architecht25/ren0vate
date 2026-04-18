# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :iban, :bic, :national_number, :registre_national, :revenu, :revenu_demandeur, :revenu_conjoint,
  :revenu_imposable_global, :texte_ocr_brut, :donnees_extraites
]

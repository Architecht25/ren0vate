class DataRetentionJob < ApplicationJob
  queue_as :default

  # RGPD art. 5(1)(e) — limitation de la conservation
  # Anonymise les comptes inactifs depuis plus de 2 ans.
  #
  # "Inactif" = updated_at < 2.years.ago (proxy d'activité).
  # Pour plus de précision, activer le module Devise :trackable
  # afin d'obtenir last_sign_in_at.
  #
  # L'anonymisation efface les données personnelles tout en conservant
  # l'ID pour l'intégrité référentielle des projets/documents.

  INACTIVITY_THRESHOLD = 2.years
  ANONYMIZED_EMAIL_DOMAIN = 'anonymized.ren0vate.be'

  def perform(dry_run: false)
    cutoff = INACTIVITY_THRESHOLD.ago

    candidates = User.where(role: :user)
                     .where('updated_at < ?', cutoff)

    Rails.logger.info "[DataRetentionJob] #{dry_run ? '[DRY RUN] ' : ''}#{candidates.count} compte(s) inactifs depuis > 2 ans (cutoff: #{cutoff.to_date})"

    return if dry_run

    anonymized_count = 0
    candidates.find_each do |user|
      anonymize_user!(user)
      anonymized_count += 1
    rescue => e
      Rails.logger.error "[DataRetentionJob] Erreur anonymisation user ##{user.id}: #{e.message}"
    end

    Rails.logger.info "[DataRetentionJob] Anonymisation terminée — #{anonymized_count} compte(s) traité(s)"
  end

  private

  def anonymize_user!(user)
    anonymous_email = "anonymized_#{user.id}@#{ANONYMIZED_EMAIL_DOMAIN}"

    user.update_columns(
      email:                    anonymous_email,
      encrypted_password:       Devise.friendly_token,   # rend le compte inaccessible
      first_name:               nil,
      last_name:                nil,
      nom:                      nil,
      nom_cabinet:              nil,
      phone:                    nil,
      street:                   nil,
      number:                   nil,
      city:                     nil,
      postal_code:              nil,
      national_number:          nil,
      iban:                     nil,
      num_bce:                  nil,
      revenu_demandeur:         nil,
      revenu_conjoint:          nil,
      annee_revenus_demandeur:  nil,
      annee_revenus_conjoint:   nil,
      nombre_enfants:           nil,
      personnes_60_ans_et_plus: nil,
      femme_enceinte:           nil,
      protected_client:         nil,
      situation_familiale:      nil,
      region:                   nil,
      stripe_customer_id:       nil,
      referral_token:           nil,
      reset_password_token:     nil,
      reset_password_sent_at:   nil,
      remember_created_at:      nil,
      unlock_token:             nil
    )

    Rails.logger.info "[DataRetentionJob] Anonymisé user ##{user.id} (était: #{user.email})"
  end
end

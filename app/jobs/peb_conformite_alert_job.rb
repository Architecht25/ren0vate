class PebConformiteAlertJob < ApplicationJob
  queue_as :default

  PEB_LABELS_CONCERNES = %w[F G E].freeze
  PEB_LABELS_URGENTS   = %w[F G].freeze

  def perform
    Rails.logger.info "[PebConformiteAlertJob] Démarrage vérification PEB Bruxelles"

    notifications_creees = 0

    # Propriétés Bruxelles avec un label PEB renseigné (champ direct ou via peb_donnees)
    properties_bruxelles.each do |property|
      peb_label = detect_peb_label(property)
      next unless peb_label.present? && PEB_LABELS_CONCERNES.include?(peb_label.upcase)

      begin
        notif = Notification.create_alerte_peb_bruxelles(property.user, property, peb_label)
        notifications_creees += 1 if notif.present?
      rescue => e
        Rails.logger.error "[PebConformiteAlertJob] Erreur property##{property.id}: #{e.message}"
      end
    end

    Rails.logger.info "[PebConformiteAlertJob] #{notifications_creees} notification(s) créée(s)"
    notifications_creees
  end

  private

  def properties_bruxelles
    Property
      .joins(:user)
      .where(region: 'bruxelles')
      .where.not(
        certificat_peb_bruxelles: [nil, ''],
      )
      .or(
        Property
          .joins(:user)
          .where(region: 'bruxelles')
          .where.not(peb: [nil, ''])
      )
      .includes(:user, :peb_donnees)
  end

  def detect_peb_label(property)
    # Priorité : champ direct Bruxelles > champ générique > dernier scan OCR
    label = property.certificat_peb_bruxelles.presence ||
            property.peb.presence ||
            property.peb_donnees
              .where(phase: 'avant_travaux')
              .order(created_at: :desc)
              .pick(:label_peb)

    # Normaliser : extraire la lettre principale (ex: "F+", "G-" → "F", "G")
    label&.strip&.upcase&.match(/\A([A-G][+-]?)/i)&.[](1)&.first
  end
end

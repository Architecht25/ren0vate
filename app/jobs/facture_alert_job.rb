class FactureAlertJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Démarrage du job de vérification des alertes factures"

    begin
      # Vérifier les alertes automatiques
      resultats = FactureAlertService.verifier_alertes_automatiques

      # Logger les résultats
      Rails.logger.info "Alertes factures vérifiées: #{resultats[:notifications_creees]} notifications créées"
      Rails.logger.info "Détails: délais=#{resultats[:delais_critiques].count}, budget=#{resultats[:depassements_budget].count}, extraction=#{resultats[:extractions_faibles].count}"

      # Optionnel: envoyer un email de rapport admin si beaucoup d'alertes
      if resultats[:notifications_creees] > 10
        AdminMailer.facture_alert_report(resultats).deliver_later if defined?(AdminMailer)
      end

    rescue => e
      Rails.logger.error "Erreur dans FactureAlertJob: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Optionnel: notifier les admins de l'erreur
      raise e if Rails.env.development?
    end
  end
end

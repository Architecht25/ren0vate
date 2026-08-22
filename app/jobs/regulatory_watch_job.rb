# Vérification mensuelle des pages réglementaires officielles (RegulatorySource).
# N'envoie un email que s'il y a au moins un changement détecté — silencieux sinon.
# Voir config/recurring.yml (schedule mensuel) et RegulatoryWatchService.
class RegulatoryWatchJob < ApplicationJob
  queue_as :default

  # watch_service injectable pour les tests (doit répondre à .check_all)
  def perform(watch_service: RegulatoryWatchService)
    results = watch_service.check_all

    changed = results.select(&:changed?)
    errored = results.select(&:error?)

    if errored.any?
      Rails.logger.warn "RegulatoryWatchJob — #{errored.size} source(s) en échec: " \
                         "#{errored.map { |r| r.source.label }.join(', ')}"
    end

    if changed.any?
      Rails.logger.info "RegulatoryWatchJob — #{changed.size} source(s) modifiée(s): " \
                         "#{changed.map { |r| r.source.label }.join(', ')}"
      AdminMailer.regulatory_sources_changed(changed.map(&:source)).deliver_later
    else
      Rails.logger.info "RegulatoryWatchJob — aucun changement détecté (#{results.size} source(s) vérifiée(s))"
    end
  end
end

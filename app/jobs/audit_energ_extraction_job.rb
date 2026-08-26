# AuditEnergExtractionJob
#
# Exécute l'extraction Claude (ou son fallback OCR) en arrière-plan, sur le
# dyno worker dédié (Solid Queue). L'appel Claude en lecture PDF native peut
# prendre 30 à 90s sur un audit complet — largement au-delà des 30s de timeout
# fixe du routeur Heroku (H12) si on le faisait en synchrone dans la requête
# web (cf. ProjectsController#scan_audit_energ, qui ne fait plus que créer la
# ligne "en_cours" et enqueuer ce job).

class AuditEnergExtractionJob < ApplicationJob
  queue_as :default

  def perform(audit_energ_donnee_id, document_id)
    audit = AuditEnergDonnee.find_by(id: audit_energ_donnee_id)
    return unless audit

    document = Document.find_by(id: document_id)
    unless document&.file&.attached?
      audit.marquer_echec_extraction!('document ou fichier attaché introuvable')
      return
    end

    document.file.blob.open do |tempfile|
      file    = ActiveStorageFileAdapter.new(tempfile, document.file.content_type)
      result  = AuditEnergClaudeService.new(file).extraire_donnees_audit

      if result[:success]
        audit.appliquer_resultat_extraction!(result)
        synchroniser_projet(audit.project, result)
      else
        audit.marquer_echec_extraction!(result[:error])
      end
    end
  rescue StandardError => e
    Rails.logger.error "AuditEnergExtractionJob error (audit_id=#{audit_energ_donnee_id}): #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    audit&.marquer_echec_extraction!(e.message)
  end

  private

  def synchroniser_projet(project, result)
    return unless project

    if project.numero_audit.blank? && result[:numero_audit].present?
      project.update_column(:numero_audit, result[:numero_audit])
    end
    if project.numero_agrement_auditeur.blank? && result[:numero_pae].present?
      project.update_column(:numero_agrement_auditeur, result[:numero_pae])
    end
  end
end

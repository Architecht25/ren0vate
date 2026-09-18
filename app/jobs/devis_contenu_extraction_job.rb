# DevisContenuExtractionJob
#
# Exécute la ventilation par poste d'un devis (Bots::DevisContenuClaudeService)
# en arrière-plan, sur le dyno worker dédié (Solid Queue). La lecture PDF native
# par Claude peut prendre 10-40s — largement au-delà des 30s de timeout fixe du
# routeur Heroku (H12) si faite en synchrone dans la requête web (cf.
# OcrController#scan_devis, qui reste synchrone pour le montant/les dates mais
# enqueue ce job séparément pour la ventilation par poste, plus coûteuse).
class DevisContenuExtractionJob < ApplicationJob
  queue_as :default

  def perform(devis_donnee_id, document_id)
    devis_donnee = DevisDonnee.find_by(id: devis_donnee_id)
    return unless devis_donnee

    document = Document.find_by(id: document_id)
    unless document&.file&.attached?
      devis_donnee.marquer_echec_analyse_contenu!('document ou fichier attaché introuvable')
      return
    end

    document.file.blob.open do |tempfile|
      file   = Documents::ActiveStorageFileAdapter.new(tempfile, document.file.content_type)
      result = Bots::DevisContenuClaudeService.new(file).extraire_postes

      if result[:success]
        devis_donnee.appliquer_resultat_analyse_contenu!(result)
      else
        devis_donnee.marquer_echec_analyse_contenu!(result[:error])
      end
    end
  rescue StandardError => e
    Rails.logger.error "DevisContenuExtractionJob error (devis_donnee_id=#{devis_donnee_id}): #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    devis_donnee&.marquer_echec_analyse_contenu!(e.message)
  end
end

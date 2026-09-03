# PebExtractionJob
#
# Exécute le scan OCR du certificat PEB en arrière-plan, sur le dyno worker
# dédié (Solid Queue). Pour les PDFs VEKA (Flandre), dont l'encodage de police
# est incompatible avec pdftotext/PDF::Reader, OcrService bascule sur un
# fallback OCR page-par-page (pdftoppm + Tesseract multi-langue), qui peut
# largement dépasser les 30s de timeout fixe du routeur Heroku (H12) si fait
# en synchrone dans la requête web (cf. OcrController#scan_peb, qui ne fait
# plus que créer la ligne "en_cours" et enqueuer ce job).
class PebExtractionJob < ApplicationJob
  queue_as :default

  def perform(peb_donnee_id, document_id)
    peb_donnee = PebDonnee.find_by(id: peb_donnee_id)
    return unless peb_donnee

    document = Document.find_by(id: document_id)
    unless document&.file&.attached?
      peb_donnee.marquer_echec_extraction!('document ou fichier attaché introuvable')
      return
    end

    document.file.blob.open do |tempfile|
      file   = ActiveStorageFileAdapter.new(tempfile, document.file.content_type)
      result = PebOcrService.new(file).extraire_donnees_peb

      if result[:success]
        peb_donnee.appliquer_resultat_extraction!(result)
        document.update_column(:notes, "Certificat PEB scanné le #{Date.today.strftime('%d/%m/%Y')} — #{result[:region]&.capitalize} — confiance #{result[:confiance_ocr].to_i} %")
        synchroniser_propriete(peb_donnee, result)
      else
        peb_donnee.marquer_echec_extraction!(result[:error])
      end
    end
  rescue StandardError => e
    Rails.logger.error "PebExtractionJob error (peb_donnee_id=#{peb_donnee_id}): #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    peb_donnee&.marquer_echec_extraction!(e.message)
  end

  private

  # Mise à jour automatique des champs PEB de la propriété — même règle que
  # l'ancien flux synchrone (confiance >= 70), qui diffère selon la phase :
  # - avant_travaux : certificat_peb_* (région) + date_peb_avant_travaux, si label détecté
  # - apres_travaux : date_peb_apres_travaux uniquement, si date détectée
  def synchroniser_propriete(peb_donnee, result)
    property = peb_donnee.property
    return unless property && result[:confiance_ocr].to_i >= 70

    if peb_donnee.apres_travaux?
      property.update_column(:date_peb_apres_travaux, result[:date_certificat]) if result[:date_certificat].present?
      return
    end

    return unless result[:label_peb].present?

    champ_peb = case result[:region]
                when 'wallonie'  then :certificat_peb_wallonie
                when 'flandre'   then :certificat_peb_flandre
                when 'bruxelles' then :certificat_peb_bruxelles
                end
    return unless champ_peb

    updates = { champ_peb => result[:label_peb] }
    updates[:date_peb_avant_travaux] = result[:date_certificat] if result[:date_certificat].present?
    property.update(updates)
  end
end

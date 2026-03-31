class OcrController < ApplicationController
  before_action :authenticate_user!

  # POST /ocr/scan
  def scan
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      ocr_service = OcrService.new(params[:file])
      result = ocr_service.call

      if result[:success]
        render json: {
          success: true,
          text: result[:text],
          confidence: result[:confidence],
          language: result[:language],
          processing_time: result[:processing_time],
          method: result[:method]
        }
      else
        render json: {
          error: result[:error]
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Erreur OCR: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement OCR',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # POST /ocr/scan_and_create_document
  def scan_and_create_document
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      # Effectuer l'OCR d'abord
      ocr_service = OcrService.new(params[:file])
      ocr_result = ocr_service.call

      unless ocr_result[:success]
        return render json: { error: ocr_result[:error] }, status: :unprocessable_entity
      end

      # Créer le document avec le texte OCR dans les notes
      document_params = build_document_params(ocr_result)
      @document = current_user.documents.build(document_params)

      if @document.save
        # Générer file_url après la sauvegarde
        if @document.file.attached? && @document.file_url.blank?
          @document.update(file_url: rails_blob_url(@document.file))
        end

        render json: {
          success: true,
          document: document_json(@document),
          ocr: {
            text: ocr_result[:text],
            confidence: ocr_result[:confidence],
            language: ocr_result[:language],
            method: ocr_result[:method]
          },
          message: 'Document créé avec succès et texte extrait par OCR'
        }
      else
        render json: {
          error: 'Erreur lors de la création du document',
          details: @document.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Erreur OCR + Document: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # POST /ocr/scan_existing/:id
  def scan_existing
    @document = current_user.documents.find(params[:id])

    unless @document.file.attached?
      return render json: { error: 'Ce document ne possède pas de fichier attaché' }, status: :unprocessable_entity
    end

    begin
      # Télécharger le fichier depuis ActiveStorage dans un Tempfile
      tempfile = Tempfile.new(['ocr_existing', File.extname(@document.file.filename.to_s)])
      tempfile.binmode
      tempfile.write(@document.file.download)
      tempfile.rewind

      # Construire un objet compatible OcrService
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: @document.file.filename.to_s,
        type: @document.file.content_type
      )

      ocr_service = OcrService.new(uploaded_file)
      result = ocr_service.call

      if result[:success]
        # Mettre à jour les notes du document avec le résultat OCR
        ocr_notes = "📄 Texte extrait par OCR (#{result[:method]}):\n" \
                    "Confiance: #{result[:confidence]}%\n" \
                    "Langue: #{result[:language]}\n" \
                    "Temps de traitement: #{result[:processing_time]}s\n\n" \
                    "#{result[:text]}"

        existing_notes = @document.notes.to_s.sub(/📄 Texte extrait par OCR.*\z/m, '').strip
        new_notes = [existing_notes.presence, ocr_notes].compact.join("\n\n")
        @document.update!(notes: new_notes)

        render json: {
          success: true,
          document_id: @document.id,
          text: result[:text],
          confidence: result[:confidence],
          language: result[:language],
          processing_time: result[:processing_time],
          method: result[:method]
        }
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Document introuvable' }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "OCR scan_existing error: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement OCR',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    ensure
      tempfile&.close
      tempfile&.unlink
    end
  end

  # POST /ocr/scan_rib
  # Scanne un RIB et retourne l'IBAN/BIC pour pré-remplissage du profil.
  def scan_rib
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      rib_service = RibOcrService.new(params[:file])
      result      = rib_service.extraire_donnees_rib

      unless result[:success]
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end

      document = current_user.documents.create!(
        file:          params[:file],
        type_document: 'rib',
        status:        'pending',
        notes:         "RIB scanné le #{Date.today.strftime('%d/%m/%Y')} — confiance #{result[:confiance_extraction].to_f.round(1)} %"
      )

      if document.file.attached? && document.file_url.blank?
        document.update_column(:file_url, rails_blob_url(document.file))
      end

      rib_donnee = RibDonnee.create!(
        document:           document,
        user:               current_user,
        iban:               result[:iban],
        bic:                result[:bic],
        nom_titulaire:      result[:nom_titulaire],
        nom_banque:         result[:nom_banque],
        confiance_ocr:      result[:confiance_extraction],
        extraction_complete: result[:extraction_complete],
        texte_ocr_brut:     result[:texte_brut],
        donnees_extraites:  result[:donnees_rib].to_h
      )

      # Application automatique si IBAN extrait avec confiance suffisante
      if rib_donnee.confiance_ocr.to_f >= 75 && result[:iban].present?
        current_user.update(iban: result[:iban])
      end

      render json: {
        success:             true,
        document_id:         document.id,
        rib_donnee_id:       rib_donnee.id,
        iban:                result[:iban],
        iban_formate:        rib_donnee.iban_formate,
        bic:                 result[:bic],
        nom_titulaire:       result[:nom_titulaire],
        nom_banque:          result[:nom_banque],
        confiance_extraction: result[:confiance_extraction],
        extraction_complete: result[:extraction_complete],
        applied_to_profile:  rib_donnee.confiance_ocr.to_f >= 75 && result[:iban].present?,
        message:             message_retour_rib(result)
      }

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "RIB save error: #{e.message}"
      render json: { error: "Erreur lors de la sauvegarde des données RIB", details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "RIB OCR error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: {
        error:   "Erreur lors du traitement du RIB",
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # POST /ocr/scan_aer
  # Scanne un AER (Avertissement-Extrait de Rôle) et retourne les données fiscales
  # extraites pour pré-remplissage du profil utilisateur.
  # Le document AER est créé dans la base et les données extraites persistées.
  # Si confiance >= 75, les champs de revenus du User sont mis à jour automatiquement.
  def scan_aer
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      aer_service = AerOcrService.new(params[:file])
      result      = aer_service.extraire_donnees_aer

      unless result[:success]
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end

      # Créer le document AER lié à l'utilisateur courant
      document = current_user.documents.create!(
        file:          params[:file],
        type_document: 'aer',
        status:        'pending',
        notes:         "AER scanné le #{Date.today.strftime('%d/%m/%Y')} — confiance #{result[:confiance_extraction].to_f.round(1)} %"
      )

      # Générer file_url si nécessaire
      if document.file.attached? && document.file_url.blank?
        document.update_column(:file_url, rails_blob_url(document.file))
      end

      # Persister les données extraites dans aer_donnees
      aer_donnee = AerDonnee.create!(
        document:                       document,
        user:                           current_user,
        annee_revenus:                  result[:annee_revenus],
        annee_exercice_imposition:      result[:annee_exercice_imposition],
        revenu_imposable_global:        result[:revenu_imposable_global],
        revenu_demandeur:               result[:revenu_demandeur],
        revenu_conjoint:                result[:revenu_conjoint],
        nombre_enfants_charge:          result[:nombre_enfants_charge],
        nom_contribuable:               result[:nom_contribuable],
        prenom_contribuable:            result[:prenom_contribuable],
        type_declaration:               result[:donnees_aer]&.dig(:type_declaration),
        date_enrolement:                result[:date_enrolement],
        confiance_ocr:                  result[:confiance_extraction],
        extraction_complete:            result[:extraction_complete],
        revenus_potentiellement_perimes: result[:revenus_potentiellement_perimes],
        texte_ocr_brut:                 result[:texte_brut],
        donnees_extraites:              result[:donnees_aer].to_h
      )

      # Application automatique si extraction fiable
      # Les colonnes user sont integer → on arrondit les valeurs decimales de l'AER
      if aer_donnee.confiance_ocr.to_f >= 75
        user_updates = {}
        user_updates[:revenu_demandeur]        = result[:revenu_demandeur].to_f.round        if result[:revenu_demandeur].present?
        user_updates[:revenu_conjoint]         = result[:revenu_conjoint].to_f.round          if result[:revenu_conjoint].present?
        user_updates[:annee_revenus_demandeur] = result[:annee_revenus]                        if result[:annee_revenus].present?
        user_updates[:annee_revenus_conjoint]  = result[:annee_revenus]                        if result[:revenu_conjoint].present? && result[:annee_revenus].present?
        current_user.update(user_updates) if user_updates.any?
      end

      render json: {
        success:                         true,
        document_id:                     document.id,
        aer_donnee_id:                   aer_donnee.id,
        # Données pour pré-remplissage côté JS
        revenu_demandeur:                result[:revenu_demandeur],
        revenu_conjoint:                 result[:revenu_conjoint],
        revenu_imposable_global:         result[:revenu_imposable_global],
        annee_revenus:                   result[:annee_revenus],
        annee_exercice_imposition:       result[:annee_exercice_imposition],
        nom_contribuable:                result[:nom_contribuable],
        prenom_contribuable:             result[:prenom_contribuable],
        type_declaration:                result[:donnees_aer]&.dig(:type_declaration),
        nombre_enfants_charge:           result[:nombre_enfants_charge],
        confiance_extraction:            result[:confiance_extraction],
        extraction_complete:             result[:extraction_complete],
        revenus_potentiellement_perimes: result[:revenus_potentiellement_perimes],
        applied_to_profile:              aer_donnee.confiance_ocr.to_f >= 75,
        message:                         message_retour(result)
      }

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "AER save error: #{e.message}"
      render json: { error: "Erreur lors de la sauvegarde des données AER", details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "AER OCR error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: {
        error:   'Erreur lors du traitement de l\'AER',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # POST /ocr/scan_peb
  # Scanne un certificat PEB (Flandre/Wallonie/Bruxelles) et persiste les données
  # dans peb_donnees. Lie le document au bien property_id si fourni.
  # Met à jour automatiquement le champ certificat_peb_* du bien si confiance >= 70.
  def scan_peb
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      peb_service = PebOcrService.new(params[:file])
      result      = peb_service.extraire_donnees_peb

      unless result[:success]
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end

      # Propriété associée (optionnelle mais attendue depuis les formulaires de bien)
      property = nil
      if params[:property_id].present?
        property = current_user.properties.find_by(id: params[:property_id])
      end

      # Créer le document PEB
      document = current_user.documents.create!(
        file:          params[:file],
        type_document: 'certificat_peb_avant',
        property:      property,
        status:        'pending',
        notes:         "Certificat PEB scanné le #{Date.today.strftime('%d/%m/%Y')} — #{result[:region]&.capitalize} — confiance #{result[:confiance_ocr].to_i} %"
      )

      if document.file.attached? && document.file_url.blank?
        document.update_column(:file_url, rails_blob_url(document.file))
      end

      # Persister les données extraites
      peb_donnee = PebDonnee.create!(
        property:           property,
        document:           document,
        user:               current_user,
        region:             result[:region],
        numero_certificat:  result[:numero_certificat],
        label_peb:          result[:label_peb],
        score_ep:           result[:score_ep],
        surface_reference:  result[:surface_reference],
        date_certificat:    result[:date_certificat],
        date_validite:      result[:date_validite],
        confiance_ocr:      result[:confiance_ocr],
        extraction_complete: result[:extraction_complete],
        texte_ocr_brut:     result[:texte_ocr_brut],
        donnees_extraites:  { 'recommandations' => result[:recommandations] || [] }
      )

      # Mise à jour automatique du champ certificat_peb_* de la propriété
      if property && result[:confiance_ocr].to_i >= 70 && result[:label_peb].present?
        champ_peb = case result[:region]
                    when 'wallonie'  then :certificat_peb_wallonie
                    when 'flandre'   then :certificat_peb_flandre
                    when 'bruxelles' then :certificat_peb_bruxelles
                    end
        if champ_peb
          updates = { champ_peb => result[:label_peb] }
          updates[:date_peb_avant_travaux] = result[:date_certificat] if result[:date_certificat].present?
          property.update(updates)
        end
      end

      render json: {
        success:            true,
        document_id:        document.id,
        peb_donnee_id:      peb_donnee.id,
        region:             result[:region],
        numero_certificat:  result[:numero_certificat],
        label_peb:          result[:label_peb],
        score_ep:           result[:score_ep],
        surface_reference:  result[:surface_reference],
        date_certificat:    result[:date_certificat]&.strftime('%d/%m/%Y'),
        date_validite:      result[:date_validite]&.strftime('%d/%m/%Y'),
        confiance_ocr:      result[:confiance_ocr],
        extraction_complete: result[:extraction_complete],
        perime:             peb_donnee.perime?,
        applied_to_property: property.present? && result[:confiance_ocr].to_i >= 70 && result[:label_peb].present?,
        message:            message_retour_peb(result, peb_donnee)
      }

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "PEB save error: #{e.message}"
      render json: { error: "Erreur lors de la sauvegarde du certificat PEB", details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "PEB OCR error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: {
        error:   'Erreur lors du traitement du certificat PEB',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  private

  def message_retour_peb(result, peb_donnee)
    region_label = { 'wallonie' => 'Wallonie', 'flandre' => 'Flandre', 'bruxelles' => 'Bruxelles' }[result[:region]] || 'Région non détectée'
    if peb_donnee.perime?
      return "⚠️ Certificat PEB #{region_label} expiré (validité : #{result[:date_validite]&.strftime('%d/%m/%Y')}) — veuillez le renouveler."
    end
    if result[:extraction_complete]
      return "✅ Certificat PEB #{region_label} extrait (label #{result[:label_peb]}, #{result[:score_ep].to_i} kWh/m².an). Vérifiez et sauvegardez."
    end
    "⚠️ Extraction partielle #{region_label} (confiance #{result[:confiance_ocr].to_i} %). Complétez les champs manquants."
  end

  def message_retour_rib(result)
    return "✅ IBAN extrait avec succès (confiance #{result[:confiance_extraction].to_f.round(1)} %). Vérifiez et sauvegardez." if result[:extraction_complete]

    "⚠️ IBAN non détecté (confiance #{result[:confiance_extraction].to_f.round(1)} %). Encodez votre IBAN manuellement."
  end

  def message_retour(result)
    return "⚠️ Données fiscales potentiellement périmées (revenus #{result[:annee_revenus]}) — vérifiez qu'elles correspondent bien aux revenus de référence pour les primes #{Date.today.year}." if result[:revenus_potentiellement_perimes]
    return "✅ Données extraites avec succès (confiance #{result[:confiance_extraction].to_f.round(1)} %). Veuillez vérifier les champs pré-remplis avant de sauvegarder." if result[:extraction_complete]

    "⚠️ Extraction partielle (confiance #{result[:confiance_extraction].to_f.round(1)} %). Complétez manuellement les champs manquants."
  end

  def build_document_params(ocr_result)
    # Construire les notes avec le texte OCR
    ocr_notes = if ocr_result[:confidence] > 0
      "📄 Texte extrait par OCR (#{ocr_result[:method]}):\n" \
      "Confiance: #{ocr_result[:confidence]}%\n" \
      "Langue: #{ocr_result[:language]}\n" \
      "Temps de traitement: #{ocr_result[:processing_time]}s\n\n" \
      "#{ocr_result[:text]}"
    else
      "📄 Document scanné (OCR non disponible)\n" \
      "Méthode: #{ocr_result[:method]}\n\n" \
      "#{ocr_result[:text]}"
    end

    document_params = {
      file: params[:file],
      type_document: params[:type_document] || 'facture',
      notes: ocr_notes,
      status: 'pending'
    }

    # Associer à un contexte si fourni
    document_params[:property_id] = params[:property_id] if params[:property_id].present?
    document_params[:project_id] = params[:project_id] if params[:project_id].present?
    document_params[:request_id] = params[:request_id] if params[:request_id].present?
    document_params[:simulation_id] = params[:simulation_id] if params[:simulation_id].present?

    document_params
  end

  def document_json(document)
    {
      id: document.id,
      type_document: document.type_document,
      filename: document.file.filename.to_s,
      file_size: document.file.byte_size,
      notes: document.notes,
      status: document.status,
      created_at: document.created_at.strftime("%d/%m/%Y %H:%M"),
      file_url: document.file_url
    }
  end
end

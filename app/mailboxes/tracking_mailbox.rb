class TrackingMailbox < ApplicationMailbox
  # Traiter uniquement les emails envoyés aux adresses de tracking

  def process
    Rails.logger.info "📧 Traitement d'un email de tracking pour: #{mail.to.first}"

    # Rechercher le RequestProgress correspondant
    find_request_progress
    ensure_request_progress_exists

    # Mettre à jour les informations de base
    update_request_progress_from_email

    # Traiter les pièces jointes si présentes
    process_attachments if mail.attachments.any?

    # Envoyer une notification à l'utilisateur
    notify_user_of_update

    Rails.logger.info "✅ Email de tracking traité avec succès pour RequestProgress ##{@request_progress.id}"
  end

  private

  def find_request_progress
    email_address = mail.to.first
    Rails.logger.info "🔍 Recherche RequestProgress pour: #{email_address}"
    @request_progress = RequestProgress.find_by(email_suivi: email_address)
    Rails.logger.info "📧 RequestProgress #{@request_progress ? "trouvé (ID: #{@request_progress.id})" : "NON TROUVÉ"}"
  end

  def ensure_request_progress_exists
    unless @request_progress
      Rails.logger.error "❌ Aucun RequestProgress trouvé pour l'email: #{mail.to.first}"
      Rails.logger.error "📋 Adresses disponibles: #{RequestProgress.pluck(:email_suivi).join(', ')}"
      # Optionnel: envoyer un email de bounce ou créer une notification admin
      bounce_with ProcessingError.new("Adresse de tracking non reconnue")
    else
      Rails.logger.info "✅ RequestProgress #{@request_progress.id} prêt pour traitement"
    end
  end

  def update_request_progress_from_email
    # Extraire les informations du sujet et du corps de l'email
    subject_info = extract_info_from_subject(mail.subject)
    body_info = extract_info_from_body(mail.decoded)

    # Mettre à jour le RequestProgress avec tracking email
    @request_progress.update!(
      date_derniere_maj: Date.current,
      commentaires_admin: build_comment_from_email,
      document_recu: true,
      email_processed_at: Time.current,
      document_extraction_status: mail.attachments.any? ? 'pending' : 'completed',
      # Mettre à jour le statut si on peut le détecter
      status_administratif: detect_status_from_email || @request_progress.status_administratif
    )
  end

  def process_attachments
    Rails.logger.info "📎 Traitement de #{mail.attachments.count} pièce(s) jointe(s)"

    mail.attachments.each do |attachment|
      # Traiter selon le type de fichier
      case attachment.content_type
      when /pdf/
        process_pdf_attachment(attachment)
      when /image/
        process_image_attachment(attachment)
      else
        Rails.logger.warn "⚠️  Type de fichier non supporté: #{attachment.content_type}"
      end
    end
  end

  def process_pdf_attachment(attachment)
    # Attacher le PDF au RequestProgress
    @request_progress.document_suivi_pdf.attach(
      io: StringIO.new(attachment.decoded),
      filename: attachment.filename,
      content_type: attachment.content_type
    )

    # Programmer l'extraction d'informations en arrière-plan
    EmailDocumentExtractionJob.perform_later(@request_progress.id, 'pdf')
  end

  def process_image_attachment(attachment)
    # Attacher l'image au RequestProgress
    @request_progress.document_suivi_photo.attach(
      io: StringIO.new(attachment.decoded),
      filename: attachment.filename,
      content_type: attachment.content_type
    )

    # Programmer l'extraction d'informations en arrière-plan
    EmailDocumentExtractionJob.perform_later(@request_progress.id, 'image')
  end

  def extract_info_from_subject(subject)
    # Logique pour extraire des infos du sujet
    # Ex: rechercher des numéros de dossier, statuts, etc.
    {
      numero_dossier: extract_dossier_number(subject),
      status_hint: extract_status_hint(subject)
    }
  end

  def extract_info_from_body(body)
    # Logique pour extraire des infos du corps de l'email
    {
      montant_accorde: extract_amount(body),
      decision: extract_decision(body)
    }
  end

  def build_comment_from_email
    comment = "📧 Email reçu le #{Date.current.strftime('%d/%m/%Y')}\n"
    comment += "De: #{mail.from.first}\n"
    comment += "Sujet: #{mail.subject}\n\n"

    # Ajouter un extrait du corps de l'email
    body_preview = mail.decoded.gsub(/<[^>]*>/, '').strip[0..500]
    comment += "Contenu:\n#{body_preview}"
    comment += "..." if mail.decoded.length > 500

    # Ajouter la liste des pièces jointes
    if mail.attachments.any?
      comment += "\n\nPièces jointes:\n"
      mail.attachments.each do |attachment|
        comment += "- #{attachment.filename} (#{attachment.content_type})\n"
      end
    end

    comment
  end

  def detect_status_from_email
    subject_and_body = "#{mail.subject} #{mail.decoded}".downcase

    # Rechercher des mots-clés pour détecter le statut
    return 'accorde' if subject_and_body.match?(/accord[ée]|accept[ée]|approuv[ée]/)
    return 'refuse' if subject_and_body.match?(/refus[ée]|rejet[ée]|non.*accord[ée]/)
    return 'incomplet' if subject_and_body.match?(/incomplet|manqu[ea]nt|document.*requise?/)
    return 'en_cours' if subject_and_body.match?(/en.*cours|traitement|examen/)

    nil # Garder le statut actuel si aucun indicateur trouvé
  end

  def extract_dossier_number(text)
    # Rechercher des patterns de numéro de dossier
    match = text.match(/(?:dossier|n[°o]|ref(?:erence)?)[:\s]*([a-z0-9\/\-]+)/i)
    match&.captures&.first
  end

  def extract_status_hint(text)
    text.downcase.scan(/accord[ée]|refus[ée]|incomplet|en.*cours/).first
  end

  def extract_amount(text)
    # Rechercher des montants en euros
    match = text.match(/(\d+(?:[.,]\d{2})?)\s*€?/)
    match&.captures&.first&.tr(',', '.')&.to_f
  end

  def extract_decision(text)
    text.downcase.scan(/accord[ée]|refus[ée]|accept[ée]|rejet[ée]/).first
  end

  def notify_user_of_update
    # Envoyer une notification à l'utilisateur propriétaire de la demande
    request = @request_progress.request
    return unless request&.property&.user

    user = request.property.user
    UserMailer.tracking_email_received(user, @request_progress).deliver_later
  rescue => e
    Rails.logger.error "❌ Erreur lors de l'envoi de notification: #{e.message}"
  end
end

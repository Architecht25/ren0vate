class RequestProgressService
  def initialize(request_progress)
    @request_progress = request_progress
  end

  # Générer l'email de suivi unique
  def self.generate_tracking_email(request)
    timestamp = Time.current.to_i
    property_id = request.property_id
    project_id = request.project_id || 'general'
    region = request.region

    "#{region}-#{property_id}-#{project_id}-#{timestamp}@tracking.ren0vate.be"
  end

  # Trouver un RequestProgress par email de suivi
  def self.find_by_tracking_email(email)
    RequestProgress.find_by(email_suivi: email)
  end

  # Mettre à jour le statut à partir d'un document reçu
  def update_from_document(document_data)
    return false unless document_data.is_a?(Hash)

    updates = {}

    # Extraire les informations du document
    updates[:numero_dossier] = document_data[:numero_dossier] if document_data[:numero_dossier]
    updates[:status_administratif] = normalize_status(document_data[:status]) if document_data[:status]
    updates[:montant_accorde] = document_data[:montant_accorde] if document_data[:montant_accorde]
    updates[:prime_accordee] = document_data[:prime_accordee] if document_data[:prime_accordee]
    updates[:commentaires_admin] = document_data[:commentaires] if document_data[:commentaires]
    updates[:document_recu] = true
    updates[:date_derniere_maj] = Date.current

    @request_progress.update(updates)
  end

  # Parser un document PDF (à implémenter selon le format de chaque région)
  def self.parse_pdf_document(pdf_file, region)
    case region
    when 'bruxelles'
      parse_bruxelles_pdf(pdf_file)
    when 'wallonie'
      parse_wallonie_pdf(pdf_file)
    when 'flandre'
      parse_flandre_pdf(pdf_file)
    else
      {}
    end
  end

  # Parser une photo de document (OCR pour Wallonie)
  def self.parse_photo_document(photo_file)
    # TODO: Implémenter OCR pour extraire le texte de la photo
    # Peut utiliser un service comme Google Vision API ou Tesseract
    {}
  end

  # Créer ou mettre à jour un RequestProgress à partir d'un email reçu
  def self.process_email_notification(email_data)
    tracking_email = email_data[:to]
    request_progress = find_by_tracking_email(tracking_email)

    return nil unless request_progress

    document_data = {}

    # Parser les pièces jointes
    if email_data[:attachments]
      email_data[:attachments].each do |attachment|
        if attachment[:content_type].include?('pdf')
          document_data.merge!(parse_pdf_document(attachment[:file], request_progress.region))
        elsif attachment[:content_type].include?('image')
          document_data.merge!(parse_photo_document(attachment[:file]))
        end
      end
    end

    # Extraire des informations du corps de l'email si disponible
    if email_data[:body]
      document_data.merge!(extract_from_email_body(email_data[:body]))
    end

    # Mettre à jour le RequestProgress
    service = new(request_progress)
    service.update_from_document(document_data)

    # Créer une notification pour l'utilisateur
    create_user_notification(request_progress)

    request_progress
  end

  private

  # Normaliser les statuts selon les différentes administrations
  def normalize_status(status_text)
    status_text = status_text.to_s.downcase.strip

    case status_text
    when /complet|complete|dossier.*complet/
      'complet'
    when /incomplet|incomplete|manque|manquant/
      'incomplet'
    when /accord|accepté|approuvé|favorable/
      'accorde'
    when /refus|rejeté|défavorable|négatif/
      'refuse'
    when /cours|traitement|analyse/
      'en_cours'
    else
      'en_cours' # Par défaut
    end
  end

  # Parser spécifique pour Bruxelles
  def self.parse_bruxelles_pdf(pdf_file)
    # TODO: Implémenter selon le format PDF de Bruxelles
    {}
  end

  # Parser spécifique pour Wallonie
  def self.parse_wallonie_pdf(pdf_file)
    # TODO: Implémenter selon le format PDF de Wallonie
    {}
  end

  # Parser spécifique pour Flandre
  def self.parse_flandre_pdf(pdf_file)
    # TODO: Implémenter selon le format PDF de Flandre
    {}
  end

  # Extraire des informations du corps de l'email
  def self.extract_from_email_body(email_body)
    data = {}

    # Rechercher des patterns communs
    if match = email_body.match(/dossier\s*n[°#]?\s*:?\s*(\w+)/i)
      data[:numero_dossier] = match[1]
    end

    if match = email_body.match(/montant.*?(\d+[,.]?\d*)\s*€/i)
      data[:montant_accorde] = match[1].gsub(',', '.').to_f
    end

    data
  end

  # Créer une notification pour informer l'utilisateur
  def self.create_user_notification(request_progress)
    user = request_progress.request.user

    NotificationService.new.create_notification(
      user: user,
      type: 'update_demande',
      title: "Mise à jour de votre demande",
      message: "Le statut de votre demande a été mis à jour : #{request_progress.status_administratif.humanize}",
      category: 'administratif',
      priority: 'normale',
      property: request_progress.property,
      project: request_progress.project
    )
  end
end

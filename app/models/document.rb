class Document < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :property, optional: true
  belongs_to :request, optional: true
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  # Relation avec les données de facture extraites
  has_one :facture,                   dependent: :destroy
  has_one :aer_donnee,                dependent: :destroy
  has_one :rib_donnee,                dependent: :destroy
  has_one :peb_donnee,                dependent: :destroy
  has_one :devis_donnee,              dependent: :destroy
  has_one :bordereau_chassis_donnee,  dependent: :destroy

  has_one_attached :file

  # Validations améliorées pour l'upload
  validates :type_document, presence: true
  validates :file_url, presence: true, unless: -> { file.attached? }
  validate :file_or_url_present
  validate :file_size_limit_debug # Validation avec debug
  validate :file_format_validation
  validate :file_magic_bytes_validation

  # Validations techniques spécifiques - DÉSACTIVÉES
  # validate :check_audit_conformity, if: :should_validate_technical_documents_strict?
  validate :verify_insulation_thickness, if: :insulation_document?
  validate :check_deadline_compliance, if: :time_sensitive_document?

  # Énumérations pour les types de documents
  enum :type_document, {
    facture: 'facture',
    devis: 'devis',
    etat_avancement: 'etat_avancement',
    attestation_entrepreneur: 'attestation_entrepreneur',
    certificat_peb: 'certificat_peb',
    certificat_peb_avant: 'certificat_peb_avant',
    certificat_peb_apres: 'certificat_peb_apres',
    photo: 'photo',
    photo_avant: 'photo_avant',
    photo_pendant: 'photo_pendant',
    photo_apres: 'photo_apres',
    certificat_label: 'certificat_label',
    attestation_conformite: 'attestation_conformite',
    plan: 'plan',
    metre: 'metre',
    permis_urbanisme: 'permis_urbanisme',
    dossier_prime: 'dossier_prime',
    plan_diu: 'plan_diu',
    acte_notarial: 'acte_notarial',
    compromis: 'compromis',
    # Documents châssis spécifiques
    bordereau_chassis: 'bordereau_chassis',
    photo_chassis: 'photo_chassis',
    # Documents audit énergétique
    preuve_paiement_audit: 'preuve_paiement_audit',
    rapport_audit_energetique: 'rapport_audit_energetique',
    copie_carte_identite: 'copie_carte_identite',
    # Documents bancaires
    rib: 'rib',
    aer: 'aer',
    # Fiches techniques
    fiche_technique: 'fiche_technique',
    # Documents DIU (Dossier d'Intervention Ultérieure)
    notice_equipement: 'notice_equipement',
    fiche_securite_materiaux: 'fiche_securite_materiaux',
    certificat_garantie: 'certificat_garantie',
    instruction_entretien: 'instruction_entretien',
    assurance_decennale: 'assurance_decennale',
    assurance_rc_pro: 'assurance_rc_pro'
  }

  # Status est une colonne string dans la DB, pas un enum integer
  enum :status, { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  scope :for_property, ->(property) { where(property: property) }
  scope :by_type, ->(type) { where(type_document: type) }
  scope :completed, -> { where(status: :approved) }
  scope :by_phase, ->(phase) { where(type_document: phase.required_document_types + phase.optional_document_types) }

  # Callbacks pour maintenir les statuts des phases à jour
  before_save :configure_storage_service_for_pdfs
  after_save :refresh_property_phase_statuses
  after_destroy :refresh_property_phase_statuses

  # Formats de fichiers autorisés
  ALLOWED_FORMATS = {
    images: %w[image/jpeg image/png image/gif image/webp],
    documents: %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document],
    spreadsheets: %w[application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]
  }.freeze

  ALL_ALLOWED_FORMATS = ALLOWED_FORMATS.values.flatten.freeze

  # Limite de taille (30 MB - correspond à config.active_storage.max_file_size)
  MAX_FILE_SIZE = 30.megabytes
  # Limite de taille pour les photos (100 MB)
  MAX_PHOTO_FILE_SIZE = 100.megabytes

  # Méthodes helper
  def completed?
    approved?
  end

  def file_name
    file.attached? ? file.filename.to_s : File.basename(file_url.to_s) if file_url.present?
  end

  def file_size_human
    file.attached? ? ActionController::Base.helpers.number_to_human_size(file.byte_size) : nil
  end

  def file_type
    if file.attached?
      file.content_type
    elsif file_url.present?
      File.extname(file_url).downcase
    end
  end

  def is_image?
    return false unless file.attached?
    ALLOWED_FORMATS[:images].include?(file.content_type)
  end

  def is_pdf?
    return false unless file.attached?
    file.content_type == 'application/pdf'
  end

  def preview_available?
    return false unless file.attached?
    is_image? || is_pdf?
  end

  # Méthodes pour gérer le contenu OCR
  def has_ocr_content?
    notes.present? && notes.include?('📄 Texte extrait par OCR')
  end

  def ocr_content
    return nil unless has_ocr_content?

    # Extraire le texte OCR des notes
    lines = notes.split("\n")
    ocr_start_index = lines.find_index { |line| line.include?('📄 Texte extrait par OCR') }
    return nil unless ocr_start_index

    # Ignorer les 4 premières lignes (header + métadonnées) et récupérer le reste
    ocr_lines = lines[(ocr_start_index + 4)..-1] || []
    ocr_lines.join("\n").strip
  end

  def ocr_confidence
    return nil unless has_ocr_content?

    confidence_line = notes.split("\n").find { |line| line.include?('Confiance:') }
    return nil unless confidence_line

    match = confidence_line.match(/Confiance:\s*(\d+)%/)
    match ? match[1].to_i : nil
  end

  def ocr_language
    return nil unless has_ocr_content?

    language_line = notes.split("\n").find { |line| line.include?('Langue:') }
    return nil unless language_line

    match = language_line.match(/Langue:\s*(.+)/)
    match ? match[1].strip : nil
  end

  def ocr_method
    return nil unless has_ocr_content?

    method_line = notes.split("\n").find { |line| line.include?('📄 Texte extrait par OCR') }
    return nil unless method_line

    match = method_line.match(/\((.+)\)/)
    match ? match[1] : nil
  end

  # Vérifie si le document est un type photo (avec limite augmentée)
  def is_photo_type?
    %w[photo photo_avant photo_pendant photo_apres photo_chassis].include?(type_document)
  end

  def cloudinary_url
    return nil unless file.attached?
    return nil unless file.service_name.to_s == 'cloudinary'

    begin
      Rails.logger.info "🔗 Génération URL Cloudinary pour #{file.filename} (#{file.content_type})"

      if file.content_type == 'application/pdf'
        # Utiliser le service Cloudinary PDF spécialisé avec le nom de fichier original
        url = CloudinaryPdfService.generate_pdf_url(file.key, filename: file.filename.to_s)
        Rails.logger.info "📄 URL PDF Cloudinary générée: #{url}"
        url
      else
        # URL standard Cloudinary pour les autres fichiers
        url = rails_blob_url(file)
        Rails.logger.info "📎 URL standard générée: #{url}"
        url
      end
    rescue => e
      Rails.logger.error "❌ Erreur génération URL Cloudinary pour document #{id}: #{e.message}"
      Rails.logger.error "🔄 Fallback vers Rails blob URL"
      rails_blob_url(file) # Fallback
    end
  end

  def cloudinary_preview_url
    return nil unless file.attached?
    return nil unless file.service_name.to_s == 'cloudinary'
    return nil unless is_pdf?

    PdfPreviewService.generate_preview_for_document(self)
  rescue => e
    Rails.logger.warn "Could not generate PDF preview for document #{id}: #{e.message}"
    nil
  end

  def self.completion_stats_for_property(property)
    total_types = type_documents.values.count
    completed_types = for_property(property).completed.distinct.count(:type_document)
    {
      total: total_types,
      completed: completed_types,
      percentage: total_types > 0 ? (completed_types * 100.0 / total_types).round : 0
    }
  end

  # === MÉTHODES POUR LES PHASES ===

  # Trouve la phase associée à ce document
  def document_phase
    return nil unless type_document.present?
    DocumentPhase.find_phase_for_document_type(type_document)
  end

  # Vérifie si ce document est requis pour sa phase
  def required_for_phase?
    phase = document_phase
    return false unless phase
    phase.required_document_types.include?(type_document)
  end

  # Vérifie si ce document est optionnel pour sa phase
  def optional_for_phase?
    phase = document_phase
    return false unless phase
    phase.optional_document_types.include?(type_document)
  end

  # Badge de priorité basé sur la phase
  def priority_badge_class
    if required_for_phase?
      'danger'
    elsif optional_for_phase?
      'warning'
    else
      'secondary'
    end
  end

  # Texte de priorité
  def priority_text
    if required_for_phase?
      'Obligatoire'
    elsif optional_for_phase?
      'Optionnel'
    else
      'Non classé'
    end
  end

  # Impact sur l'avancement de la phase
  def phase_impact_percentage
    return 0 unless property && document_phase

    # Calcul de l'impact de ce document sur la phase
    if required_for_phase?
      required_count = document_phase.required_document_types.count
      return required_count > 0 ? (70.0 / required_count) : 0
    elsif optional_for_phase?
      optional_count = document_phase.optional_document_types.count
      return optional_count > 0 ? (30.0 / optional_count) : 0
    end

    0
  end

  # Suggestions d'amélioration pour ce document
  def improvement_suggestions
    suggestions = []

    case status
    when 'pending'
      if created_at < 3.days.ago
        days_ago = (Date.current - created_at.to_date).to_i
        suggestions << "Document en attente depuis #{days_ago} jour(s). Relancer si nécessaire."
      end
    when 'rejected'
      suggestions << "Document rejeté. Vérifier les critères requis et re-soumettre."
    when 'approved'
      if required_for_phase? && document_phase
        missing_siblings = document_phase.missing_required_documents_for_property(property)
        if missing_siblings.any?
          suggestions << "Compléter la phase avec : #{missing_siblings.first(2).join(', ')}"
        end
      end
    end

    suggestions
  end

  private

  # Met à jour les statuts des phases de la propriété
  def refresh_property_phase_statuses
    return unless property

    # Rafraîchir le statut de la phase concernée
    if document_phase
      property.phase_status_for(document_phase).refresh_status!
    end

    # Rafraîchir tous les statuts si c'est un document critique
    property.refresh_all_phase_statuses! if required_for_phase?
  end

  private

  def file_or_url_present
    unless file.attached? || file_url.present?
      errors.add(:base, "Un fichier ou une URL doit être fourni")
    end
  end

  def file_size_limit_debug
    return unless file.attached?

    Rails.logger.info "🔍 Document validation DEBUG - filename: #{file.filename}"
    Rails.logger.info "🔍 file.attached?: #{file.attached?}"
    Rails.logger.info "🔍 file.blob present?: #{file.blob.present?}"
    Rails.logger.info "🔍 type_document: #{type_document}"

    begin
      byte_size = file.byte_size
      max_size = is_photo_type? ? MAX_PHOTO_FILE_SIZE : MAX_FILE_SIZE

      Rails.logger.info "🔍 file.byte_size: #{byte_size} bytes (#{ActionController::Base.helpers.number_to_human_size(byte_size)})"
      Rails.logger.info "🔍 is_photo_type?: #{is_photo_type?}"
      Rails.logger.info "🔍 MAX_SIZE: #{max_size} bytes (#{ActionController::Base.helpers.number_to_human_size(max_size)})"
      Rails.logger.info "🔍 Comparaison: #{byte_size} > #{max_size} = #{byte_size > max_size}"

      if byte_size > max_size
        human_size = ActionController::Base.helpers.number_to_human_size(byte_size)
        max_human_size = ActionController::Base.helpers.number_to_human_size(max_size)
        Rails.logger.error "❌ File too large - #{file.filename}: #{human_size} > #{max_human_size}"
        errors.add(:file, "ne doit pas dépasser #{max_human_size}")
      else
        Rails.logger.info "✅ File size OK - #{file.filename}: #{ActionController::Base.helpers.number_to_human_size(byte_size)}"
      end
    rescue => e
      Rails.logger.error "❌ Erreur lors de la validation de taille: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      errors.add(:file, "Erreur lors de la validation de taille: #{e.message}")
    end
  end

  def file_size_limit
    return unless file.attached?

    max_size = is_photo_type? ? MAX_PHOTO_FILE_SIZE : MAX_FILE_SIZE
    Rails.logger.info "🔍 Document validation - filename: #{file.filename}, byte_size: #{file.byte_size}, type: #{type_document}, is_photo: #{is_photo_type?}, MAX_SIZE: #{max_size}"

    if file.byte_size > max_size
      human_size = ActionController::Base.helpers.number_to_human_size(file.byte_size)
      max_human_size = ActionController::Base.helpers.number_to_human_size(max_size)
      Rails.logger.error "❌ File too large - #{file.filename}: #{human_size} > #{max_human_size}"
      errors.add(:file, "ne doit pas dépasser #{max_human_size}")
    else
      Rails.logger.info "✅ File size OK - #{file.filename}: #{ActionController::Base.helpers.number_to_human_size(file.byte_size)}"
    end
  end

  private

  def file_or_url_present
    if file.attached? || file_url.present?
      true
    else
      errors.add(:base, 'Un fichier ou une URL est requis.')
      false
    end
  end

  def file_format_validation
    return unless file.attached?

    allowed_formats = [
      'application/pdf',
      'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain'
    ]

    # Vérifie le content-type déclaré (UX : message d'erreur lisible)
    unless allowed_formats.include?(file.content_type)
      errors.add(:file, 'format non supporté. Formats acceptés : PDF, images, Word, Excel, texte.')
    end
  end

  def file_magic_bytes_validation
    return unless file.attached? && file.blob.persisted?

    begin
      # Lire les 4 premiers Ko — suffisant pour tous les magic bytes connus
      raw = file.blob.download.byteslice(0, 4096)
      return unless raw.present?

      detected = Marcel::MimeType.for(StringIO.new(raw), name: file.blob.filename.to_s)

      # Marcel renvoie 'application/zip' pour les formats Office Open XML (DOCX, XLSX)
      # car ils partagent la même signature ZIP — on accepte si le content_type déclaré est cohérent
      office_ooxml = %w[
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      ]
      return if detected == 'application/zip' && office_ooxml.include?(file.blob.content_type)

      unless ALL_ALLOWED_FORMATS.include?(detected)
        errors.add(:file, "le contenu du fichier ne correspond pas à un format autorisé (détecté : #{detected})")
      end
    rescue => e
      Rails.logger.warn "[Security] Vérification magic bytes échouée pour #{file.blob.filename}: #{e.message}"
      # Fail open — ne pas bloquer l'upload si la vérification technique échoue
    end
  end

  # Configure le service de stockage selon le type de fichier
  def configure_storage_service_for_pdfs
    return unless file.attached?

    # En développement, utilise le stockage local pour les PDFs
    if Rails.env.development? && file.content_type == 'application/pdf'
      # Force l'utilisation du service local pour les PDFs
      Rails.logger.info "📁 Utilisation du stockage local pour PDF: #{file.filename}"
    end
  end

  # Validations techniques spécifiques
  def technical_document?
    %w[rapport_audit_energetique devis fiche_technique].include?(type_document)
  end

  def insulation_document?
    %w[devis fiche_technique].include?(type_document)
  end

  def time_sensitive_document?
    %w[facture rapport_audit_energetique].include?(type_document)
  end

  # Méthode supprimée - validation technique désactivée
  # def check_audit_conformity

  def verify_insulation_thickness
    return unless project&.property&.region&.downcase == 'wallonie'

    # Ajouter un warning si pas de validation d'épaisseur
    # Cette validation sera enrichie avec l'OCR
    Rails.logger.info "Document #{id} : Vérification épaisseur isolant requise"
  end

  def check_deadline_compliance
    return unless project

    case project.property.region&.downcase
    when 'wallonie'
      check_wallonie_deadlines
    when 'bruxelles'
      check_bruxelles_deadlines
    when 'flandre'
      check_flandre_deadlines
    end
  end

  def check_wallonie_deadlines
    return unless type_document == 'facture'

    # Vérifier délai de 2 ans pour les factures Wallonie
    if created_at && created_at < 2.years.ago
      errors.add(:base, 'Cette facture dépasse le délai de 2 ans pour les primes Wallonie')
    end
  end

  def check_bruxelles_deadlines
    # Règles spécifiques Bruxelles
  end

  def check_flandre_deadlines
    # Règles spécifiques Flandre
  end
end

class TechnicalValidationService
  attr_reader :project, :audit_document, :devis_documents, :photo_documents, :errors, :warnings

  def initialize(project)
    @project = project
    @audit_document = project.documents.where(type_document: 'rapport_audit_energetique').first
    @devis_documents = project.documents.where(type_document: 'devis')
    @photo_documents = project.documents.where(type_document: 'photo')
    @errors = []
    @warnings = []
  end

  def validate!
    # Vérifier d'abord que nous avons tous les éléments requis
    unless @project&.property&.region.present?
      Rails.logger.warn "⚠️ Validation technique impossible: région non définie pour le project #{@project&.id}"
      return {
        valid: true,
        errors: [],
        warnings: [{ type: 'no_region', message: 'Région non définie, validation technique non applicable' }],
        validation_score: 0
      }
    end

    validate_audit_presence
    validate_devis_presence
    validate_photo_presence
    validate_audit_devis_coherence
    validate_insulation_thickness
    validate_deadline_compliance
    validate_technical_requirements

    {
      valid: @errors.empty?,
      errors: @errors,
      warnings: @warnings,
      validation_score: calculate_validation_score
    }
  end

  private

  def validate_audit_presence
    # L'audit énergétique n'est obligatoire qu'en Wallonie
    return unless @project.property&.region&.downcase == 'wallonie'

    unless @audit_document
      @errors << {
        type: 'missing_audit',
        message: 'Rapport d\'audit énergétique manquant (requis en Wallonie)',
        critical: true
      }
    end
  end

  def validate_devis_presence
    if @devis_documents.empty?
      @errors << {
        type: 'missing_devis',
        message: 'Aucun devis trouvé pour validation',
        critical: true
      }
    end
  end

  def validate_photo_presence
    if @photo_documents.empty?
      @warnings << {
        type: 'missing_photos',
        message: 'Photos recommandées pour validation visuelle des travaux',
        critical: false
      }
    end
  end

  def validate_audit_devis_coherence
    return unless @audit_document && @devis_documents.any?

    # Vérification des écarts entre audit et devis
    audit_data = extract_audit_data
    devis_data = extract_devis_data

    check_surface_coherence(audit_data, devis_data)
    check_work_type_coherence(audit_data, devis_data)
    check_material_specifications(audit_data, devis_data)
  end

  def validate_insulation_thickness
    return unless @project.property.region&.downcase == 'wallonie'

    # Normes Wallonie pour isolation
    required_thickness = {
      'toiture' => 20, # cm minimum
      'murs' => 12,    # cm minimum
      'sols' => 10     # cm minimum
    }

    @devis_documents.each do |devis|
      # Analyser le contenu du devis pour vérifier les épaisseurs
      # Cette partie nécessiterait l'intégration avec un service OCR/parsing
      validate_thickness_from_devis(devis, required_thickness)
    end
  end

  def validate_deadline_compliance
    # Vérification des délais selon la région
    case @project.property.region&.downcase
    when 'wallonie'
      validate_wallonie_deadlines
    when 'bruxelles'
      validate_bruxelles_deadlines
    when 'flandre'
      validate_flandre_deadlines
    end
  end

  def validate_technical_requirements
    # Vérification des exigences techniques spécifiques
    property = @project.property

    case property.region&.downcase
    when 'wallonie'
      validate_wallonie_technical_requirements
    when 'bruxelles'
      validate_bruxelles_technical_requirements
    when 'flandre'
      validate_flandre_technical_requirements
    end
  end

  def extract_audit_data
    # Extraction des données de l'audit
    # Cette méthode devrait parser le contenu de l'audit
    return {} unless @audit_document

    {
      surface_toiture: nil, # À extraire du document
      surface_murs: nil,    # À extraire du document
      surface_sols: nil,    # À extraire du document
      travaux_recommandes: [], # À extraire du document
      r_values: {}          # Valeurs R recommandées
    }
  end

  def extract_devis_data
    # Extraction des données des devis
    devis_data = []

    @devis_documents.each do |devis|
      devis_data << {
        document_id: devis.id,
        surface_prevue: nil,  # À extraire du document
        materiaux: [],        # À extraire du document
        epaisseurs: {},       # À extraire du document
        prix_total: nil       # À extraire du document
      }
    end

    devis_data
  end

  def check_surface_coherence(audit_data, devis_data)
    # Vérification de la cohérence des surfaces
    return if audit_data.empty? || devis_data.empty?

    # Logique de comparaison des surfaces
    # Si écart > 10%, générer un warning
    devis_data.each do |devis|
      if significant_surface_difference?(audit_data, devis)
        @warnings << {
          type: 'surface_mismatch',
          message: "Écart important entre surfaces audit et devis (document ##{devis[:document_id]})",
          critical: false
        }
      end
    end
  end

  def check_work_type_coherence(audit_data, devis_data)
    # Vérification que les travaux du devis correspondent aux recommandations audit
    return if audit_data.empty? || devis_data.empty?

    recommended_works = audit_data[:travaux_recommandes] || []

    if recommended_works.any? && devis_data.none? { |d| matches_recommended_work?(d, recommended_works) }
      @warnings << {
        type: 'work_type_mismatch',
        message: 'Les travaux devisés ne correspondent pas exactement aux recommandations de l\'audit',
        critical: false
      }
    end
  end

  def check_material_specifications(audit_data, devis_data)
    # Vérification des spécifications matériaux
    return if audit_data.empty? || devis_data.empty?

    devis_data.each do |devis|
      check_r_values(audit_data[:r_values], devis)
      check_material_quality(devis)
    end
  end

  def validate_thickness_from_devis(devis, required_thickness)
    # Cette méthode nécessiterait un parsing du contenu du devis
    # Pour l'instant, on ajoute un placeholder

    @warnings << {
      type: 'thickness_validation_needed',
      message: "Vérification manuelle requise pour les épaisseurs d'isolant (document ##{devis.id})",
      critical: false
    }
  end

  def validate_wallonie_deadlines
    return unless @audit_document

    # Règles Wallonie : 2 ans à partir de la première facture
    first_invoice_date = @project.factures.minimum(:date_facture)
    return unless first_invoice_date

    deadline = first_invoice_date + 2.years

    if Date.current > deadline
      @errors << {
        type: 'deadline_exceeded',
        message: "Délai de 2 ans dépassé depuis la première facture (#{first_invoice_date.strftime('%d/%m/%Y')})",
        critical: true
      }
    elsif Date.current > deadline - 3.months
      @warnings << {
        type: 'deadline_approaching',
        message: "Attention : délai de 2 ans arrive à échéance le #{deadline.strftime('%d/%m/%Y')}",
        critical: false
      }
    end
  end

  def validate_bruxelles_deadlines
    # Règles spécifiques Bruxelles
    # À implémenter selon les règles locales
  end

  def validate_flandre_deadlines
    # Règles spécifiques Flandre
    # À implémenter selon les règles locales
  end

  def validate_wallonie_technical_requirements
    property = @project.property

    # Vérifications spécifiques Wallonie
    if property.annee_construction && property.annee_construction >= 2006
      @warnings << {
        type: 'recent_construction',
        message: 'Bien construit après 2006 : vérifier l\'éligibilité aux primes',
        critical: false
      }
    end

    # Vérification PEB
    if property.certificat_peb_wallonie.blank?
      @warnings << {
        type: 'missing_peb',
        message: 'Certificat PEB manquant pour validation complète',
        critical: false
      }
    end
  end

  def validate_bruxelles_technical_requirements
    # Exigences techniques Bruxelles
  end

  def validate_flandre_technical_requirements
    # Exigences techniques Flandre
  end

  def significant_surface_difference?(audit_data, devis)
    # Logique de comparaison des surfaces
    # Retourne true si écart > 10%
    false # Placeholder
  end

  def matches_recommended_work?(devis, recommended_works)
    # Vérifie si le devis correspond aux travaux recommandés
    true # Placeholder
  end

  def check_r_values(audit_r_values, devis)
    # Vérification des valeurs R
    # Placeholder pour validation des performances thermiques
  end

  def check_material_quality(devis)
    # Vérification de la qualité des matériaux
    # Placeholder pour validation des certifications
  end

  def calculate_validation_score
    # Score de validation sur 100
    total_checks = 10
    failed_checks = @errors.count + (@warnings.count * 0.5)

    [((total_checks - failed_checks) / total_checks * 100).round, 0].max
  end
end

module DocumentsHelper
  # Service pour la logique conditionnelle
  def document_display_service
    @document_display_service ||= Documents::ConditionalDisplayService.new(
      @property,
      @simulation_data
    )
  end

  # Raccourcis pour les conditions les plus courantes
  def show_urban_permit_section?
    document_display_service.requires_urban_permit?
  end

  def show_peb_certificate_section?
    document_display_service.requires_peb_certificate?
  end

  def show_energy_audit_section?
    document_display_service.requires_energy_audit?
  end

  def show_electrical_documents_section?
    document_display_service.requires_electrical_documents?
  end

  # Pour les messages conditionnels
  def conditional_document_message(document_type)
    case document_type
    when 'urban_permit'
      if show_urban_permit_section?
        "📋 Permis d'urbanisme requis selon votre projet"
      else
        "ℹ️ Aucun permis d'urbanisme nécessaire pour ce projet"
      end
    when 'peb_certificate'
      "🏠 Certificat PEB obligatoire pour tous les biens résidentiels"
    when 'energy_audit'
      if show_energy_audit_section?
        "🔍 Audit énergétique recommandé pour vos primes"
      else
        "💡 Audit énergétique non requis pour ce projet"
      end
    end
  end

  # Pour styler conditionnellement les cartes
  def document_card_classes(document_type, base_classes = "")
    classes = base_classes.split(' ')

    case document_type
    when 'required'
      classes << 'border-red-200 bg-red-50'
    when 'conditional'
      classes << 'border-yellow-200 bg-yellow-50'
    when 'optional'
      classes << 'border-green-200 bg-green-50'
    end

    classes.join(' ')
  end

  # Rendu du bouton d'upload contextuel
  def upload_document_button(context_object, options = {})
    default_options = {
      class: "btn btn-outline-success",
      text: "Uploader un document",
      icon: "bi-cloud-upload"
    }

    options = default_options.merge(options)

    case context_object
    when Property
      path = new_property_document_path(context_object)
    when Project
      path = new_project_document_path(context_object)
    when Request
      path = new_request_document_path(context_object)
    when Simulation
      path = new_simulation_document_path(context_object)
    else
      path = new_document_path
    end

    link_to path, class: options[:class] do
      content_tag(:i, "", class: "#{options[:icon]} me-2") + options[:text]
    end
  end

  # Badge de statut pour documents
  def document_status_badge(status)
    case status.to_s
    when 'pending'
      content_tag :span, "En attente", class: "badge bg-warning"
    when 'approved'
      content_tag :span, "Approuvé", class: "badge bg-success"
    when 'rejected'
      content_tag :span, "Rejeté", class: "badge bg-danger"
    else
      content_tag :span, status.humanize, class: "badge bg-secondary"
    end
  end

  # Icône selon le type de fichier
  def document_type_icon(document)
    if document.file.attached?
      case document.file.content_type
      when /image/
        "bi-image text-info"
      when /pdf/
        "bi-file-pdf text-danger"
      when /word|doc/
        "bi-file-word text-primary"
      when /excel|sheet/
        "bi-file-excel text-success"
      else
        "bi-file-earmark text-muted"
      end
    else
      "bi-file-earmark text-muted"
    end
  end

  # Statistiques de documents pour un contexte
  def document_completion_info(context_object)
    case context_object
    when Property
      stats = Document.completion_stats_for_property(context_object)
      {
        completed: stats[:completed],
        total: stats[:total],
        percentage: stats[:percentage],
        class: stats[:percentage] >= 80 ? 'success' : (stats[:percentage] >= 50 ? 'warning' : 'danger')
      }
    else
      { completed: 0, total: 0, percentage: 0, class: 'secondary' }
    end
  end

  # Widget de progression des documents
  def document_progress_widget(context_object, options = {})
    info = document_completion_info(context_object)

    content_tag :div, class: "document-progress-widget" do
      concat(
        content_tag(:div, class: "d-flex justify-content-between align-items-center mb-2") do
          concat content_tag(:span, "Documents", class: "small text-muted")
          concat content_tag(:span, "#{info[:completed]}/#{info[:total]}", class: "small fw-medium")
        end
      )
      concat(
        content_tag(:div, class: "progress", style: "height: 8px;") do
          content_tag :div, "",
            class: "progress-bar bg-#{info[:class]}",
            style: "width: #{info[:percentage]}%",
            role: "progressbar"
        end
      )
    end
  end

  # Zone de drop rapide
  def quick_upload_zone(context_object, options = {})
    render partial: 'shared/quick_upload_zone', locals: {
      context_object: context_object,
      options: options
    }
  end

  # Nom localisé du type de document
  def document_type_name(type_document)
    return type_document.map { |t| document_type_name(t) }.join(", ") if type_document.is_a?(Array)
    I18n.t("documents.types.#{type_document}", default: type_document.to_s.humanize)
  end

  # Note explicative sur le rôle du document dans l'application
  DOCUMENT_TYPE_HINTS = {
    "aer"                        => "Détermine la catégorie de revenus pour le calcul des primes et prêts",
    "rib"                        => "Coordonnées bancaires pour le versement des primes",
    "certificat_peb_avant"       => "Détermine la catégorie de primes énergie selon le label actuel",
    "certificat_peb_apres"       => "Atteste l'amélioration énergétique obtenue après travaux",
    "certificat_peb"             => "Étiquette énergétique du bien",
    "devis"                      => "Base de calcul du montant des primes accordées",
    "facture"                    => "Justifie les dépenses pour le versement des primes",
    "attestation_entrepreneur"   => "Certifie que l'entrepreneur est agréé / reconnu",
    "permis_urbanisme"           => "Autorisation légale requise pour les travaux",
    "copie_carte_identite"       => "Vérifie l'identité du demandeur",
    "rapport_audit_energetique"  => "Recommande les travaux prioritaires et conditionne les primes audit",
    "preuve_paiement_audit"      => "Justifie le paiement de l'auditeur pour débloquer la prime",
    "bordereau_chassis"          => "Détails techniques des châssis pour le calcul des primes",
    "certificat_label"           => "Label de performance du produit installé requis pour la prime",
    "fiche_technique"            => "Caractéristiques techniques des matériaux posés",
    "attestation_conformite"     => "Certifie la conformité des travaux réalisés",
    "etat_avancement"            => "Preuve de l'avancement des travaux pour déblocage partiel",
    "photo_avant"                => "Situation initiale avant travaux",
    "photo_apres"                => "Preuve visuelle des travaux réalisés",
    "photo"                      => "Suivi visuel des travaux réalisés",
    "dossier_prime"              => "Dossier complet de demande de prime auprès de l'organisme",
    "plan_diu"                   => "Plans obligatoires transmis au futur propriétaire (DIU)",
  }.freeze

  def document_type_hint(type_document)
    DOCUMENT_TYPE_HINTS[type_document.to_s]
  end

  # Limite de taille selon le type de document
  def max_file_size_for_type(type_document)
    if is_photo_type?(type_document)
      Document::MAX_PHOTO_FILE_SIZE
    else
      Document::MAX_FILE_SIZE
    end
  end

  # Limite de taille en format humain
  def max_file_size_human_for_type(type_document)
    ActionController::Base.helpers.number_to_human_size(max_file_size_for_type(type_document))
  end

  # Vérifier si c'est un type photo
  def is_photo_type?(type_document)
    %w[photo photo_avant photo_pendant photo_apres photo_chassis].include?(type_document)
  end

  # Texte d'aide pour les formats et taille
  def upload_help_text(type_document = nil)
    max_size = type_document ? max_file_size_human_for_type(type_document) : "30 MB (photos: 100 MB)"
    "Formats acceptés: PDF, Images (JPEG, PNG, GIF, WebP), Word, Excel<br>Taille max: #{max_size} par fichier".html_safe
  end

  # Aperçu PDF avec upload automatique sur Cloudinary si nécessaire
  def pdf_preview_url_cached(document)
    return nil unless document&.file&.attached?
    return nil unless document.file.content_type == 'application/pdf'

    # Utiliser le nouveau service PdfPreviewService
    PdfPreviewService.generate_preview_for_document(document)
  rescue => e
    Rails.logger.warn "Could not generate PDF preview for document #{document.id}: #{e.message}"
    nil
  end
end

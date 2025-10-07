class PropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: [:show, :dashboard, :edit, :update, :destroy, :documents_dashboard]

  def index
    # Tri des propriétés par région : Flandre -> Bruxelles -> Wallonie
    @properties = current_user.properties.sort_by do |property|
      case property.region&.downcase
      when 'flandre'
        1
      when 'bruxelles'
        2
      when 'wallonie'
        3
      else
        4 # Pour les propriétés sans région définie
      end
    end
  end

  def show
    # Redirection vers le dashboard unifié
    redirect_to dashboard_property_path(@property)
  end

  def new
    @property = current_user.properties.new
    # Préserver le paramètre région s'il est passé
    @property.region = params[:region] if params[:region].present?
    # Préserver le paramètre type s'il est passé (pour les entreprises)
    @property.type = params[:type] if params[:type].present?
  end

  def create
    @property = current_user.properties.new(property_params)

    # Rails.logger.info "Creating property with params: #{property_params.inspect}"
    # Rails.logger.info "Property region: #{@property.region}"
    # Rails.logger.info "Property valid?: #{@property.valid?}"
    # Rails.logger.info "Property errors: #{@property.errors.full_messages}" unless @property.valid?

    if @property.save
      redirect_to @property, notice: t('notices.property_created')
    else
      # Préserver le paramètre région lors du rendu d'erreur
      flash.now[:alert] = t('common.please_correct_errors')
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Rails.logger.info "[PROPERTY UPDATE] 🔄 Tentative de mise à jour pour propriété ID: #{@property.id}"
    # Rails.logger.info "[PROPERTY UPDATE] 📊 Paramètres reçus: #{property_params.inspect}"
    # Rails.logger.info "[PROPERTY UPDATE] 🌍 Région actuelle: #{@property.region}"

    if @property.update(property_params)
      # Rails.logger.info "[PROPERTY UPDATE] ✅ Mise à jour réussie pour propriété ID: #{@property.id}"
      # Rails.logger.info "[PROPERTY UPDATE] 🔧 Nouvelles valeurs: region=#{@property.region}, ean_flandre=#{@property.ean_flandre}, certificat_peb_flandre=#{@property.certificat_peb_flandre}"

      redirect_to @property, notice: t('notices.property_updated')
    else
      Rails.logger.error "[PROPERTY UPDATE] ❌ Échec de la mise à jour pour propriété ID: #{@property.id}"
      Rails.logger.error "[PROPERTY UPDATE] 🚨 Erreurs: #{@property.errors.full_messages.join(', ')}"

      flash.now[:alert] = t('errors.property_update_failed', errors: @property.errors.full_messages.join(', '))
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    property_name = @property.name || "Bien ##{@property.id}"

    begin
      # Rails.logger.info "Attempting to delete property '#{property_name}' (ID: #{@property.id})"

      # Vérifier les associations avant suppression pour debug
      simulations_count = @property.simulations.count
      projects_count = @property.projects.count
      requests_count = @property.requests.count
      documents_count = @property.documents.count

      # Rails.logger.info "Property has #{simulations_count} simulations, #{projects_count} projects, #{requests_count} requests, #{documents_count} documents"

      @property.destroy!

      # Rails.logger.info "Successfully deleted property '#{property_name}'"
      redirect_to properties_path, notice: t('notices.property_deleted', name: property_name)

    rescue => e
      Rails.logger.error "Failed to delete property '#{property_name}': #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      redirect_to @property, alert: t('errors.property_deletion_failed', message: e.message)
    end
  end

  def dashboard
    # Données pour le dashboard du bien
    @completion_stats = {
      admin: @property.admin_completion_percentage,
      chantier: @property.chantier_completion_percentage,
      primes: @property.primes_completion_percentage,
      overall: @property.completion_percentage
    }

    # Requests et simulations liées à ce bien
    @recent_requests = @property.requests.recent.limit(3) if @property.respond_to?(:requests)
    @recent_simulations = @property.simulations.recent.limit(3) if @property.respond_to?(:simulations)

    # Actions disponibles
    @actions_available = {
      can_request: @property.ready_for_request?,
      missing_fields: @property.missing_required_fields
    }

    # Notifications liées à ce bien
    @property_notifications = current_user.notifications.where(property: @property).recent.limit(5) if current_user.respond_to?(:notifications)

    # Progressions des demandes pour ce bien
    @request_progresses = RequestProgress.joins(:request)
                                       .where(requests: { property: @property })
                                       .includes(:request, :prime)
                                       .order(created_at: :desc)

    # Statistiques des demandes
    @demandes_stats = {
      total: @request_progresses.count,
      en_attente: @request_progresses.en_attente.count,
      finalises: @request_progresses.finalises.count,
      accordees: @request_progresses.where(status_administratif: 'accorde').count,
      montant_total_demande: @request_progresses.sum(:montant_demande) || 0,
      montant_total_accorde: @request_progresses.sum(:montant_accorde) || 0
    }
  end

  def documents_dashboard
    @property = current_user.properties.find(params[:id])
    @documents_by_type = @property.documents_by_type
    @document_stats = Document.completion_stats_for_property(@property)

    # Nouveau système de phases
    @phases_data = @property.phases_with_status
    @phase_calculator = DocumentPhaseCalculatorService.new(@property)
    @comprehensive_metrics = @phase_calculator.calculate_comprehensive_metrics
    @recommendations = @phase_calculator.intelligent_recommendations.first(3)
    @potential_issues = @phase_calculator.detect_potential_issues

    # Configuration des types de documents avec leurs informations (legacy pour transition)
    @document_types_config = {
      'devis' => {
        title: '📄 Devis/métré',
        image: 'devis.webp',
        conditions: [
          'Être signé par l\'architecte, budgété et quantifié obligatoirement',
          'Minimum 3 devis recommandés'
        ],
        priority: 'required'
      },
      'facture' => {
        title: '🧾 Factures',
        image: 'facture.webp',
        conditions: [
          'Établies au nom du demandeur de la prime',
          'Adresse du chantier + description travaux + budget',
          'Montant total = montant du devis',
          'Maximum 2 ans d\'ancienneté'
        ],
        priority: 'required'
      },
      'etat_avancement' => {
        title: '📸 États d\'avancement',
        image: 'avancement.webp',
        conditions: [
          'Photos pendant les travaux',
          'Progression documentée'
        ],
        priority: 'recommended'
      },
      'attestation_entrepreneur' => {
        title: '📋 Attestations entrepreneur',
        image: 'entrepreneur.webp',
        conditions: [
          'Signées et cachetées par l\'entrepreneur',
          'Types: Avant/Pendant/Après'
        ],
        priority: 'required'
      },
      'certificat_peb' => {
        title: '📋 Certificat PEB',
        image: 'certificat.webp',
        conditions: [
          'PEB avant ET après travaux',
          'Ventilation conforme'
        ],
        priority: 'required'
      },
      'photo' => {
        title: '📸 Preuves photo',
        image: 'photo.webp',
        conditions: [
          'Obligatoire pour châssis',
          'Recommandé pour autres travaux',
          'Étapes: Avant/Pendant/Après'
        ],
        priority: 'recommended'
      },
      'certificat_label' => {
        title: '🏷️ Certificats label européen',
        image: 'label.avif',
        conditions: [
          'Pompe à chaleur ou chauffe-eau thermodynamique',
          'Label énergétique certifié'
        ],
        priority: 'optional'
      },
      'attestation_conformite' => {
        title: '⚡ Attestation conformité électrique',
        image: 'conformité.webp',
        conditions: [
          'Attestation après travaux',
          'Conformité électrique certifiée'
        ],
        priority: 'required'
      },
      'plan' => {
        title: '🏠 Plans',
        image: 'plan.webp',
        conditions: [
          'Plans avant travaux',
          'Schémas techniques si nécessaire'
        ],
        priority: 'optional'
      },
      'permis_urbanisme' => {
        title: '🏛️ Permis d\'urbanisme',
        image: 'Permis.jpeg',
        conditions: [
          'Si requis selon travaux',
          'Permis accordé avant travaux'
        ],
        priority: 'optional'
      },
      'dossier_prime' => {
        title: '💰 Dossier primes',
        image: 'prime.jpg',
        conditions: [
          'Primes acceptées/refusées',
          'Historique des demandes'
        ],
        priority: 'optional'
      },
      'certificat_protection' => {
        title: '🛡️ Client protégé',
        image: 'protege.jpg',
        conditions: [
          'Certificat de protection consommateur',
          'Si applicable'
        ],
        priority: 'optional'
      },
      'acte_notarial' => {
        title: '📜 Acte notarial',
        image: 'acte_notarial.jpg',
        conditions: [
          'Acte notarié de la propriété',
          'Document officiel de propriété'
        ],
        priority: 'optional'
      },
      'compromis' => {
        title: '🤝 Compromis',
        image: 'compromis.jpg',
        conditions: [
          'Compromis de vente signé',
          'Accord préliminaire d\'achat'
        ],
        priority: 'optional'
      }
    }
  end

  def documents_phases_dashboard
    @property = current_user.properties.find(params[:id])

    # Données pour les phases chantier
    @phases_chantier = DocumentPhase.chantier.ordered.includes(:document_phase_statuses).map do |phase|
      {
        phase: phase,
        status: @property.phase_status_for(phase),
        completion_percentage: phase.completion_percentage_for_property(@property),
        phase_status: phase.status_for_property(@property),
        missing_required: phase.missing_required_documents_for_property(@property),
        missing_optional: phase.missing_optional_documents_for_property(@property)
      }
    end

    # Données pour les phases investissement
    @phases_investissement = DocumentPhase.investissement.ordered.includes(:document_phase_statuses).map do |phase|
      {
        phase: phase,
        status: @property.phase_status_for(phase),
        completion_percentage: phase.completion_percentage_for_property(@property),
        phase_status: phase.status_for_property(@property),
        missing_required: phase.missing_required_documents_for_property(@property),
        missing_optional: phase.missing_optional_documents_for_property(@property)
      }
    end

    # Données actuelles basées sur le type de projet
    @phases_data = @property.phases_with_status
    @phase_calculator = DocumentPhaseCalculatorService.new(@property)
    @comprehensive_metrics = @phase_calculator.calculate_comprehensive_metrics
    @recommendations = @phase_calculator.intelligent_recommendations.first(3)
    @potential_issues = @phase_calculator.detect_potential_issues
  end

  def formulaire_miroir
    @property = current_user.properties.find(params[:id])

    # Vérifier la complétude avant d'accéder au formulaire miroir
    unless @property.ready_for_submission?
      redirect_to property_dashboard_path(@property),
                  alert: "Veuillez compléter toutes les informations avant d'accéder au formulaire miroir."
      return
    end

    # Pré-remplir les données du formulaire à partir des informations de la propriété
    @form_data = build_formulaire_data(@property)
    @completion_stats = {
      admin: @property.admin_completion_percentage,
      chantier: @property.chantier_completion_percentage,
      documents: @property.documents_completion_percentage,
      overall: @property.completion_percentage
    }

    # Déterminer le template selon la région
    @template_region = @property.region || 'flandre'

    # Render du template qui est maintenant dans requests/
    render 'requests/formulaire_miroir'
  end

  def submit_prime
    @property = current_user.properties.find(params[:id])

    # Vérifier les conditions de soumission
    unless @property.ready_for_submission? && current_user.can_submit?
      redirect_to property_dashboard_path(@property),
                  alert: "Conditions non remplies pour la soumission."
      return
    end

    # Traitement de la soumission
    result = PrimeSubmissionService.new(@property, current_user, params).call

    if result.success?
      redirect_to property_dashboard_path(@property),
                  notice: "Demande de prime soumise avec succès ! Numéro de dossier : #{result.dossier_number}"
    else
      redirect_to formulaire_miroir_property_path(@property),
                  alert: "Erreur lors de la soumission : #{result.error}"
    end
  end

  def select_form
    @property = current_user.properties.find(params[:id])

    # Charger les requests existantes pour cette propriété
    @existing_requests = @property.requests.includes(:request_progresses)
                                            .order(created_at: :desc)

    # Grouper par form_type pour éviter les doublons
    @existing_form_types = @existing_requests.pluck(:form_type).compact.uniq

    # Configuration des formulaires disponibles selon la région et le type de bien
    @available_forms = get_available_forms_for_property(@property)

    # Statistiques de complétude
    @completion_stats = calculate_forms_completion_stats(@existing_requests)
  end

  private

  def set_property
    @property = current_user.properties.find(params[:id])
  end

  def property_params
    params.require(:property).permit(
      # Champs de base
      :rue, :numero, :code_postal, :commune, :region,
      :type_propriete, :type, :occupation,
      :autre_bien, :peb, :audit_energetique, :reconstruit,
      :annee_construction, :date_raccordement_electrique,
      :numero_ean, :numero_cadastre,
      :date_peb_avant_travaux, :date_peb_apres_travaux,
      :titre, :surface_totale, :usage, :primes_recues,

      # Photo du bien
      :photo,

      # Informations d'achat
      :valeur_achat, :date_achat,

      # Champs communs améliorés
      :surface_habitable, :mode_chauffage_principal,

      # Champs pour l'éligibilité aux primes
      :habitation_percentage,

      # Champs spécifiques Wallonie
      :type_propriete_wallonie, :certificat_peb_wallonie,
      :surface_habitable_wallonie, :mode_chauffage_wallonie,

      # Champs spécifiques Flandre
      :type_bien_flandre, :usage_flandre, :chauffage_post_renovation_flandre,
      :ean_flandre, :parcelle_flandre, :certificat_peb_flandre,
      :type_propriete_flandre, :pourcentage_propriete, :domicilie_flandre, :client_protege_flandre,
      :profil_demandeur,

      # Champs spécifiques Bruxelles
      :type_bien_bruxelles, :certificat_peb_bruxelles,

      # Champs spécifiques Entreprise
      :nombre_salaries, :date_creation, :regle_minimis, :bce_number,
      :code_nace_1, :code_nace_2, :code_nace_3, :code_nace_4, :code_nace_5,
      :comptes_annuels_conformes, :plan_diversite_actif, :pourcentage_financement_public,

      # Champs d'adresse d'exploitation
      :rue_exploitation, :numero_exploitation, :code_postal_exploitation,
      :commune_exploitation, :meme_adresse_exploitation
    )
  end

  def build_formulaire_data(property)
    {
      # Données administratives du demandeur
      nom: current_user.last_name,
      prenom: current_user.first_name,
      email: current_user.email,
      telephone: current_user.phone,
      registre_national: current_user.national_number,

      # Données spécifiques pour les formulaires officiels
      applicant_firstname: current_user.first_name,
      applicant_lastname: current_user.last_name,
      applicant_email: current_user.email,
      applicant_phone: current_user.phone,
      applicant_national_number: current_user.national_number,
      applicant_address: current_user.street,
      applicant_number: current_user.number,
      applicant_postal_code: current_user.postal_code,
      applicant_city: current_user.city,

      # Champs combinés pour certains formulaires
      applicant_full_name: "#{current_user.first_name} #{current_user.last_name}".strip,
      applicant_full_address: "#{current_user.street} #{current_user.number}".strip,
      applicant_postal_city: "#{current_user.postal_code} #{current_user.city}".strip,

      # Données du logement/bien
      ean: property.ean_flandre || property.numero_ean,
      adresse: "#{property.numero} #{property.rue}",
      code_postal: property.code_postal,
      commune: property.commune,
      type_bien: map_property_type(property),
      usage: map_property_usage(property),
      parcelle: property.parcelle_flandre || property.numero_cadastre,

      # Données spécifiques pour patrimoine
      heritage_address: property.rue,
      heritage_number: property.numero,
      heritage_postal_code: property.code_postal,
      heritage_city: property.commune,

      # Données techniques
      annee_construction: property.annee_construction,
      date_raccordement: property.date_raccordement_electrique,
      peb: property.peb,
      audit_energetique: property.audit_energetique,
      chauffage_post_renovation: property.chauffage_post_renovation_flandre,

      # Travaux (à partir des simulations/demandes)
      travaux_toiture: property.has_travaux?('toiture'),
      travaux_murs: property.has_travaux?('murs'),
      travaux_vitrage: property.has_travaux?('vitrage'),
      travaux_sol: property.has_travaux?('sol'),
      travaux_chauffage: property.has_travaux?('chauffage'),

      # Données du projet associé (si disponible)
      **build_project_data(property),

      # Documents
      documents_count: property.documents.approved.count,
      documents_complete: property.documents_completion_percentage >= 80
    }
  end

  # Méthodes helper pour le mapping des données
  def map_property_type(property)
    case property.region&.downcase
    when 'flandre'
      property.type_bien_flandre
    when 'wallonie'
      property.type_propriete_wallonie
    when 'bruxelles'
      property.type_bien_bruxelles
    else
      property.type
    end
  end

  def map_property_usage(property)
    case property.region&.downcase
    when 'flandre'
      property.usage_flandre
    else
      property.usage || property.occupation
    end
  end

  def build_project_data(property)
    project = property.projects.first # Ou le projet actif
    return {} unless project

    {
      # Données architecte
      architecte_prenom: project.architecte_prenom,
      architecte_nom: project.architecte_nom,
      architecte_entreprise: project.architecte_entreprise,
      architecte_telephone: project.architecte_telephone,
      architecte_email: project.architecte_email,
      architecte_numero_ordre: project.architecte_numero_ordre,
      architecte_adresse: project.architecte_adresse,

      # Données entrepreneur principal
      entrepreneur_principal_nom: project.entrepreneur_principal_nom,
      entrepreneur_principal_entreprise: project.entrepreneur_principal_entreprise,
      entrepreneur_principal_telephone: project.entrepreneur_principal_telephone,
      entrepreneur_principal_email: project.entrepreneur_principal_email,
      entrepreneur_principal_numero_tva: project.entrepreneur_principal_numero_tva,
      entrepreneur_principal_adresse: project.entrepreneur_principal_adresse,

      # Autres professionnels
      maitre_ouvrage_nom: project.maitre_ouvrage_nom,
      maitre_ouvrage_contact: project.maitre_ouvrage_contact,
      coordinateur_securite_nom: project.coordinateur_securite_nom
    }
  end

  # Méthodes pour le sélecteur de formulaires
  def get_available_forms_for_property(property)
    forms = []

    case property.region&.downcase
    when 'bruxelles'
      forms += [
        {
          code: 'regional_bruxelles',
          title: 'Prime régionale habitation',
          description: 'Primes pour travaux de rénovation énergétique',
          icon: 'bi-house-gear',
          category: 'Rénovation',
          eligible: true,
          external_url: 'https://www.bruxelles.be/logement-et-energie/renovation-de-mon-logement/primes'
        },
        {
          code: 'monuments_bruxelles',
          title: 'Monuments & Sites classés',
          description: 'Subventions pour conservation de biens classés',
          icon: 'bi-building-check',
          category: 'Patrimoine',
          eligible: property.monument_classe? || property.site_classe?,
          external_url: 'https://urban.brussels/patrimoine'
        },
        {
          code: 'patrimoine_bruxelles',
          title: 'Petit patrimoine populaire',
          description: 'Conservation du petit patrimoine architectural',
          icon: 'bi-gem',
          category: 'Patrimoine',
          eligible: property.petit_patrimoine?,
          external_url: 'https://urban.brussels/patrimoine'
        },
        {
          code: 'communal_bruxelles',
          title: 'Primes communales',
          description: 'Primes spécifiques à votre commune bruxelloise',
          icon: 'bi-geo-alt',
          category: 'Communal',
          eligible: true,
          external_url: 'https://www.bruxelles.be/logement-et-energie/renovation-de-mon-logement/primes'
        }
      ]
    when 'wallonie'
      forms += [
        {
          code: 'regional_wallonie',
          title: 'Prime régionale habitation',
          description: 'Primes habitation de la Région wallonne',
          icon: 'bi-house-gear',
          category: 'Rénovation',
          eligible: true,
          external_url: 'https://energie.wallonie.be/fr/aides-et-primes.html?IDC=10717'
        },
        {
          code: 'audit_wallonie',
          title: 'Audit énergétique',
          description: 'Prime pour audit énergétique en Wallonie',
          icon: 'bi-clipboard-data',
          category: 'Audit',
          eligible: property.needs_audit?,
          external_url: 'https://energie.wallonie.be/fr/aides-et-primes.html?IDC=10717'
        },
        {
          code: 'monuments_wallonie',
          title: 'Monuments & Sites classés',
          description: 'Patrimoine classé et sites archéologiques',
          icon: 'bi-building-check',
          category: 'Patrimoine',
          eligible: property.monument_classe? || property.site_classe?,
          external_url: 'https://patrimoine.wallonie.be/'
        },
        {
          code: 'communal_wallonie',
          title: 'Primes communales',
          description: 'Primes spécifiques à votre commune wallonne',
          icon: 'bi-geo-alt',
          category: 'Communal',
          eligible: true,
          external_url: 'https://energie.wallonie.be/fr/aides-et-primes.html?IDC=10717'
        }
      ]
    when 'flandre'
      forms += [
        {
          code: 'regional_flandre',
          title: 'Prime régionale habitation',
          description: 'Verbouwpremie - Primes de rénovation flamandes',
          icon: 'bi-house-gear',
          category: 'Rénovation',
          eligible: true,
          external_url: 'https://www.vlaanderen.be/premies-pour-renovation/mijn-verbouwpremie'
        },
        {
          code: 'monuments_flandre',
          title: 'Monuments & Sites (Onroerend Erfgoed)',
          description: 'Primes restauration patrimoine flamand',
          icon: 'bi-building-check',
          category: 'Patrimoine',
          eligible: property.monument_classe? || property.site_classe?,
          external_url: 'https://www.onroerenderfgoed.be/'
        },
        {
          code: 'communal_flandre',
          title: 'Primes communales',
          description: 'Primes spécifiques à votre commune flamande',
          icon: 'bi-geo-alt',
          category: 'Communal',
          eligible: true,
          external_url: 'https://www.vlaanderen.be/premies-pour-renovation/'
        }
      ]
    end

    # Ajouter formulaires entreprises si applicable
    if current_user.entreprise?
      forms += get_enterprise_forms
    end

    forms
  end

  def get_enterprise_forms
    [
      {
        code: 'consultance_bruxelles',
        title: 'Aide Consultance (Bruxelles)',
        description: 'Aide pour consultance externe',
        icon: 'bi-person-workspace',
        category: 'Entreprise',
        eligible: true,
        external_url: 'https://www.economie-emploi.brussels/'
      },
      {
        code: 'investissement_bruxelles',
        title: 'Prime Investissements Généraux',
        description: 'Aide aux investissements généraux',
        icon: 'bi-graph-up-arrow',
        category: 'Entreprise',
        eligible: true,
        external_url: 'https://www.economie-emploi.brussels/'
      }
      # ... autres formulaires entreprises
    ]
  end

  def calculate_forms_completion_stats(requests)
    stats = {}
    requests.each do |request|
      next if request.form_type.blank?
      stats[request.form_type] = {
        completion: request.form_completion_percentage,
        status: request.status,
        updated_at: request.updated_at
      }
    end
    stats
  end
end

class PropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: [:show, :dashboard, :edit, :update, :destroy, :debug_completion, :documents_dashboard]

  def index
    @properties = current_user.properties
  end

  def show
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
  end

  def new
    @property = current_user.properties.new
  end

  def create
    @property = current_user.properties.new(property_params)

    if @property.save
      redirect_to @property
    else
      # Si la création échoue, garder le paramètre region pour ré-afficher le bon formulaire
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property
    else
      render :edit
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_path
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
  end

  def debug_completion
    @debug_info = @property.completion_debug_info
    render json: @debug_info, status: :ok
  end

  def documents_dashboard
    @property = current_user.properties.find(params[:id])
    @documents_by_type = @property.documents_by_type
    @document_stats = Document.completion_stats_for_property(@property)

    # Configuration des types de documents avec leurs informations
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
      }
    }
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

      # Champs communs améliorés
      :surface_habitable, :mode_chauffage_principal,

      # Champs spécifiques Wallonie
      :type_propriete_wallonie, :certificat_peb_wallonie,
      :surface_habitable_wallonie, :mode_chauffage_wallonie,

      # Champs spécifiques Flandre
      :type_bien_flandre, :usage_flandre, :chauffage_post_renovation_flandre,
      :ean_flandre, :parcelle_flandre, :certificat_peb_flandre,

      # Champs spécifiques Bruxelles
      :type_bien_bruxelles, :certificat_peb_bruxelles
    )
  end

  def build_formulaire_data(property)
    {
      # Données administratives
      nom: current_user.last_name,
      prenom: current_user.first_name,
      email: current_user.email,
      telephone: current_user.phone,
      registre_national: current_user.national_number,

      # Données du logement
      ean: property.numero_ean,
      adresse: "#{property.numero} #{property.rue}",
      code_postal: property.code_postal,
      commune: property.commune,
      type_bien: property.type,
      usage: property.occupation,
      parcelle: property.numero_cadastre,

      # Données techniques
      annee_construction: property.annee_construction,
      date_raccordement: property.date_raccordement_electrique,
      peb: property.peb,
      audit_energetique: property.audit_energetique,

      # Travaux (à partir des simulations/demandes)
      travaux_toiture: property.has_travaux?('toiture'),
      travaux_murs: property.has_travaux?('murs'),
      travaux_vitrage: property.has_travaux?('vitrage'),
      travaux_sol: property.has_travaux?('sol'),
      travaux_chauffage: property.has_travaux?('chauffage'),

      # Documents
      documents_count: property.documents.approved.count,
      documents_complete: property.documents_completion_percentage >= 80
    }
  end
end

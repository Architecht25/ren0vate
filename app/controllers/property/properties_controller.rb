class PropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_gestion_locative_access!, only: [:gestion_locative, :profil_bailleur]
  before_action :set_property, only: [:show, :dashboard, :edit, :update, :destroy, :purge_photo, :documents_dashboard, :peb_recommandations, :documents_phases_dashboard, :formulaire_miroir, :submit_prime, :mise_en_vente, :activer_vente, :desactiver_vente, :marquer_vendu, :gestion_locative, :profil_bailleur]

  def index
    @properties = current_user.properties
                             .includes(:simulations, :documents)
                             .order(Arel.sql("CASE region WHEN 'flandre' THEN 1 WHEN 'bruxelles' THEN 2 WHEN 'wallonie' THEN 3 ELSE 4 END"), created_at: :desc)

    @portfolio_stats = {
      biens_count:        @properties.size,
      simulations_count:  current_user.simulations.count,
      total_primes:       current_user.simulations.sum(:total_simule).to_i,
      projets_actifs:     current_user.projects.where.not(statut: ['termine', 'annule', nil]).count
    }
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
    unless plan_exempt?
      limit = current_user.property_limit
      if limit != Float::INFINITY && current_user.properties.count >= limit
        redirect_to pricing_path,
          notice: "Vous avez atteint la limite de #{limit} bien(s) de votre offre #{current_user.subscription_tier_name}. " \
                  "Passez à l'offre Individuel (3 biens) ou Portfolio (10 biens) pour gérer tous vos projets."
        return
      end
    end

    @property = current_user.properties.new(property_params)

    Rails.logger.info "Creating property with params: #{property_params.inspect}"
    Rails.logger.info "Property region: #{@property.region}"
    Rails.logger.info "Property type: #{@property.type}"
    Rails.logger.info "Property type_bien_bruxelles: #{@property.type_bien_bruxelles}"
    Rails.logger.info "Property valid?: #{@property.valid?}"
    Rails.logger.info "Property errors: #{@property.errors.full_messages}" unless @property.valid?

    if @property.save
      # Redirection vers le dashboard du bien : le CTA "Compléter les informations"
      # y est déjà visible, pour un remplissage au fil de l'eau plutôt qu'en bloc à la création.
      redirect_to dashboard_property_path(@property), notice: t('notices.property_created')
    else
      # Préserver les paramètres région et type lors du rendu d'erreur
      @property.region = params[:region] if params[:region].present?
      @property.type = params[:type] if params[:type].present?
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

      # Redirection vers la propriété mise à jour
      redirect_to @property, notice: t('notices.property_updated')
    else
      Rails.logger.error "[PROPERTY UPDATE] ❌ Échec de la mise à jour pour propriété ID: #{@property.id}"
      Rails.logger.error "[PROPERTY UPDATE] 🚨 Erreurs: #{@property.errors.full_messages.join(', ')}"

      flash.now[:alert] = t('errors.property_update_failed', errors: @property.errors.full_messages.join(', '))
      render :edit, status: :unprocessable_entity
    end
  end

  def check_heritage
    render json: Properties::HeritageCheckService.call(lat: params[:lat], lon: params[:lon])
  rescue Properties::HeritageCheckService::InvalidCoordinates
    render json: { error: 'Coordonnées invalides' }, status: :bad_request
  rescue => e
    render json: { error: e.message }, status: :bad_gateway
  end

  def purge_photo
    @property.photo.purge
    redirect_to edit_property_path(@property), notice: "Photo supprimée."
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
    data_details = @property.data_completeness_details
    @completion_stats = {
      admin: @property.admin_completion_percentage,
      chantier: @property.chantier_completion_percentage,
      primes: @property.primes_completion_percentage,
      overall: @property.completion_percentage,
      data: data_details[:percentage],
      data_done: data_details[:done],
      data_total: data_details[:total]
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

    # Données PEB pour la carte recommandations du dashboard
    @peb_donnees_recent = @property.peb_donnees.order(created_at: :desc).limit(3)
  end

  def peb_recommandations
    all_peb = @property.peb_donnees.includes(:document).order(created_at: :desc)

    # Backfill — force si recommandations absentes OU si fragments détectés (moy < 50 chars)
    all_peb.each do |peb|
      next unless peb.texte_ocr_brut.present? && peb.region.present?

      existing = peb.donnees_extraites['recommandations'] || []
      needs_refresh = existing.empty? ||
                      existing.first.is_a?(String) ||
                      (existing.first.is_a?(Hash) && existing.first['poste'].blank?)
      next unless needs_refresh

      recs = Ocr::PebOcrService.recommandations_depuis_texte(peb.texte_ocr_brut, peb.region)
      peb.update_column(:donnees_extraites, peb.donnees_extraites.merge('recommandations' => recs))
    end

    # Dédupliquer par numero_certificat (garder le plus récent de chaque groupe)
    all_peb = @property.peb_donnees.includes(:document).order(created_at: :desc)
    @peb_donnees = all_peb
      .group_by { |p| p.numero_certificat.presence || "id_#{p.id}" }
      .map { |_, group| group.first }
      .sort_by(&:created_at).reverse
  end

  def documents_dashboard
    @property = current_user.properties.find(params[:id])
    @document_stats = Document.completion_stats_for_property(@property)

    load_phase_metrics

    # Configuration des types de documents avec leurs informations (legacy pour transition)
    @document_types_config = DocumentTypeCatalog::CONFIG
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
    load_phase_metrics
  end

  def formulaire_miroir
    @property = current_user.properties.find(params[:id])

    # Vérifier la complétude avant d'accéder au formulaire miroir
    unless @property.ready_for_submission?
      redirect_to dashboard_property_path(@property),
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
      redirect_to dashboard_property_path(@property),
                  alert: "Conditions non remplies pour la soumission."
      return
    end

    # Traitement de la soumission
    result = PrimeSubmissionService.new(@property, current_user, params).call

    if result.success?
      redirect_to dashboard_property_path(@property),
                  notice: "Demande de prime soumise avec succès ! Numéro de dossier : #{result.dossier_number}"
    else
      redirect_to formulaire_miroir_property_path(@property),
                  alert: "Erreur lors de la soumission : #{result.error}"
    end
  end

  # GET /properties/:id/mise_en_vente
  def mise_en_vente
    @checklist_vente = @property.checklist_vente
    @checklist_diu   = @property.checklist_diu
    @readiness_score = @property.vente_readiness_score
    @projects        = @property.projects.order(created_at: :desc)
  end

  # PATCH /properties/:id/activer_vente
  def activer_vente
    if @property.update(statut_vente: 'en_vente',
                        date_mise_en_vente: Date.current,
                        prix_vente_estime: params[:prix_vente_estime].presence)
      redirect_to mise_en_vente_property_path(@property),
                  notice: 'Votre bien est maintenant en mode « En vente ».'
    else
      redirect_to mise_en_vente_property_path(@property),
                  alert: 'Impossible d\'activer le mode vente.'
    end
  end

  # PATCH /properties/:id/desactiver_vente
  def desactiver_vente
    @property.update(statut_vente: 'actif', date_mise_en_vente: nil)
    redirect_to dashboard_property_path(@property),
                notice: 'Mode vente désactivé.'
  end

  # PATCH /properties/:id/marquer_vendu
  def marquer_vendu
    @property.update(statut_vente: 'vendu')
    redirect_to dashboard_property_path(@property),
                notice: 'Bien marqué comme vendu. Félicitations !'
  end

  def gestion_locative
    @leases   = @property.leases.includes(:tenant, :rent_payments).order(created_at: :desc)
    @tenants  = @property.tenants.includes(:leases).order(:last_name, :first_name)
    @bail_actif = @leases.find { |l| l.actif? }
    @paiements_retard = @bail_actif&.rent_payments&.overdue || []
  end

  # GET /properties/:id/profil_bailleur
  # Tableau de bord dédié propriétaire-bailleur (suggestion veille marketing, 24/08/2026) :
  # centralise PEB actuel vs cible réglementaire, travaux réalisés/planifiés et conformité
  # locative. Réutilise des données déjà présentes ailleurs (gestion locative + chantiers +
  # trajectoire PEB) — pas de nouveau moteur de calcul.
  def profil_bailleur
    @leases     = @property.leases.includes(:tenant).order(created_at: :desc)
    @bail_actif = @leases.find(&:actif?)

    @peb_trajectory = @property.peb_trajectory
    @peb_actuel     = @property.peb_donnees.order(created_at: :desc).first

    @projets_en_cours   = @property.projects.where.not(statut: ['termine', 'annule', nil])
    @projets_termines   = @property.projects.where(statut: 'termine')

    # Conformité locative — checklist factuelle, pas de calcul juridique
    @conformite = {
      bail_actif:          @bail_actif.present?,
      garantie_renseignee: @bail_actif&.rental_guarantee_amount.present?,
      peb_valide:          @peb_actuel.present? && !@peb_actuel.perime?
    }
  end

  private

  def set_property
    @property = current_user.properties.find(params[:id])
  end

  # Commun à documents_dashboard et documents_phases_dashboard
  def load_phase_metrics
    @phases_data = @property.phases_with_status
    @phase_calculator = Documents::DocumentPhaseCalculatorService.new(@property)
    @comprehensive_metrics = @phase_calculator.calculate_comprehensive_metrics
    @recommendations = @phase_calculator.intelligent_recommendations.first(3)
    @potential_issues = @phase_calculator.detect_potential_issues
  end

  def property_params
    params.require(:property).permit(
      # Champs de base
      :rue, :numero, :code_postal, :commune, :region,
      :type_propriete, :type, :occupation,
      :autre_bien, :peb, :audit_energetique,
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
      :type_propriete_wallonie, :type_bien_wallonie, :certificat_peb_wallonie,
      :surface_habitable_wallonie, :mode_chauffage_wallonie,

      # Champs spécifiques Flandre
      :type_bien_flandre, :usage_flandre, :chauffage_post_renovation_flandre,
      :ean_flandre, :certificat_peb_flandre,
      :type_propriete_flandre, :pourcentage_propriete, :domicilie_flandre, :client_protege_flandre,
      :profil_demandeur, :type_demandeur,

      # Champs spécifiques Bruxelles
      :type_bien_bruxelles, :certificat_peb_bruxelles,
      :domiciliation, :nouvelle_construction, :bien_classe, :petit_patrimoine, :facade_patrimoine,
      :bce_number,
      :statut_patrimonial, :denomination_monument, :date_classement, :numero_dossier_monument,
      elements_petit_patrimoine: []
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
      type_bien: property.mapped_type,
      usage: property.mapped_usage,
      parcelle: property.numero_cadastre,

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

  # map_property_type / map_property_usage fournis par Property#mapped_type / #mapped_usage

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
end

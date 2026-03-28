class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :gantt, :edit_budget, :update_budget, :edit_professionals, :update_professionals]

  def index
    # Récupérer les projets, filtrer par property_id si fourni
    base_projects = current_user.projects.includes(:property)

    if params[:property_id].present?
      @property = current_user.properties.find(params[:property_id])
      @projects = base_projects.where(property: @property).order(created_at: :desc)
    else
      # Récupérer et trier les projets par région de la propriété (Flandre → Bruxelles → Wallonie)
      @projects = base_projects.order(created_at: :desc).sort_by do |project|
        case project.property&.region&.downcase
        when 'flandre' then 1
        when 'bruxelles' then 2
        when 'wallonie' then 3
        else 4 # Projets sans propriété ou sans région en dernier
        end
      end
    end
  end

  def show
    @documents = @project.documents.order(created_at: :desc) if @project.documents.respond_to?(:order)
    photo_types = %w[photo_avant photo_pendant photo_apres photo_chassis]
    @photos = @project.documents.where(type_document: photo_types).order(created_at: :desc)
    @photos_by_type = @photos.group_by(&:type_document)

    # Planning preview
    @latest_quote = @project.property&.quotes&.includes(:quote_items)&.order(created_at: :desc)&.first
    @planning_items_count = @latest_quote ? @latest_quote.quote_items.count : 0
    @factures_count = @project.factures.count
    @simulations = @project.simulations.order(created_at: :desc)
  end

  def new
    @project = current_user.projects.build
    @project.project_type = params[:project_type] if params[:project_type].present?
  end

  def create
    @project = Project.new(project_params)
    @project.user = current_user

    if @project.save
      message = @project.investment? ? 'Investissement créé avec succès.' : 'Chantier créé avec succès.'
      redirect_to @project, notice: message
    else
      Rails.logger.error "Project validation errors: #{@project.errors.full_messages}"
      flash.now[:alert] = "Erreurs de validation : #{@project.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def edit_budget
  end

  def edit_professionals
  end

  def update_professionals
    if @project.update(professionals_params)
      redirect_to @project, notice: 'Équipe projet mise à jour avec succès.'
    else
      render :edit_professionals, status: :unprocessable_entity
    end
  end

  def update_budget
    if @project.update(budget_params)
      redirect_to @project, notice: 'Budget mis à jour avec succès.'
    else
      render :edit_budget, status: :unprocessable_entity
    end
  end

  def update
    # Traitement spécial pour les entrepreneurs additionnels
    if params[:additional_entrepreneurs].present?
      additional_entrepreneurs_data = params[:additional_entrepreneurs].map do |entrepreneur|
        entrepreneur.permit(:nom, :entreprise, :numero_tva, :telephone, :email, :adresse, :assurance, :specialite, :devis_montant)
      end
      @project.additional_entrepreneurs = additional_entrepreneurs_data.to_json
    end

    if @project.update(project_params)
      message = @project.investment? ? 'Investissement mis à jour avec succès.' : 'Chantier mis à jour avec succès.'
      redirect_to @project, notice: message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project_name = @project.nom
    project_type = @project.investment? ? "l'investissement" : "le chantier"

    begin
      @project.destroy
      redirect_to projects_path, notice: "#{project_type.capitalize} '#{project_name}' a été supprimé avec succès."
    rescue => e
      redirect_to @project, alert: "Erreur lors de la suppression #{project_type.gsub('l\'', 'd\'un ')} : #{e.message}"
    end
  end

  def gantt
    @quotes = @project.property.quotes.includes(:quote_items).order(created_at: :desc)
    @latest_quote = @quotes.first
    @factures = @project.factures.order(:date_facture)

    # Date de début : date_début du projet ou aujourd'hui
    @start_date = @project.date_début || Date.today

    # Construire les barres Gantt depuis le dernier devis
    @gantt_bars = build_gantt_bars(@start_date, @latest_quote)

    # Jalons : date début, factures, date fin
    @milestones = build_milestones
  end

  private

  def build_gantt_bars(start_date, quote)
    return [] unless quote

    cursor = start_date
    bars = []

    quote.quote_items.each do |item|
      wt = WorkType.find(item.work_type_key)
      next unless wt

      duration = item.unit_price_min.present? ? (wt.duration_min + wt.duration_max) / 2.0 : wt.duration_min
      end_date = cursor + duration.ceil.days

      bars << {
        key:      item.work_type_key,
        name:     wt.name,
        icon:     wt.icon,
        category: wt.category,
        start:    cursor,
        end:      end_date,
        total_min: item.total_min,
        total_max: item.total_max,
        total_avg: item.total_avg || ((item.total_min.to_f + item.total_max.to_f) / 2).round(2)
      }

      # Chevauchement léger : démarrage du suivant à J+2 du début (travaux parallèles possibles)
      cursor = cursor + 2.days
    end

    bars
  end

  def build_milestones
    milestones = []
    milestones << { date: @project.date_début, label: 'Début chantier', color: 'success' } if @project.date_début
    @factures.each do |f|
      next unless f.date_facture
      milestones << { date: f.date_facture, label: "Facture #{f.type_facture&.humanize}", color: 'warning' }
    end
    milestones << { date: @project.date_fin, label: 'Fin prévue', color: 'danger' } if @project.date_fin
    milestones.sort_by { |m| m[:date] }
  end

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def budget_params
    params.require(:project).permit(:architecte_devis_montant, :contractor_devis_montant)
  end

  def professionals_params
    params.require(:project).permit(
      :architecte_nom, :architecte_prenom, :architecte_entreprise, :architecte_numero_ordre,
      :architecte_telephone, :architecte_email, :architecte_adresse, :architecte_specialites,
      :entrepreneur_principal_nom, :entrepreneur_principal_entreprise, :entrepreneur_principal_numero_tva,
      :entrepreneur_principal_telephone, :entrepreneur_principal_email, :entrepreneur_principal_adresse,
      :entrepreneur_principal_assurance, :entrepreneur_principal_certifications,
      :maitre_ouvrage_nom, :maitre_ouvrage_contact, :coordinateur_securite_nom, :coordinateur_securite_contact,
      :assurance_decennale_architecte, :assurance_decennale_entrepreneur, :garanties_travaux,
      :additional_entrepreneurs
    )
  end

  def project_params
    params.require(:project).permit(
      :nom, :description, :date_début, :date_fin, :statut, :property_id, :project_type,
      :bce_number, :invoice_date, :work_completion_date,
      # Champs spécifiques Flandre
      :type_travaux, :reconstruction_demolition, :tva_reduit_6_pourcent,
      # Checkboxes pour types de travaux Flandre
      :type_travaux_isolation, :type_travaux_chauffage, :type_travaux_ventilation,
      :type_travaux_fenetres, :type_travaux_toiture, :type_travaux_autre,
      # Champs architecte
      :architecte_nom, :architecte_prenom, :architecte_entreprise, :architecte_numero_ordre,
      :architecte_telephone, :architecte_email, :architecte_adresse, :architecte_specialites,
      # Champs entrepreneur principal
      :entrepreneur_principal_nom, :entrepreneur_principal_entreprise, :entrepreneur_principal_numero_tva,
      :entrepreneur_principal_telephone, :entrepreneur_principal_email, :entrepreneur_principal_adresse,
      :entrepreneur_principal_assurance, :entrepreneur_principal_certifications,
      # Champs montants de devis
      :architecte_devis_montant, :contractor_devis_montant,
      # Champs autres professionnels
      :maitre_ouvrage_nom, :maitre_ouvrage_contact, :coordinateur_securite_nom, :coordinateur_securite_contact,
      # Champs assurances
      :assurance_decennale_architecte, :assurance_decennale_entrepreneur, :garanties_travaux,
      # Champs audit énergétique (Wallonie)
      :numero_audit, :date_audit, :numero_agrement_auditeur, :prix_audit,
      # Corps de métiers (JSON)
      :corps_metiers,
      # Entrepreneurs additionnels
      :additional_entrepreneurs,
      additional_entrepreneurs: []
    )
  end
end

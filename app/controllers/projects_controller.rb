class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy]

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

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :nom, :description, :date_début, :date_fin, :statut, :property_id, :project_type, :finalite,
      :bce_number, :invoice_date, :work_completion_date,
      # Nouveaux champs d'éligibilité pour Bruxelles Entreprises
      :demande_avant_debut, :finalite_economique_confirmee,
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

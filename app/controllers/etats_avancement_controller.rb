class EtatsAvancementController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_etat_avancement, only: [:show, :edit, :update, :destroy, :soumettre, :approuver, :rejeter]
  before_action :ensure_can_create,   only: [:new, :create, :analyze_devis]
  before_action :ensure_can_approve,  only: [:approuver, :rejeter]

  # GET /projects/:project_id/etats_avancement
  def index
    @etats = @project.etats_avancement.chronologique.includes(:created_by, :lignes)
    @dernier_approuve = @etats.approuves.last
  end

  # GET /projects/:project_id/etats_avancement/new
  def new
    @etat = @project.etats_avancement.build(source_type: 'manuel', created_by: current_user)
    @devis_disponibles = devis_disponibles
  end

  # POST /projects/:project_id/etats_avancement
  def create
    @etat = @project.etats_avancement.build(etat_params.merge(created_by: current_user))

    if @etat.save
      redirect_to project_etats_avancement_path(@project, @etat),
                  notice: "État d'avancement n°#{@etat.numero} créé."
    else
      @devis_disponibles = devis_disponibles
      render :new, status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/etats_avancement/:id
  def show
    @lignes_par_thematique = @etat.lignes_par_thematique
    @avancement_pct        = @etat.avancement_global_pct
  end

  # GET /projects/:project_id/etats_avancement/:id/edit
  def edit
    @lignes_par_thematique = @etat.lignes_par_thematique
  end

  # PATCH /projects/:project_id/etats_avancement/:id
  def update
    if @etat.brouillon? || @etat.rejete?
      ActiveRecord::Base.transaction do
        # Mettre à jour les % des lignes
        if params[:lignes].present?
          params[:lignes].each do |ligne_id, ligne_params|
            ligne = @etat.lignes.find_by(id: ligne_id)
            next unless ligne
            ligne.update!(pct_cumule_actuel: ligne_params[:pct_cumule_actuel].to_i.clamp(0, 100))
          end
        end
        # Recalculer et sauvegarder les totaux
        @etat.recalculate_totals
        @etat.save!
      end

      redirect_to project_etats_avancement_path(@project, @etat),
                  notice: "Pourcentages mis à jour."
    else
      redirect_to project_etats_avancement_path(@project, @etat),
                  alert: "Cet état ne peut plus être modifié (statut : #{@etat.statut_label})."
    end
  rescue ActiveRecord::RecordInvalid => e
    @lignes_par_thematique = @etat.lignes_par_thematique
    flash.now[:alert] = "Erreur : #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  # DELETE /projects/:project_id/etats_avancement/:id
  def destroy
    unless @etat.brouillon?
      return redirect_to project_etats_avancement_index_path(@project),
                         alert: "Seul un brouillon peut être supprimé."
    end
    @etat.destroy
    redirect_to project_etats_avancement_index_path(@project),
                notice: "État d'avancement supprimé."
  end

  # POST /projects/:project_id/etats_avancement/:id/soumettre
  def soumettre
    unless @etat.brouillon? || @etat.rejete?
      return redirect_to project_etats_avancement_path(@project, @etat),
                         alert: "Cet état ne peut pas être soumis."
    end
    @etat.soumettre!
    redirect_to project_etats_avancement_path(@project, @etat),
                notice: "État d'avancement soumis pour validation."
  end

  # POST /projects/:project_id/etats_avancement/:id/approuver
  def approuver
    @etat.approuver!(commentaire: params[:commentaire])
    redirect_to project_etats_avancement_path(@project, @etat),
                notice: "État d'avancement approuvé."
  end

  # POST /projects/:project_id/etats_avancement/:id/rejeter
  def rejeter
    @etat.rejeter!(commentaire: params[:commentaire])
    redirect_to project_etats_avancement_path(@project, @etat),
                alert: "État d'avancement rejeté."
  end

  # POST /projects/:project_id/etats_avancement/analyze_devis
  # Analyse un devis via l'IA et retourne le JSON proposé (AJAX/Turbo)
  def analyze_devis
    devis_donnee = nil
    texte        = ''

    if params[:devis_donnee_id].present?
      devis_donnee = @project.devis_donnees.find_by(id: params[:devis_donnee_id])
      texte        = devis_donnee&.texte_ocr_brut.to_s
    elsif params[:texte_libre].present?
      texte = params[:texte_libre].to_s
    end

    if texte.blank?
      return render json: { success: false, error: 'Aucun texte à analyser.' }, status: :unprocessable_entity
    end

    result = DevisAvancementService.new(
      texte:        texte,
      project:      @project,
      devis_donnee: devis_donnee
    ).call

    if result[:success]
      render json: result, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  # POST /projects/:project_id/etats_avancement/create_from_analysis
  # Crée l'état + toutes les lignes depuis le résultat JSON de l'IA
  def create_from_analysis
    analysis = JSON.parse(params[:analysis_json])

    ActiveRecord::Base.transaction do
      devis_donnee = @project.devis_donnees.find_by(id: params[:devis_donnee_id])

      @etat = @project.etats_avancement.create!(
        created_by:    current_user,
        source_type:   params[:source_type].presence || 'devis_entrepreneur',
        devis_donnee:  devis_donnee,
        date_emission: Date.current,
        resume_ia:     analysis['resume'],
        genere_par_ia: true
      )

      position = 0
      Array(analysis['thematiques']).each do |them|
        Array(them['lignes']).each do |l|
          montant = l['montant_marche'] ||
                    ((l['quantite'].to_f * l['prix_unitaire'].to_f).round(2) if l['quantite'] && l['prix_unitaire'])

          @etat.lignes.create!(
            thematique_code:  them['code'],
            thematique_label: them['label'],
            sous_secteur:     l['sous_secteur'],
            reference:        l['reference'],
            designation:      l['designation'],
            unite:            l['unite'] || 'forfait',
            quantite:         l['quantite'],
            prix_unitaire:    l['prix_unitaire'],
            montant_marche:   montant,
            pct_cumule_precedent: 0,
            pct_cumule_actuel:    0,
            position:         position,
            ia_suggere:       true,
            ia_confiance:     l['ia_confiance'] || 'moyenne'
          )
          position += 1
        end
      end

      @etat.recalculate_totals
      @etat.save!
    end

    redirect_to project_etats_avancement_path(@project, @etat),
                notice: "État d'avancement n°#{@etat.numero} créé avec #{@etat.lignes.count} postes depuis l'IA."
  rescue JSON::ParserError
    redirect_to new_project_etats_avancement_path(@project), alert: "Données d'analyse invalides."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_project_etats_avancement_path(@project), alert: "Erreur : #{e.message}"
  end

  private

  def set_project
    @project = current_user.projects.find_by(id: params[:project_id]) ||
               current_user.project_members.active.joins(:project)
                           .where(projects: { id: params[:project_id] })
                           .first&.project
    redirect_to projects_path, alert: "Projet introuvable." unless @project
  end

  def set_etat_avancement
    @etat = @project.etats_avancement.find(params[:id])
  end

  def membership
    @membership ||= current_user.project_members.find_by(project: @project)
  end

  def ensure_can_create
    # Propriétaire ou entrepreneur du projet
    is_owner       = @project.user_id == current_user.id
    is_entrepreneur = membership&.role == 'entrepreneur'
    unless is_owner || is_entrepreneur
      redirect_to project_path(@project), alert: "Seul l'entrepreneur ou le propriétaire peut créer un état d'avancement."
    end
  end

  def ensure_can_approve
    is_owner    = @project.user_id == current_user.id
    is_architect = membership&.role == 'architect'
    unless is_owner || is_architect
      redirect_to project_etats_avancement_path(@project, @etat),
                  alert: "Seul l'architecte ou le propriétaire peut valider un état d'avancement."
    end
  end

  def etat_params
    params.require(:etat_avancement).permit(
      :source_type, :date_emission, :periode_debut, :periode_fin,
      :commentaire_entrepreneur, :devis_donnee_id
    )
  end

  def devis_disponibles
    entrepreneur_devis = @project.devis_donnees.emetteur_entrepreneur.with_montant.order(created_at: :desc)
    architecte_devis   = @project.devis_donnees.emetteur_architecte.with_montant.order(created_at: :desc)
    { entrepreneur: entrepreneur_devis, architecte: architecte_devis }
  end
end

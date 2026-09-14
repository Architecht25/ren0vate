class LoansHubController < ApplicationController
  before_action :authenticate_user!
  before_action :load_property
  before_action :load_project

  def index
  end

  def credit_classique
  end

  def verbouwlening
    @categories_flandre = Category.flandre
                                  .where(eligible_pour_verbouwlening: true)
                                  .order(:seuil_seul)
  end

  def renopack
  end

  def ecoreno
  end

  private

  def load_property
    @property = current_user.properties.find_by(id: params[:property_id]) if params[:property_id].present?
  end

  # Contexte projet optionnel : quand présent, permet le bouton "Ajouter comme
  # source de financement" (voir _simulator.html.erb) qui pousse le résultat du
  # simulateur dans FinancingSource. Même règle d'autorisation que les autres
  # ressources imbriquées sous /projects/:project_id (owner ou membre pro actif).
  def load_project
    return if params[:project_id].blank?

    @project = current_user.projects.find_by(id: params[:project_id])
    @project ||= Project
                   .joins(:project_members)
                   .where(project_members: { user_id: current_user.id, status: "active" })
                   .find_by(id: params[:project_id])
  end
end

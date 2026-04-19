class Admin::PropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def show
    @property = Property.includes(
      :user,
      projects: [:documents],
      simulations: [],
      documents: { file_attachment: :blob },
      requests: :request_progresses
    ).find(params[:id])
    @user = @property.user
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_dashboard_path, alert: "Propriété introuvable (ID: #{params[:id]})"
  end

  private

  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès non autorisé."
    end
  end
end

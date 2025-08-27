class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def dashboard
    @local_storage_data = {} # Placeholder pour les données JS
    @primes = Prime.all
    @categories = Category.all
    @documents = Document.all
    @notifications = Notification.all
    @properties = Property.all
    @projects = Project.all
    @requests = Request.all
    @simulations = Simulation.all
    @users = User.all
    @backup_status = BackupStatusService.call
  end

  private

  def ensure_admin
    unless current_user&.admin?
      flash[:alert] = "Accès non autorisé. Vous devez être administrateur."
      redirect_to root_path
    end
  end
end

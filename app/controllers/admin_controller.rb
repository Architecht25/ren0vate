class AdminController < ApplicationController
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
    @work = Work.all
  end
end

class Admin::IntelligenceReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    @reports = IntelligenceReport.recent.limit(20)
    @current_week = IntelligenceReport.current_week_key
  end

  def show
    @report = IntelligenceReport.find(params[:id])
  end

  # Lancer manuellement une analyse pour la semaine courante
  def run
    report = IntelligenceReport.find_or_initialize_for_current_week

    if report.processing?
      redirect_to admin_dashboard_path(anchor: 'intelligence-panel'), alert: "Analyse déjà en cours pour #{report.week_of}."
      return
    end

    if report.completed?
      redirect_to admin_dashboard_path(anchor: 'intelligence-panel'), notice: "Rapport #{report.week_of} déjà disponible."
      return
    end

    report.save! if report.new_record?
    IntelligenceReportJob.perform_later
    redirect_to admin_dashboard_path(anchor: 'intelligence-panel'), notice: "Analyse lancée pour #{report.week_of}. Tu recevras un email dès que c'est prêt (~2 min)."
  end

  private

  def ensure_admin
    redirect_to root_path, alert: "Accès refusé." unless current_user.admin?
  end
end

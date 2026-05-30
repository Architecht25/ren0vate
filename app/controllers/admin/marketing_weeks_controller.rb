class Admin::MarketingWeeksController < AdminController
  before_action :ensure_admin
  before_action :set_week, only: [:show, :destroy, :mark_reviewed, :mark_published]

  def index
    @weeks = MarketingWeek.recent.includes(:article).limit(20)
  end

  def show; end

  def destroy
    @week.article&.destroy
    @week.destroy
    redirect_to admin_marketing_weeks_path, notice: "Semaine #{@week.week_of} supprimée."
  end

  def mark_reviewed
    @week.update!(status: 'reviewed')
    redirect_to admin_marketing_week_path(@week), notice: "Marqué comme relu."
  end

  def mark_published
    @week.update!(status: 'published')
    redirect_to admin_marketing_week_path(@week), notice: "Marqué comme publié."
  end

  private

  def set_week
    @week = MarketingWeek.find(params[:id])
  end

  def ensure_admin
    redirect_to root_path, alert: "Accès refusé." unless current_user.admin?
  end
end

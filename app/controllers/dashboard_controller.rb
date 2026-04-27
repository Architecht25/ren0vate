class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_onboarding_done

  def index
    # Résoudre le profil : user_profile (onboarding) OU professional_type (inscription directe)
    resolved_profile = current_user.user_profile
    if resolved_profile == 'proprietaire' && current_user.professional_type.present?
      resolved_profile = case current_user.professional_type
                         when 'architect'     then 'architecte'
                         when 'entrepreneur'  then 'entrepreneur'
                         when 'intermediary'  then 'intermediaire'
                         end
    end

    case resolved_profile
    when 'architecte'
      load_pro_dashboard_data
      render 'dashboard/architecte' and return
    when 'entrepreneur'
      load_pro_dashboard_data
      render 'dashboard/entrepreneur' and return
    when 'intermediaire'
      load_pro_dashboard_data
      render 'dashboard/intermediaire' and return
    end

    # Profil propriétaire (défaut)
    if current_user.professional_guest?
      redirect_to member_projects_path and return
    end

    @properties = current_user.properties.includes(:requests, :simulations).limit(10)
    @total_properties = current_user.properties.count
    @total_requests = current_user.requests.count
    @active_requests = current_user.requests.where(status: ['pending', 'in_progress']).count
    @recent_notifications = current_user.notifications.recent.limit(3) if current_user.respond_to?(:notifications)

    @completion_stats = calculate_completion_stats
    @request_stats = calculate_request_stats
  rescue => e
    Rails.logger.error "Dashboard error: #{e.message}"
    @properties = []
    @total_properties = 0
    @total_requests = 0
    @active_requests = 0
    @completion_stats = { average: 0, completed: 0, eligible: 0, in_progress: 0 }
    @request_stats = { total: 0, pending: 0, in_progress: 0, submitted: 0, validated: 0, estimated_amount: 0 }
  end

  private

  def load_pro_dashboard_data
    @project_members = current_user.project_members.includes(project: :property).order(created_at: :desc)
    @active_members  = @project_members.where(status: 'active')
    @pending_members = @project_members.where(status: 'pending')
    @projects        = @active_members.map(&:project).compact
    @project_count   = @projects.count
    @referral_url    = "#{request.base_url}/?ref=#{current_user.referral_token}" if current_user.referral_token.present?
  rescue => e
    Rails.logger.error "Pro dashboard error: #{e.message}"
    @project_members = []
    @active_members  = []
    @pending_members = []
    @projects        = []
    @project_count   = 0
    @referral_url    = nil
  end


  def calculate_completion_stats
    return { average: 0, completed: 0, eligible: 0, in_progress: 0 } if @properties.empty?

    completions = @properties.map(&:completion_percentage)
    {
      average: (completions.sum.to_f / completions.size).round,
      completed: @properties.count { |p| p.completion_percentage >= 80 },
      eligible: @properties.count { |p| p.completion_percentage >= 80 },
      in_progress: @properties.count { |p| p.completion_percentage < 80 }
    }
  end

  def calculate_request_stats
    user_requests = current_user.requests

    {
      total: user_requests.count,
      pending: user_requests.where(status: 'pending').count,
      in_progress: user_requests.where(status: 'in_progress').count,
      submitted: user_requests.where(status: 'submitted').count,
      validated: user_requests.where(status: 'validated').count,
      estimated_amount: calculate_estimated_amount(user_requests.where(status: ['pending', 'in_progress', 'submitted']))
    }
  end

  def calculate_estimated_amount(requests)
    # Utilise montant_travaux en priorité, puis cout_estime, puis montant_total
    total = 0
    requests.each do |request|
      amount = request.montant_travaux || request.cout_estime || request.montant_total || 0
      total += amount.to_f
    end
    total.round(2)
  end

  def ensure_onboarding_done
    return if current_user.onboarding_done?
    redirect_to onboarding_profile_selection_path(locale: I18n.locale)
  end
end

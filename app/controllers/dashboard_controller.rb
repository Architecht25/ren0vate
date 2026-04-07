class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Les professionnels invités (entrepreneurs/architectes sans bien propre) ont leur propre vue
    if current_user.professional_guest?
      redirect_to member_projects_path and return
    end

    @properties = current_user.properties.includes(:requests, :simulations).limit(10)
    @total_properties = current_user.properties.count
    @total_requests = current_user.requests.count
    @active_requests = current_user.requests.where(status: ['pending', 'in_progress']).count
    @recent_notifications = current_user.notifications.recent.limit(3) if current_user.respond_to?(:notifications)

    # Calculs pour les statistiques
    @completion_stats = calculate_completion_stats
    @request_stats = calculate_request_stats

    # Log pour débogage en production
    # Rails.logger.info "Dashboard - User #{current_user.id}: #{@total_properties} properties total, #{@properties.count} displayed"
    # @properties.each { |p| Rails.logger.info "Property #{p.id}: #{p.region} - #{p.name rescue p.commune}" }
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
end

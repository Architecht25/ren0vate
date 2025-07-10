class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @properties = current_user.properties.includes(:requests, :simulations).limit(6)
    @total_properties = current_user.properties.count
    @total_requests = current_user.requests.count
    @active_requests = current_user.requests.where(status: ['pending', 'in_progress']).count
    @recent_notifications = current_user.notifications.recent.limit(3) if current_user.respond_to?(:notifications)
    
    # Calculs pour les statistiques
    @completion_stats = calculate_completion_stats
  end

  private

  def calculate_completion_stats
    return { average: 0, completed: 0, in_progress: 0 } if @properties.empty?

    completions = @properties.map(&:completion_percentage)
    {
      average: (completions.sum.to_f / completions.size).round,
      completed: @properties.count { |p| p.completion_percentage >= 90 },
      in_progress: @properties.count { |p| p.completion_percentage < 90 }
    }
  end
end

class Api::NpsController < ApplicationController
  before_action :authenticate_user!

  def create
    score   = params[:score].to_i
    comment = params[:comment].to_s.strip.truncate(1000)
    trigger = params[:trigger].presence_in(NpsResponse::TRIGGERS) || 'day14'

    unless (0..10).include?(score)
      render json: { error: 'Score invalide' }, status: :unprocessable_entity
      return
    end

    # Un seul NPS par trigger par utilisateur
    existing = current_user.nps_responses.find_by(trigger: trigger)
    if existing
      render json: { status: 'already_submitted' }, status: :ok
      return
    end

    response = current_user.nps_responses.create!(
      score:   score,
      comment: comment.presence,
      trigger: trigger
    )

    current_user.update_column(:nps_prompted_at, Time.current)

    render json: { status: 'ok', id: response.id }, status: :created
  end
end

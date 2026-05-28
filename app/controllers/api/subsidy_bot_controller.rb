class Api::SubsidyBotController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Accessible pre-login (attract + convert) et post-login (personnalisé)
  # Pas d'authenticate_user! intentionnel — voir CLAUDE.md stratégie GTM

  def chat
    message = sanitize_message(params[:message])
    return render json: { error: 'Message manquant' }, status: :bad_request if message.blank?

    bot    = build_service
    result = bot.chat(message)

    render json: {
      response: {
        content:   result[:content],
        timestamp: Time.current.strftime('%H:%M')
      }
    }
  rescue => e
    Rails.logger.error "SubsidyBot Error: #{e.message}"
    render json: {
      response: {
        content:   "Problème technique momentané. Réessayez dans quelques secondes.",
        timestamp: Time.current.strftime('%H:%M')
      }
    }
  end

  def clear_history
    build_service.clear_history
    render json: { status: 'ok' }
  end

  private

  def build_service
    cache_key = if user_signed_in?
      "subsidy_bot_#{current_user.id}_#{session.id}"
    else
      "subsidy_bot_guest_#{session.id}"
    end

    SubsidyBotService.new(
      user:      user_signed_in? ? current_user : nil,
      cache_key: cache_key,
      region:    params[:region].presence
    )
  end

  def sanitize_message(raw)
    raw&.strip&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  rescue
    nil
  end
end

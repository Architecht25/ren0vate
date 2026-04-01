class Api::ContextualBotController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # POST /api/contextual_bot/chat  (et alias /message pour decision_hub)
  def chat
    message = sanitize_message(params[:message])
    return render_error('Message manquant') if message.blank?

    current_page = params[:current_page] || 'home'
    mode         = params[:mode] || 'expert'
    property_id  = params[:property_id].presence

    bot    = build_bot_service(property_id: property_id)
    result = bot.chat(message, mode: mode, current_page: current_page, locale: I18n.locale)

    render json: {
      response:    { content: result[:content], timestamp: Time.current.strftime('%H:%M') },
      suggestions: bot.get_suggestions(current_page, mode),
      mode:        mode,
      page:        current_page
    }
  rescue => e
    Rails.logger.error "ContextualBot Error: #{e.message}"
    render json: build_error_response(mode || 'expert', current_page || 'home')
  end

  # POST /api/contextual_bot/suggestions
  def suggestions
    current_page = params[:current_page] || 'home'
    mode         = params[:mode] || 'expert'
    render json: { suggestions: build_bot_service.get_suggestions(current_page, mode), page: current_page, mode: mode }
  rescue => e
    render json: { suggestions: ['💡 Comment puis-je vous aider ?'], page: 'home', mode: 'expert' }
  end

  # POST /api/contextual_bot/clear_history
  def clear_history
    build_bot_service.clear_history
    render json: { status: 'ok' }
  end

  private

  def build_bot_service(property_id: nil)
    # Résoudre le bien sélectionné (vérifié auquel l'user appartient)
    property = if property_id
      current_user.properties.find_by(id: property_id)
    end
    ContextualBotService.new(current_user, history_cache_key, property: property)
  end

  def history_cache_key
    "chat_history_#{current_user.id}_#{session.id}"
  end

  def sanitize_message(raw)
    raw&.strip&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  rescue
    nil
  end

  def build_error_response(mode, page)
    {
      response: {
        content: "🔄 Difficulté technique momentanée. Reformulez votre question ?",
        timestamp: Time.current.strftime('%H:%M')
      },
      suggestions: ['💡 Réessayez votre question', '🔍 Posez une autre question'],
      mode: mode,
      page: page
    }
  end

  def render_error(message)
    render json: { error: message }, status: :bad_request
  end
end

class ContextualBotController < ApplicationController
  before_action :set_locale
  before_action :authenticate_user!

  # POST /api/contextual_bot/chat
  def chat
    message      = params[:message].to_s.strip
    current_page = params[:current_page] || 'home'
    mode         = params[:mode] || 'expert'

    return render json: { error: 'Message vide' }, status: :unprocessable_entity if message.blank?

    bot      = build_bot_service
    result   = bot.chat(message, mode: mode, current_page: current_page, locale: I18n.locale)

    render json: {
      response: { content: result[:content] },
      suggestions: bot.get_suggestions(current_page, mode),
      mode: mode
    }
  end

  # POST /api/contextual_bot/clear_history
  def clear_history
    build_bot_service.clear_history
    render json: { status: 'ok' }
  end

  private

  def build_bot_service
    property = params[:property_id].present? ? current_user.properties.find_by(id: params[:property_id]) : nil
    ContextualBotService.new(current_user, history_cache_key, property: property)
  end

  def history_cache_key
    "chat_history_#{current_user.id}_#{session.id}"
  end

  # Gardé pour compatibilité arrière (non utilisé)
  def generate_response(message, current_page, mode)
    build_bot_service.chat(message, mode: mode, current_page: current_page)[:content]
  end
end

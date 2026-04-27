class ContextualBotController < ApplicationController
  before_action :set_locale
  before_action :authenticate_user!

  # POST /api/contextual_bot/chat
  def chat
    message      = params[:message].to_s.strip
    current_page = params[:current_page] || 'home'
    mode         = params[:mode] || 'expert'

    return render json: { error: 'Message vide' }, status: :unprocessable_entity if message.blank?

    property_id = params[:property_id].presence
    bot         = build_bot_service(property_id: property_id)

    result = if bot.is_a?(ProContextualBotService)
               bot.chat(message, mode: mode, locale: I18n.locale)
             else
               bot.chat(message, mode: mode, current_page: current_page, locale: I18n.locale)
             end

    suggestions = if bot.is_a?(ProContextualBotService)
                   bot.get_suggestions
                 else
                   bot.get_suggestions(current_page, mode)
                 end

    render json: {
      response:    { content: result[:content] },
      suggestions: suggestions,
      mode:        mode
    }
  end

  # POST /api/contextual_bot/clear_history
  def clear_history
    build_bot_service.clear_history
    render json: { status: 'ok' }
  end

  private

  def build_bot_service(property_id: nil)
    pro_role = resolved_pro_role
    if pro_role
      project = if property_id
        current_user.project_members
                    .where(status: 'active')
                    .joins(:project)
                    .map(&:project)
                    .find { |pr| pr.id.to_s == property_id.to_s }
      end
      return ProContextualBotService.new(
        current_user,
        pro_role:  pro_role,
        project:   project,
        cache_key: history_cache_key
      )
    end

    property = current_user.properties.find_by(id: property_id) if property_id
    ContextualBotService.new(current_user, history_cache_key, property: property)
  end

  # Résout le rôle pro en fusionnant user_profile et professional_type
  def resolved_pro_role
    profile = current_user.user_profile
    if profile == 'proprietaire' && current_user.professional_type.present?
      profile = case current_user.professional_type
                when 'architect'    then 'architecte'
                when 'entrepreneur' then 'entrepreneur'
                when 'intermediary' then 'intermediaire'
                end
    end
    case profile
    when 'architecte'    then :architecte
    when 'entrepreneur'  then :entrepreneur
    when 'intermediaire' then :intermediaire
    end
  end

  def history_cache_key
    "chat_history_#{current_user.id}_#{session.id}"
  end

  # Gardé pour compatibilité arrière (non utilisé)
  def generate_response(message, current_page, mode)
    build_bot_service.chat(message, mode: mode, current_page: current_page)[:content]
  end
end

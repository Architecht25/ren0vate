class Api::ContextualBotController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # POST /api/contextual_bot/chat  (et alias /message pour decision_hub)
  def chat
    message = sanitize_message(params[:message])
    return render_error('Message manquant') if message.blank?

    # --- Quota mensuel par tier ---
    unless plan_exempt?
      limit = current_user.ren0chat_monthly_limit
      if limit != Float::INFINITY
        count = ren0chat_monthly_count
        if count >= limit
          render json: {
            response: {
              content: "Vous avez atteint votre quota mensuel de #{limit} messages Ren0chat. " \
                       "Passez à une offre supérieure pour continuer.",
              timestamp: Time.current.strftime('%H:%M')
            },
            quota_exceeded: true,
            quota_limit: limit,
            quota_used: count
          }, status: :ok
          return
        end
        ren0chat_increment_count
      end
    end

    current_page = params[:current_page] || 'home'
    mode         = params[:mode] || 'expert'
    property_id  = params[:property_id].presence

    bot    = build_bot_service(property_id: property_id)
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
      response:    { content: result[:content], timestamp: Time.current.strftime('%H:%M') },
      suggestions: suggestions,
      mode:        mode,
      page:        current_page,
      quota_used:  plan_exempt? ? nil : ren0chat_monthly_count,
      quota_limit: plan_exempt? ? nil : current_user.ren0chat_monthly_limit
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
    # Pros → ProContextualBotService (cloisonnement par rôle)
    pro_role = resolved_pro_role
    if pro_role
      # property_id est ici l'ID du projet (pas du bien) pour les pros
      project = if property_id
        # Vérification stricte : le pro doit être membre actif de ce projet
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

    # Propriétaires → service existant inchangé
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
    when 'architecte'   then :architecte
    when 'entrepreneur' then :entrepreneur
    when 'intermediaire' then :intermediaire
    end
  end

  def history_cache_key
    "chat_history_#{current_user.id}_#{session.id}"
  end

  def ren0chat_cache_key
    "ren0chat:#{current_user.id}:#{Date.current.strftime('%Y-%m')}"
  end

  def ren0chat_monthly_count
    Rails.cache.read(ren0chat_cache_key).to_i
  end

  def ren0chat_increment_count
    expires_at = Time.current.end_of_month
    Rails.cache.increment(ren0chat_cache_key, 1, expires_in: expires_at - Time.current)
  rescue NotImplementedError
    # Fallback si le store cache ne supporte pas increment (ex: NullStore en test)
    current = Rails.cache.read(ren0chat_cache_key).to_i
    Rails.cache.write(ren0chat_cache_key, current + 1, expires_in: Time.current.end_of_month - Time.current)
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

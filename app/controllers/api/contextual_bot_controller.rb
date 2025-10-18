class Api::ContextualBotController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # Cache des suggestions pour éviter les re-calculs
  before_action :set_cache_headers

  def chat
    # Protection contre les erreurs d'encodage
    begin
      message = params[:message]&.strip
      # Nettoyage des caractères invalides
      message = message&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '') if message
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
      Rails.logger.warn "⚠️ Erreur d'encodage corrigée: #{e.message}"
      return render_error('Caractères invalides détectés')
    end

    current_page = params[:current_page] || 'home'
    mode = params[:mode] || 'guide'

    # Validation en une seule fois
    return render_error('Message manquant') if message.blank?

    # Utilisation du cache de session pour éviter de recréer le service
    contextual_service = get_cached_service

    # Traitement optimisé avec gestion d'erreur simplifiée
    begin
      response_content = case mode
      when 'expert'
        contextual_service.expert_response(message, current_page)
      else
        contextual_service.guide_response(message, current_page)
      end

      # Réponse optimisée avec cache des suggestions
      render json: build_chat_response(response_content, current_page, mode)

    rescue => e
      Rails.logger.error "ContextualBot Error: #{e.message}"
      render json: build_error_response(mode, current_page)
    end
  end

  def suggestions
    current_page = params[:current_page] || 'home'
    mode = params[:mode] || 'guide'

    # Service optimisé avec cache
    contextual_service = get_cached_service
    suggestions = contextual_service.get_suggestions(current_page, mode)

    render json: {
      suggestions: suggestions,
      page: current_page,
      mode: mode
    }
  rescue => e
    Rails.logger.error "Suggestions Error: #{e.message}"
    render json: {
      suggestions: ['💡 Comment puis-je vous aider ?', '🔍 Posez votre question'],
      page: current_page,
      mode: mode
    }
  end

  private

  def set_cache_headers
    # Headers pour améliorer les performances
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
  end

  def get_cached_service
    # Cache du service dans la session pour éviter les re-créations
    @contextual_service ||= ContextualBotService.new(current_user)
  end

  def build_chat_response(content, page, mode)
    {
      response: {
        content: content,
        timestamp: Time.current.strftime('%H:%M')
      },
      suggestions: get_fast_suggestions(page),
      mode: mode,
      page: page
    }
  end

  def build_error_response(mode, page)
    {
      response: {
        content: "Désolé, difficulté technique. Reformulez votre question ?",
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

  def get_fast_suggestions(page)
    # Suggestions ultra-rapides sans requête service
    @fast_suggestions ||= get_fallback_suggestions(page)
  end

  def get_fallback_suggestions(page)
    # Suggestions de base en cas d'erreur
    fallback_suggestions = {
      'profil' => [
        '💡 Comment bien remplir mon profil ?',
        '🏠 Quelle est ma catégorie de revenus ?',
        '📊 Dois-je mentionner tous mes revenus ?'
      ],
      'bien' => [
        '🏠 Comment décrire précisément mon bien ?',
        '📏 Comment mesurer la superficie ?',
        '🔥 Quel est mon type de chauffage ?'
      ],
      'chantier' => [
        '⚡ Par quels travaux commencer ?',
        '👷 Comment choisir un entrepreneur agréé ?',
        '📅 Combien de temps pour les travaux ?'
      ],
      'simulation' => [
        '💰 Comment augmenter mes primes ?',
        '📊 Ces montants sont-ils garantis ?',
        '📄 Quels documents prévoir ?'
      ],
      'documents' => [
        '📄 Quels documents sont obligatoires ?',
        '📋 Comment organiser mes papiers ?',
        '✅ Ai-je tous les documents nécessaires ?'
      ],
      'decision_hub' => [
        '🎯 Par où commencer mes travaux ?',
        '💡 Quelle est la meilleure stratégie ?',
        '📊 Comment optimiser mes aides ?'
      ]
    }

    fallback_suggestions[page] || [
      '💡 Comment puis-je vous aider ?',
      '🔍 Expliquez-moi cette page',
      '📚 Donnez-moi des conseils'
    ]
  end
end

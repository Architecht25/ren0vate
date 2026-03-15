class ContextualBotService
  include HTTParty

  ANTHROPIC_API_URL  = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION  = '2023-06-01'
  # Haiku = rapide + économique (guide), Sonnet = puissant (expert)
  GUIDE_MODEL        = 'claude-3-5-haiku-20241022'
  EXPERT_MODEL       = 'claude-3-7-sonnet-20250219'
  MAX_HISTORY        = 20  # messages gardés en mémoire (10 échanges)
  HISTORY_TTL        = 2.hours

  # Réponses instantanées uniquement pour les salutations (zéro latence)
  INSTANT_RESPONSES = {
    'bonjour' => "👋 **Bonjour !** Je suis votre assistant Ren0vate, expert en primes énergétiques belges.\n\nPosez-moi n'importe quelle question sur vos primes, vos travaux ou votre dossier — je me souviens de toute notre conversation !",
    'merci'   => "😊 De rien, c'est avec plaisir ! N'hésitez pas si vous avez d'autres questions sur vos primes ou votre projet."
  }.freeze

  def initialize(user = nil, cache_key = nil)
    @user      = user
    @api_key   = ENV['ANTHROPIC_API_KEY']
    @cache_key = cache_key  # clé pour persister l'historique entre requêtes
  end

  # Point d'entrée principal — retourne { content:, suggestions: }
  def chat(message, mode: 'expert', current_page: 'home', locale: :fr)
    # Réponses instantanées pour les salutations simples
    normalized = message.downcase.strip
    INSTANT_RESPONSES.each do |kw, resp|
      return { content: resp } if normalized.include?(kw)
    end

    history = load_history

    model   = mode == 'guide' ? GUIDE_MODEL : EXPERT_MODEL
    system  = build_system_prompt(mode, current_page)
    msgs    = history + [{ role: 'user', content: message }]

    content = call_claude(model, system, msgs)
    content ||= fallback_message

    # Sauvegarder l'historique mis à jour
    updated = (history + [
      { role: 'user',      content: message },
      { role: 'assistant', content: content }
    ]).last(MAX_HISTORY)
    save_history(updated)

    { content: content }
  end

  # Vider l'historique (appelé au sign-out ou par le bouton clear)
  def clear_history
    Rails.cache.delete(@cache_key) if @cache_key
  end

  # --- Compatibilité avec l'ancien controller (guide_response / expert_response) ---
  def guide_response(message, current_page)
    chat(message, mode: 'guide', current_page: current_page)[:content]
  end

  def expert_response(message, current_page)
    chat(message, mode: 'expert', current_page: current_page)[:content]
  end

  def get_expert_response(message, locale = :fr)
    chat(message, mode: 'expert', locale: locale)[:content]
  end

  def get_suggestions(current_page, mode)
    mode == 'expert' ? EXPERT_SUGGESTIONS : (GUIDE_SUGGESTIONS[current_page] || GUIDE_SUGGESTIONS['pages'])
  end

  private

  # ─── Anthropic API ──────────────────────────────────────────────────────────

  def call_claude(model, system, messages)
    return nil unless @api_key.present?

    start = Time.current
    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'x-api-key'         => @api_key,
        'anthropic-version' => ANTHROPIC_VERSION,
        'content-type'      => 'application/json'
      },
      body: {
        model:      model,
        max_tokens: 800,
        system:     system,
        messages:   messages
      }.to_json,
      timeout: 15
    )

    duration = (Time.current - start).round(2)

    if response.success?
      content = response.dig('content', 0, 'text')&.strip
      Rails.logger.info "✅ Claude #{model} — #{duration}s — #{content&.length} chars"
      content
    else
      Rails.logger.error "❌ Claude API #{response.code}: #{response.body[0..200]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn "⏰ Claude timeout après #{(Time.current - start).round(2)}s"
    nil
  rescue => e
    Rails.logger.error "🔥 Claude error: #{e.message}"
    nil
  end

  # ─── Historique (Rails.cache) ────────────────────────────────────────────────

  def load_history
    return [] unless @cache_key
    Rails.cache.read(@cache_key) || []
  end

  def save_history(messages)
    return unless @cache_key
    Rails.cache.write(@cache_key, messages, expires_in: HISTORY_TTL)
  end

  # ─── Prompt système ─────────────────────────────────────────────────────────

  def build_system_prompt(mode, current_page)
    user_ctx = build_user_context

    base = <<~PROMPT
      Tu es l'assistant IA de Ren0vate, expert en primes énergétiques belges (Wallonie, Bruxelles, Flandre).
      Tu as une mémoire complète de la conversation en cours — utilise-la pour donner des réponses personnalisées et te souvenir de ce que l'utilisateur a déjà dit.

      DONNÉES RÉELLES DE L'UTILISATEUR :
      #{user_ctx}

      PAGE ACTUELLE DE L'APP : #{current_page}

      RÈGLES ABSOLUES :
      - Réponds toujours en français (sauf si l'utilisateur écrit en néerlandais → réponds en néerlandais)
      - Utilise les données réelles ci-dessus pour personnaliser chaque réponse
      - Format markdown avec émojis thématiques
      - Sois concret, actionnable, précis — pas de généralités
      - Maximum 400 mots par réponse
      - Quand tu parles de montants : indique toujours la région concernée
      - Terminologie belge : "entrepreneur agréé", "avertissement-extrait de rôle", "primes énergétiques"
    PROMPT

    if mode == 'guide'
      base + "\nMODE GUIDE : Tu aides l'utilisateur à naviguer sur la page '#{current_page}'. Conseils pratiques, pas à pas."
    else
      base + "\nMODE EXPERT : Réponses approfondies, analyse financière complète, optimisation maximale des primes, stratégies avancées."
    end
  end

  def build_user_context
    return "Utilisateur non connecté — réponses génériques." unless @user

    lines = ["Prénom/Nom : #{@user.first_name} #{@user.last_name}",
             "Email : #{@user.email}"]

    # Propriétés
    properties = @user.properties.order(updated_at: :desc).limit(3)
    if properties.any?
      lines << "\nPROPRIÉTÉS (#{properties.count}) :"
      properties.each do |p|
        lines << "  • #{p.titre || 'Sans nom'} — #{p.commune}, #{p.region} | PEB: #{p.peb || 'non renseigné'} | Année: #{p.annee_construction || 'N/A'} | Type: #{p.type_propriete || p.type}"
      end
    else
      lines << "Aucune propriété enregistrée."
    end

    # Projets
    projects = @user.projects.order(updated_at: :desc).limit(3)
    if projects.any?
      lines << "\nPROJETS EN COURS (#{projects.count}) :"
      projects.each do |pr|
        budget = pr.contractor_devis_montant ? "Budget devis: #{number_to_currency_simple(pr.contractor_devis_montant)}" : ""
        lines << "  • #{pr.nom || 'Sans nom'} — statut: #{pr.statut || 'N/A'} #{budget}"
      end
    end

    # Simulations
    simulations = @user.simulations.order(created_at: :desc).limit(3)
    if simulations.any?
      lines << "\nSIMULATIONS RÉCENTES :"
      simulations.each do |s|
        eligible = s.eligible ? "✅ éligible" : "❌ non éligible"
        lines << "  • #{s.titre || s.region} — #{number_to_currency_simple(s.total_simule)} #{eligible}"
      end
    end

    lines.join("\n")
  end

  def number_to_currency_simple(amount)
    return "N/A" unless amount
    "#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse} €"
  end

  def fallback_message
    "🔄 Je rencontre un problème technique momentané. Réessayez dans quelques secondes, ou utilisez le simulateur directement !"
  end

  # ─── Suggestions ─────────────────────────────────────────────────────────────

  GUIDE_SUGGESTIONS = {
    'profil'       => ['💡 Comment calculer mes revenus de référence ?', '🏠 Quelle catégorie de revenus ai-je ?', '👨‍👩‍👧 Comment compter les occupants ?'],
    'bien'         => ['🏠 Comment mesurer la surface habitable ?', '🔥 Mon chauffage influence-t-il les primes ?', '📅 Année de construction ou rénovation ?'],
    'chantier'     => ['⚡ Par quels travaux commencer ?', '👷 Comment vérifier un entrepreneur agréé ?', '💰 Puis-je échelonner mes travaux ?'],
    'simulation'   => ['💰 Comment augmenter mes primes ?', '📊 Ces montants sont-ils garantis ?', '📄 Quels documents préparer ?'],
    'documents'    => ['📄 Quels documents sont obligatoires ?', '📸 Dois-je prendre des photos ?', '✅ Comment vérifier la conformité ?'],
    'decision_hub' => ['🎯 Quelle stratégie de rénovation adopter ?', '💡 Comment prioriser mes travaux ?', '📊 Comment optimiser mes aides ?'],
    'pages'        => ['🚀 Comment utiliser Ren0vate ?', '📊 Quelle est la prochaine étape ?', '💡 Conseils pour optimiser mes primes ?']
  }.freeze

  EXPERT_SUGGESTIONS = [
    '🧠 Quelle est la meilleure stratégie pour mon bien ?',
    '💰 Comment maximiser mes primes énergétiques ?',
    '⚡ Quels travaux sont les plus rentables pour moi ?',
    '🏛️ Quelles réglementations 2025/2026 me concernent ?'
  ].freeze
end

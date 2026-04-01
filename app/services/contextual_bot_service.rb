class ContextualBotService
  include HTTParty

  ANTHROPIC_API_URL  = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION  = '2023-06-01'
  # Haiku = rapide + économique (guide), Sonnet = puissant (expert)
  GUIDE_MODEL        = 'claude-haiku-4-5-20251001'
  EXPERT_MODEL       = 'claude-sonnet-4-5-20250929'
  MAX_HISTORY        = 20  # messages gardés en mémoire (10 échanges)
  HISTORY_TTL        = 2.hours

  # Réponses instantanées uniquement pour les salutations (zéro latence)
  INSTANT_RESPONSES = {
    'bonjour' => "👋 **Bonjour !** Je suis votre assistant Ren0vate, expert en primes énergétiques belges.\n\nPosez-moi n'importe quelle question sur vos primes, vos travaux ou votre dossier — je me souviens de toute notre conversation !",
    'merci'   => "😊 De rien, c'est avec plaisir ! N'hésitez pas si vous avez d'autres questions sur vos primes ou votre projet."
  }.freeze

  def initialize(user = nil, cache_key = nil, property: nil)
    @user      = user
    @api_key   = ENV['ANTHROPIC_API_KEY']
    @cache_key = cache_key  # clé pour persister l'historique entre requêtes
    @property  = property  # bien sélectionné — contexte focal de l'IA
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
        max_tokens: 1200,
        system:     system,
        messages:   messages
      }.to_json,
      timeout: 60
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
    property_ctx = @property ? "Bien focal : #{@property.titre.presence || @property.full_address} (#{@property.region&.capitalize})" : "Aucun bien sélectionné"

    base = <<~PROMPT
      Tu es l'assistant IA de Ren0vate, expert en primes énergétiques belges (Wallonie, Bruxelles, Flandre).
      Tu as une mémoire complète de la conversation en cours — utilise-la pour des réponses personnalisées et cohérentes.

      CONTEXTE ACTIF : #{property_ctx}

      DONNÉES COMPLÈTES DU DOSSIER :
      #{user_ctx}

      PAGE ACTUELLE DE L'APP : #{current_page}

      RÈGLES ABSOLUES :
      - Réponds toujours en français (sauf si l'utilisateur écrit en néerlandais → réponds en néerlandais)
      - Utilise les données réelles ci-dessus — ne généralise pas quand la donnée est disponible
      - Si une donnée manque (N/A), signale-le et suggère comment la compléter dans l'app
      - Format markdown avec émojis thématiques
      - Sois concret, actionnable, précis
      - Maximum 500 mots par réponse
      - Toujours indiquer la région pour les montants de primes
      - Terminologie belge : "entrepreneur agréé", "avertissement-extrait de rôle", "primes énergétiques"
      - Pour les délais de factures (date_limite_prime), signale toujours l'urgence si < 60 jours
    PROMPT

    if mode == 'guide'
      base + "\nMODE GUIDE : Accompagne l'utilisateur pas à pas sur la page '#{current_page}'."
    else
      base + "\nMODE EXPERT : Analyse financière complète, stratégie d'optimisation maximale des primes, risques et pièges."
    end
  end

  def build_user_context
    return "Utilisateur non connecté — réponses génériques." unless @user

    lines = []

    # ══ PROFIL COMPLET DU DEMANDEUR ══════════════════════════════════════════
    lines << "═══ PROFIL DU DEMANDEUR ═══"
    lines << "Identité    : #{@user.first_name} #{@user.last_name} | #{@user.email}"
    lines << "Téléphone   : #{@user.phone || 'N/A'}"
    lines << "Adresse     : #{[@user.street, @user.number, @user.postal_code, @user.city].compact.join(' ')}"
    lines << "Région      : #{@user.region&.capitalize || 'N/A'}"
    lines << "Type demandeur : #{@user.type_demandeur || 'N/A'}"
    lines << "Statut prof.: #{@user.statut_professionnel || 'N/A'} | Indépendant: #{bool_fr(@user.independant)} | TVA déductible: #{bool_fr(@user.tva_deductible)}"

    # Situation familiale et sociale
    lines << "\n── Situation familiale & sociale ──"
    lines << "  Situation  : #{@user.situation_familiale || 'N/A'}"
    lines << "  Nb enfants : #{@user.nombre_enfants || 0}"
    lines << "  Personnes 60+ ans : #{bool_fr(@user.personnes_60_ans_et_plus)}"
    lines << "  Femme enceinte    : #{bool_fr(@user.femme_enceinte)}"
    lines << "  BIM/RIS    : #{bool_fr(@user.bim || @user.ris)}"
    lines << "  Client protégé Bxl: #{bool_fr(@user.client_protege_bruxelles)}"

    # Revenus déclarés
    lines << "\n── Revenus déclarés ──"
    if @user.revenu_demandeur.present?
      lines << "  Revenu demandeur  : #{number_to_currency_simple(@user.revenu_demandeur)} (année #{@user.annee_revenus_demandeur || 'N/A'})"
    end
    if @user.revenu_conjoint.present?
      lines << "  Revenu conjoint   : #{number_to_currency_simple(@user.revenu_conjoint)} (année #{@user.annee_revenus_conjoint || 'N/A'})"
    end
    lines << "  IBAN belge : #{@user.compte_bancaire_belge ? 'Oui (' + (@user.iban.present? ? @user.iban[0..6] + '****' : 'renseigné') + ')' : 'Non'}"

    # AER (avertissement-extrait de rôle) — source officielle des revenus
    aer = @user.aer_donnees.order(created_at: :desc).first
    if aer
      lines << "  AER officiel: Revenu imposable #{number_to_currency_simple(aer.revenu_imposable_global)} | Année #{aer.annee_revenus} | #{aer.valide_manuellement ? '✅ validé' : '⏳ en attente'}"
    end

    # Vente prévue dans 5 ans — impacte l'éligibilité Wallonie
    lines << "  Vente prévue 5 ans : #{bool_fr(@user.vente_prevue_5_ans)}"

    if @property
      # ══ BIEN SÉLECTIONNÉ — contexte focal ════════════════════════════════
      lines << build_property_context(@property)
    else
      # ══ APERÇU DE TOUS LES BIENS ═════════════════════════════════════════
      properties = @user.properties.order(updated_at: :desc)
      if properties.any?
        lines << "\n═══ BIENS IMMOBILIERS (#{properties.count}) ═══"
        properties.each do |p|
          peb = p.certificat_peb_wallonie || p.certificat_peb_flandre || p.certificat_peb_bruxelles || p.peb
          type_bien = p.type_propriete_wallonie || p.type_bien_flandre || p.type_bien_bruxelles || p.type_propriete
          best_sim  = p.simulations.max_by { |s| s.total_simule.to_i }
          primes    = best_sim ? " | Primes max: #{number_to_currency_simple(best_sim.total_simule)}" : ""
          lines << "  • #{p.titre.presence || p.commune} — #{p.commune}, #{p.region&.capitalize} | PEB: #{peb || 'N/A'} | #{type_bien || 'N/A'}#{primes} | #{p.projects.count} chantier(s)"
        end
      else
        lines << "Aucun bien immobilier enregistré."
      end
    end

    lines.join("\n")
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Contexte complet d'un bien : données directes + toutes les données indirectes
  # ─────────────────────────────────────────────────────────────────────────────
  def build_property_context(p)
    lines = []
    peb       = p.certificat_peb_wallonie || p.certificat_peb_flandre || p.certificat_peb_bruxelles || p.peb
    type_bien = p.type_propriete_wallonie || p.type_bien_flandre || p.type_bien_bruxelles || p.type_propriete

    lines << "\n═══ BIEN SÉLECTIONNÉ ═══"
    lines << "  Nom       : #{p.titre.presence || 'Sans nom'}"
    lines << "  Adresse   : #{p.full_address}"
    lines << "  Région    : #{p.region&.capitalize}"
    lines << "  Type bien : #{type_bien || 'N/A'}"
    lines << "  Occupation: #{p.occupation || p.usage || p.usage_flandre || 'N/A'}"
    lines << "  Surface   : #{p.surface_habitable || p.surface_habitable_wallonie || p.surface_totale || 'N/A'} m²"

    # Données énergétiques
    lines << "\n── Énergie & technique ──"
    lines << "  PEB actuel  : #{peb || 'non renseigné'}"
    lines << "  Année constr: #{p.annee_construction || 'N/A'}"
    lines << "  Chauffage   : #{p.mode_chauffage_principal || p.mode_chauffage_wallonie || 'N/A'}"
    lines << "  Audit énerg.: #{p.audit_energetique || 'N/A'}"
    lines << "  EAN         : #{p.numero_ean || p.ean_flandre || 'N/A'}"
    lines << "  Cadastre    : #{p.numero_cadastre || p.parcelle_flandre || 'N/A'}"
    lines << "  Été reconstr: #{bool_fr(p.reconstruit)}"
    lines << "  Bien classé : #{bool_fr(p.bien_classe)} | Petit patrimoine: #{bool_fr(p.petit_patrimoine)}"

    # Données financières du bien
    if p.valeur_achat.present?
      lines << "  Valeur achat: #{number_to_currency_simple(p.valeur_achat)} (#{p.date_achat&.strftime('%d/%m/%Y') || 'N/A'})"
    end
    lines << "  Primes déjà reçues: #{p.primes_recues || 'aucune déclarée'}"

    # Spécificités régionales
    case p.region&.downcase
    when 'wallonie'
      lines << "  Profil demandeur WL: #{p.profil_demandeur || 'N/A'}"
    when 'flandre'
      lines << "  Domicilié Flandre  : #{bool_fr(p.domicilie_flandre)} | Client protégé: #{bool_fr(p.client_protege_flandre)}"
      lines << "  Chauffage post-rénov: #{p.chauffage_post_renovation_flandre || 'N/A'}"
    when 'bruxelles'
      lines << "  Type bien Bruxelles: #{p.type_bien_bruxelles || 'N/A'}"
    end

    # Certificats PEB scannés (OCR)
    peb_donnees = p.peb_donnees.order(created_at: :desc)
    if peb_donnees.any?
      lines << "\n── Certificats PEB scannés (#{peb_donnees.count}) ──"
      peb_donnees.each do |pd|
        valid = pd.valide_manuellement ? '✅' : '⏳'
        lines << "  #{valid} PEB #{pd.label_peb || 'N/A'} | Score EP: #{pd.score_ep || 'N/A'} | Surf. réf: #{pd.surface_reference || 'N/A'} m² | #{pd.date_certificat&.strftime('%d/%m/%Y') || 'N/A'}"
      end
    end

    # ── CHANTIERS (projets) ──────────────────────────────────────────────────
    projects = p.projects.order(updated_at: :desc)
    if projects.any?
      lines << "\n── Chantiers liés (#{projects.count}) ──"
      projects.each do |pr|
        lines << "  ▸ #{pr.nom || 'Sans nom'} [#{pr.statut || 'en cours'}]"
        lines << "    Type travaux    : #{pr.type_travaux || 'N/A'}"
        lines << "    Période         : #{pr.date_début&.strftime('%d/%m/%Y') || '?'} → #{pr.date_fin&.strftime('%d/%m/%Y') || '?'}"
        lines << "    Permis urbanisme: #{pr.permis_urbanisme_number || 'N/A'}"
        lines << "    Budget architecte: #{pr.architecte_devis_montant ? number_to_currency_simple(pr.architecte_devis_montant) : 'N/A'}"
        lines << "    Budget entrepreneur: #{pr.contractor_devis_montant ? number_to_currency_simple(pr.contractor_devis_montant) : 'N/A'}"

        # Architecte
        if pr.architecte_nom.present? || pr.architecte_entreprise.present?
          lines << "    Architecte      : #{[pr.architecte_nom, pr.architecte_prenom].compact.join(' ')} | #{pr.architecte_entreprise || ''} | N°ordre: #{pr.architecte_numero_ordre || 'N/A'}"
        end

        # Entrepreneur principal
        if pr.entrepreneur_principal_nom.present? || pr.entrepreneur_principal_entreprise.present?
          lines << "    Entrepreneur    : #{pr.entrepreneur_principal_nom || ''} | #{pr.entrepreneur_principal_entreprise || ''} | TVA: #{pr.entrepreneur_principal_numero_tva || 'N/A'}"
          if pr.entrepreneur_principal_certifications.present?
            certs = Array(pr.entrepreneur_principal_certifications).join(', ')
            lines << "    Certifications  : #{certs}"
          end
        end

        # Audit énergétique
        if pr.numero_audit.present?
          lines << "    Audit N°#{pr.numero_audit} du #{pr.date_audit&.strftime('%d/%m/%Y') || 'N/A'} | Prix: #{pr.prix_audit ? number_to_currency_simple(pr.prix_audit) : 'N/A'}"
        end

        # Devis scannés (OCR)
        devis = pr.devis_donnees.order(created_at: :desc)
        if devis.any?
          lines << "    Devis scannés (#{devis.count}) :"
          devis.each do |dv|
            valid = dv.valide_manuellement ? '✅' : '⏳'
            lines << "      #{valid} #{dv.nom_entreprise || 'N/A'} | #{number_to_currency_simple(dv.montant_total_tvac)} TVAC | #{dv.types_travaux_detectes&.first(3)&.join(', ') || 'N/A'} | #{dv.date_devis&.strftime('%d/%m/%Y') || 'N/A'}"
          end
        end

        # Factures
        factures = pr.factures.order(date_facture: :desc)
        if factures.any?
          total = factures.sum { |f| f.montant.to_f }
          lines << "    Factures (#{factures.count}) — Total: #{number_to_currency_simple(total)} :"
          factures.each do |f|
            expire = f.date_limite_prime ? " | ⚠️ Délai prime: #{f.date_limite_prime.strftime('%d/%m/%Y')}" : ""
            lines << "      • [#{f.type_facture}] #{f.nom_entreprise || 'N/A'} | #{number_to_currency_simple(f.montant)} | #{f.statut_paiement || 'N/A'}#{expire}"
          end
        end
      end
    end

    # ── SIMULATIONS DE PRIMES ───────────────────────────────────────────────
    simulations = p.simulations.order(created_at: :desc)
    if simulations.any?
      lines << "\n── Simulations de primes (#{simulations.count}) ──"
      simulations.each do |s|
        eligible = s.eligible ? "✅ éligible" : "❌ non éligible"
        cat = s.category.present? ? " | Catégorie: #{s.category}" : ""
        lines << "  #{eligible} #{s.titre || s.region&.capitalize} — #{number_to_currency_simple(s.total_simule)}#{cat} (#{s.created_at.strftime('%d/%m/%Y')})"
        lines << "    Raison inéligibilité: #{s.ineligibility_reason}" if s.ineligibility_reason.present?
      end
      best = simulations.select(&:eligible).max_by { |s| s.total_simule.to_i }
      lines << "  → Meilleure simulation éligible : #{best ? number_to_currency_simple(best.total_simule) + ' (' + (best.titre || best.region) + ')' : 'aucune éligible'}"
    end

    # ── DEMANDES OFFICIELLES ────────────────────────────────────────────────
    requests = p.requests.order(created_at: :desc)
    if requests.any?
      lines << "\n── Demandes officielles (#{requests.count}) ──"
      requests.each do |r|
        montant = r.montant_total.present? ? " | Montant: #{number_to_currency_simple(r.montant_total)}" : ""
        lines << "  • #{r.title || r.type_travaux || 'N/A'} [#{r.status || 'N/A'}] #{r.region&.capitalize}#{montant}"
      end
    end

    # ── DEVIS GLOBAUX (quotes) ───────────────────────────────────────────────
    quotes = p.quotes.order(created_at: :desc)
    if quotes.any?
      lines << "\n── Devis estimatifs (#{quotes.count}) ──"
      quotes.each do |q|
        lines << "  • #{number_to_currency_simple(q.total_min)} – #{number_to_currency_simple(q.total_max)} | Durée: #{q.duration_min_days}–#{q.duration_max_days} jours | #{q.status || 'N/A'}"
      end
    end

    # ── DOCUMENTS ───────────────────────────────────────────────────────────
    documents = p.documents.order(created_at: :desc)
    if documents.any?
      by_type = documents.group_by(&:type_document)
      lines << "\n── Documents (#{documents.count}) ──"
      by_type.each do |type, docs|
        statuts = docs.map(&:status).uniq.join('/')
        lines << "  • #{type || 'Autre'} (#{docs.count}) — #{statuts}"
      end
    end

    lines.join("\n")
  end

  def number_to_currency_simple(amount)
    return "N/A" unless amount
    "#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse} €"
  end

  def bool_fr(val)
    return 'N/A' if val.nil?
    val ? 'Oui' : 'Non'
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

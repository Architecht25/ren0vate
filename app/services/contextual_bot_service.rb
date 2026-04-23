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

    # ══ PROFIL PSEUDONYMISÉ DU DEMANDEUR ══════════════════════════════════════
    # NOTE RGPD : les données directement identifiantes (nom complet, email,
    # téléphone, adresse exacte, revenus précis, IBAN) sont pseudonymisées
    # avant transmission à l'API Anthropic (serveurs USA).
    lines << "═══ PROFIL DU DEMANDEUR ═══"
    lines << "Prénom      : #{@user.first_name}"
    lines << "ID interne  : USR-#{Digest::SHA256.hexdigest(@user.id.to_s)[0..7]}"
    lines << "Localisation: #{[@user.postal_code, @user.city].compact.join(' ')} — #{@user.region&.capitalize || 'N/A'}"

    # Situation familiale et sociale
    lines << "\n── Situation familiale & sociale ──"
    lines << "  Situation  : #{@user.situation_familiale || 'N/A'}"
    lines << "  Nb enfants : #{@user.nombre_enfants || 0}"
    lines << "  Personnes 60+ ans : #{bool_fr(@user.personnes_60_ans_et_plus)}"
    lines << "  Femme enceinte    : #{bool_fr(@user.femme_enceinte)}"

    # Revenus — transmis en tranche (pas de montant exact)
    lines << "\n── Tranche de revenus ──"
    if @user.revenu_demandeur.present?
      lines << "  Revenu demandeur  : #{revenue_bracket(@user.revenu_demandeur)} (année #{@user.annee_revenus_demandeur || 'N/A'})"
    end
    if @user.revenu_conjoint.present?
      lines << "  Revenu conjoint   : #{revenue_bracket(@user.revenu_conjoint)} (année #{@user.annee_revenus_conjoint || 'N/A'})"
    end

    # AER (avertissement-extrait de rôle) — tranche uniquement
    aer = @user.aer_donnees.order(created_at: :desc).first
    if aer
      lines << "  AER officiel: Revenu imposable #{revenue_bracket(aer.revenu_imposable_global)} | Année #{aer.annee_revenus} | #{aer.valide_manuellement ? '✅ validé' : '⏳ en attente'}"
    end

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
  # Contexte pseudonymisé d'un bien — RGPD art. 5.1.c (minimisation)
  # Données supprimées : adresse exacte, EAN, cadastre, noms tiers, montants exacts
  # ─────────────────────────────────────────────────────────────────────────────
  def build_property_context(p)
    lines = []
    peb       = p.certificat_peb_wallonie || p.certificat_peb_flandre || p.certificat_peb_bruxelles || p.peb
    type_bien = p.type_propriete_wallonie || p.type_bien_flandre || p.type_bien_bruxelles || p.type_propriete

    lines << "\n═══ BIEN SÉLECTIONNÉ ═══"
    lines << "  Ref interne : BIEN-#{Digest::SHA256.hexdigest(p.id.to_s)[0..7]}"
    # Localisation : commune + code postal uniquement (pas rue/numéro)
    lines << "  Localisation: #{[p.code_postal, p.commune].compact.join(' ')} — #{p.region&.capitalize}"
    lines << "  Type bien : #{type_bien || 'N/A'}"
    lines << "  Type demandeur: #{p.type_demandeur || 'N/A'}"
    lines << "  Occupation: #{p.occupation || p.usage || p.usage_flandre || 'N/A'}"
    lines << "  Surface   : #{p.surface_habitable || p.surface_habitable_wallonie || p.surface_totale || 'N/A'} m²"

    # Données énergétiques — aucune donnée d'identification de compteur
    lines << "\n── Énergie & technique ──"
    lines << "  PEB actuel  : #{peb || 'non renseigné'}"
    lines << "  Année constr: #{p.annee_construction || 'N/A'}"
    lines << "  Chauffage   : #{p.mode_chauffage_principal || p.mode_chauffage_wallonie || 'N/A'}"
    lines << "  Audit énerg.: #{p.audit_energetique || 'N/A'}"
    lines << "  EAN         : #{(p.numero_ean || p.ean_flandre).present? ? 'Renseigné' : 'Non renseigné'}"
    lines << "  Cadastre    : #{(p.numero_cadastre || p.parcelle_flandre).present? ? 'Renseigné' : 'Non renseigné'}"
    lines << "  Été reconstr: #{bool_fr(p.reconstruit)}"
    lines << "  Bien classé : #{bool_fr(p.bien_classe)} | Petit patrimoine: #{bool_fr(p.petit_patrimoine)}"

    # Données financières — tranche uniquement
    if p.valeur_achat.present?
      lines << "  Valeur achat: #{amount_bracket(p.valeur_achat)}"
    end
    lines << "  Primes déjà reçues: #{p.primes_recues.present? ? 'Oui' : 'Non'}"

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

    # Certificats PEB scannés (OCR) — données techniques conservées, pas d'identifiant
    peb_donnees = p.peb_donnees.order(created_at: :desc)
    if peb_donnees.any?
      lines << "\n── Certificats PEB scannés (#{peb_donnees.count}) ──"
      peb_donnees.each do |pd|
        valid = pd.valide_manuellement ? '✅' : '⏳'
        lines << "  #{valid} PEB #{pd.label_peb || 'N/A'} | Score EP: #{pd.score_ep || 'N/A'} | Surf. réf: #{pd.surface_reference || 'N/A'} m² | #{pd.date_certificat&.strftime('%m/%Y') || 'N/A'}"
      end
    end

    # ── CHANTIERS (projets) ──────────────────────────────────────────────────
    projects = p.projects.order(updated_at: :desc)
    if projects.any?
      lines << "\n── Chantiers liés (#{projects.count}) ──"
      projects.each do |pr|
        lines << "  ▸ Chantier [#{pr.statut || 'en cours'}]"
        lines << "    Type travaux    : #{pr.type_travaux || 'N/A'}"
        lines << "    Période         : #{pr.date_début&.strftime('%m/%Y') || '?'} → #{pr.date_fin&.strftime('%m/%Y') || '?'}"
        lines << "    Permis urbanisme: #{pr.permis_urbanisme_number.present? ? 'Oui' : 'Non'}"
        lines << "    Budget architecte: #{pr.architecte_devis_montant ? amount_bracket(pr.architecte_devis_montant) : 'N/A'}"
        lines << "    Budget entrepreneur: #{pr.contractor_devis_montant ? amount_bracket(pr.contractor_devis_montant) : 'N/A'}"

        # Architecte — rôle + certifications uniquement, pas d'identité
        if pr.architecte_nom.present? || pr.architecte_entreprise.present?
          lines << "    Architecte      : Renseigné | N°ordre: #{pr.architecte_numero_ordre.present? ? 'Oui' : 'Non'}"
        end

        # Entrepreneur principal — certifications uniquement
        if pr.entrepreneur_principal_nom.present? || pr.entrepreneur_principal_entreprise.present?
          has_tva = pr.entrepreneur_principal_numero_tva.present?
          lines << "    Entrepreneur    : Renseigné | TVA enregistrée: #{bool_fr(has_tva)}"
          if pr.entrepreneur_principal_certifications.present?
            certs = Array(pr.entrepreneur_principal_certifications).join(', ')
            lines << "    Certifications  : #{certs}"
          end
        end

        # Audit énergétique — présence + date, pas le numéro
        if pr.numero_audit.present?
          lines << "    Audit énergétique: #{pr.date_audit&.strftime('%m/%Y') || 'N/A'} | Prix: #{pr.prix_audit ? amount_bracket(pr.prix_audit) : 'N/A'}"
        end

        # Devis scannés — tranche de montant, type travaux, pas de nom d'entreprise
        devis = pr.devis_donnees.order(created_at: :desc)
        if devis.any?
          lines << "    Devis scannés (#{devis.count}) :"
          devis.each do |dv|
            valid = dv.valide_manuellement ? '✅' : '⏳'
            lines << "      #{valid} #{amount_bracket(dv.montant_total_tvac)} TVAC | #{dv.types_travaux_detectes&.first(3)&.join(', ') || 'N/A'} | #{dv.date_devis&.strftime('%m/%Y') || 'N/A'}"
          end
        end

        # Factures — tranche de montant, type, pas de nom d'entreprise
        factures = pr.factures.order(date_facture: :desc)
        if factures.any?
          total = factures.sum { |f| f.montant.to_f }
          lines << "    Factures (#{factures.count}) — Total: #{amount_bracket(total)} :"
          factures.each do |f|
            expire = f.date_limite_prime ? " | ⚠️ Délai prime: #{f.date_limite_prime.strftime('%d/%m/%Y')}" : ""
            lines << "      • [#{f.type_facture}] #{amount_bracket(f.montant)} | #{f.statut_paiement || 'N/A'}#{expire}"
          end
        end
      end
    end

    # ── SIMULATIONS DE PRIMES — montants conservés (utiles pour conseils) ──
    simulations = p.simulations.order(created_at: :desc)
    if simulations.any?
      lines << "\n── Simulations de primes (#{simulations.count}) ──"
      simulations.each do |s|
        eligible = s.eligible ? "✅ éligible" : "❌ non éligible"
        cat = s.category.present? ? " | Catégorie: #{s.category}" : ""
        lines << "  #{eligible} #{s.titre || s.region&.capitalize} — #{amount_bracket(s.total_simule)}#{cat}"
        lines << "    Raison inéligibilité: #{s.ineligibility_reason}" if s.ineligibility_reason.present?
      end
      best = simulations.select(&:eligible).max_by { |s| s.total_simule.to_i }
      lines << "  → Meilleure simulation éligible : #{best ? amount_bracket(best.total_simule) + ' (' + (best.titre || best.region) + ')' : 'aucune éligible'}"
    end

    # ── DEMANDES OFFICIELLES ────────────────────────────────────────────────
    requests = p.requests.order(created_at: :desc)
    if requests.any?
      lines << "\n── Demandes officielles (#{requests.count}) ──"
      requests.each do |r|
        montant = r.montant_total.present? ? " | Montant: #{amount_bracket(r.montant_total)}" : ""
        lines << "  • #{r.title || r.type_travaux || 'N/A'} [#{r.status || 'N/A'}] #{r.region&.capitalize}#{montant}"
      end
    end

    # ── DEVIS GLOBAUX (quotes) ───────────────────────────────────────────────
    quotes = p.quotes.order(created_at: :desc)
    if quotes.any?
      lines << "\n── Devis estimatifs (#{quotes.count}) ──"
      quotes.each do |q|
        lines << "  • #{amount_bracket(q.total_min)} – #{amount_bracket(q.total_max)} | Durée: #{q.duration_min_days}–#{q.duration_max_days} jours | #{q.status || 'N/A'}"
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

  # Tranches pour les montants de travaux / devis / primes (calées sur barèmes belges)
  def amount_bracket(amount)
    return 'N/A' unless amount
    val = amount.to_f
    case val
    when 0...1_000      then "< 1 000 €"
    when 1_000...5_000  then "1 000–5 000 €"
    when 5_000...10_000 then "5 000–10 000 €"
    when 10_000...20_000 then "10 000–20 000 €"
    when 20_000...35_000 then "20 000–35 000 €"
    when 35_000...50_000 then "35 000–50 000 €"
    when 50_000...75_000 then "50 000–75 000 €"
    when 75_000...100_000 then "75 000–100 000 €"
    when 100_000...150_000 then "100 000–150 000 €"
    when 150_000...250_000 then "150 000–250 000 €"
    else                    "> 250 000 €"
    end
  end
  # envoyés à l'API Anthropic. Les tranches correspondent aux seuils des
  # régimes de primes belges (Wallonie, Bruxelles, Flandre).
  def revenue_bracket(amount)
    return 'N/A' unless amount
    val = amount.to_f
    case val
    when 0...15_000   then "< 15 000 €"
    when 15_000...20_000 then "15 000–20 000 €"
    when 20_000...25_000 then "20 000–25 000 €"
    when 25_000...30_000 then "25 000–30 000 €"
    when 30_000...35_000 then "30 000–35 000 €"
    when 35_000...45_000 then "35 000–45 000 €"
    when 45_000...60_000 then "45 000–60 000 €"
    when 60_000...80_000 then "60 000–80 000 €"
    else                   "> 80 000 €"
    end
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

# ProContextualBotService — Assistant IA pour les professionnels (architecte / entrepreneur / intermédiaire)
#
# PRINCIPE DE CLOISONNEMENT (sécurité + RGPD) :
#   Chaque pro ne voit QUE les données qu'il génère ou qui lui sont pertinentes
#   dans le cadre de sa mission sur le chantier.
#
#   ┌─────────────────┬──────────────────────────────────────────────────────────┐
#   │ Architecte      │ Ses devis archi, ses factures d'honoraires, permis,      │
#   │                 │ PV de réception, avancement des phases qu'il pilote.     │
#   │                 │ ❌ Pas : revenus client, situation familiale, fiscalité   │
#   ├─────────────────┼──────────────────────────────────────────────────────────┤
#   │ Entrepreneur    │ Ses devis travaux, ses factures émises (type_intervenant  │
#   │                 │ = entrepreneur), états d'avancement, certifications,     │
#   │                 │ délais de paiement.                                      │
#   │                 │ ❌ Pas : données financières client, honoraires archi     │
#   ├─────────────────┼──────────────────────────────────────────────────────────┤
#   │ Intermédiaire   │ Vue de coordination : tous les projets du portefeuille,  │
#   │                 │ avancement global, primes éligibles, documents clés.     │
#   │                 │ ❌ Pas : revenus exacts, données fiscales, IBAN           │
#   └─────────────────┴──────────────────────────────────────────────────────────┘

class ProContextualBotService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  EXPERT_MODEL      = 'claude-sonnet-4-5-20250929'
  GUIDE_MODEL       = 'claude-haiku-4-5-20251001'
  MAX_HISTORY       = 20
  HISTORY_TTL       = 2.hours

  # @param pro_user [User]       Le professionnel connecté
  # @param pro_role [Symbol]     :architecte | :entrepreneur | :intermediaire
  # @param project  [Project]    Optionnel — si nil, contexte portefeuille complet
  # @param cache_key [String]    Clé Rails.cache pour l'historique
  def initialize(pro_user, pro_role:, project: nil, cache_key: nil)
    @user       = pro_user
    @pro_role   = pro_role.to_sym
    @project    = project
    @cache_key  = cache_key
    @api_key    = ENV['ANTHROPIC_API_KEY']
  end

  # Point d'entrée principal
  def chat(message, mode: 'expert', locale: :fr)
    history = load_history
    model   = mode == 'guide' ? GUIDE_MODEL : EXPERT_MODEL
    system  = build_system_prompt(mode)
    msgs    = history + [{ role: 'user', content: message }]

    content = call_claude(model, system, msgs)
    content ||= fallback_message

    updated = (history + [
      { role: 'user',      content: message },
      { role: 'assistant', content: content }
    ]).last(MAX_HISTORY)
    save_history(updated)

    { content: content }
  end

  def clear_history
    Rails.cache.delete(@cache_key) if @cache_key
  end

  def get_suggestions
    case @pro_role
    when :architecte
      [
        "Quels documents manquent pour le permis d'urbanisme ?",
        "Quelle est la prochaine étape réglementaire sur ce chantier ?",
        "Synthèse des primes éligibles pour mon client",
        "Avancement des phases de ce chantier",
        "Quels PV de réception sont encore à établir ?"
      ]
    when :entrepreneur
      [
        "Quelles factures sont en attente de paiement ?",
        "Avancement des travaux sur ce chantier",
        "Délais de dépôt des primes pour ce chantier",
        "Documents manquants pour clôturer ce chantier",
        "Certifications requises pour ces travaux ?"
      ]
    when :intermediaire
      [
        "Quel client a le dossier le plus avancé ?",
        "Quels dossiers sont en retard ou bloqués ?",
        "Synthèse des primes éligibles par client",
        "Prochaines échéances urgentes dans mon portefeuille",
        "Quels documents manquent sur l'ensemble des dossiers ?"
      ]
    end
  end

  private

  # ─── Prompt système ──────────────────────────────────────────────────────────

  def build_system_prompt(mode)
    role_label = { architecte: 'architecte', entrepreneur: 'entrepreneur en construction', intermediaire: 'intermédiaire / conseiller en rénovation' }[@pro_role]
    context    = @project ? build_project_context : build_portfolio_context

    base = <<~PROMPT
      Tu es l'assistant IA Ren0vate, spécialisé pour un #{role_label}.
      Tu as une mémoire complète de la conversation — utilise-la pour des réponses cohérentes et personnalisées.

      RÔLE PROFESSIONNEL : #{role_label.upcase}
      CABINET / ENTREPRISE : #{@user.nom_cabinet.presence || @user.first_name}

      DONNÉES DE TON PÉRIMÈTRE :
      #{context}

      RÈGLES ABSOLUES :
      - Réponds en français (ou en néerlandais si l'utilisateur écrit en néerlandais)
      - Tu ne vois QUE les données de ton périmètre — ne spécule pas sur d'autres intervenants
      - Si une donnée manque, signale-le et suggère où la renseigner dans l'app
      - Format markdown avec émojis thématiques
      - Sois concret et actionnable
      - Maximum 500 mots par réponse
      - Terminologie belge : "entrepreneur agréé", "PV de réception", "primes énergétiques", "avertissement-extrait de rôle"
      - Pour les délais de primes ou de paiement, signale toujours l'urgence si < 60 jours
    PROMPT

    if mode == 'guide'
      base + "\nMODE GUIDE : Accompagne pas à pas, questions courtes et précises."
    else
      base + "\nMODE EXPERT : Analyse approfondie, stratégie optimale, risques et opportunités."
    end
  end

  # ─── Contexte : vue d'un seul projet ─────────────────────────────────────────

  def build_project_context
    pr = @project
    lines = []

    lines << "═══ CHANTIER ═══"
    lines << "Ref interne : CHANTIER-#{Digest::SHA256.hexdigest(pr.id.to_s)[0..7]}"
    lines << "Nom         : #{pr.name}"
    lines << "Statut      : #{pr.statut || 'en cours'}"
    lines << "Type travaux: #{pr.type_travaux || 'N/A'}"
    lines << "Période     : #{pr.date_début&.strftime('%m/%Y') || '?'} → #{pr.date_fin&.strftime('%m/%Y') || '?'}"

    # Localisation — commune + région uniquement (pas adresse complète)
    if pr.property
      p = pr.property
      lines << "Localisation: #{[p.code_postal, p.commune].compact.join(' ')} — #{p.region&.capitalize || 'N/A'}"
      lines << "Type bien   : #{p.type_propriete_wallonie || p.type_bien_flandre || p.type_bien_bruxelles || p.type_propriete || 'N/A'}"
      lines << "PEB         : #{p.certificat_peb_wallonie || p.certificat_peb_flandre || p.certificat_peb_bruxelles || p.peb || 'N/A'}"
      lines << "Année constr: #{p.annee_construction || 'N/A'}"
    end

    # Avancement des phases
    lines << "\n── Avancement phases chantier ──"
    lines << "  Global : #{pr.avancement_global_pct}%"
    Project::PHASES_CHANTIER.each do |phase|
      pct = pr.phase_pct(phase[:key])
      bar = "█" * (pct / 20) + "░" * (5 - pct / 20)
      lines << "  #{phase[:label].ljust(20)} #{bar} #{pct}%"
    end

    # Permis
    lines << "\n── Documents réglementaires ──"
    lines << "  Permis urbanisme: #{pr.permis_urbanisme_number.present? ? "Oui (#{pr.permis_urbanisme_number})" : 'Non'}"
    lines << "  Audit énergétique: #{pr.numero_audit.present? ? "Oui — #{pr.date_audit&.strftime('%m/%Y') || 'N/A'}" : 'Non'}"

    # PV de réception
    if pr.pv_reception.present?
      pv = pr.pv_reception
      lines << "  PV de réception : #{pv.created_at.strftime('%d/%m/%Y')} | Statut: #{pv.statut || 'N/A'}"
    else
      lines << "  PV de réception : Non établi"
    end

    # Données spécifiques au rôle
    case @pro_role
    when :architecte
      lines.concat(architecte_project_lines(pr))
    when :entrepreneur
      lines.concat(entrepreneur_project_lines(pr))
    when :intermediaire
      lines.concat(intermediaire_project_lines(pr))
    end

    # États d'avancement structurés (bordereaux)
    etats = pr.etats_avancement.order(created_at: :desc)
    if etats.any?
      lines << "\n── Bordereaux d'avancement (#{etats.count}) ──"
      etats.first(5).each do |ea|
        lines << "  • #{ea.created_at.strftime('%d/%m/%Y')} | Statut: #{ea.statut || 'N/A'}"
      end
    end

    lines.join("\n")
  end

  # Données visibles par l'architecte sur un projet
  def architecte_project_lines(pr)
    lines = []

    lines << "\n── Vos honoraires & devis (architecte) ──"
    montant_devis = pr.architecte_devis_montant_effectif
    montant_factures = pr.architecte_factures_total
    lines << "  Devis honoraires  : #{montant_devis ? amount_bracket(montant_devis) : 'Non renseigné'}"
    lines << "  Factures émises   : #{amount_bracket(montant_factures)}"
    if montant_devis && montant_devis > 0
      diff = pr.architecte_devis_vs_factures_difference
      lines << "  Solde devis/fact. : #{diff >= 0 ? '+' : ''}#{amount_bracket(diff.abs)} #{diff >= 0 ? '(en avance)' : '(solde restant)'}"
    end

    # Devis OCR uploadés par l'architecte
    devis_archi = pr.devis_ocr_architecte
    if devis_archi.any?
      lines << "\n  Devis scannés architecte (#{devis_archi.count}) :"
      devis_archi.each do |dv|
        valid = dv.valide_manuellement ? '✅' : '⏳'
        lines << "    #{valid} #{amount_bracket(dv.montant_total_tvac)} | #{dv.types_travaux_detectes&.first(2)&.join(', ') || 'N/A'} | #{dv.date_devis&.strftime('%m/%Y') || 'N/A'}"
      end
    end

    # Factures architecte uniquement
    factures_archi = pr.factures.travaux_only.architecte.order(date_facture: :desc)
    if factures_archi.any?
      lines << "\n  Factures architecte (#{factures_archi.count}) :"
      factures_archi.each do |f|
        expire = f.date_limite_prime ? " | ⚠️ Délai prime: #{f.date_limite_prime.strftime('%d/%m/%Y')}" : ""
        lines << "    • [#{f.type_facture}] #{amount_bracket(f.montant)} | #{f.statut_paiement || 'N/A'}#{expire}"
      end
    end

    # Spécialités architecte
    if pr.architecte_specialites.present?
      lines << "\n  Vos spécialités déclarées : #{Array(pr.architecte_specialites).join(', ')}"
    end

    lines
  end

  # Données visibles par l'entrepreneur sur un projet
  def entrepreneur_project_lines(pr)
    lines = []

    lines << "\n── Vos travaux & facturation (entrepreneur) ──"
    montant_devis = pr.contractor_devis_montant_effectif
    montant_factures = pr.contractor_factures_total
    lines << "  Devis travaux     : #{montant_devis ? amount_bracket(montant_devis) : 'Non renseigné'}"
    lines << "  Factures émises   : #{amount_bracket(montant_factures)}"
    if montant_devis && montant_devis > 0
      diff = pr.contractor_devis_vs_factures_difference
      lines << "  Solde devis/fact. : #{diff >= 0 ? '+' : ''}#{amount_bracket(diff.abs)} #{diff >= 0 ? '(en avance)' : '(solde restant)'}"
    end

    # Devis OCR uploadés par l'entrepreneur
    devis_entr = pr.devis_ocr_entrepreneur
    if devis_entr.any?
      lines << "\n  Devis scannés entrepreneur (#{devis_entr.count}) :"
      devis_entr.each do |dv|
        valid = dv.valide_manuellement ? '✅' : '⏳'
        lines << "    #{valid} #{amount_bracket(dv.montant_total_tvac)} | #{dv.types_travaux_detectes&.first(2)&.join(', ') || 'N/A'} | #{dv.date_devis&.strftime('%m/%Y') || 'N/A'}"
      end
    end

    # Factures entrepreneur uniquement
    factures_entr = pr.factures.travaux_only.entrepreneur.order(date_facture: :desc)
    if factures_entr.any?
      lines << "\n  Factures entrepreneur (#{factures_entr.count}) :"
      factures_entr.each do |f|
        expire = f.date_limite_prime ? " | ⚠️ Délai prime: #{f.date_limite_prime.strftime('%d/%m/%Y')}" : ""
        lines << "    • [#{f.type_facture}] #{amount_bracket(f.montant)} | #{f.statut_paiement || 'N/A'}#{expire}"
      end
    end

    # Certifications
    if pr.entrepreneur_principal_certifications.present?
      certs = Array(pr.entrepreneur_principal_certifications).join(', ')
      lines << "\n  Certifications déclarées : #{certs}"
    end

    # Numéro BCE (pas de données perso)
    lines << "  N° BCE enregistré : #{pr.entrepreneur_principal_numero_tva.present? ? 'Oui' : 'Non'}"

    # Bordereau chassis (spécifique entrepreneur)
    if pr.respond_to?(:bordereau_chassis_donnees) && pr.bordereau_chassis_donnees.any?
      lines << "\n  Bordereaux chassis (#{pr.bordereau_chassis_donnees.count}) : renseignés"
    end

    lines
  end

  # Données visibles par l'intermédiaire sur un projet (vue de coordination)
  def intermediaire_project_lines(pr)
    lines = []

    lines << "\n── Vue coordination (intermédiaire) ──"
    # Budget global — tranches uniquement
    total_devis = pr.total_devis_montant
    lines << "  Budget total devis: #{total_devis > 0 ? amount_bracket(total_devis) : 'Non renseigné'}"

    # Primes éligibles sur ce bien — montants conservés (utiles pour conseil)
    if pr.property
      sims = pr.property.simulations.order(created_at: :desc)
      if sims.any?
        eligible = sims.select(&:eligible)
        best = eligible.max_by { |s| s.total_simule.to_i }
        lines << "  Primes éligibles  : #{eligible.count} simulation(s) — Meilleure: #{best ? amount_bracket(best.total_simule) : 'N/A'}"
      end
    end

    # Demandes officielles (statuts)
    if pr.property
      requests = pr.property.requests.order(created_at: :desc)
      if requests.any?
        lines << "  Demandes primes   : #{requests.count} (#{requests.group_by(&:status).map { |s, r| "#{r.count} #{s}" }.join(', ')})"
      end
    end

    # Intervenants présents (sans données perso)
    lines << "\n  Intervenants déclarés :"
    lines << "    Architecte  : #{pr.architecte_complet? ? '✅ Renseigné' : '⚠️ Incomplet'}"
    lines << "    Entrepreneur: #{pr.entrepreneur_principal_complet? ? '✅ Renseigné' : '⚠️ Incomplet'}"

    lines
  end

  # ─── Contexte : vue portefeuille complet ─────────────────────────────────────

  def build_portfolio_context
    # Projets où le pro est membre actif
    members = @user.project_members.includes(project: :property).where(status: 'active').order(created_at: :desc)
    projects = members.map(&:project).compact

    lines = []
    lines << "═══ PORTEFEUILLE #{@pro_role.to_s.upcase} ═══"
    lines << "Cabinet/Entreprise : #{@user.nom_cabinet.presence || @user.first_name}"
    lines << "BCE                : #{@user.num_bce.present? ? 'Renseigné' : 'Non renseigné'}"
    lines << "Projets actifs     : #{projects.count}"

    if projects.empty?
      lines << "\nAucun projet actif. Invitez vos clients via votre lien de referral."
      return lines.join("\n")
    end

    lines << ""
    projects.each_with_index do |pr, i|
      prop = pr.property
      pct  = pr.avancement_global_pct

      lines << "── Chantier #{i + 1} ──"
      lines << "  Nom         : #{pr.name}"
      lines << "  Localisation: #{prop ? [prop.code_postal, prop.commune].compact.join(' ') + ' — ' + (prop.region&.capitalize || 'N/A') : 'N/A'}"
      lines << "  Statut      : #{pr.statut || 'en cours'} | Avancement global: #{pct}%"
      lines << "  Type travaux: #{pr.type_travaux || 'N/A'}"
      lines << "  PEB         : #{prop ? (prop.certificat_peb_wallonie || prop.certificat_peb_flandre || prop.certificat_peb_bruxelles || prop.peb || 'N/A') : 'N/A'}"

      case @pro_role
      when :architecte
        montant = pr.architecte_devis_montant_effectif
        factures_total = pr.architecte_factures_total
        lines << "  Devis archi : #{montant ? amount_bracket(montant) : 'Non renseigné'} | Facturé: #{amount_bracket(factures_total)}"
        lines << "  Permis      : #{pr.permis_urbanisme_number.present? ? 'Oui' : 'Non'} | PV réception: #{pr.pv_reception.present? ? 'Établi' : 'Non établi'}"

      when :entrepreneur
        montant = pr.contractor_devis_montant_effectif
        factures_total = pr.contractor_factures_total
        nb_fact_impayees = pr.factures.travaux_only.entrepreneur.non_payees.count
        lines << "  Devis trvx  : #{montant ? amount_bracket(montant) : 'Non renseigné'} | Facturé: #{amount_bracket(factures_total)}"
        lines << "  Factures impayées: #{nb_fact_impayees}"

      when :intermediaire
        total_devis = pr.total_devis_montant
        best_sim = prop ? prop.simulations.select(&:eligible).max_by { |s| s.total_simule.to_i } : nil
        lines << "  Budget total : #{total_devis > 0 ? amount_bracket(total_devis) : 'N/A'}"
        lines << "  Primes max   : #{best_sim ? amount_bracket(best_sim.total_simule) : 'N/A'}"
        lines << "  Architecte   : #{pr.architecte_complet? ? '✅' : '⚠️ Incomplet'} | Entrepreneur: #{pr.entrepreneur_principal_complet? ? '✅' : '⚠️ Incomplet'}"
      end

      lines << ""
    end

    lines.join("\n")
  end

  # ─── Anthropic API ───────────────────────────────────────────────────────────

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
      Rails.logger.info "✅ ProBot #{@pro_role} #{model} — #{duration}s — #{content&.length} chars"
      content
    else
      Rails.logger.error "❌ ProBot Claude #{response.code}: #{response.body[0..200]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn "⏰ ProBot timeout"
    nil
  rescue => e
    Rails.logger.error "🔥 ProBot error: #{e.message}"
    nil
  end

  # ─── Historique ──────────────────────────────────────────────────────────────

  def load_history
    return [] unless @cache_key
    Rails.cache.read(@cache_key) || []
  end

  def save_history(messages)
    return unless @cache_key
    Rails.cache.write(@cache_key, messages, expires_in: HISTORY_TTL)
  end

  def fallback_message
    "Je rencontre une difficulté technique momentanée. Veuillez réessayer dans quelques secondes."
  end

  # ─── Helpers montants ────────────────────────────────────────────────────────

  def amount_bracket(amount)
    return 'N/A' unless amount
    val = amount.to_f
    case val
    when 0...1_000        then "< 1 000 €"
    when 1_000...5_000    then "1 000–5 000 €"
    when 5_000...10_000   then "5 000–10 000 €"
    when 10_000...20_000  then "10 000–20 000 €"
    when 20_000...35_000  then "20 000–35 000 €"
    when 35_000...50_000  then "35 000–50 000 €"
    when 50_000...75_000  then "50 000–75 000 €"
    when 75_000...100_000 then "75 000–100 000 €"
    when 100_000...150_000 then "100 000–150 000 €"
    when 150_000...250_000 then "150 000–250 000 €"
    else                    "> 250 000 €"
    end
  end
end

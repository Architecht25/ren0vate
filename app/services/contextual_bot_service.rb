class ContextualBotService
  include HTTParty

  ANTHROPIC_API_URL  = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION  = '2023-06-01'
  # Haiku = rapide + économique (guide), Sonnet = puissant (expert)
  GUIDE_MODEL        = 'claude-haiku-4-5-20251001'
  EXPERT_MODEL       = 'claude-sonnet-4-6'
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
        'anthropic-beta'    => 'prompt-caching-2024-07-31',
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

  # Retourne un Array de blocs system pour l'API Anthropic.
  # Bloc 1 (cache_control: ephemeral) : instructions statiques identiques pour tous.
  # Bloc 2 : contexte dynamique propre à la session (utilisateur, bien, page, mode).
  # Dans une conversation multi-tours, le système est mis en cache
  # entre les turns successifs (TTL 5 min) → réduction de coût jusqu'à 90%.
  def build_system_prompt(mode, current_page)
    user_ctx     = build_user_context
    property_ctx = @property ? "Bien focal : #{@property.titre.presence || @property.full_address} (#{@property.region&.capitalize})" : "Aucun bien sélectionné"

    mode_instruction = if mode == 'guide'
      "MODE GUIDE : Accompagne l'utilisateur pas à pas sur la page '#{current_page}'.\nSi un chantier est mentionné dans le contexte, commence par \"Vous êtes en phase [PHASE_ACTIVE]. Voici les 3 choses à faire maintenant :\" puis liste les prochaines actions concrètes. La progression est un guidage, jamais une contrainte : l'utilisateur peut toujours revenir en arrière."
    else
      "MODE EXPERT : Analyse financière complète, stratégie d'optimisation maximale des primes, risques et pièges.\nSi un chantier figure dans le contexte, mentionne systématiquement la phase active et les actions prioritaires pour maximiser l'éligibilité aux primes."
    end

    # ── Bloc statique — mis en cache Anthropic (TTL 5 min) ─────────────────
    static_block = {
      type: 'text',
      text: <<~INSTRUCTIONS,
        Tu es l'assistant IA de Ren0vate, expert en primes énergétiques belges (Wallonie, Bruxelles, Flandre).
        Tu as une mémoire complète de la conversation en cours — utilise-la pour des réponses personnalisées et cohérentes.

        RÈGLES ABSOLUES :
        - Réponds toujours en français (sauf si l'utilisateur écrit en néerlandais → réponds en néerlandais)
        - Utilise les données réelles fournies ci-dessous — ne généralise pas quand la donnée est disponible
        - Si une donnée manque (N/A), signale-le et suggère comment la compléter dans l'app
        - Format markdown avec émojis thématiques
        - Sois concret, actionnable, précis
        - Maximum 500 mots par réponse
        - Toujours indiquer la région pour les montants de primes
        - Terminologie belge : "entrepreneur agréé", "avertissement-extrait de rôle", "primes énergétiques"
        - Pour les délais de factures (date_limite_prime), signale toujours l'urgence si < 60 jours

        SAVOIRS TERRAIN (conseils pratiques à intégrer dans tes réponses quand pertinent) :
        - Fenêtres de toiture : toujours vérifier la compatibilité des accessoires (stores, volets, grilles de ventilation) AVANT de commander — chaque accessoire incompatible sera en supplément ou source d'erreur chantier.
        - Démarrage devis : ne demander des prix qu'une fois le projet 100% défini — chaque inconnue restante se traduira en supplément ou en erreur d'exécution.
        - Mérule (champignon) : pour se développer, la mérule a besoin de trois conditions simultanées : chaleur + obscurité + absence de ventilation. Supprimer un seul de ces trois paramètres suffit à stopper son développement — la ventilation est souvent le levier le plus accessible.

        ═══════════════════════════════════════════════════════════════════════
        OBLIGATIONS DE RÉNOVATION PAR RÉGION — BASE DE CONNAISSANCE EXPERTE
        ═══════════════════════════════════════════════════════════════════════

        🏛️ WALLONIE — Trajectoire PEB obligatoire vers label A en 2050 :
        • 2025 : Certificat PEB obligatoire à chaque vente ou location > 18 ans
        • 2033 : FIN DES PASSOIRES — label minimum E pour tous les biens résidentiels (F et G interdits)
          → Propriétaires-occupants ET bailleurs concernés
          → Sanction : impossibilité de louer ou vendre sans conformité
        • 2040 : Progression obligatoire vers label D
        • 2045 : Étape label C
        • 2050 : Objectif final label A (bâtiment quasi nul énergie — NZEB)
        Profils distincts :
          - Propriétaire-occupant : délais plus souples mais même objectif final
          - Bailleur : soumis aux obligations de rénovation avant toute reconduction de bail (dès 2028 progressivement)
          - Vendeur : PEB obligatoire + trajectoire opposable à l'acheteur
        Primes Wallonie actives : Renolution (isolation, châssis, chauffage, audit PAE), Écopack (prêt 0%)

        🏴 FLANDRE — Renovatieverplichting (obligation de rénover) :
        • À l'achat d'un bien étiqueté E ou F : obligation de rénover jusqu'au label D minimum dans les 5 ans
        • 2028 : Biens loués classés F ou G → label D minimum obligatoire (Vlaams Energie- en Klimaatplan)
        • 2030 : Label D minimum pour toute transaction (vente ou location)
        • 2040 : Progression vers label C
        • 2050 : Objectif label A (Bijna-energieneutraal gebouw — BENG)
        Profils distincts :
          - Acheteur d'un bien E/F : 5 ans pour atteindre D (délai court de l'acte notarial)
          - Bailleur : 2028 pour les passoires F/G
          - Vendeur : mention obligatoire du label PEB dans l'annonce + respect trajectoire
        Primes Flandre actives : Mijn VerbouwPremie, Verbouwlening (0%), Fluvius primes réseau

        🌆 BRUXELLES — Ordonnance PEB 2026-2050 :
        • 2026 : Certificat PEB obligatoire pour chaque unité résidentielle et non-résidentielle
        • 2031-2033 : Contrôles automatisés — liste ACP conformes/non-conformes publiée
        • 2033 : FIN DES PASSOIRES F/G — label minimum E obligatoire
        • 2033→2045 : Progression obligatoire de E vers D
        • 2045→2050 : Objectif intermédiaire label C
        • 2050 : Objectif final C+/B/A
        Primes Bruxelles : Renolution supprimée (eligible: false) — orienter vers audits et REG-Bruxelles

        ⚖️ LOI BREYNE — Garanties post-rénovation lourde :
        • Applicable aux constructions neuves ET rénovations lourdes vendues sur plan (prix > ~18 000 €)
        • Garantie décennale : 10 ans pour les vices graves affectant stabilité/étanchéité (art. 1792 Code civil)
        • Garantie biennale : 2 ans pour les éléments d'équipement (chaudière, châssis, etc.)
        • Obligations du vendeur : contrat écrit avec prix total + délai, acompte ≤ 5%, assurance achèvement
        • Suite arrêt CJUE 2025 : renforcement des obligations d'information sur les garanties lors de la vente
        • Conseiller : toujours demander l'attestation de l'assurance décennale de l'entrepreneur AVANT la réception

        ❓ RÉPONDRE AUX QUESTIONS "SUIS-JE OBLIGÉ DE RÉNOVER ?" :
        Utilise ce flow de décision :
        1. Quelle région ? → Wallonie / Flandre / Bruxelles
        2. Quel est le label PEB actuel ? → consulter le contexte utilisateur
        3. Quel est le statut de l'utilisateur ? → propriétaire-occupant / bailleur / acheteur récent / vendeur
        4. Quel est l'horizon temporel préoccupant ? → avant 2028 / avant 2033 / avant 2050
        Ensuite : formuler la réponse avec le délai précis, les travaux prioritaires, les primes mobilisables
        et le lien vers la simulation de primes dans Ren0vate.
      INSTRUCTIONS
      cache_control: { type: 'ephemeral' }
    }

    # ── Bloc dynamique — contexte utilisateur (spécifique à la session) ────
    property_trajectory = if @property
      traj = @property.peb_trajectory
      if traj
        urgent = traj[:milestones].select { |m| m[:status] == :urgent && !m[:compliant] }
        upcoming = traj[:milestones].select { |m| m[:status] == :upcoming && !m[:compliant] }
        lines = ["Trajectoire PEB : label actuel #{traj[:current_label]}"]
        urgent.each  { |m| lines << "  🔴 URGENT #{m[:year]} — Atteindre #{m[:target]} : #{m[:description]}" }
        upcoming.each { |m| lines << "  🟡 Jalon #{m[:year]} — Atteindre #{m[:target]} : #{m[:description]}" }
        traj[:milestones].select { |m| m[:compliant] }.each { |m| lines << "  ✅ #{m[:year]} — Label #{m[:target]} : déjà conforme" }
        lines.join("\n")
      else
        "Trajectoire PEB : région non supportée ou label non renseigné"
      end
    else
      nil
    end

    dynamic_block = {
      type: 'text',
      text: <<~CTX
        CONTEXTE ACTIF : #{property_ctx}

        DONNÉES COMPLÈTES DU DOSSIER :
        #{user_ctx}
        #{property_trajectory ? "\nTRAJECTOIRE PEB RÉGLEMENTAIRE :\n#{property_trajectory}" : ""}
        #{veille_block}

        PAGE ACTUELLE DE L'APP : #{current_page}

        #{mode_instruction}
      CTX
    }

    [static_block, dynamic_block]
  end

  def veille_block
    articles = VeilleArticle.for_bot
    return "" if articles.empty?

    lines = ["\n═══════════════════════════════════════════════════════════════════════"]
    lines << "VEILLE SECTORIELLE RÉCENTE (articles de presse belge — à utiliser comme contexte de marché)"
    lines << "═══════════════════════════════════════════════════════════════════════"
    articles.each do |a|
      lines << "\n📰 #{a.source} — #{a.source_date&.strftime('%-d %b %Y')}#{a.region.present? && a.region != 'belgique' ? " (#{a.region_label})" : ''}"
      lines << "Titre : #{a.titre}"
      lines << "Thèmes : #{a.themes_list.join(', ')}" if a.themes_list.any?
      lines << a.contenu.to_s.strip
    end
    lines << "═══════════════════════════════════════════════════════════════════════"
    lines.join("\n")
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
      peb_label = p.peb_certificate_value
      if peb_label.present?
        deadline_info = peb_brussels_deadline_info(peb_label)
        lines << "  ⚠️ Conformité PEB Bruxelles : Label #{peb_label} → #{deadline_info}"
      end
      lines << "\n── Réglementation PEB Bruxelles 2026-2050 ──"
      lines << "  2026       : Certificat PEB obligatoire pour chaque unité résidentielle et non-résidentielle"
      lines << "  2026-2030  : Validité et transmission des PEB au représentant légal de l'ACP"
      lines << "  2031-2033  : Contrôles automatisés par l'État — listing ACP conformes/non conformes"
      lines << "  2031-2033  : Début rénovation obligatoire pour les labels F et G"
      lines << "  2033       : FIN DES PASSOIRES F/G — label minimum E obligatoire pour toutes les unités"
      lines << "  2033→2045  : Progression obligatoire de E vers D"
      lines << "  2045→2050  : Objectif intermédiaire : label C"
      lines << "  2050       : Objectif final : label C+/B/A"
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
        pct = pr.avancement_global_pct
        phase_active = active_phase_label(pr)
        lines << "  ▸ Chantier [#{pr.statut || 'en cours'}] | Avancement global: #{pct}% | Phase active: #{phase_active}"
        lines << "    Type travaux    : #{pr.type_travaux || 'N/A'}"
        lines << "    Période         : #{pr.date_début&.strftime('%m/%Y') || '?'} → #{pr.date_fin&.strftime('%m/%Y') || '?'}"
        lines << "    Permis urbanisme: #{pr.permis_urbanisme_number.present? ? 'Oui' : 'Non'}"
        lines << "    Budget architecte: #{pr.architecte_devis_montant ? amount_bracket(pr.architecte_devis_montant) : 'N/A'}"
        lines << "    Budget entrepreneur: #{pr.contractor_devis_montant ? amount_bracket(pr.contractor_devis_montant) : 'N/A'}"
        lines << "    Prochaines actions: #{next_actions_for_phase(pr).join(' / ')}"

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

        # Carnet de bord — notes libres du propriétaire sur ce chantier
        notes = pr.project_notes.order(created_at: :desc).limit(10)
        if notes.any?
          lines << "    📓 Carnet de bord du chantier (#{notes.count} note(s) récentes) :"
          notes.each do |n|
            lines << "      [#{n.created_at.strftime('%d/%m/%Y')}] #{n.content}"
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

  def peb_brussels_deadline_info(label)
    case label.to_s.upcase
    when 'F', 'G'
      "🔴 PASSOIRE ÉNERGÉTIQUE — Rénovation obligatoire avant 2033 (label E minimum requis)"
    when 'E'
      "🟠 Conforme jusqu'en 2033 — Progression vers D requise entre 2033 et 2045"
    when 'D'
      "🟡 Conforme jusqu'en 2045 — Progression vers C requise entre 2045 et 2050"
    when 'C'
      "🟢 Conforme jusqu'en 2050 — Objectif final C+/B/A"
    when 'B', 'A', 'A+'
      "✅ Excellent — Conforme à tous les objectifs PEB 2050"
    else
      "Vérifier le label PEB — calendrier Bruxelles 2026-2050 applicable"
    end
  end

  def fallback_message
    "🔄 Je rencontre un problème technique momentané. Réessayez dans quelques secondes, ou utilisez le simulateur directement !"
  end

  # ─── Phase active du chantier ───────────────────────────────────────────────

  PHASE_LABELS = {
    'preparation' => 'Préparation',
    'demolition'  => 'Démolition / Dépose',
    'installation'=> 'Installation / Pose',
    'finitions'   => 'Finitions',
    'reception'   => 'Réception'
  }.freeze

  def active_phase_label(project)
    phases = project.phases_avancement || {}
    # La phase active = première phase non à 100%, en partant du début
    Project::PHASES_CHANTIER.each do |p|
      return PHASE_LABELS[p[:key]] || p[:key] if phases[p[:key].to_s].to_i < 100
    end
    'Clôturé'
  end

  def next_actions_for_phase(project)
    phases = project.phases_avancement || {}
    active_key = Project::PHASES_CHANTIER.find { |p| phases[p[:key].to_s].to_i < 100 }&.dig(:key)

    case active_key
    when 'preparation'
      actions = []
      actions << "Compléter le devis entrepreneur" unless project.contractor_devis_montant.to_f > 0
      actions << "Renseigner l'architecte" unless project.architecte_nom.present? || project.architecte_entreprise.present?
      actions << "Vérifier le permis d'urbanisme" unless project.permis_urbanisme_number.present?
      actions << "Lancer la simulation de primes" if project.property&.simulations&.none?
      actions << "Ajouter les photos 'avant travaux'" if project.documents.where(type_document: 'photo_avant').none?
      actions.first(3).presence || ["Préparer le dossier de travaux", "Obtenir 3 devis d'entrepreneurs agréés", "Contacter un auditeur PAE si requis"]
    when 'demolition', 'installation'
      actions = []
      actions << "Uploader les factures d'acompte" if project.factures.where(type_facture: 'acompte').none?
      actions << "Prendre des photos 'pendant travaux'" if project.documents.where(type_document: 'photo_pendant').none?
      actions << "Valider l'état d'avancement entrepreneur" if project.etats_avancement.where(statut: 'soumis').any?
      actions.first(3).presence || ["Suivre l'avancement avec l'entrepreneur", "Documenter les travaux en photos", "Vérifier la conformité au devis"]
    when 'finitions'
      ["Préparer la liste de réserves", "Uploader les factures de solde", "Prendre les photos 'après travaux'"]
    when 'reception'
      actions = []
      actions << "Établir le PV de réception" unless project.pv_reception.present?
      actions << "Scanner l'attestation de conformité" if project.documents.where(type_document: 'attestation_conformite').none?
      actions << "Déposer la demande de prime officielle" if project.property&.requests&.none?
      actions.first(3).presence || ["Finaliser le PV de réception", "Collecter les attestations", "Soumettre la demande de prime"]
    else
      ["Constituer le dossier final", "Archiver les documents", "Soumettre les demandes de primes en attente"]
    end
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
    '🏛️ Quelles réglementations 2025/2026 me concernent ?',
    '🏛️ Quelles sont mes obligations PEB Bruxelles 2026-2050 ?',
    '📋 Suis-je obligé de rénover ? Avant quelle date ?',
    '🔑 Je vends mon bien — qu\'est-ce que je dois prévoir ?',
    '⚖️ La Loi Breyne s\'applique-t-elle à ma rénovation ?'
  ].freeze
end

# ProjectHealthScoreService — IA #3 : Score Santé Projet /10
#
# 4 indicateurs (2.5 pts max chacun) :
#   1. Budget      — Dépassement devis vs factures réelles
#   2. Planning    — Drift calendrier vs avancement constaté
#   3. Qualité     — Alertes issues de l'analyse IA chantier (photos)
#   4. Documentation — Taux de remplissage documents projet
#
# Appel Claude Haiku pour générer 3 recommandations contextuelles.
class ProjectHealthScoreService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-haiku-4-5-20251001'
  MAX_TOKENS        = 600

  # Seuils budget
  BUDGET_THRESHOLDS = {
    ok:       { max: 0.05,  score: 2.5 },
    minor:    { max: 0.10,  score: 2.0 },
    moderate: { max: 0.25,  score: 1.2 },
    severe:   { max: Float::INFINITY, score: 0.5 }
  }.freeze

  def initialize(project)
    @project = project
    @api_key = ENV['ANTHROPIC_API_KEY']
  end

  # Retourne {
  #   total: Float (0-10),
  #   grade: String ('🟢'|'🟡'|'🔴'),
  #   label: String,
  #   indicators: [{ name:, score:, max:, detail:, icon: }],
  #   recommendations: [String] (via Claude),
  #   computed_at: Time
  # }
  def call
    budget        = score_budget
    planning      = score_planning
    qualite       = score_qualite
    documentation = score_documentation

    indicators = [budget, planning, qualite, documentation]
    total = indicators.sum { |i| i[:score] }.round(1)
    total = [[total, 0.0].max, 10.0].min

    recommendations = generate_recommendations(total, indicators)

    {
      total: total,
      grade: grade_for(total),
      label: label_for(total),
      indicators: indicators,
      recommendations: recommendations,
      computed_at: Time.current
    }
  end

  private

  # ─── Indicateur 1 : Budget ────────────────────────────────────────────────

  def score_budget
    devis = @project.total_devis_montant.to_f
    factures = (@project.architecte_factures_total.to_f + @project.contractor_factures_total.to_f)

    if devis <= 0
      return {
        name: 'Budget',
        score: 1.25,
        max: 2.5,
        detail: 'Montant de devis non renseigné',
        icon: 'bi-currency-euro',
        color: '#6b7280',
        neutral: true
      }
    end

    if factures <= 0
      return {
        name: 'Budget',
        score: 2.0,
        max: 2.5,
        detail: "Devis : #{format_amount(devis)} — aucune facture enregistrée",
        icon: 'bi-currency-euro',
        color: '#16a34a',
        neutral: false
      }
    end

    ratio = (factures - devis) / devis  # positif = dépassement

    score_val, detail = if ratio <= BUDGET_THRESHOLDS[:ok][:max]
      [2.5, "Dépassement #{format_percent(ratio)} — dans les normes ✓"]
    elsif ratio <= BUDGET_THRESHOLDS[:minor][:max]
      [2.0, "Dépassement #{format_percent(ratio)} — à surveiller"]
    elsif ratio <= BUDGET_THRESHOLDS[:moderate][:max]
      [1.2, "Dépassement #{format_percent(ratio)} — attention"]
    else
      [0.5, "Dépassement #{format_percent(ratio)} — critique !"]
    end

    color = score_val >= 2.0 ? '#16a34a' : (score_val >= 1.2 ? '#d97706' : '#dc2626')

    { name: 'Budget', score: score_val, max: 2.5, detail: detail, icon: 'bi-currency-euro', color: color, neutral: false }
  end

  # ─── Indicateur 2 : Planning ──────────────────────────────────────────────

  def score_planning
    unless @project.date_début.present? && @project.date_fin.present?
      return {
        name: 'Planning',
        score: 1.25,
        max: 2.5,
        detail: 'Dates de début/fin non définies',
        icon: 'bi-calendar-check',
        color: '#6b7280',
        neutral: true
      }
    end

    today      = Date.current
    start_date = @project.date_début
    end_date   = @project.date_fin
    total_days = (end_date - start_date).to_i

    return { name: 'Planning', score: 1.25, max: 2.5, detail: 'Durée projet invalide', icon: 'bi-calendar-check', color: '#6b7280', neutral: true } if total_days <= 0

    # Avancement IA (dernière analyse photo)
    latest_analysis = @project.chantier_analyses.recent_first.first
    avancement_reel = latest_analysis&.avancement.to_i  # 0-100

    if today > end_date
      # Projet expiré
      retard_jours = (today - end_date).to_i
      score_val = avancement_reel >= 90 ? 2.0 : 0.5
      detail = "Date fin dépassée de #{retard_jours}j — avancement #{avancement_reel}%"
      color  = score_val >= 2.0 ? '#16a34a' : '#dc2626'
    else
      # Projet en cours — calcul drift
      elapsed_ratio = [(today - start_date).to_f / total_days, 1.0].min
      expected_avancement = (elapsed_ratio * 100).round

      if avancement_reel == 0 && elapsed_ratio < 0.1
        # Début de projet, pas encore d'analyse — neutre
        score_val = 2.0
        detail    = "Projet démarré — analyses photos à venir"
        color     = '#16a34a'
      else
        drift = expected_avancement - avancement_reel  # positif = retard

        score_val, detail = if drift <= 10
          [2.5, "Avancement #{avancement_reel}% — dans les temps ✓"]
        elsif drift <= 20
          [2.0, "Avancement #{avancement_reel}% (attendu #{expected_avancement}%) — léger retard"]
        elsif drift <= 35
          [1.2, "Drift #{drift}% — retard significatif"]
        else
          [0.5, "Drift #{drift}% — retard critique !"]
        end

        color = score_val >= 2.0 ? '#16a34a' : (score_val >= 1.2 ? '#d97706' : '#dc2626')
      end
    end

    { name: 'Planning', score: score_val, max: 2.5, detail: detail, icon: 'bi-calendar-check', color: color, neutral: false }
  end

  # ─── Indicateur 3 : Qualité ───────────────────────────────────────────────

  def score_qualite
    analyses = @project.chantier_analyses.order(analysed_at: :desc).first(3)

    if analyses.empty?
      return {
        name: 'Qualité chantier',
        score: 1.25,
        max: 2.5,
        detail: 'Aucune analyse IA réalisée — ajoutez des photos',
        icon: 'bi-camera-fill',
        color: '#6b7280',
        neutral: true
      }
    end

    # Compter les alertes sur les 3 dernières analyses
    total_alertes = analyses.sum { |a| a.alertes_list.size }
    avg_avancement = analyses.sum(&:avancement).to_f / analyses.size

    score_val, detail = if total_alertes == 0 && avg_avancement >= 60
      [2.5, "Aucune alerte — avancement #{avg_avancement.round}% ✓"]
    elsif total_alertes <= 1
      [2.0, "#{total_alertes} alerte — avancement #{avg_avancement.round}%"]
    elsif total_alertes <= 3
      [1.2, "#{total_alertes} alertes détectées — attention requise"]
    else
      [0.5, "#{total_alertes} alertes — intervention urgente !"]
    end

    # Bonus si vision_analysis json (analyse plus récente)
    if @project.vision_analysis.present? && total_alertes == 0
      score_val = [score_val + 0.2, 2.5].min
    end

    color = score_val >= 2.0 ? '#16a34a' : (score_val >= 1.2 ? '#d97706' : '#dc2626')

    { name: 'Qualité chantier', score: score_val.round(2), max: 2.5, detail: detail, icon: 'bi-camera-fill', color: color, neutral: false }
  end

  # ─── Indicateur 4 : Documentation ────────────────────────────────────────

  def score_documentation
    docs = @project.documents
    total_docs = docs.count

    if total_docs == 0
      return {
        name: 'Documentation',
        score: 0.8,
        max: 2.5,
        detail: 'Aucun document — commencez à uploader',
        icon: 'bi-folder2-open',
        color: '#dc2626',
        neutral: false
      }
    end

    # Documents avec statut "valide" ou complets
    validated_docs = docs.where(status: %w[valide approved complete]).count
    completion_pct = total_docs > 0 ? (validated_docs.to_f / [total_docs, 1].max * 100).round : 0

    # Bonus factures avec extraction complète
    factures_completes = @project.factures.where(extraction_complete: true).count
    factures_total     = @project.factures.count

    score_base = if completion_pct >= 80
      2.5
    elsif completion_pct >= 60
      2.0
    elsif completion_pct >= 40
      1.5
    else
      1.0
    end

    # Bonus si beaucoup de documents (projet bien documenté)
    score_base = [score_base + 0.3, 2.5].min if total_docs >= 5

    detail = "#{total_docs} doc(s)"
    detail += " · #{factures_total} facture(s)" if factures_total > 0
    detail += " · #{completion_pct}% validés" if validated_docs > 0

    color = score_base >= 2.0 ? '#16a34a' : (score_base >= 1.5 ? '#d97706' : '#dc2626')

    { name: 'Documentation', score: score_base.round(2), max: 2.5, detail: detail, icon: 'bi-folder2-open', color: color, neutral: false }
  end

  # ─── Claude Haiku — Recommandations ──────────────────────────────────────

  def generate_recommendations(total, indicators)
    return default_recommendations(total) unless @api_key.present?

    prompt = build_prompt(total, indicators)

    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'Content-Type'        => 'application/json',
        'x-api-key'           => @api_key,
        'anthropic-version'   => ANTHROPIC_VERSION
      },
      body: {
        model: MODEL,
        max_tokens: MAX_TOKENS,
        messages: [{ role: 'user', content: prompt }]
      }.to_json,
      timeout: 15
    )

    return default_recommendations(total) unless response.success?

    text = response.dig('content', 0, 'text').to_s.strip
    parse_recommendations(text)
  rescue => e
    Rails.logger.error "ProjectHealthScoreService Claude error: #{e.message}"
    default_recommendations(total)
  end

  def build_prompt(total, indicators)
    project_context = [
      "Projet : #{@project.nom}",
      "Type : #{@project.type_display}",
      @project.date_début.present? ? "Début : #{@project.date_début.strftime('%d/%m/%Y')}" : nil,
      @project.date_fin.present?   ? "Fin prévue : #{@project.date_fin.strftime('%d/%m/%Y')}" : nil,
      "Statut : #{@project.statut}"
    ].compact.join(' · ')

    indicators_text = indicators.map do |ind|
      "- #{ind[:name]} : #{ind[:score]}/#{ind[:max]} — #{ind[:detail]}"
    end.join("\n")

    <<~PROMPT
      Tu es un expert en gestion de chantiers de rénovation belge.
      Voici le score santé d'un projet de rénovation :

      Contexte : #{project_context}
      Score global : #{total}/10 (#{label_for(total)})

      Détail des indicateurs :
      #{indicators_text}

      Génère EXACTEMENT 3 recommandations concrètes et actionnables pour améliorer ce projet.
      Format strict (une recommandation par ligne, préfixée d'un emoji pertinent) :
      ACTION 1: [conseil court et précis, max 15 mots]
      ACTION 2: [conseil court et précis, max 15 mots]
      ACTION 3: [conseil court et précis, max 15 mots]

      Réponds UNIQUEMENT avec les 3 lignes, sans introduction ni conclusion.
      Langue : français.
    PROMPT
  end

  def parse_recommendations(text)
    lines = text.split("\n").map(&:strip).reject(&:blank?)
    recs  = lines.select { |l| l.match?(/^ACTION\s*\d+\s*:/i) || l.match?(/^[🔴🟡🟢⚠️✅📋💡🔧📅💰📊🏗️]/) }

    recs = recs.map { |l| l.sub(/^ACTION\s*\d+\s*:\s*/i, '').strip }
    recs = recs.first(3)

    recs.empty? ? default_recommendations_from_text(text) : recs
  end

  def default_recommendations_from_text(text)
    lines = text.split("\n").map(&:strip).reject(&:blank?)
    lines.first(3).presence || default_recommendations(5.0)
  end

  def default_recommendations(total)
    if total >= 9
      [
        '✅ Excellent ! Maintenez la cadence et documentez les finitions',
        '📋 Préparez le dossier de clôture de chantier en avance',
        '🏗️ Planifiez les réceptions de chantier avec vos prestataires'
      ]
    elsif total >= 8
      [
        '📊 Vérifiez régulièrement l\'avancement vs le planning initial',
        '💰 Contrôlez les factures entrantes par rapport au devis',
        '📋 Complétez la documentation manquante sans tarder'
      ]
    elsif total >= 6
      [
        '⚠️ Réunion de suivi urgente avec l\'entrepreneur principal',
        '💰 Révisez le budget prévisionnel face aux dépassements constatés',
        '📋 Mettez à jour les documents de suivi immédiatement'
      ]
    else
      [
        '🔴 Intervention immédiate — contactez votre coordinateur de chantier',
        '💰 Audit budgétaire urgent — dépassements critiques à traiter',
        '📅 Renégociez les délais contractuels avec vos prestataires'
      ]
    end
  end

  # ─── Helpers ──────────────────────────────────────────────────────────────

  def grade_for(total)
    if total >= 9     then '🟢'
    elsif total >= 8  then '🟢'
    elsif total >= 6  then '🟡'
    else                   '🔴'
    end
  end

  def label_for(total)
    if total >= 9     then 'Excellent'
    elsif total >= 8  then 'Bon'
    elsif total >= 6  then 'Attention'
    else                   'Intervention urgente'
    end
  end

  def format_amount(amount)
    "#{amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse} €"
  end

  def format_percent(ratio)
    "#{(ratio * 100).round(1)}%"
  end
end

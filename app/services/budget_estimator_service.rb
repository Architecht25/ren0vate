# Service d'estimation budgétaire basé sur les données du bien
# Analyse : PEB, année de construction, surface habitable, région, description travaux
# Retourne des suggestions de travaux avec quantités pré-estimées et justifications
class BudgetEstimatorService
  # Surface de repli quand surface_habitable n'est pas renseignée
  FALLBACK_SURFACE = 100.0

  def initialize(property, type_travaux: nil)
    @property    = property
    @type_travaux = type_travaux.to_s
  end

  # @return [Hash] { suggestions:, confidence:, summary: }
  def call
    suggestions = {}

    apply_peb_rules(suggestions)
    apply_age_rules(suggestions)
    apply_description_rules(suggestions)

    {
      suggestions: suggestions.map { |key, attrs| { work_type_key: key }.merge(attrs) },
      confidence:  compute_confidence,
      summary:     build_summary,
      narrative:   build_narrative,
      data_used:   data_points_used
    }
  end

  private

  # ── Données source ──────────────────────────────────────────────────────────

  def peb_donnee
    @peb_donnee ||= @property.peb_donnees
                             .where(phase: 'avant_travaux')
                             .order(created_at: :desc)
                             .first
  end

  def surface
    @surface ||= begin
      s = [peb_donnee&.surface_reference.to_f,
           @property.surface_habitable.to_i.to_f,
           @property.surface_habitable_wallonie.to_i.to_f,
           @property.surface_totale.to_i.to_f].find { |v| v > 0 }
      s || FALLBACK_SURFACE
    end
  end

  def surface_provided?
    [peb_donnee&.surface_reference,
     @property.surface_habitable,
     @property.surface_habitable_wallonie,
     @property.surface_totale].any? { |v| v.to_f > 0 }
  end

  def peb
    @peb ||= begin
      # Priorité 1 : peb_donnees scanné (label_peb = "C", "F", etc.)
      raw = peb_donnee&.label_peb.to_s.strip
      # Priorité 2 : champ régional certificat_peb_xxx
      raw = @property.peb_certificate_value.to_s.strip if raw.blank?
      # Priorité 3 : champ générique peb
      raw = @property.peb.to_s.strip if raw.blank?
      raw.upcase.match(/([A-G][+]*)/i)&.captures&.first.to_s
    end
  end

  def year
    @year ||= @property.annee_construction.to_i
  end

  def region
    @region ||= @property.region.to_s.downcase
  end

  def description
    @description ||= @type_travaux.downcase
  end

  # ── Règles PEB ──────────────────────────────────────────────────────────────

  def apply_peb_rules(s)
    return if peb.blank?

    case peb
    when 'F', 'G'
      # Enveloppe complète prioritaire
      add(s, 'isolation_toiture',     roof_surface,        "PEB #{peb} — isolation toiture urgente")
      add(s, 'isolation_murs_ext',    wall_surface,        "PEB #{peb} — murs extérieurs non isolés")
      add(s, 'chassis_pvc',           window_surface,      "PEB #{peb} — remplacement châssis prioritaire")
      add(s, 'pompe_chaleur_air_eau', 1,                   "PEB #{peb} — remplacement système chauffage recommandé")
      add(s, 'ventilation_double_flux', 1,                 "PEB #{peb} — VMC obligatoire après isolation complète")
    when 'E'
      add(s, 'isolation_toiture',     roof_surface,        "PEB E — isolation toiture prioritaire")
      add(s, 'chassis_pvc',           window_surface,      "PEB E — châssis à renouveler")
      add(s, 'ventilation_double_flux', 1,                 "PEB E — ventilation conseillée")
    when 'D'
      add(s, 'chassis_pvc',           window_surface,      "PEB D — amélioration châssis recommandée") if year < 1995
      add(s, 'ventilation_double_flux', 1,                 "PEB D — VMC conseillée")
    when 'A+', 'A', 'B', 'C'
      add(s, 'panneaux_solaires',           solar_kwc,  "Bon PEB — optimiser avec production solaire PV")
      add(s, 'chauffe_eau_thermodynamique', 1,           "Bon PEB — eau chaude thermodynamique recommandée")
    end
  end

  # ── Règles ancienneté ───────────────────────────────────────────────────────

  def apply_age_rules(s)
    return if year == 0

    if year < 1945
      add_unless_present(s, 'electricite_conformite', 1, "Bâtiment avant 1945 — mise en conformité électrique probable")
      add_unless_present(s, 'plomberie_renovation',   1, "Bâtiment avant 1945 — réseau plomberie à vérifier")
    elsif year < 1971
      add_unless_present(s, 'electricite_conformite', 1, "Construction #{year} — mise en conformité électrique probable")
      add_unless_present(s, 'plomberie_renovation',   1, "Construction #{year} — réseau plomberie à vérifier")
    elsif year < 1985
      add_unless_present(s, 'electricite_conformite', 1, "Construction #{year} — vérifier conformité électrique")
    end
  end

  # ── Règles description travaux ──────────────────────────────────────────────

  def apply_description_rules(s)
    return if description.blank?

    # Pièces
    add_unless_present(s, 'cuisine_renovation', 1, "Décrit : cuisine")                             if description.match?(/cuisine/)
    add_unless_present(s, 'salle_de_bain',      1, "Décrit : salle de bain")                       if description.match?(/salle.{0,5}bain|sdb/)

    # Enveloppe
    if description.match?(/toiture|toit|couverture|ardoise|tuile|zinc/)
      if s.key?('isolation_toiture')
        add_unless_present(s, 'toiture_remplacement', roof_surface, "Décrit : remplacement toiture")
      else
        add_unless_present(s, 'isolation_toiture', roof_surface, "Décrit : travaux de toiture")
      end
    end
    add_unless_present(s, 'charpente_renovation', 1, "Décrit : charpente")                         if description.match?(/charpente|ferme|bois.*toit/)
    add_unless_present(s, 'chassis_pvc', window_surface, "Décrit : châssis/fenêtres")             if description.match?(/ch[aâ]ssis|fen[eê]tre|vitrage|double.{0,4}vitrage|baie.{0,6}vitr/)
    add_unless_present(s, 'velux', 1, "Décrit : fenêtre de toiture")                              if description.match?(/velux|fen.{0,4}toiture|lumière.*toit/)
    add_unless_present(s, 'isolation_toiture',    roof_surface,   "Décrit : isolation")            if description.match?(/isolation/) && !s.key?('isolation_toiture')
    add_unless_present(s, 'isolation_murs_ext',   wall_surface,   "Décrit : isolation murs")       if description.match?(/isolation.*mur|mur.*isolat|façade.*isolation/)

    # Énergie
    add_unless_present(s, 'pompe_chaleur_air_eau',    1,          "Décrit : chauffage/pompe à chaleur") if description.match?(/pompe.{0,6}chaleur|pac\b|chauffage/)
    add_unless_present(s, 'plancher_chauffant',       floor_surface, "Décrit : plancher chauffant")   if description.match?(/plancher.{0,6}chauf|chauffage.{0,6}sol/)
    add_unless_present(s, 'radiateurs_remplacement',  1,          "Décrit : radiateurs")              if description.match?(/radiateur/)
    add_unless_present(s, 'panneaux_solaires',        solar_kwc,  "Décrit : panneaux solaires")         if description.match?(/panneau|solaire|photovolta/)
    add_unless_present(s, 'ventilation_double_flux',  1,          "Décrit : ventilation")               if description.match?(/ventilation|vmc/)

    # Technique
    add_unless_present(s, 'electricite_conformite', 1, "Décrit : électricité")                     if description.match?(/[eé]lectricit[eé]|[eé]lectrique|tableau.*[eé]lec/)
    add_unless_present(s, 'plomberie_renovation',   1, "Décrit : plomberie")                       if description.match?(/plomberie|tuyau|canalisation/)
    add_unless_present(s, 'desamiantage',           1, "Décrit : amiante")                          if description.match?(/amiant/)
    add_unless_present(s, 'citerne_mazout_retrait', 1, "Décrit : citerne mazout")                   if description.match?(/citerne|mazout|fioul|fuel/)
    add_unless_present(s, 'detection_incendie',     1, "Décrit : sécurité incendie")                if description.match?(/detect.{0,4}incendie|détecteur|alarme.{0,6}fum/)
    # Sols & intérieur
    add_unless_present(s, 'parquet',      floor_surface, "Décrit : parquet/plancher") if description.match?(/parquet|plancher.*bois/)
    add_unless_present(s, 'carrelage_sol', floor_surface, "Décrit : carrelage")       if description.match?(/carrelage/)
    add_unless_present(s, 'peinture_int',  paint_surface, "Décrit : peinture")        if description.match?(/peinture|repeindre/)
    add_unless_present(s, 'sous_sol_assechement', 1, "Décrit : sous-sol/humidité")    if description.match?(/sous.{0,4}sol|cave|humidit/)
    add_unless_present(s, 'collecte_eaux_pluie',  1, "Décrit : récupération eau")     if description.match?(/eau.{0,6}pluie|citerne|r[eé]cup/)
  end

  # ── Helpers quantités ───────────────────────────────────────────────────────

  def roof_surface
    [(surface * 1.1).round, surface_provided? ? 20 : 40].max
  end

  def wall_surface
    [(surface * 0.9).round, surface_provided? ? 20 : 60].max
  end

  def window_surface
    [(surface * 0.12).round(1), 5.0].max
  end

  def floor_surface
    [(surface * 0.7).round, surface_provided? ? 10 : 40].max
  end

  def paint_surface
    [(surface * 2.5).round, surface_provided? ? 20 : 100].max
  end

  def solar_kwc
    [(surface / 12.0).round(1), 2.5].max
  end

  # ── Helpers suggestions ─────────────────────────────────────────────────────

  def add(s, key, quantity, reason)
    s[key] = { quantity: quantity, reason: reason }
  end

  def add_unless_present(s, key, quantity, reason)
    s[key] ||= { quantity: quantity, reason: reason }
  end

  # ── Confiance & résumé ──────────────────────────────────────────────────────

  def data_points_used
    pts = []
    pts << "PEB #{peb}" if peb.present?
    pts << "construction #{year}" if year > 0
    surf_val = [peb_donnee&.surface_reference.to_f,
                @property.surface_habitable.to_i.to_f,
                @property.surface_habitable_wallonie.to_i.to_f,
                @property.surface_totale.to_i.to_f].find { |v| v > 0 }
    pts << "#{surf_val&.to_i || "~#{FALLBACK_SURFACE.to_i}"} m²"
    pts << "région #{@property.region}" if region.present?
    pts << "description travaux" if description.present?
    pts
  end

  def compute_confidence
    score = 0
    score += 2 if peb.present?
    score += 1 if year > 0
    score += 1 if surface_provided?
    score += 1 if description.present?

    case score
    when 4..10 then 'high'
    when 2..3  then 'medium'
    else            'low'
    end
  end

  def build_summary
    pts = data_points_used
    if pts.any?
      "Base d'analyse : #{pts.join(' · ')}."
    else
      "Données insuffisantes. Complétez le PEB, l'année de construction et la surface habitable."
    end
  end
  def build_narrative
    parts = []

    # Diagnostic bien
    if peb.present?
      age_str  = year > 0 ? " construit en #{year}" : ""
      surf_str = surface_provided? ? " sur #{surface.to_i} m²" : ""
      peb_desc = case peb
      when 'G'       then "une performance énergétique très déficiente — parmi les moins efficaces du parc belge"
      when 'F'       then "une performance déficiente, typique des bâtiments non isolés"
      when 'E'       then "une performance insuffisante avec des pertes thermiques importantes"
      when 'D'       then "une performance modérée, en dessous des standards actuels"
      when 'C'       then "un niveau intermédiaire correct, mais améliorable"
      when 'B'       then "une bonne performance énergétique"
      when 'A', 'A+' then "d'excellentes performances énergétiques"
      else                "un niveau à améliorer"
      end
      parts << "Votre bien#{age_str} affiche un PEB #{peb}#{surf_str} — #{peb_desc}."
    elsif year > 0
      parts << "Votre bien a été construit en #{year}."
    end

    # Recommandation selon PEB
    case peb
    when 'F', 'G'
      parts << "Une rénovation complète de l'enveloppe thermique est prioritaire : isolation toiture, murs extérieurs, remplacement des châssis et modernisation du chauffage sont incontournables pour atteindre les objectifs de rénovation 2050."
    when 'E'
      parts << "Les priorités sont l'isolation de la toiture et le renouvellement des châssis. L'ajout d'une ventilation double flux est fortement conseillé après isolation."
    when 'D'
      parts << "Des améliorations ciblées sur les châssis et la ventilation permettront de progresser. Un audit énergétique précisera les priorités."
    when 'C'
      parts << "Avec un PEB C, le potentiel d'amélioration passe surtout par la production d'énergie renouvelable (solaire, chauffe-eau thermodynamique) et l'optimisation du chauffage de l'eau."
    when 'A+', 'A', 'B'
      parts << "Votre bâtiment est déjà très performant. Les améliorations portent sur les équipements (solaire, domotique) plutôt que sur l'enveloppe."
    end

    # Ancienneté
    if year > 0 && year < 1971
      parts << "L'ancienneté du bâtiment rend très probable une mise en conformité électrique et une rénovation du réseau de plomberie."
    elsif year > 0 && year < 1985
      parts << "La date de construction suggère de vérifier la conformité électrique."
    end

    # Description travaux
    if description.present?
      detected = []
      detected << "châssis/fenêtres" if description.match?(/ch[aâ]ssis|fen[eê]tre|vitrage|baie.{0,6}vitr/)
      detected << "toiture"           if description.match?(/toiture|toit|couverture/)
      detected << "chauffage"         if description.match?(/chauffage|pompe|chaleur/)
      detected << "salle de bain"     if description.match?(/salle.{0,5}bain|sdb/)
      detected << "cuisine"           if description.match?(/cuisine/)
      detected << "isolation"         if description.match?(/isolation/)
      detected << "électricité"      if description.match?(/[ée]lectricit/)
      parts << "D'après votre description, les travaux mentionnés concernent : #{detected.join(', ')}." if detected.any?
    end

    # Note régionale primes
    if region.present?
      note = case region
      when 'wallonie'   then "En Wallonie, les primes Habitation (isolation, chauffage, audit) peuvent couvrir jusqu'à 70 % des travaux selon vos revenus."
      when 'bruxelles'  then "À Bruxelles, les primes Bruxelles-Rénovation sont cumulables avec le prêt vert à taux zéro de Bruxelles Environnement."
      when 'flandre'    then "En Flandre, le Mijn VerbouwPremie et le Mijn VerbouwLening permettent de financer une large partie des travaux de rénovation."
      end
      parts << note if note
    end

    parts.join(" ")
  end
end

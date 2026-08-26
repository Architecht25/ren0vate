class AuditEnergDonnee < ApplicationRecord
  belongs_to :document, optional: true
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :project,  optional: true

  LABELS_VALIDES = %w[A++ A+ A B C D E F G].freeze

  # Catégories d'alertes non-énergétiques qui bloquent toute demande de prime
  # tant qu'elles ne sont pas conformes (cf. CLAUDE.md — "préalable obligatoire").
  # Le radon, l'évacuation des eaux, etc. sont des recommandations mais ne
  # bloquent pas administrativement la prime.
  CATEGORIES_ALERTES_BLOQUANTES = %w[installation_electrique].freeze

  validates :label_initial, inclusion: { in: LABELS_VALIDES }, allow_blank: true
  validates :label_final,   inclusion: { in: LABELS_VALIDES }, allow_blank: true

  scope :recents,  -> { order(created_at: :desc) }
  scope :valides,  -> { where(extraction_complete: true) }
  scope :via_claude, -> { where(source_extraction: 'claude') }

  # ── Couleurs Bootstrap pour les labels ──────────────────────────────────────
  COULEURS_LABEL = {
    'A++' => 'success', 'A+' => 'success', 'A' => 'success',
    'B'   => 'info',
    'C'   => 'primary',
    'D'   => 'warning',
    'E'   => 'warning',
    'F'   => 'danger',
    'G'   => 'danger'
  }.freeze

  def couleur_label_initial
    COULEURS_LABEL.fetch(label_initial&.upcase, 'secondary')
  end

  def couleur_label_final
    COULEURS_LABEL.fetch(label_final&.upcase, 'secondary')
  end

  # ── Regroupement des recommandations par corps de métier (lisibilité) ────────
  # Ordre d'affichage : enveloppe d'abord (là où sont les plus gros postes),
  # puis systèmes, puis le reste.
  TYPE_ELEMENT_ORDRE = %w[
    toiture mur plancher etancheite menuiserie
    chauffage ecs ventilation photovoltaique non_energetique
  ].freeze

  TYPE_ELEMENT_LABELS = {
    'toiture'         => 'Toiture',
    'mur'             => 'Murs',
    'plancher'        => 'Plancher / sol',
    'etancheite'      => "Étanchéité à l'air",
    'menuiserie'      => 'Fenêtres & portes',
    'chauffage'       => 'Chauffage',
    'ecs'             => 'Eau chaude sanitaire',
    'ventilation'     => 'Ventilation',
    'photovoltaique'  => 'Panneaux solaires',
    'non_energetique' => 'Sécurité & administratif'
  }.freeze

  TYPE_ELEMENT_ICONS = {
    'toiture'         => 'bi-house-up',
    'mur'             => 'bi-bricks',
    'plancher'        => 'bi-layers',
    'etancheite'      => 'bi-shield-check',
    'menuiserie'      => 'bi-window',
    'chauffage'       => 'bi-thermometer-half',
    'ecs'             => 'bi-droplet-half',
    'ventilation'     => 'bi-wind',
    'photovoltaique'  => 'bi-sun',
    'non_energetique' => 'bi-exclamation-circle'
  }.freeze

  def self.type_element_label(type)
    TYPE_ELEMENT_LABELS.fetch(type.to_s, 'Autres travaux')
  end

  def self.type_element_icon(type)
    TYPE_ELEMENT_ICONS.fetch(type.to_s, 'bi-tools')
  end

  def self.type_element_ordre_index(type)
    TYPE_ELEMENT_ORDRE.index(type.to_s) || TYPE_ELEMENT_ORDRE.size
  end

  # ── Préfixes de référence Audit Logement (T, M, P, F, CC, ECS…) ──────────────
  # Ces codes sont ceux imprimés par le logiciel Walloreno à côté de chaque
  # paroi/système ("T1" = toiture n°1, "ECS1" = 1ère installation d'eau chaude…).
  # Ils sont peu explicites pour un non-initié — on les fait pointer vers un
  # libellé clair + une icône, affichés en infobulle sur le badge de référence.
  REFERENCE_PREFIXES = {
    'T'   => ['Toiture',               'bi-house-up'],
    'M'   => ['Mur',                   'bi-bricks'],
    'P'   => ['Plancher / sol',        'bi-layers'],
    'F'   => ['Fenêtre ou porte',      'bi-window'],
    'CC'  => ['Chauffage central',     'bi-thermometer-half'],
    'ECS' => ['Eau chaude sanitaire',  'bi-droplet-half'],
    'CN'  => ['Appareil à combustion', 'bi-fire'],
    'PV'  => ['Panneaux solaires',     'bi-sun']
  }.freeze

  def self.reco_reference_prefix_info(reco)
    return nil unless reco_reference_affichable?(reco)
    prefixe = reco[:reference].to_s[/\A[A-Za-z]+/].to_s.upcase
    REFERENCE_PREFIXES[prefixe]
  end

  # Libellé clair du préfixe (ex: "T1" → "Toiture"), ou à défaut le libellé du
  # corps de métier extrait par Claude — pour l'infobulle du badge de référence.
  def self.reco_reference_label(reco)
    info = reco_reference_prefix_info(reco)
    info ? info[0] : type_element_label(reco[:type_element])
  end

  def self.reco_reference_icon(reco)
    info = reco_reference_prefix_info(reco)
    info ? info[1] : type_element_icon(reco[:type_element])
  end

  # ── Lecture tolérante d'une ligne de recommandation ──────────────────────────
  # Les audits extraits avant la bascule vers Claude utilisent l'ancien schéma
  # regex (recommandation/label_avant/label_apres) ; ceux extraits via Claude
  # utilisent description/performance_avant/performance_apres/type_element.
  # Ces helpers lisent l'un ou l'autre pour ne pas casser l'affichage des
  # anciens audits déjà en base.
  def self.reco_titre(reco)
    (reco[:description] || reco[:recommandation]).to_s
  end

  def self.reco_avant(reco)
    reco[:performance_avant] || reco[:label_avant]
  end

  def self.reco_apres(reco)
    reco[:performance_apres] || reco[:label_apres]
  end

  # Un "reference" n'est affiché que s'il ressemble à un vrai code technique
  # imprimé sur le rapport (T1, F8, CC, ECS1…) — évite d'afficher un mot mal
  # extrait (ex: "Aération") comme s'il s'agissait d'un code de paroi/système.
  def self.reco_reference_affichable?(reco)
    ref = reco[:reference].to_s
    ref.present? && ref.length <= 8 && ref.match?(/\A[A-Za-z]{1,6}\d*(\.\d+)?\z/)
  end

  def self.reco_reste_a_charge(reco)
    cout = reco[:cout_estime_euro].to_f
    return nil if cout.zero?
    (cout - reco[:subsides_euro].to_f).round(2)
  end

  # ── Accesseurs sur les recommandations ──────────────────────────────────────
  # Retourne Array<HashWithIndifferentAccess> depuis le JSONB
  def recommandations
    (recommandations_json || []).map(&:with_indifferent_access)
  end

  def recommandations_bouquet(numero)
    recommandations.select { |r| r[:bouquet].to_i == numero.to_i }
  end

  def bouquets
    recommandations.map { |r| r[:bouquet].to_i }.uniq.sort
  end

  # ── Bilan global ─────────────────────────────────────────────────────────────
  # Le bilan legacy (regex) reste lisible via `bilan` ; le bilan Claude est plus
  # fiable et vit dans les colonnes dédiées (cout_total_scenario, etc.) — ces
  # accesseurs retombent sur l'un ou l'autre pour ne pas casser les vues existantes.
  def bilan
    (bilan_json || {}).with_indifferent_access
  end

  def cout_total_estime
    cout_total_scenario || bilan[:cout_total].to_i
  end

  def primes_total
    subsides_total_scenario || bilan[:subsides_total].to_i
  end

  def gain_annuel_total
    economie_annuelle_scenario || bilan[:economie_an].to_i
  end

  def temps_retour_global
    temps_retour_scenario.presence || bilan[:temps_retour]
  end

  # Montant net qu'il resterait à financer sur le scénario complet une fois les
  # primes déduites — donnée d'entrée directe pour le simulateur de prêt à 0%.
  def montant_net_a_financer
    return nil if cout_total_estime.to_f.zero?
    (cout_total_estime.to_f - primes_total.to_f).round(2)
  end

  # ── Performance détaillée (Claude) — pages 13 & 45 ───────────────────────────
  def performance(etat = :initiale)
    (performance_json || {}).with_indifferent_access[etat.to_s] || {}
  end

  def peb_projection
    (peb_projection_json || {}).with_indifferent_access
  end

  # ── Feuille de route par étapes (Claude) — page 1 ────────────────────────────
  def etapes
    (etapes_json || []).map(&:with_indifferent_access)
  end

  # Première étape non encore atteinte (label cible différent du label actuel),
  # triée par numéro — c'est le prochain palier à financer/planifier.
  def prochaine_etape
    etapes.sort_by { |e| e[:numero].to_i }.find { |e| e[:label_cible].present? && e[:label_cible] != label_initial }
  end

  # Étape de la feuille de route qui regroupe un bouquet donné — un même
  # bouquet peut n'appartenir qu'à une seule étape, mais une étape (le label
  # atteint) résulte de TOUS les bouquets qui y sont associés cumulés depuis
  # le début (coûts/primes cumulés — cf. page "feuille de route" du rapport).
  def etape_pour_bouquet(numero_bouquet)
    etapes.sort_by { |e| e[:numero].to_i }
          .find { |e| Array(e[:bouquets]).map(&:to_i).include?(numero_bouquet.to_i) }
  end

  # Label duquel on part pour atteindre cette étape : celui de l'étape
  # précédente dans la feuille de route, ou le label initial du logement pour
  # la toute première étape.
  def label_avant_etape(etape)
    return label_initial unless etape
    etapes_triees = etapes.sort_by { |e| e[:numero].to_i }
    idx = etapes_triees.find_index { |e| e[:numero].to_i == etape[:numero].to_i }
    return label_initial if idx.nil? || idx.zero?
    etapes_triees[idx - 1][:label_cible]
  end

  # Montant net à financer pour atteindre une étape donnée (coût cumulé - primes cumulées).
  def montant_net_etape(etape)
    return nil unless etape
    cout = etape[:cout_cumule_euro].to_f
    return nil if cout.zero?
    (cout - etape[:primes_cumule_euro].to_f).round(2)
  end

  # ── Alertes non-énergétiques (Claude) — pages 9, 17, 19, 39-42 ───────────────
  def alertes
    (alertes_json || []).map(&:with_indifferent_access)
  end

  def alertes_non_conformes
    alertes.select { |a| a[:conforme] == false }
  end

  # Alertes qui bloquent administrativement toute demande de prime tant
  # qu'elles ne sont pas levées (cf. CATEGORIES_ALERTES_BLOQUANTES).
  def alertes_bloquantes
    alertes_non_conformes.select { |a| CATEGORIES_ALERTES_BLOQUANTES.include?(a[:categorie].to_s) }
  end

  # ── Trajectoire Label A 2050 ──────────────────────────────────────────────────
  # Nombre de paliers séparant le label actuel du label A décarboné (0 = déjà au
  # niveau A ou meilleur). LABELS_VALIDES est ordonné du meilleur (A++) au pire
  # (G) : passer de C à A signifie DESCENDRE dans cet index, d'où idx_label - idx_a.
  def distance_label_a(label = label_initial)
    idx_label = LABELS_VALIDES.index(label)
    idx_a     = LABELS_VALIDES.index('A')
    return nil unless idx_label && idx_a
    [idx_label - idx_a, 0].max
  end

  # ── Présentation ─────────────────────────────────────────────────────────────
  def titre_court
    return "Audit #{numero_audit}" if numero_audit.present?
    "Audit énergétique du #{date_enregistrement&.strftime('%d/%m/%Y')}"
  end

  def auditeur_complet
    parts = [denomination_auditeur, numero_pae]
    parts.compact_blank.join(' — ')
  end

  def perime?
    # La date de validité affichée sur le rapport prime toujours sur l'heuristique
    # 10 ans — un Audit Logement PAE2 peut être valable 7, 8 ou 10 ans selon le type.
    return valable_jusquau < Time.zone.today if valable_jusquau
    return false unless date_enregistrement
    date_enregistrement < 10.years.ago.to_date
  end

  def nombre_recommandations
    recommandations.size
  end

  def nombre_bouquets
    bouquets.size
  end

  def extrait_via_claude?
    source_extraction == 'claude'
  end
end

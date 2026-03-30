class WorkType
  # Catégories pour regroupement dans l'UI
  CATEGORIES = {
    'toiture'   => 'Toiture',
    'murs'      => 'Murs & Façades',
    'ouvertures'=> 'Châssis & Ouvertures',
    'sol'       => 'Sol & Structure',
    'energie'   => 'Énergie & Chauffage',
    'pieces'    => 'Pièces de vie',
    'technique' => 'Technique'
  }.freeze

  CATALOGUE = [
    # ── TOITURE ──────────────────────────────────────────────────────────────
    {
      key: 'isolation_toiture',
      category: 'toiture',
      name: 'Isolation de toiture',
      icon: 'bi-house-fill',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 45,
      price_max: 75,
      duration_min: 3,
      duration_max: 7,
      vat_rate: 6
    },
    {
      key: 'toiture_remplacement',
      category: 'toiture',
      name: 'Remplacement toiture (tuiles/ardoises)',
      icon: 'bi-house-door',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 80,
      price_max: 160,
      duration_min: 5,
      duration_max: 12,
      vat_rate: 6
    },
    {
      key: 'charpente_renovation',
      category: 'toiture',
      name: 'Rénovation charpente (structure bois)',
      icon: 'bi-tools',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 5_000,
      price_max: 20_000,
      duration_min: 5,
      duration_max: 15,
      vat_rate: 6
    },
    {
      key: 'couverture_toiture',
      category: 'toiture',
      name: 'Couverture toiture (zinc/tuiles/ardoises)',
      icon: 'bi-house-up',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 60,
      price_max: 130,
      duration_min: 3,
      duration_max: 10,
      vat_rate: 6
    },
    {
      key: 'etancheite_toiture',
      category: 'toiture',
      name: 'Étanchéité toiture plate',
      icon: 'bi-shield-check',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 50,
      price_max: 120,
      duration_min: 2,
      duration_max: 6,
      vat_rate: 6
    },
    {
      key: 'collecte_eaux_pluie',
      category: 'toiture',
      name: 'Collecte eaux de pluie (citerne + réseau)',
      icon: 'bi-droplet-fill',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 3_000,
      price_max: 8_000,
      duration_min: 2,
      duration_max: 5,
      vat_rate: 6
    },

    # ── MURS & FAÇADES ───────────────────────────────────────────────────────
    {
      key: 'isolation_murs_ext',
      category: 'murs',
      name: 'Isolation murs extérieurs',
      icon: 'bi-bricks',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 80,
      price_max: 140,
      duration_min: 5,
      duration_max: 10,
      vat_rate: 6
    },
    {
      key: 'isolation_murs_int',
      category: 'murs',
      name: 'Isolation murs intérieurs',
      icon: 'bi-bricks',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 40,
      price_max: 90,
      duration_min: 3,
      duration_max: 8,
      vat_rate: 6
    },
    {
      key: 'isolation_murs_coulisse',
      category: 'murs',
      name: 'Isolation murs en coulisse (injection)',
      icon: 'bi-bricks',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 15,
      price_max: 35,
      duration_min: 1,
      duration_max: 3,
      vat_rate: 6
    },
    {
      key: 'enduit_murs_ext',
      category: 'murs',
      name: 'Enduit murs extérieurs (crépi/minéral)',
      icon: 'bi-brush',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 25,
      price_max: 60,
      duration_min: 3,
      duration_max: 8,
      vat_rate: 6
    },
    {
      key: 'enduit_murs_int',
      category: 'murs',
      name: 'Enduit murs intérieurs (plâtre/lissage)',
      icon: 'bi-brush-fill',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 15,
      price_max: 40,
      duration_min: 2,
      duration_max: 6,
      vat_rate: 6
    },
    {
      key: 'facade_ravalement',
      category: 'murs',
      name: 'Ravalement de façade',
      icon: 'bi-house-facade',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 40,
      price_max: 90,
      duration_min: 3,
      duration_max: 8,
      vat_rate: 6
    },

    # ── CHÂSSIS & OUVERTURES ─────────────────────────────────────────────────
    {
      key: 'chassis_remplacement',
      category: 'ouvertures',
      name: 'Remplacement châssis (PVC/ALU)',
      icon: 'bi-window',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 450,
      price_max: 900,
      duration_min: 3,
      duration_max: 6,
      vat_rate: 6
    },
    {
      key: 'porte_entree',
      category: 'ouvertures',
      name: 'Remplacement porte d\'entrée',
      icon: 'bi-door-open',
      unit: 'forfait',
      unit_label: 'pièce',
      forfait: true,
      price_min: 1_500,
      price_max: 4_000,
      duration_min: 1,
      duration_max: 2,
      vat_rate: 6
    },

    # ── SOL & STRUCTURE ──────────────────────────────────────────────────────
    {
      key: 'isolation_plancher',
      category: 'sol',
      name: 'Isolation plancher / sous-sol',
      icon: 'bi-layers',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 25,
      price_max: 60,
      duration_min: 2,
      duration_max: 5,
      vat_rate: 6
    },
    {
      key: 'structure_sol',
      category: 'sol',
      name: 'Structure de sol (dalle/hourdis/plancher bois)',
      icon: 'bi-layers-fill',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 80,
      price_max: 180,
      duration_min: 5,
      duration_max: 15,
      vat_rate: 6
    },
    {
      key: 'carrelage_sol',
      category: 'sol',
      name: 'Carrelage sol (pose + matériaux)',
      icon: 'bi-grid',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 50,
      price_max: 110,
      duration_min: 3,
      duration_max: 7,
      vat_rate: 6
    },
    {
      key: 'parquet',
      category: 'sol',
      name: 'Parquet (pose + finition)',
      icon: 'bi-grid-3x3',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 40,
      price_max: 120,
      duration_min: 2,
      duration_max: 6,
      vat_rate: 6
    },
    {
      key: 'sous_sol_assechement',
      category: 'sol',
      name: 'Assèchement sous-sol / cave',
      icon: 'bi-moisture',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 5_000,
      price_max: 15_000,
      duration_min: 3,
      duration_max: 10,
      vat_rate: 21
    },

    # ── ÉNERGIE & CHAUFFAGE ──────────────────────────────────────────────────
    {
      key: 'pompe_chaleur_air_eau',
      category: 'energie',
      name: 'Pompe à chaleur air-eau',
      icon: 'bi-thermometer-half',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 8_000,
      price_max: 15_000,
      duration_min: 3,
      duration_max: 5,
      vat_rate: 6
    },
    {
      key: 'pompe_chaleur_air_air',
      category: 'energie',
      name: 'Pompe à chaleur air-air',
      icon: 'bi-wind',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 3_500,
      price_max: 8_000,
      duration_min: 2,
      duration_max: 4,
      vat_rate: 6
    },
    {
      key: 'chaudiere_condensation',
      category: 'energie',
      name: 'Chaudière gaz condensation',
      icon: 'bi-fire',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 2_500,
      price_max: 5_000,
      duration_min: 1,
      duration_max: 2,
      vat_rate: 6
    },
    {
      key: 'chauffe_eau_thermodynamique',
      category: 'energie',
      name: 'Chauffe-eau thermodynamique',
      icon: 'bi-water',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 1_800,
      price_max: 3_500,
      duration_min: 1,
      duration_max: 2,
      vat_rate: 6
    },
    {
      key: 'panneaux_solaires',
      category: 'energie',
      name: 'Panneaux solaires photovoltaïques',
      icon: 'bi-sun',
      unit: 'kWc',
      unit_label: 'kWc',
      forfait: false,
      price_min: 1_200,
      price_max: 1_800,
      duration_min: 2,
      duration_max: 4,
      vat_rate: 6
    },
    {
      key: 'batterie_stockage',
      category: 'energie',
      name: 'Batterie de stockage solaire',
      icon: 'bi-battery-charging',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 5_000,
      price_max: 12_000,
      duration_min: 1,
      duration_max: 2,
      vat_rate: 21
    },
    {
      key: 'ventilation_double_flux',
      category: 'energie',
      name: 'Ventilation double flux (VMC)',
      icon: 'bi-fan',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 4_000,
      price_max: 8_000,
      duration_min: 2,
      duration_max: 4,
      vat_rate: 6
    },
    {
      key: 'poele_pellets',
      category: 'energie',
      name: 'Poêle à pellets',
      icon: 'bi-tree',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 3_000,
      price_max: 7_000,
      duration_min: 1,
      duration_max: 2,
      vat_rate: 6
    },

    # ── PIÈCES DE VIE ────────────────────────────────────────────────────────
    {
      key: 'salle_de_bain',
      category: 'pieces',
      name: 'Salle de bain — rénovation complète',
      icon: 'bi-droplet',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 8_000,
      price_max: 20_000,
      duration_min: 7,
      duration_max: 14,
      vat_rate: 6
    },
    {
      key: 'cuisine_renovation',
      category: 'pieces',
      name: 'Cuisine — rénovation complète',
      icon: 'bi-cup-hot',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 8_000,
      price_max: 25_000,
      duration_min: 7,
      duration_max: 14,
      vat_rate: 6
    },
    {
      key: 'peinture_int',
      category: 'pieces',
      name: 'Peinture intérieure',
      icon: 'bi-paint-bucket',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 15,
      price_max: 35,
      duration_min: 2,
      duration_max: 7,
      vat_rate: 6
    },
    {
      key: 'faux_plafond',
      category: 'pieces',
      name: 'Faux plafond (placo/acoustique)',
      icon: 'bi-square',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 30,
      price_max: 70,
      duration_min: 2,
      duration_max: 5,
      vat_rate: 6
    },

    # ── TECHNIQUE ────────────────────────────────────────────────────────────
    {
      key: 'electricite_conformite',
      category: 'technique',
      name: 'Électricité — mise en conformité',
      icon: 'bi-lightning-charge',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 3_000,
      price_max: 8_000,
      duration_min: 3,
      duration_max: 7,
      vat_rate: 6
    },
    {
      key: 'plomberie_renovation',
      category: 'technique',
      name: 'Plomberie — rénovation réseau',
      icon: 'bi-pipe',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 3_000,
      price_max: 12_000,
      duration_min: 3,
      duration_max: 8,
      vat_rate: 6
    },
    {
      key: 'escalier_renovation',
      category: 'technique',
      name: 'Rénovation escalier (bois/métal)',
      icon: 'bi-staircase',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 2_000,
      price_max: 8_000,
      duration_min: 2,
      duration_max: 5,
      vat_rate: 6
    }
  ].freeze

  attr_reader :key, :category, :name, :icon, :unit, :unit_label, :forfait,
              :price_min, :price_max, :duration_min, :duration_max, :vat_rate

  def initialize(attrs)
    attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
  end

  def price_avg
    ((price_min + price_max) / 2.0).round(2)
  end

  def duration_avg
    ((duration_min + duration_max) / 2.0).round(1)
  end

  def forfait?
    @forfait
  end

  def self.all
    CATALOGUE.map { |attrs| new(attrs) }
  end

  def self.by_category
    all.group_by(&:category).transform_keys { |k| CATEGORIES[k] || k }
  end

  def self.find(key)
    attrs = CATALOGUE.find { |a| a[:key] == key.to_s }
    new(attrs) if attrs
  end
end

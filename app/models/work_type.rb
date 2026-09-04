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

  # Catalogue de référence — fourchettes de marché belge 2026
  CATALOGUE_BELGIQUE = [
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
      name: 'Remplacement toiture complet (charpente + isolation + couverture)',
      icon: 'bi-house-door',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 150,
      price_max: 300,
      duration_min: 10,
      duration_max: 20,
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
    {
      key: 'velux',
      category: 'toiture',
      name: 'Placement/remplacement de velux',
      icon: 'bi-window-fullscreen',
      unit: 'pièce',
      unit_label: 'pièce',
      forfait: false,
      price_min: 800,
      price_max: 2_500,
      duration_min: 1,
      duration_max: 2,
      vat_rate: 6
    },
    {
      key: 'echafaudage',
      category: 'toiture',
      name: 'Échafaudage (location + montage/démontage)',
      icon: 'bi-bounding-box',
      unit: 'forfait',
      unit_label: 'chantier',
      forfait: true,
      price_min: 800,
      price_max: 3_000,
      duration_min: 1,
      duration_max: 3,
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
      price_max: 25,
      duration_min: 2,
      duration_max: 6,
      vat_rate: 6
    },
    {
      key: 'plafonnage_facade',
      category: 'murs',
      name: 'Plafonnage de façade (ciment/chaux)',
      icon: 'bi-house-fill',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 40,
      price_max: 80,
      duration_min: 3,
      duration_max: 8,
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
      key: 'chassis_pvc',
      category: 'ouvertures',
      name: 'Châssis PVC (double/triple vitrage)',
      icon: 'bi-window',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 350,
      price_max: 650,
      duration_min: 2,
      duration_max: 5,
      vat_rate: 6
    },
    {
      key: 'chassis_alu',
      category: 'ouvertures',
      name: 'Châssis aluminium (double/triple vitrage)',
      icon: 'bi-window',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 700,
      price_max: 1_100,
      duration_min: 3,
      duration_max: 6,
      vat_rate: 6
    },
    {
      key: 'chassis_bois',
      category: 'ouvertures',
      name: 'Châssis bois (double/triple vitrage)',
      icon: 'bi-window',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 900,
      price_max: 1_600,
      duration_min: 3,
      duration_max: 7,
      vat_rate: 6
    },
    {
      key: 'store_isolant',
      category: 'ouvertures',
      name: 'Store extérieur isolant / brise-soleil',
      icon: 'bi-columns',
      unit: 'forfait',
      unit_label: 'pièce',
      forfait: true,
      price_min: 300,
      price_max: 1_750,
      duration_min: 1,
      duration_max: 2,
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
      key: 'plancher_chauffant',
      category: 'energie',
      name: 'Plancher chauffant (eau ou électrique)',
      icon: 'bi-grid-3x3-gap-fill',
      unit: 'm²',
      unit_label: 'm²',
      forfait: false,
      price_min: 50,
      price_max: 110,
      duration_min: 3,
      duration_max: 8,
      vat_rate: 6
    },
    {
      key: 'radiateurs_remplacement',
      category: 'energie',
      name: 'Remplacement radiateurs (acier/aluminium)',
      icon: 'bi-thermometer',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 2_000,
      price_max: 6_000,
      duration_min: 2,
      duration_max: 4,
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
    },
    {
      key: 'desamiantage',
      category: 'technique',
      name: 'Désamiantage (retrait amiante certifié)',
      icon: 'bi-exclamation-triangle-fill',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 3_000,
      price_max: 20_000,
      duration_min: 3,
      duration_max: 15,
      vat_rate: 21
    },
    {
      key: 'detection_incendie',
      category: 'technique',
      name: 'Détecteurs incendie/CO (obligations légales)',
      icon: 'bi-alarm',
      unit: 'forfait',
      unit_label: 'installation',
      forfait: true,
      price_min: 300,
      price_max: 1_500,
      duration_min: 1,
      duration_max: 1,
      vat_rate: 21
    },
    {
      key: 'citerne_mazout_retrait',
      category: 'technique',
      name: 'Retrait citerne à mazout (dépose + neutralisation)',
      icon: 'bi-droplet-slash',
      unit: 'forfait',
      unit_label: 'forfait',
      forfait: true,
      price_min: 1_500,
      price_max: 5_000,
      duration_min: 1,
      duration_max: 3,
      vat_rate: 21
    }
  ].freeze

  # Alias rétrocompatibilité — code existant référençant WorkType::CATALOGUE
  CATALOGUE = CATALOGUE_BELGIQUE

  # Catalogue de référence — fourchettes de marché espagnol 2026
  # Mêmes postes/unités/durées que la Belgique ; seuls les prix et le taux de TVA (IVA) diffèrent.
  # Prix calibrés à partir de sources de marché espagnol (aislamiento, ventanas, bomba de calor,
  # placas solares — sept. 2026) ; à ajuster au fil des retours terrain, ce ne sont pas des tarifs
  # d'entrepreneurs vérifiés poste par poste.
  # IVA réduit 10% pour travaux de rénovation résidentielle (équivalent de la TVA 6% belge),
  # IVA standard 21% pour les mêmes postes que ceux en 21% côté belge.
  CATALOGUE_ESPAGNE = [
    # ── TOITURE ──────────────────────────────────────────────────────────────
    { key: 'isolation_toiture',     category: 'toiture', name: 'Isolation de toiture', icon: 'bi-house-fill', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 35,   price_max: 60,    duration_min: 3,  duration_max: 7,  vat_rate: 10 },
    { key: 'toiture_remplacement',  category: 'toiture', name: 'Remplacement toiture complet (charpente + isolation + couverture)', icon: 'bi-house-door', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 120, price_max: 240, duration_min: 10, duration_max: 20, vat_rate: 10 },
    { key: 'charpente_renovation',  category: 'toiture', name: 'Rénovation charpente (structure bois)', icon: 'bi-tools', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 4_000, price_max: 16_000, duration_min: 5, duration_max: 15, vat_rate: 10 },
    { key: 'couverture_toiture',    category: 'toiture', name: 'Couverture toiture (zinc/tuiles/ardoises)', icon: 'bi-house-up', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 45,  price_max: 100,   duration_min: 3,  duration_max: 10, vat_rate: 10 },
    { key: 'etancheite_toiture',    category: 'toiture', name: 'Étanchéité toiture plate', icon: 'bi-shield-check', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 40, price_max: 95,     duration_min: 2,  duration_max: 6,  vat_rate: 10 },
    { key: 'collecte_eaux_pluie',   category: 'toiture', name: 'Collecte eaux de pluie (citerne + réseau)', icon: 'bi-droplet-fill', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 2_500, price_max: 6_500, duration_min: 2, duration_max: 5, vat_rate: 10 },
    { key: 'velux',                 category: 'toiture', name: 'Placement/remplacement de velux', icon: 'bi-window-fullscreen', unit: 'pièce', unit_label: 'pièce', forfait: false, price_min: 700, price_max: 2_200,  duration_min: 1,  duration_max: 2,  vat_rate: 10 },
    { key: 'echafaudage',           category: 'toiture', name: 'Échafaudage (location + montage/démontage)', icon: 'bi-bounding-box', unit: 'forfait', unit_label: 'chantier', forfait: true, price_min: 700, price_max: 2_500, duration_min: 1, duration_max: 3, vat_rate: 10 },

    # ── MURS & FAÇADES ───────────────────────────────────────────────────────
    { key: 'isolation_murs_ext',      category: 'murs', name: 'Isolation murs extérieurs', icon: 'bi-bricks', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 60, price_max: 120, duration_min: 5, duration_max: 10, vat_rate: 10 },
    { key: 'isolation_murs_int',      category: 'murs', name: 'Isolation murs intérieurs', icon: 'bi-bricks', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 30, price_max: 65,  duration_min: 3, duration_max: 8,  vat_rate: 10 },
    { key: 'isolation_murs_coulisse', category: 'murs', name: 'Isolation murs en coulisse (injection)', icon: 'bi-bricks', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 12, price_max: 28,  duration_min: 1, duration_max: 3,  vat_rate: 10 },
    { key: 'enduit_murs_ext',         category: 'murs', name: 'Enduit murs extérieurs (crépi/minéral)', icon: 'bi-brush', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 20, price_max: 48,  duration_min: 3, duration_max: 8,  vat_rate: 10 },
    { key: 'enduit_murs_int',         category: 'murs', name: 'Enduit murs intérieurs (plâtre/lissage)', icon: 'bi-brush-fill', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 12, price_max: 20, duration_min: 2, duration_max: 6, vat_rate: 10 },
    { key: 'plafonnage_facade',       category: 'murs', name: 'Plafonnage de façade (ciment/chaux)', icon: 'bi-house-fill', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 30, price_max: 64,   duration_min: 3, duration_max: 8, vat_rate: 10 },
    { key: 'facade_ravalement',       category: 'murs', name: 'Ravalement de façade', icon: 'bi-house-facade', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 30, price_max: 70,           duration_min: 3, duration_max: 8, vat_rate: 10 },

    # ── CHÂSSIS & OUVERTURES ─────────────────────────────────────────────────
    { key: 'chassis_pvc',   category: 'ouvertures', name: 'Châssis PVC (double/triple vitrage)', icon: 'bi-window', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 250, price_max: 550,  duration_min: 2, duration_max: 5, vat_rate: 10 },
    { key: 'chassis_alu',   category: 'ouvertures', name: 'Châssis aluminium (double/triple vitrage)', icon: 'bi-window', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 500, price_max: 900,  duration_min: 3, duration_max: 6, vat_rate: 10 },
    { key: 'chassis_bois',  category: 'ouvertures', name: 'Châssis bois (double/triple vitrage)', icon: 'bi-window', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 650, price_max: 1_300, duration_min: 3, duration_max: 7, vat_rate: 10 },
    { key: 'store_isolant', category: 'ouvertures', name: 'Store extérieur isolant / brise-soleil', icon: 'bi-columns', unit: 'forfait', unit_label: 'pièce', forfait: true, price_min: 250, price_max: 1_500, duration_min: 1, duration_max: 2, vat_rate: 10 },
    { key: 'porte_entree',  category: 'ouvertures', name: 'Remplacement porte d\'entrée', icon: 'bi-door-open', unit: 'forfait', unit_label: 'pièce', forfait: true, price_min: 1_100, price_max: 3_200, duration_min: 1, duration_max: 2, vat_rate: 10 },

    # ── SOL & STRUCTURE ──────────────────────────────────────────────────────
    { key: 'isolation_plancher',    category: 'sol', name: 'Isolation plancher / sous-sol', icon: 'bi-layers', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 20, price_max: 48,  duration_min: 2, duration_max: 5,  vat_rate: 10 },
    { key: 'structure_sol',         category: 'sol', name: 'Structure de sol (dalle/hourdis/plancher bois)', icon: 'bi-layers-fill', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 60, price_max: 145, duration_min: 5, duration_max: 15, vat_rate: 10 },
    { key: 'carrelage_sol',         category: 'sol', name: 'Carrelage sol (pose + matériaux)', icon: 'bi-grid', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 40, price_max: 90,   duration_min: 3, duration_max: 7,  vat_rate: 10 },
    { key: 'parquet',               category: 'sol', name: 'Parquet (pose + finition)', icon: 'bi-grid-3x3', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 32, price_max: 95,     duration_min: 2, duration_max: 6,  vat_rate: 10 },
    { key: 'sous_sol_assechement',  category: 'sol', name: 'Assèchement sous-sol / cave', icon: 'bi-moisture', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 4_000, price_max: 12_000, duration_min: 3, duration_max: 10, vat_rate: 21 },

    # ── ÉNERGIE & CHAUFFAGE ──────────────────────────────────────────────────
    { key: 'pompe_chaleur_air_eau',        category: 'energie', name: 'Pompe à chaleur air-eau', icon: 'bi-thermometer-half', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 5_000, price_max: 14_000, duration_min: 3, duration_max: 5, vat_rate: 10 },
    { key: 'pompe_chaleur_air_air',        category: 'energie', name: 'Pompe à chaleur air-air', icon: 'bi-wind', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 2_500, price_max: 6_500, duration_min: 2, duration_max: 4, vat_rate: 10 },
    { key: 'chaudiere_condensation',       category: 'energie', name: 'Chaudière gaz condensation', icon: 'bi-fire', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 2_000, price_max: 4_200, duration_min: 1, duration_max: 2, vat_rate: 10 },
    { key: 'chauffe_eau_thermodynamique',  category: 'energie', name: 'Chauffe-eau thermodynamique', icon: 'bi-water', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 1_400, price_max: 2_800, duration_min: 1, duration_max: 2, vat_rate: 10 },
    { key: 'plancher_chauffant',           category: 'energie', name: 'Plancher chauffant (eau ou électrique)', icon: 'bi-grid-3x3-gap-fill', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 40, price_max: 90, duration_min: 3, duration_max: 8, vat_rate: 10 },
    { key: 'radiateurs_remplacement',      category: 'energie', name: 'Remplacement radiateurs (acier/aluminium)', icon: 'bi-thermometer', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 1_500, price_max: 4_800, duration_min: 2, duration_max: 4, vat_rate: 10 },
    { key: 'panneaux_solaires',            category: 'energie', name: 'Panneaux solaires photovoltaïques', icon: 'bi-sun', unit: 'kWc', unit_label: 'kWc', forfait: false, price_min: 900, price_max: 1_400, duration_min: 2, duration_max: 4, vat_rate: 10 },
    { key: 'batterie_stockage',            category: 'energie', name: 'Batterie de stockage solaire', icon: 'bi-battery-charging', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 4_000, price_max: 9_500, duration_min: 1, duration_max: 2, vat_rate: 21 },
    { key: 'ventilation_double_flux',      category: 'energie', name: 'Ventilation double flux (VMC)', icon: 'bi-fan', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 3_200, price_max: 6_500, duration_min: 2, duration_max: 4, vat_rate: 10 },
    { key: 'poele_pellets',                category: 'energie', name: 'Poêle à pellets', icon: 'bi-tree', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 2_400, price_max: 5_600, duration_min: 1, duration_max: 2, vat_rate: 10 },

    # ── PIÈCES DE VIE ────────────────────────────────────────────────────────
    { key: 'salle_de_bain',      category: 'pieces', name: 'Salle de bain — rénovation complète', icon: 'bi-droplet', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 4_500, price_max: 13_000, duration_min: 7, duration_max: 14, vat_rate: 10 },
    { key: 'cuisine_renovation', category: 'pieces', name: 'Cuisine — rénovation complète', icon: 'bi-cup-hot', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 5_000, price_max: 15_000, duration_min: 7, duration_max: 14, vat_rate: 10 },
    { key: 'peinture_int',       category: 'pieces', name: 'Peinture intérieure', icon: 'bi-paint-bucket', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 8, price_max: 22, duration_min: 2, duration_max: 7, vat_rate: 10 },
    { key: 'faux_plafond',       category: 'pieces', name: 'Faux plafond (placo/acoustique)', icon: 'bi-square', unit: 'm²', unit_label: 'm²', forfait: false, price_min: 22, price_max: 55, duration_min: 2, duration_max: 5, vat_rate: 10 },

    # ── TECHNIQUE ────────────────────────────────────────────────────────────
    { key: 'electricite_conformite', category: 'technique', name: 'Électricité — mise en conformité', icon: 'bi-lightning-charge', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 2_200, price_max: 6_200, duration_min: 3, duration_max: 7, vat_rate: 10 },
    { key: 'plomberie_renovation',   category: 'technique', name: 'Plomberie — rénovation réseau', icon: 'bi-pipe', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 2_200, price_max: 9_000, duration_min: 3, duration_max: 8, vat_rate: 10 },
    { key: 'escalier_renovation',    category: 'technique', name: 'Rénovation escalier (bois/métal)', icon: 'bi-staircase', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 1_500, price_max: 6_200, duration_min: 2, duration_max: 5, vat_rate: 10 },
    { key: 'desamiantage',           category: 'technique', name: 'Désamiantage (retrait amiante certifié)', icon: 'bi-exclamation-triangle-fill', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 2_200, price_max: 15_000, duration_min: 3, duration_max: 15, vat_rate: 21 },
    { key: 'detection_incendie',     category: 'technique', name: 'Détecteurs incendie/CO (obligations légales)', icon: 'bi-alarm', unit: 'forfait', unit_label: 'installation', forfait: true, price_min: 250, price_max: 1_200, duration_min: 1, duration_max: 1, vat_rate: 21 },
    { key: 'citerne_mazout_retrait', category: 'technique', name: 'Retrait citerne à mazout (dépose + neutralisation)', icon: 'bi-droplet-slash', unit: 'forfait', unit_label: 'forfait', forfait: true, price_min: 1_200, price_max: 4_000, duration_min: 1, duration_max: 3, vat_rate: 21 }
  ].freeze

  # Sélection du catalogue par pays. Toute région belge (wallonie/flandre/bruxelles)
  # ou une région vide/inconnue retombe sur le catalogue belge par défaut.
  CATALOGUES = {
    'belgique' => CATALOGUE_BELGIQUE,
    'espagne'  => CATALOGUE_ESPAGNE
  }.freeze

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

  # Mappe une région Property vers la clé de catalogue pays.
  def self.country_for_region(region)
    region.to_s.downcase == 'espagne' ? 'espagne' : 'belgique'
  end

  def self.catalogue_for(region)
    CATALOGUES[country_for_region(region)] || CATALOGUE_BELGIQUE
  end

  def self.all(region: nil)
    catalogue_for(region).map { |attrs| new(attrs) }
  end

  def self.by_category(region: nil)
    all(region: region).group_by(&:category).transform_keys { |k| CATEGORIES[k] || k }
  end

  def self.find(key, region: nil)
    attrs = catalogue_for(region).find { |a| a[:key] == key.to_s }
    new(attrs) if attrs
  end
end

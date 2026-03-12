class WorkType
  CATALOGUE = [
    {
      key: 'isolation_toiture',
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
      key: 'isolation_murs_ext',
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
      key: 'chassis_remplacement',
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
      key: 'pompe_chaleur_air_eau',
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
      key: 'chaudiere_condensation',
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
      key: 'panneaux_solaires',
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
      key: 'isolation_plancher',
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
      key: 'electricite_conformite',
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
      key: 'salle_de_bain',
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
      key: 'toiture_remplacement',
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
    }
  ].freeze

  attr_reader :key, :name, :icon, :unit, :unit_label, :forfait,
              :price_min, :price_max, :duration_min, :duration_max, :vat_rate

  def initialize(attrs)
    attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
  end

  def forfait?
    @forfait
  end

  def self.all
    CATALOGUE.map { |attrs| new(attrs) }
  end

  def self.find(key)
    attrs = CATALOGUE.find { |a| a[:key] == key.to_s }
    new(attrs) if attrs
  end
end

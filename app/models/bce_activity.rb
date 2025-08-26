class BceActivity < ApplicationRecord
  belongs_to :bce_enterprise, foreign_key: :entity_number, primary_key: :enterprise_number, optional: true

  scope :main_activities, -> { where(classification: 'MAIN') }
  scope :secondary_activities, -> { where(classification: 'SECONDARY') }

  def self.main_for_entity(entity_number)
    where(entity_number: entity_number, classification: 'MAIN').first ||
    where(entity_number: entity_number).first
  end

  def main_activity?
    classification == 'MAIN'
  end

  def secondary_activity?
    classification == 'SECONDARY'
  end

  def nace_description
    # Mapping basique des codes NACE les plus courants
    # Dans un vrai système, on aurait une table séparée pour les descriptions NACE
    nace_mappings = {
      '47110' => 'Commerce de détail en magasin non spécialisé à prédominance alimentaire',
      '62010' => 'Programmation informatique',
      '62020' => 'Conseil en systèmes et logiciels informatiques',
      '70100' => 'Activités des sièges sociaux',
      '70220' => 'Conseil pour les affaires et autres conseils de gestion',
      '68100' => 'Achat et vente de biens immobiliers propres',
      '68200' => 'Location et exploitation de biens immobiliers propres ou loués',
      '64200' => 'Activités des sociétés holding',
      '85510' => 'Enseignement de disciplines sportives et d\'activités de loisirs',
      '43110' => 'Travaux de démolition',
      '43120' => 'Travaux de terrassement',
      '41100' => 'Promotion immobilière',
      '41200' => 'Construction de bâtiments résidentiels et non résidentiels',
      '46900' => 'Commerce de gros non spécialisé',
      '56100' => 'Restaurants et services de restauration mobile',
      '56300' => 'Débits de boissons'
    }

    nace_mappings[nace_code] || "Activité NACE #{nace_code}"
  end

  def formatted_classification
    case classification
    when 'MAIN'
      'Activité principale'
    when 'SECONDARY'
      'Activité secondaire'
    else
      classification
    end
  end

  def nace_section
    return nil unless nace_code.present?

    # Les sections NACE sont déterminées par les premiers chiffres
    first_two = nace_code[0..1].to_i

    case first_two
    when 1..3
      'A - Agriculture, sylviculture et pêche'
    when 5..9
      'B - Industries extractives'
    when 10..33
      'C - Industrie manufacturière'
    when 35
      'D - Production et distribution d\'électricité, de gaz, de vapeur et d\'air conditionné'
    when 36..39
      'E - Production et distribution d\'eau; assainissement, gestion des déchets et dépollution'
    when 41..43
      'F - Construction'
    when 45..47
      'G - Commerce; réparation d\'automobiles et de motocycles'
    when 49..53
      'H - Transports et entreposage'
    when 55..56
      'I - Hébergement et restauration'
    when 58..63
      'J - Information et communication'
    when 64..66
      'K - Activités financières et d\'assurance'
    when 68..75
      'L - Activités immobilières'
    when 69..75
      'M - Activités spécialisées, scientifiques et techniques'
    when 77..82
      'N - Activités de services administratifs et de soutien'
    when 84
      'O - Administration publique'
    when 85
      'P - Enseignement'
    when 86..88
      'Q - Santé humaine et action sociale'
    when 90..93
      'R - Arts, spectacles et activités récréatives'
    when 94..96
      'S - Autres activités de services'
    else
      'Section non déterminée'
    end
  end
end

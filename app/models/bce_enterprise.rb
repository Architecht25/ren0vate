class BceEnterprise < ApplicationRecord
  has_many :bce_denominations, foreign_key: :entity_number, primary_key: :enterprise_number
  has_many :bce_addresses, foreign_key: :entity_number, primary_key: :enterprise_number
  has_many :bce_activities, foreign_key: :entity_number, primary_key: :enterprise_number

  # Alias pour compatibility
  alias_method :denominations, :bce_denominations
  alias_method :addresses, :bce_addresses
  alias_method :activities, :bce_activities

  scope :active, -> { where(status: 'AC') }
  scope :inactive, -> { where.not(status: 'AC') }

  def self.find_by_number(number)
    normalized = number.to_s.gsub(/[\.\s\-]/, '')
    where("REPLACE(REPLACE(REPLACE(enterprise_number, '.', ''), ' ', ''), '-', '') = ?", normalized).first
  end

  def primary_denomination
    bce_denominations.where(type_of_denomination: '001').first&.denomination ||
      bce_denominations.first&.denomination
  end

  def main_address
    bce_addresses.where(type_of_address: 'BAET').first ||
      bce_addresses.first
  end

  def formatted_address
    address = main_address
    return nil unless address

    parts = []

    # Rue et numéro
    street = address.street_fr.presence || address.street_nl.presence
    if street.present?
      street_part = street
      street_part += " #{address.house_number}" if address.house_number.present?
      street_part += " boîte #{address.box}" if address.box.present?
      parts << street_part
    end

    # Code postal et commune
    if address.zipcode.present? || address.municipality_fr.present? || address.municipality_nl.present?
      city_part = ""
      city_part += address.zipcode + " " if address.zipcode.present?
      city_part += (address.municipality_fr.presence || address.municipality_nl.presence || "")
      parts << city_part if city_part.present?
    end

    # Pays
    country = address.country_fr.presence || address.country_nl.presence
    parts << country if country.present? && country.downcase != 'belgique' && country.downcase != 'belgië'

    parts.join(', ')
  end

  def primary_activity
    bce_activities.where(classification: 'MAIN').first ||
      bce_activities.first
  end

  def activity_codes
    bce_activities.pluck(:nace_code).compact.uniq
  end

  def formatted_status
    case status
    when 'AC'
      'Actif'
    when 'IN'
      'Inactif'
    when 'CS'
      'Cessation'
    when 'FO'
      'Faillite'
    else
      status
    end
  end

  def formatted_juridical_form
    return nil if juridical_form.blank?

    form_mappings = {
      '1' => 'Personne physique',
      '2' => 'Société privée à responsabilité limitée (SPRL)',
      '3' => 'Société anonyme (SA)',
      '4' => 'Société en nom collectif (SNC)',
      '5' => 'Société en commandite simple (SCS)',
      '6' => 'Société en commandite par actions (SCA)',
      '7' => 'Société coopérative à responsabilité limitée (SCRL)',
      '8' => 'Société coopérative à responsabilité illimitée (SCRI)',
      '9' => 'Association sans but lucratif (ASBL)',
      '401' => 'Société privée à responsabilité limitée (SRL)',
      '801' => 'Société coopérative (SC)'
    }

    form_mappings[juridical_form] || juridical_form
  end
end

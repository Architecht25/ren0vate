class BceAddress < ApplicationRecord
  belongs_to :bce_enterprise, foreign_key: :entity_number, primary_key: :enterprise_number, optional: true

  scope :main_establishments, -> { where(type_of_address: 'BAET') }
  scope :secondary_establishments, -> { where(type_of_address: 'ETAS') }
  scope :active, -> { where(date_striking_off: nil) }

  def self.main_for_entity(entity_number)
    where(entity_number: entity_number, type_of_address: 'BAET').first ||
    where(entity_number: entity_number).first
  end

  def main_establishment?
    type_of_address == 'BAET'
  end

  def secondary_establishment?
    type_of_address == 'ETAS'
  end

  def active?
    date_striking_off.nil?
  end

  def full_address
    parts = []

    # Rue et numéro
    street = street_fr.presence || street_nl.presence
    if street.present?
      street_part = street
      street_part += " #{house_number}" if house_number.present?
      street_part += " boîte #{box}" if box.present?
      parts << street_part
    end

    # Code postal et commune
    if zipcode.present? || municipality_fr.present? || municipality_nl.present?
      city_part = ""
      city_part += zipcode + " " if zipcode.present?
      city_part += (municipality_fr.presence || municipality_nl.presence || "")
      parts << city_part if city_part.present?
    end

    # Pays
    country = country_fr.presence || country_nl.presence
    parts << country if country.present?

    parts.join(', ')
  end

  def formatted_type
    case type_of_address
    when 'BAET'
      'Établissement principal'
    when 'ETAS'
      'Établissement secondaire'
    else
      type_of_address
    end
  end
end

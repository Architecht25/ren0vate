class BceDenomination < ApplicationRecord
  belongs_to :bce_enterprise, foreign_key: :entity_number, primary_key: :enterprise_number, optional: true

  scope :official, -> { where(type_of_denomination: '001') }
  scope :french, -> { where(language: 'FR') }
  scope :dutch, -> { where(language: 'NL') }
  scope :german, -> { where(language: 'DE') }

  def self.primary_for_entity(entity_number)
    where(entity_number: entity_number)
      .where(type_of_denomination: '001')
      .first&.denomination ||
    where(entity_number: entity_number)
      .first&.denomination
  end

  def official?
    type_of_denomination == '001'
  end

  def commercial?
    type_of_denomination == '002'
  end

  def abbreviated?
    type_of_denomination == '003'
  end

  def formatted_type
    case type_of_denomination
    when '001'
      'Dénomination officielle'
    when '002'
      'Dénomination commerciale'
    when '003'
      'Dénomination abrégée'
    else
      "Type #{type_of_denomination}"
    end
  end
end

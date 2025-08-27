require 'csv'
require 'set'

class Entreprises::BrusselsBceImportServiceOptimized
  BRUSSELS_POSTAL_CODES = %w[
    1000 1020 1030 1040 1050 1060 1070 1080 1081 1082 1083 1090
    1120 1130 1140 1150 1160 1170 1180 1190 1200 1210
  ].freeze

  def initialize
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import_brussels_sample_optimized(sample_size = 50)
    Rails.logger.info "🇧🇪 Import optimisé - #{sample_size} entreprises"

    start_time = Time.current

    # Étape 1: Identifier les entreprises éligibles (rapide)
    eligible_enterprises = identify_eligible_enterprises.first(sample_size)
    Rails.logger.info "📊 #{eligible_enterprises.size} entreprises sélectionnées"

    if eligible_enterprises.empty?
      return { imported: 0, skipped: 0, errors: [], duration: 0 }
    end

    # Étape 2: Index des données liées (une seule fois)
    puts "📝 Indexation des adresses..."
    addresses_index = build_addresses_index(eligible_enterprises)

    puts "📝 Indexation des dénominations..."
    denominations_index = build_denominations_index(eligible_enterprises)

    puts "📝 Indexation des activités..."
    activities_index = build_activities_index(eligible_enterprises)

    # Étape 3: Import rapide avec index
    puts "🚀 Import des entreprises..."
    eligible_enterprises.each do |entity_number|
      begin
        import_single_enterprise_optimized(
          entity_number,
          addresses_index[entity_number] || [],
          denominations_index[entity_number] || [],
          activities_index[entity_number] || []
        )
        @imported_count += 1
        print "." if @imported_count % 10 == 0
      rescue => e
        @errors << { entity_number: entity_number, error: e.message }
        @skipped_count += 1
      end
    end

    duration = Time.current - start_time
    puts ""
    Rails.logger.info "✅ Import terminé en #{duration.round(2)}s"

    {
      imported: @imported_count,
      skipped: @skipped_count,
      errors: @errors,
      duration: duration
    }
  end

  private

  def identify_eligible_enterprises
    # Même logique que le service original
    eligible_entities = Set.new

    CSV.foreach(address_file_path, headers: true, quote_char: '"') do |row|
      next unless row['TypeOfAddress'] == 'REGO'
      next unless BRUSSELS_POSTAL_CODES.include?(row['Zipcode'])

      eligible_entities << row['EntityNumber']
    end

    final_entities = Set.new
    CSV.foreach(enterprise_file_path, headers: true, quote_char: '"') do |row|
      next unless eligible_entities.include?(row['EnterpriseNumber'])
      next unless row['JuridicalSituation'] == '000'

      final_entities << row['EnterpriseNumber']
    end

    final_entities.to_a
  end

  def build_addresses_index(entity_numbers)
    entity_set = Set.new(entity_numbers)
    index = Hash.new { |h, k| h[k] = [] }

    CSV.foreach(address_file_path, headers: true, quote_char: '"') do |row|
      entity_number = row['EntityNumber']
      next unless entity_set.include?(entity_number)

      index[entity_number] << {
        type_of_address: row['TypeOfAddress'],
        country_nl: row['CountryNL'],
        country_fr: row['CountryFR'],
        zipcode: row['Zipcode'],
        municipality_nl: row['MunicipalityNL'],
        municipality_fr: row['MunicipalityFR'],
        street_nl: row['StreetNL'],
        street_fr: row['StreetFR'],
        house_number: row['HouseNumber'],
        box: row['Box']
      }
    end

    index
  end

  def build_denominations_index(entity_numbers)
    entity_set = Set.new(entity_numbers)
    index = Hash.new { |h, k| h[k] = [] }

    CSV.foreach(denomination_file_path, headers: true, quote_char: '"') do |row|
      entity_number = row['EntityNumber']
      next unless entity_set.include?(entity_number)

      index[entity_number] << {
        language: row['Language'],
        type_of_denomination: row['TypeOfDenomination'],
        denomination: row['Denomination']
      }
    end

    index
  end

  def build_activities_index(entity_numbers)
    entity_set = Set.new(entity_numbers)
    index = Hash.new { |h, k| h[k] = [] }

    CSV.foreach(activity_file_path, headers: true, quote_char: '"') do |row|
      entity_number = row['EntityNumber']
      next unless entity_set.include?(entity_number)

      index[entity_number] << {
        activity_group: row['ActivityGroup'],
        nace_version: row['NaceVersion'],
        nace_code: row['NaceCode'],
        classification: row['Classification']
      }
    end

    index
  end

  def import_single_enterprise_optimized(entity_number, addresses, denominations, activities)
    return if BceEnterprise.exists?(enterprise_number: entity_number)

    # Import de l'entreprise
    enterprise_data = extract_enterprise_data(entity_number)
    enterprise = BceEnterprise.create!(enterprise_data)

    # Import des données liées avec les index
    addresses.each do |addr_data|
      BceAddress.create!(addr_data.merge(bce_enterprise: enterprise))
    end

    denominations.each do |denom_data|
      BceDenomination.create!(denom_data.merge(bce_enterprise: enterprise))
    end

    activities.each do |activity_data|
      BceActivity.create!(activity_data.merge(bce_enterprise: enterprise))
    end
  end

  def extract_enterprise_data(entity_number)
    CSV.foreach(enterprise_file_path, headers: true, quote_char: '"') do |row|
      next unless row['EnterpriseNumber'] == entity_number

      return {
        enterprise_number: entity_number,
        status: row['Status'],
        juridical_situation: row['JuridicalSituation'],
        type_of_enterprise: row['TypeOfEnterprise'],
        juridical_form: row['JuridicalForm'],
        start_date: parse_date(row['StartDate'])
      }
    end

    raise "Enterprise data not found for #{entity_number}"
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.strptime(date_string, '%d-%m-%Y')
  rescue
    nil
  end

  def address_file_path
    Rails.root.join('db', 'bce_data', 'address.csv')
  end

  def enterprise_file_path
    Rails.root.join('db', 'bce_data', 'enterprise.csv')
  end

  def denomination_file_path
    Rails.root.join('db', 'bce_data', 'denomination.csv')
  end

  def activity_file_path
    Rails.root.join('db', 'bce_data', 'activity.csv')
  end
end

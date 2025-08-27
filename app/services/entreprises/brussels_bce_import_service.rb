require 'csv'
require 'set'

class Entreprises::BrusselsBceImportService
  BRUSSELS_POSTAL_CODES = %w[
    1000 1020 1030 1040 1050 1060 1070 1080 1081 1082 1083 1090
    1120 1130 1140 1150 1160 1170 1180 1190 1200 1210
  ].freeze

  def initialize
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import_brussels_enterprises
    Rails.logger.info "🇧🇪 Début import entreprises Bruxelles (cible: ~144k entreprises)"

    start_time = Time.current

    # Étape 1: Identifier les entreprises éligibles
    eligible_enterprises = identify_eligible_enterprises
    Rails.logger.info "📊 #{eligible_enterprises.size} entreprises éligibles identifiées"

    # Étape 2: Import par batch
    eligible_enterprises.each_slice(1000) do |batch|
      import_batch(batch)
      Rails.logger.info "📈 Progression: #{@imported_count}/#{eligible_enterprises.size}"
    end

    duration = Time.current - start_time
    Rails.logger.info "✅ Import terminé en #{duration.round(2)}s"
    Rails.logger.info "📊 #{@imported_count} importées, #{@skipped_count} ignorées"

    {
      imported: @imported_count,
      skipped: @skipped_count,
      errors: @errors,
      duration: duration
    }
  end

  def import_brussels_sample(sample_size = 15000)
    Rails.logger.info "🇧🇪 Début import échantillon Bruxelles (#{sample_size} entreprises max)"

    start_time = Time.current

    # Étape 1: Identifier les entreprises éligibles
    eligible_enterprises = identify_eligible_enterprises.first(sample_size)
    Rails.logger.info "📊 #{eligible_enterprises.size} entreprises sélectionnées"

    # Étape 2: Import par batch
    eligible_enterprises.each_slice(500) do |batch|
      import_batch(batch)
      Rails.logger.info "📈 Progression: #{@imported_count}/#{eligible_enterprises.size}"
    end

    duration = Time.current - start_time
    Rails.logger.info "✅ Import terminé en #{duration.round(2)}s"
    Rails.logger.info "📊 #{@imported_count} importées, #{@skipped_count} ignorées"

    {
      imported: @imported_count,
      skipped: @skipped_count,
      errors: @errors,
      duration: duration
    }
  end

  private

  def identify_eligible_enterprises
    eligible_entities = Set.new

    # Lecture du fichier address.csv pour identifier les entreprises de Bruxelles
    CSV.foreach(address_file_path, headers: true, quote_char: '"') do |row|
      next unless row['TypeOfAddress'] == 'REGO' # Siège social uniquement
      next unless BRUSSELS_POSTAL_CODES.include?(row['Zipcode'])
      next unless row['EntityNumber']&.start_with?('0') # Personnes morales uniquement

      eligible_entities << row['EntityNumber']
    end

    # Filtrer avec le fichier enterprise.csv (situation juridique normale)
    final_entities = Set.new
    CSV.foreach(enterprise_file_path, headers: true, quote_char: '"') do |row|
      next unless eligible_entities.include?(row['EnterpriseNumber'])
      next unless row['JuridicalSituation'] == '000' # Situation normale

      final_entities << row['EnterpriseNumber']
    end

    final_entities.to_a
  end

  def import_batch(entity_numbers)
    entity_numbers.each do |entity_number|
      begin
        import_single_enterprise(entity_number)
        @imported_count += 1
      rescue => e
        @errors << { entity_number: entity_number, error: e.message }
        @skipped_count += 1
      end
    end
  end

  def import_single_enterprise(entity_number)
    # Vérifier si déjà importée
    return if BceEnterprise.exists?(enterprise_number: entity_number)

    # Import des données de base
    enterprise_data = extract_enterprise_data(entity_number)
    enterprise = BceEnterprise.create!(enterprise_data)

    # Import des dénominations
    import_denominations(enterprise, entity_number)

    # Import des adresses
    import_addresses(enterprise, entity_number)

    # Import des activités
    import_activities(enterprise, entity_number)

    Rails.logger.debug "✅ Importé: #{entity_number} - #{enterprise.denomination}"
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

  def import_denominations(enterprise, entity_number)
    CSV.foreach(denomination_file_path, headers: true, quote_char: '"') do |row|
      next unless row['EntityNumber'] == entity_number

      BceDenomination.create!(
        bce_enterprise: enterprise,
        language: row['Language'],
        type_of_denomination: row['TypeOfDenomination'],
        denomination: row['Denomination']
      )
    end
  end

  def import_addresses(enterprise, entity_number)
    CSV.foreach(address_file_path, headers: true, quote_char: '"') do |row|
      next unless row['EntityNumber'] == entity_number

      BceAddress.create!(
        bce_enterprise: enterprise,
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
      )
    end
  end

  def import_activities(enterprise, entity_number)
    CSV.foreach(activity_file_path, headers: true, quote_char: '"') do |row|
      next unless row['EntityNumber'] == entity_number

      BceActivity.create!(
        bce_enterprise: enterprise,
        activity_group: row['ActivityGroup'],
        nace_version: row['NaceVersion'],
        nace_code: row['NaceCode'],
        classification: row['Classification']
      )
    end
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

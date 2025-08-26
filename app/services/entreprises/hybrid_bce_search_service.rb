# Service de Recherche BCE Hybride
# Combine base locale limitée + parsing CSV à la demande + API fallback

class Entreprises::HybridBceSearchService
  include Singleton

  CACHE_DURATION = 1.hour
  MAX_LOCAL_ENTERPRISES = 50_000 # Entreprises les plus populaires en base
  CSV_PATHS = {
    enterprises: Rails.root.join('db', 'bce_data', 'enterprise.csv'),
    denominations: Rails.root.join('db', 'bce_data', 'denomination.csv'),
    addresses: Rails.root.join('db', 'bce_data', 'address.csv'),
    activities: Rails.root.join('db', 'bce_data', 'activity.csv')
  }

  def self.search_enterprise(query)
    instance.search_enterprise(query)
  end

  def search_enterprise(query)
    Rails.logger.info "🔍 Recherche hybride BCE pour: #{query}"

    # 1. Recherche dans la base locale (rapide)
    local_result = search_in_local_database(query)
    return local_result if local_result[:found]

    # 2. Recherche dans les CSV (plus lent mais complet)
    csv_result = search_in_csv_files(query)
    return csv_result if csv_result[:found]

    # 3. Fallback API BCE officielle
    api_result = search_via_api(query)
    return api_result
  end

  def search_by_name(name, limit = 20)
    Rails.logger.info "🔍 Recherche par nom: #{name}"

    results = []

    # Recherche locale d'abord
    local_results = search_names_in_local(name, limit)
    results.concat(local_results)

    # Si pas assez de résultats, chercher dans CSV
    if results.length < limit
      remaining = limit - results.length
      csv_results = search_names_in_csv(name, remaining)
      results.concat(csv_results)
    end

    results.uniq { |r| r[:numero_bce] }.take(limit)
  end

  private

  def search_in_local_database(query)
    # Nettoyer et formater le numéro
    clean_query = query.gsub(/[^0-9]/, '')

    if clean_query.length == 10
      formatted_number = "#{clean_query[0..3]}.#{clean_query[4..6]}.#{clean_query[7..9]}"
      enterprise = BceEnterprise.find_by(enterprise_number: formatted_number)

      if enterprise
        return {
          found: true,
          data: format_enterprise_data(enterprise),
          source: 'local_database'
        }
      end
    end

    { found: false }
  end

  def search_in_csv_files(query)
    Rails.cache.fetch("bce_csv_search_#{query}", expires_in: CACHE_DURATION) do
      perform_csv_search(query)
    end
  end

  def perform_csv_search(query)
    clean_query = query.gsub(/[^0-9]/, '')

    if clean_query.length == 10
      formatted_number = "#{clean_query[0..3]}.#{clean_query[4..6]}.#{clean_query[7..9]}"

      # Recherche dans enterprise.csv
      enterprise_data = find_in_enterprise_csv(formatted_number)
      return { found: false } unless enterprise_data

      # Recherche des données associées
      denomination = find_in_denomination_csv(formatted_number)
      address = find_in_address_csv(formatted_number)
      activities = find_in_activities_csv(formatted_number)

      {
        found: true,
        data: {
          numero_bce: formatted_number,
          denomination: denomination || 'N/A',
          forme_juridique: format_juridical_form(enterprise_data[:juridical_form]),
          statut: enterprise_data[:status] == 'AC' ? 'ACTIF' : enterprise_data[:status],
          date_creation: enterprise_data[:start_date],
          adresse: address || { rue: 'N/A', code_postal: 'N/A', commune: 'N/A' },
          codes_nace: activities || [],
          code_nace_principal: activities&.first&.dig(:code) || 'N/A'
        },
        source: 'csv_parsing'
      }
    end

    { found: false }
  end

  def find_in_enterprise_csv(enterprise_number)
    return nil unless File.exist?(CSV_PATHS[:enterprises])

    CSV.foreach(CSV_PATHS[:enterprises], headers: true) do |row|
      if row['EnterpriseNumber'] == enterprise_number
        return {
          juridical_form: row['JuridicalForm'],
          juridical_situation: row['JuridicalSituation'],
          status: row['Status'],
          start_date: row['StartDate']
        }
      end
    end
    nil
  rescue => e
    Rails.logger.error "Erreur lecture enterprise.csv: #{e.message}"
    nil
  end

  def find_in_denomination_csv(enterprise_number)
    return nil unless File.exist?(CSV_PATHS[:denominations])

    CSV.foreach(CSV_PATHS[:denominations], headers: true) do |row|
      if row['EntityNumber'] == enterprise_number && row['TypeOfDenomination'] == '001'
        return row['Denomination']
      end
    end
    nil
  rescue => e
    Rails.logger.error "Erreur lecture denomination.csv: #{e.message}"
    nil
  end

  def find_in_address_csv(enterprise_number)
    return nil unless File.exist?(CSV_PATHS[:addresses])

    CSV.foreach(CSV_PATHS[:addresses], headers: true) do |row|
      if row['EntityNumber'] == enterprise_number
        return {
          rue: "#{row['StreetFR'] || row['StreetNL']} #{row['HouseNumber']}".strip,
          code_postal: row['Zipcode'],
          commune: row['MunicipalityFR'] || row['MunicipalityNL']
        }
      end
    end
    nil
  rescue => e
    Rails.logger.error "Erreur lecture address.csv: #{e.message}"
    nil
  end

  def find_in_activities_csv(enterprise_number)
    return [] unless File.exist?(CSV_PATHS[:activities])

    activities = []
    CSV.foreach(CSV_PATHS[:activities], headers: true) do |row|
      if row['EntityNumber'] == enterprise_number
        activities << {
          code: row['NaceCode'],
          version: row['NaceVersion'],
          classification: row['Classification']
        }
      end
    end
    activities
  rescue => e
    Rails.logger.error "Erreur lecture activity.csv: #{e.message}"
    []
  end

  def search_names_in_csv(name, limit)
    return [] unless File.exist?(CSV_PATHS[:denominations])

    results = []
    count = 0

    CSV.foreach(CSV_PATHS[:denominations], headers: true) do |row|
      break if count >= limit * 3 # Limite pour éviter de parser tout le fichier

      if row['Denomination']&.downcase&.include?(name.downcase)
        enterprise_data = find_in_enterprise_csv(row['EntityNumber'])
        next unless enterprise_data && enterprise_data[:status] == 'AC'

        results << {
          numero_bce: row['EntityNumber'],
          denomination: row['Denomination'],
          source: 'csv_parsing'
        }
      end
      count += 1
    end

    results.take(limit)
  rescue => e
    Rails.logger.error "Erreur recherche noms CSV: #{e.message}"
    []
  end

  def search_via_api(query)
    result = Entreprises::BceApiService.search_company(query)

    if result[:success]
      {
        found: true,
        data: result[:data],
        source: 'bce_api'
      }
    else
      { found: false, error: result[:error] }
    end
  end

  def format_enterprise_data(enterprise)
    # Utilise la logique existante du EntreprisesController
    denomination = enterprise.bce_denominations.official.first&.denomination ||
                  enterprise.bce_denominations.first&.denomination ||
                  "Dénomination non disponible"

    address = enterprise.bce_addresses.first
    main_activity = enterprise.bce_activities.where(classification: 'MAIN').first

    {
      numero_bce: enterprise.enterprise_number,
      denomination: denomination,
      forme_juridique: format_juridical_form(enterprise.juridical_form),
      statut: enterprise.status == 'AC' ? 'ACTIF' : enterprise.status,
      date_creation: enterprise.start_date&.strftime('%Y-%m-%d'),
      code_nace_principal: main_activity&.nace_code || 'N/A',
      adresse: format_address(address)
    }
  end

  def format_juridical_form(form)
    case form
    when '610' then 'Société privée à responsabilité limitée (SPRL)'
    when '620' then 'Société anonyme (SA)'
    when '000' then 'Personne physique'
    else form || 'N/A'
    end
  end

  def format_address(address)
    return { rue: 'N/A', code_postal: 'N/A', commune: 'N/A' } unless address

    {
      rue: "#{address.street_fr || address.street_nl} #{address.house_number}".strip,
      code_postal: address.zipcode || 'N/A',
      commune: address.municipality_fr || address.municipality_nl || 'N/A'
    }
  end

  def search_names_in_local(name, limit)
    BceDenomination
      .joins(:bce_enterprise)
      .where("denomination ILIKE ?", "%#{name}%")
      .where(bce_enterprises: { status: 'AC' })
      .limit(limit)
      .map do |denom|
        {
          numero_bce: denom.entity_number,
          denomination: denom.denomination,
          source: 'local_database'
        }
      end
  rescue => e
    Rails.logger.error "Erreur recherche locale: #{e.message}"
    []
  end
end

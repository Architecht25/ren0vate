require 'csv'

class FastBceImportService
  class << self
    def import_all
      Rails.logger.info "🚀 Début import rapide BCE"

      results = {
        enterprises: 0,
        denominations: 0,
        addresses: 0,
        activities: 0,
        errors: []
      }

      # Import des entreprises
      begin
        results[:enterprises] = import_enterprises
        Rails.logger.info "✅ Entreprises importées: #{results[:enterprises]}"
      rescue => e
        error_msg = "Erreur import entreprises: #{e.message}"
        Rails.logger.error error_msg
        results[:errors] << error_msg
      end

      # Import des dénominations
      begin
        results[:denominations] = import_denominations
        Rails.logger.info "✅ Dénominations importées: #{results[:denominations]}"
      rescue => e
        error_msg = "Erreur import dénominations: #{e.message}"
        Rails.logger.error error_msg
        results[:errors] << error_msg
      end

      # Import des adresses
      begin
        results[:addresses] = import_addresses
        Rails.logger.info "✅ Adresses importées: #{results[:addresses]}"
      rescue => e
        error_msg = "Erreur import adresses: #{e.message}"
        Rails.logger.error error_msg
        results[:errors] << error_msg
      end

      # Import des activités
      begin
        results[:activities] = import_activities
        Rails.logger.info "✅ Activités importées: #{results[:activities]}"
      rescue => e
        error_msg = "Erreur import activités: #{e.message}"
        Rails.logger.error error_msg
        results[:errors] << error_msg
      end

      Rails.logger.info "🎯 Import terminé: #{results}"
      results
    end

    private

    def import_enterprises
      csv_path = Rails.root.join('db', 'bce_data', 'enterprise.csv')
      return 0 unless File.exist?(csv_path)

      count = 0
      batch_size = 1000
      batch = []

      CSV.foreach(csv_path, headers: false, encoding: 'UTF-8') do |row|
        next if row.empty? || row[0].nil?

        batch << {
          enterprise_number: row[0].strip.gsub(/["']/, ''),
          status: row[1],
          juridical_situation: row[2],
          type_of_enterprise: row[3],
          juridical_form: row[4],
          start_date: parse_date(row[5]),
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          BceEnterprise.insert_all(batch)
          count += batch.size
          batch.clear

          if count % 10000 == 0
            Rails.logger.info "📊 Entreprises traitées: #{count}"
          end
        end
      end

      # Traitement du dernier batch
      if batch.any?
        BceEnterprise.insert_all(batch)
        count += batch.size
      end

      count
    end

    def import_denominations
      csv_path = Rails.root.join('db', 'bce_data', 'denomination.csv')
      return 0 unless File.exist?(csv_path)

      count = 0
      batch_size = 1000
      batch = []

      CSV.foreach(csv_path, headers: false, encoding: 'UTF-8') do |row|
        next if row.empty? || row[0].nil?

        batch << {
          entity_number: row[0].strip.gsub(/["']/, ''),
          language: row[1],
          type_of_denomination: row[2],
          denomination: row[3],
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          BceDenomination.insert_all(batch, update_conflicts: true)
          count += batch.size
          batch.clear

          if count % 10000 == 0
            Rails.logger.info "📊 Dénominations traitées: #{count}"
          end
        end
      end

      if batch.any?
        BceDenomination.insert_all(batch, update_conflicts: true)
        count += batch.size
      end

      count
    end

    def import_addresses
      csv_path = Rails.root.join('db', 'bce_data', 'address.csv')
      return 0 unless File.exist?(csv_path)

      count = 0
      batch_size = 1000
      batch = []

      CSV.foreach(csv_path, headers: false, encoding: 'UTF-8') do |row|
        next if row.empty? || row[0].nil?

        batch << {
          entity_number: row[0].strip.gsub(/["']/, ''),
          type_of_address: row[1],
          country_nl: row[2],
          country_fr: row[3],
          zipcode: row[4],
          municipality_nl: row[5],
          municipality_fr: row[6],
          street_nl: row[7],
          street_fr: row[8],
          house_number: row[9],
          box: row[10],
          extra_address_info: row[11],
          date_striking_off: parse_date(row[12]),
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          BceAddress.insert_all(batch, update_conflicts: true)
          count += batch.size
          batch.clear

          if count % 10000 == 0
            Rails.logger.info "📊 Adresses traitées: #{count}"
          end
        end
      end

      if batch.any?
        BceAddress.insert_all(batch, update_conflicts: true)
        count += batch.size
      end

      count
    end

    def import_activities
      csv_path = Rails.root.join('db', 'bce_data', 'activity.csv')
      return 0 unless File.exist?(csv_path)

      count = 0
      batch_size = 1000
      batch = []

      CSV.foreach(csv_path, headers: false, encoding: 'UTF-8') do |row|
        next if row.empty? || row[0].nil?

        batch << {
          entity_number: row[0].strip.gsub(/["']/, ''),
          activity_group: row[1],
          nace_version: row[2],
          nace_code: row[3],
          classification: row[4],
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          BceActivity.insert_all(batch, update_conflicts: true)
          count += batch.size
          batch.clear

          if count % 10000 == 0
            Rails.logger.info "📊 Activités traitées: #{count}"
          end
        end
      end

      if batch.any?
        BceActivity.insert_all(batch, update_conflicts: true)
        count += batch.size
      end

      count
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      begin
        Date.parse(date_string)
      rescue Date::Error
        nil
      end
    end
  end
end

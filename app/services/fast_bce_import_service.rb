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
          status_code: row[1],
          juridical_situation: row[2],
          type_of_enterprise: row[3],
          juridical_form: row[4],
          start_date: parse_date(row[5]),
          created_at: Time.current,
          updated_at: Time.current
        }
        
        if batch.size >= batch_size
          BceEnterprise.insert_all(batch, update_conflicts: true)
          count += batch.size
          batch.clear
          
          if count % 10000 == 0
            Rails.logger.info "📊 Entreprises traitées: #{count}"
          end
        end
      end
      
      # Traitement du dernier batch
      if batch.any?
        BceEnterprise.insert_all(batch, update_conflicts: true)
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

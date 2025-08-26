require 'csv'

class SimpleBceImportService
  class << self
    def import_enterprises_sample(limit = 1000)
      Rails.logger.info "🚀 Import échantillon #{limit} entreprises"
      
      csv_path = Rails.root.join('db', 'bce_data', 'enterprise.csv')
      return 0 unless File.exist?(csv_path)
      
      count = 0
      batch = []
      
      CSV.foreach(csv_path, headers: true, encoding: 'UTF-8') do |row|
        break if count >= limit
        
        enterprise_number = row['EnterpriseNumber']&.strip&.gsub(/["']/, '')
        next if enterprise_number.blank?
        
        batch << {
          enterprise_number: enterprise_number,
          status: row['Status'],
          juridical_situation: row['JuridicalSituation'],
          type_of_enterprise: row['TypeOfEnterprise'],
          juridical_form: row['JuridicalForm'],
          start_date: parse_date(row['StartDate']),
          created_at: Time.current,
          updated_at: Time.current
        }
        
        count += 1
        
        if batch.size >= 100
          begin
            BceEnterprise.insert_all(batch)
          rescue => e
            Rails.logger.error "Erreur batch: #{e.message}"
          end
          batch.clear
        end
      end
      
      # Dernier batch
      if batch.any?
        begin
          BceEnterprise.insert_all(batch)
        rescue => e
          Rails.logger.error "Erreur dernier batch: #{e.message}"
        end
      end
      
      count
    end
    
    private
    
    def parse_date(date_string)
      return nil if date_string.blank?
      
      begin
        # Format BCE: DD-MM-YYYY
        if date_string.match(/\d{2}-\d{2}-\d{4}/)
          Date.strptime(date_string, '%d-%m-%Y')
        else
          Date.parse(date_string)
        end
      rescue => e
        Rails.logger.warn "Date invalide: #{date_string}"
        nil
      end
    end
  end
end

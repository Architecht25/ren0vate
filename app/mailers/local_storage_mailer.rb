class LocalStorageMailer < ApplicationMailer
  default from: 'noreply@renovate.be'  def send_results(email, localStorage_data)
    @email = email
    @localStorage_data = localStorage_data
    @parsed_data = parse_localStorage_data(localStorage_data)

    Rails.logger.info "📧 Préparation email pour #{email}"
    Rails.logger.info "📊 Données à envoyer: #{@localStorage_data.keys.join(', ')}"

    mail(
      to: email,
      subject: '🏠 Vos résultats de simulation rénovation énergétique'
    )
  end

  # Version simple pour test
  def send_results_simple(email, localStorage_data)
    @email = email
    @localStorage_data = localStorage_data

    Rails.logger.info "📧 [SIMPLE] Préparation email pour #{email}"

    mail(
      to: email,
      subject: 'Test - Résultats localStorage',
      template_name: 'send_results_simple'
    )
  end

  private

  def parse_localStorage_data(data)
    parsed = {}

    data.each do |key, value|
      case key
      when 'eligibiliteRenovate', 'details_primes'
        begin
          parsed[key] = JSON.parse(value)
        rescue JSON::ParserError
          parsed[key] = value
        end
      else
        parsed[key] = value
      end
    end

    parsed
  end
end

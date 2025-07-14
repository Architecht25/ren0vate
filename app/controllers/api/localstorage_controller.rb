class Api::LocalstorageController <      # Maintenant essayons d'écrire dans un fichier d'abord
      if email.present? && localStorage_data.present?
        Rails.logger.info "✅ Données basiques OK - écriture dans fichier..."

        # Écrire dans un fichier pour tester
        timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
        filename = Rails.root.join("tmp/mails/email_#{timestamp}_#{email.gsub('@', '_at_')}.txt")

        content = <<~TEXT
          Email destinataire: #{email}
          Date: #{Time.current}

          === Données localStorage ===
          #{localStorage_data.map { |k, v| "#{k}: #{v}" }.join("\n")}

          === Fin du rapport ===
        TEXT

        File.write(filename, content)

        Rails.logger.info "✅ Fichier écrit: #{filename}"

        render json: {
          message: "Rapport généré avec succès",
          email: email,
          file: filename.basename.to_s,
          data_keys: localStorage_data.keys.join(', ')
        }, status: :ok
      else
        Rails.logger.error "❌ Données manquantes"
        render json: { error: "Données manquantes" }, status: :bad_request
      endoller
  skip_before_action :verify_authenticity_token

  def save
    localstorage_data = params[:localstorage]

    # Exemple de traitement des données
    localstorage_data.each do |key, value|
      case key
      when "region"
        # Enregistrer la région dans la base de données
        current_user.update(region: value)
      when "eligibiliteRenovate"
        # Enregistrer les données d'éligibilité
        Eligibility.create(user: current_user, data: value)
      else
        # Autres cas
        Rails.logger.info("Clé inconnue : #{key}, valeur : #{value}")
      end
    end

    render json: { message: "Données enregistrées avec succès" }, status: :ok
  end

  def send_results_email
    Rails.logger.info "🔍 === DÉBUT DEBUG EMAIL ==="

    begin
      email = params[:email]
      localStorage_data = params[:localStorage_data]

      Rails.logger.info "📧 Email reçu: #{email.inspect}"
      Rails.logger.info "📊 localStorage_data reçu: #{localStorage_data.inspect}"
      Rails.logger.info "📋 Type de localStorage_data: #{localStorage_data.class}"

      # Test simple sans mailer d'abord
      if email.present? && localStorage_data.present?
        Rails.logger.info "✅ Données basiques OK"

        # Test de création du dossier mails
        mail_dir = Rails.root.join('tmp/mails')
        Rails.logger.info "� Dossier mails existe: #{Dir.exist?(mail_dir)}"

        render json: {
          message: "Test réussi - pas d'envoi email pour le moment",
          email: email,
          data_keys: localStorage_data.keys.join(', ')
        }, status: :ok
      else
        Rails.logger.error "❌ Données manquantes"
        render json: { error: "Données manquantes" }, status: :bad_request
      end

    rescue => e
      Rails.logger.error "❌ Erreur dans send_results_email: #{e.class}: #{e.message}"
      Rails.logger.error "📍 Backtrace: #{e.backtrace.first(10).join("\n")}"
      render json: {
        error: "Erreur interne: #{e.message}"
      }, status: :internal_server_error
    end

    Rails.logger.info "🔍 === FIN DEBUG EMAIL ==="
  end
end

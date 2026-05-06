namespace :security do
  desc "Chiffre les données sensibles existantes en clair (IBAN, national_number, revenus AER/RIB)"
  task encrypt_plaintext_data: :environment do
    unless ENV["AR_ENCRYPTION_PRIMARY_KEY"].present?
      puts "❌ AR_ENCRYPTION_PRIMARY_KEY non défini — arrêt."
      exit 1
    end

    puts "🔐 Chiffrement des données sensibles en clair..."
    errors = []

    # Users — national_number et iban
    users_count = 0
    User.find_each do |user|
      changed = false
      begin
        # Lire la valeur actuelle (support_unencrypted_data: true permet de lire le clair)
        # Re-assigner force le rechiffrement si la valeur n'est pas déjà chiffrée
        if user.national_number.present?
          user.national_number = user.national_number
          changed = true
        end
        if user.iban.present?
          user.iban = user.iban
          changed = true
        end
        user.save!(validate: false) if changed
        users_count += 1 if changed
      rescue => e
        errors << "User ##{user.id}: #{e.message}"
      end
    end
    puts "  ✅ Users: #{users_count} enregistrements rechiffrés"

    # AerDonnee — revenus fiscaux
    aer_count = 0
    AerDonnee.find_each do |aer|
      begin
        aer.revenu_imposable_global = aer.revenu_imposable_global
        aer.revenu_demandeur        = aer.revenu_demandeur
        aer.revenu_conjoint         = aer.revenu_conjoint
        aer.texte_ocr_brut          = aer.texte_ocr_brut
        aer.save!(validate: false)
        aer_count += 1
      rescue => e
        errors << "AerDonnee ##{aer.id}: #{e.message}"
      end
    end
    puts "  ✅ AerDonnee: #{aer_count} enregistrements rechiffrés"

    # RibDonnee — données bancaires
    rib_count = 0
    RibDonnee.find_each do |rib|
      begin
        rib.iban           = rib.iban
        rib.nom_titulaire  = rib.nom_titulaire
        rib.texte_ocr_brut = rib.texte_ocr_brut
        rib.save!(validate: false)
        rib_count += 1
      rescue => e
        errors << "RibDonnee ##{rib.id}: #{e.message}"
      end
    end
    puts "  ✅ RibDonnee: #{rib_count} enregistrements rechiffrés"

    if errors.any?
      puts "\n⚠️  #{errors.count} erreur(s) :"
      errors.each { |e| puts "  - #{e}" }
      puts "\nCorriger les erreurs avant de passer support_unencrypted_data à false."
    else
      puts "\n✅ Toutes les données sont chiffrées."
      puts "👉 Prochaine étape : passer config.active_record.encryption.support_unencrypted_data = false"
      puts "   dans config/application.rb, puis redéployer."
    end
  end

  desc "Vérifie combien d'enregistrements contiennent encore des données en clair"
  task check_plaintext_remaining: :environment do
    unless ENV["AR_ENCRYPTION_PRIMARY_KEY"].present?
      puts "❌ AR_ENCRYPTION_PRIMARY_KEY non défini — arrêt."
      exit 1
    end

    puts "🔍 Vérification des données non chiffrées..."

    plaintext_users = User.where.not(national_number: nil).or(User.where.not(iban: nil)).count
    puts "  Users avec données sensibles : #{plaintext_users}"
    puts "  (run encrypt_plaintext_data pour les chiffrer)"
  end
end

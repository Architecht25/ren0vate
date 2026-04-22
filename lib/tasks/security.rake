namespace :security do
  desc <<~DESC
    Re-chiffre les enregistrements AerDonnee et RibDonnee existants avec AR Encryption.
    À exécuter après la migration 20260422100000 (encrypt_aer_revenus_and_ocr_brut).

    Usage :
      rails security:re_encrypt_aer_rib            # batch_size par défaut = 100
      BATCH_SIZE=500 rails security:re_encrypt_aer_rib

    Idempotent : les enregistrements déjà chiffrés sont ignorés (support_unencrypted_data: true).
  DESC
  task re_encrypt_aer_rib: :environment do
    batch_size = (ENV["BATCH_SIZE"] || 100).to_i
    total_aer = 0
    total_rib = 0

    puts "[#{Time.current}] Début du re-chiffrement AerDonnee (#{AerDonnee.count} enregistrements)..."
    AerDonnee.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |record|
        # touch(false) re-sauvegarde sans mettre à jour updated_at — les encrypts hooks s'exécutent
        record.save!(touch: false)
      rescue => e
        warn "[ERREUR] AerDonnee##{record.id} : #{e.message}"
      end
      total_aer += batch.size
      print "."
    end
    puts "\n[#{Time.current}] AerDonnee : #{total_aer} enregistrements re-chiffrés."

    puts "[#{Time.current}] Début du re-chiffrement RibDonnee (#{RibDonnee.count} enregistrements)..."
    RibDonnee.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |record|
        record.save!(touch: false)
      rescue => e
        warn "[ERREUR] RibDonnee##{record.id} : #{e.message}"
      end
      total_rib += batch.size
      print "."
    end
    puts "\n[#{Time.current}] RibDonnee : #{total_rib} enregistrements re-chiffrés."

    puts "[#{Time.current}] Re-chiffrement terminé. Total : #{total_aer + total_rib} enregistrements."
  end
end

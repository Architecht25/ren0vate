namespace :users do
  desc "Recréer tous les utilisateurs de production avec leurs données"
  task recreate_production: :environment do
    puts "🚨 RECONSTRUCTION UTILISATEURS PRODUCTION"
    puts "=" * 50
    puts ""

    # Confirmation
    if Rails.env.production?
      print "⚠️  ATTENTION: Vous êtes en PRODUCTION! Continuer? (yes/NO): "
      response = $stdin.gets.chomp.downcase
      unless response == 'yes'
        puts "❌ Opération annulée"
        exit 0
      end
    end

    puts "🔄 Chargement du seed utilisateurs..."
    load Rails.root.join("db", "seeds", "users_production.rb")

    puts ""
    puts "🎉 Reconstruction terminée!"
    puts "📱 Vous pouvez maintenant vous connecter avec:"
    puts "   📧 robin@primes-services.be"
    puts "   🔐 robin123456"
  end

  desc "Créer seulement l'admin principal"
  task create_admin_only: :environment do
    puts "👑 Création admin principal..."

    admin = User.create!(
      email: 'robin@primes-services.be',
      password: 'robin123456',
      password_confirmation: 'robin123456',
      first_name: 'Robin',
      last_name: 'Admin',
      role: 'admin',
      phone: '+32 2 123 45 67',
      city: 'Bruxelles',
      postal_code: '1000',
      confirmed_at: Time.current
    )

    puts "✅ Admin créé: #{admin.email}"
    puts "🔐 Mot de passe: robin123456"
  end

  desc "Compter les utilisateurs actuels"
  task count: :environment do
    puts "📊 Statistiques utilisateurs:"
    puts "  Total: #{User.count}"
    puts "  Admins: #{User.where(role: 'admin').count}"
    puts "  Utilisateurs: #{User.where(role: 'user').count}"

    if User.count > 0
      puts ""
      puts "📋 Liste:"
      User.all.each do |u|
        puts "  - #{u.email} (#{u.role})"
      end
    end
  end

  desc "RGPD - Supprime un compte et toutes ses données. EMAIL=... [DRY_RUN=true] [CONFIRM=CONFIRMER]"
  task gdpr_delete: :environment do
    email   = ENV['EMAIL'].to_s.downcase.strip
    dry_run = ENV['DRY_RUN'] == 'true'

    abort "Usage: rails users:gdpr_delete EMAIL=client@example.com [DRY_RUN=true] [CONFIRM=CONFIRMER]" if email.blank?

    user = User.find_by(email: email)
    abort "Utilisateur introuvable : #{email}" unless user

    # Tous les documents liés à cet utilisateur (directs + via projets/propriétés)
    project_ids  = Project.where(user_id: user.id).pluck(:id)
    property_ids = Property.where(user_id: user.id).pluck(:id)
    all_doc_ids  = Document.where(user_id: user.id)
                           .or(Document.where(project_id: project_ids))
                           .or(Document.where(property_id: property_ids))
                           .pluck(:id)
    factures_count   = Facture.where(project_id: project_ids).count
    docs_with_files  = Document.where(id: all_doc_ids).joins(:file_attachment).count rescue all_doc_ids.size

    puts ""
    puts "#{dry_run ? '[DRY RUN] ' : ''}=== Suppression RGPD ==="
    puts "  Email      : #{user.email}"
    puts "  Nom        : #{[user.first_name, user.last_name].compact.join(' ')}"
    puts "  ID         : #{user.id}"
    puts "  Compte créé: #{user.created_at.strftime('%d/%m/%Y')}"
    puts ""
    puts "  Données à supprimer :"
    puts "    - #{property_ids.size} propriété(s)"
    puts "    - #{project_ids.size} projet(s)"
    puts "    - #{all_doc_ids.size} document(s) dont #{docs_with_files} avec fichier Cloudinary"
    puts "    - #{factures_count} facture(s)"
    puts "    - #{user.simulations.count} simulation(s)"
    puts "    - #{user.requests.count} demande(s)"
    puts "    - #{user.notifications.count} notification(s)"
    puts "    - #{user.subscriptions.count} abonnement(s)"
    puts ""

    if dry_run
      puts "  [DRY RUN] Aucune donnée supprimée."
      puts "  Relancez sans DRY_RUN=true et avec CONFIRM=CONFIRMER pour appliquer."
      next
    end

    abort "Suppression annulée. Ajoutez CONFIRM=CONFIRMER à la commande pour confirmer." if ENV['CONFIRM'] != 'CONFIRMER'

    puts "  Purge des fichiers Cloudinary..."
    purged = 0
    Document.where(id: all_doc_ids).find_each do |doc|
      if doc.file.attached?
        doc.file.purge
        purged += 1
      end
    end
    Property.where(id: property_ids).find_each do |prop|
      if prop.photo.attached?
        prop.photo.purge
        purged += 1
      end
    end
    puts "  #{purged} fichier(s) Cloudinary purgé(s)."

    # ── Archivage légal 10 ans — vérification des PV finalisés ──────────────
    project_ids = user.projects.pluck(:id)
    pv_en_archivage = PvReception.where(project_id: project_ids)
                                  .where(statut: "finalise")
                                  .where("legal_archive_until > ?", Date.today)
    if pv_en_archivage.any?
      puts ""
      puts "  ⚠️  ATTENTION — PV de réception en archivage légal :"
      pv_en_archivage.each do |pv|
        puts "     - PV ##{pv.id} (projet ##{pv.project_id}) archivé jusqu'au #{pv.legal_archive_until.strftime('%d/%m/%Y')} (garantie décennale)"
      end
      puts "  La suppression en cascade va supprimer ces projets et PV."
      puts "  Si vous devez conserver ces PV pour obligation légale, abandonnez cette procédure"
      puts "  et traitez manuellement les projets concernés avant de relancer."
      puts ""
    end

    puts "  Suppression du compte en cascade..."
    user.destroy!

    puts ""
    puts "  RGPD - Effacement effectué le #{Date.today.strftime('%d/%m/%Y')}"
    puts "  Email : #{email}"
    puts "  Toutes les données personnelles, documents et fichiers ont été supprimés."
  end
end

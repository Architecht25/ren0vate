# Seeds pour les documents officiels des primes
# À exécuter avec: rails db:seed:replant RAILS_ENV=development

puts "🗂️  Création des documents officiels pour les primes..."

# Répertoire où stocker les fichiers d'exemple (à créer)
documents_dir = Rails.root.join('public', 'data', 'prime_documents')
FileUtils.mkdir_p(documents_dir) unless Dir.exist?(documents_dir)

# Compteurs
created_count = 0
skipped_count = 0

# Pour chaque prime, créer les documents standards
Prime.includes(:category).find_each do |prime|
  puts "  📋 Traitement prime: #{prime.titre} (#{prime.slug})"

  # 1. Attestation entrepreneur (obligatoire pour toutes les primes)
  attestation = PrimeDocumentTemplate.find_or_initialize_by(
    prime: prime,
    type_document: 'attestation_entrepreneur'
  )

  if attestation.new_record?
    # Titre et description spéciaux pour la prime amiante
    if prime.slug == 'amiante'
      attestation.assign_attributes(
        title: "L'attestation pour l'amiante (accompagne toujours une attestation de toiture ou de mur)",
        description: "Document obligatoire pour le désamiantage en combinaison avec isolation. Cette attestation ne se demande jamais seule et doit toujours accompagner une attestation de toiture ou de mur.",
        is_required: true,
        order_position: 8,
        file_url: "https://res.cloudinary.com/dtdelexhd/image/upload/Attest_Asbestverwijdering_In_combinatie_met_Isolatie_dak-en_of_Buitenmuur_jybksm.pdf"
      )
    else
      attestation.assign_attributes(
        title: "Attestation entrepreneur - #{prime.titre}",
        description: "Document obligatoire à faire remplir et signer par l'entrepreneur qui réalise les travaux. Ce document atteste de la conformité des travaux aux exigences de la prime.",
        is_required: true,
        order_position: 1,
        file_url: "/data/prime_documents/#{prime.slug}_attestation_entrepreneur.pdf"
      )
    end

    if attestation.save
      created_count += 1
      puts "    ✅ Attestation entrepreneur créée"
    else
      puts "    ❌ Erreur attestation: #{attestation.errors.full_messages.join(', ')}"
    end
  else
    skipped_count += 1
    puts "    ⏭️  Attestation entrepreneur existe déjà"
  end

  # 2. Formulaire de demande (pour certaines primes spécifiques)
  if prime.region == 'bruxelles' && ['bruxelles_prime_a_global', 'bruxelles_prime_j_global'].include?(prime.slug)
    formulaire = PrimeDocumentTemplate.find_or_initialize_by(
      prime: prime,
      type_document: 'formulaire_demande'
    )

    if formulaire.new_record?
      formulaire.assign_attributes(
        title: "Formulaire de demande - #{prime.titre}",
        description: "Formulaire officiel de demande de prime à remplir et à joindre au dossier. Contient les informations techniques et administratives nécessaires.",
        is_required: true,
        order_position: 2,
        file_url: "/data/prime_documents/#{prime.slug}_formulaire_demande.pdf"
      )

      if formulaire.save
        created_count += 1
        puts "    ✅ Formulaire de demande créé"
      else
        puts "    ❌ Erreur formulaire: #{formulaire.errors.full_messages.join(', ')}"
      end
    else
      skipped_count += 1
      puts "    ⏭️  Formulaire de demande existe déjà"
    end
  end

  # 3. Annexe technique (pour les primes techniques complexes)
  if prime.type_de_valeur == 'surface' || prime.slug.include?('isolation') || prime.slug.include?('pompe')
    annexe = PrimeDocumentTemplate.find_or_initialize_by(
      prime: prime,
      type_document: 'annexe_technique'
    )

    if annexe.new_record?
      annexe.assign_attributes(
        title: "Annexe technique - #{prime.titre}",
        description: "Spécifications techniques détaillées, normes à respecter et critères de performance pour cette prime.",
        is_required: false,
        order_position: 3,
        file_url: "/data/prime_documents/#{prime.slug}_annexe_technique.pdf"
      )

      if annexe.save
        created_count += 1
        puts "    ✅ Annexe technique créée"
      else
        puts "    ❌ Erreur annexe: #{annexe.errors.full_messages.join(', ')}"
      end
    else
      skipped_count += 1
      puts "    ⏭️  Annexe technique existe déjà"
    end
  end

  # 4. Guide de remplissage (pour les primes complexes)
  if prime.valeurs_par_categorie.present? && prime.valeurs_par_categorie.keys.count > 1
    guide = PrimeDocumentTemplate.find_or_initialize_by(
      prime: prime,
      type_document: 'guide_remplissage'
    )

    if guide.new_record?
      guide.assign_attributes(
        title: "Guide de remplissage - #{prime.titre}",
        description: "Guide explicatif pour remplir correctement les formulaires et comprendre les exigences spécifiques de cette prime.",
        is_required: false,
        order_position: 4,
        file_url: "/data/prime_documents/#{prime.slug}_guide_remplissage.pdf"
      )

      if guide.save
        created_count += 1
        puts "    ✅ Guide de remplissage créé"
      else
        puts "    ❌ Erreur guide: #{guide.errors.full_messages.join(', ')}"
      end
    else
      skipped_count += 1
      puts "    ⏭️  Guide de remplissage existe déjà"
    end
  end
end

puts "🎯 Création des documents terminée:"
puts "   ✅ #{created_count} documents créés"
puts "   ⏭️  #{skipped_count} documents existants ignorés"
puts "   📊 Total: #{PrimeDocumentTemplate.count} documents dans la base"

# Créer des fichiers d'exemple (placeholder)
puts "\n📄 Création de fichiers d'exemple..."
sample_primes = Prime.limit(5)

sample_primes.each do |prime|
  %w[attestation_entrepreneur formulaire_demande annexe_technique guide_remplissage].each do |doc_type|
    filename = "#{prime.slug}_#{doc_type}.pdf"
    filepath = documents_dir.join(filename)

    unless File.exist?(filepath)
      # Créer un fichier PDF simple avec du contenu d'exemple
      File.write(filepath, <<~CONTENT)
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj

        2 0 obj
        <<
        /Type /Pages
        /Kids [3 0 R]
        /Count 1
        >>
        endobj

        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox [0 0 612 792]
        /Contents 4 0 R
        >>
        endobj

        4 0 obj
        <<
        /Length 44
        >>
        stream
        BT
        /F1 12 Tf
        72 720 Td
        (#{doc_type.humanize} - #{prime.titre}) Tj
        ET
        endstream
        endobj

        xref
        0 5
        0000000000 65535 f
        0000000010 00000 n
        0000000079 00000 n
        0000000173 00000 n
        0000000301 00000 n
        trailer
        <<
        /Size 5
        /Root 1 0 R
        >>
        startxref
        492
        %%EOF
      CONTENT

      puts "   📄 Créé: #{filename}"
    end
  end
end

puts "\n✅ Seeds des documents officiels terminés avec succès!"
puts "🔗 Accédez aux documents via: /prime_document_templates"

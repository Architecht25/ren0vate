# Seeds pour les phases de documents
# À exécuter avec: rails db:seed ou rails runner 'load Rails.root.join("db/seeds/document_phases.rb")'

puts "📋 Création des phases de documents..."

# Créer les phases de base pour les chantiers si elles n'existent pas
DocumentPhase::DEFAULT_PHASES.each do |phase_data|
  phase = DocumentPhase.find_or_initialize_by(
    name: phase_data[:name],
    category: 'chantier'
  )

  if phase.new_record?
    phase.assign_attributes(
      description: phase_data[:description],
      icon: phase_data[:icon],
      color: phase_data[:color],
      position: phase_data[:position],
      required_document_types: phase_data[:required_document_types],
      optional_document_types: phase_data[:optional_document_types],
      category: 'chantier'
    )

    if phase.save
      puts "  ✅ Phase créée: #{phase.name}"
      puts "     Documents obligatoires: #{phase.required_document_types.join(', ')}"
      puts "     Documents optionnels: #{phase.optional_document_types.join(', ')}"
    else
      puts "  ❌ Erreur lors de la création de #{phase_data[:name]}: #{phase.errors.full_messages.join(', ')}"
    end
  else
    # Mettre à jour les documents si nécessaire
    updated = false

    if phase.required_document_types != phase_data[:required_document_types]
      phase.required_document_types = phase_data[:required_document_types]
      updated = true
    end

    if phase.optional_document_types != phase_data[:optional_document_types]
      phase.optional_document_types = phase_data[:optional_document_types]
      updated = true
    end

    if updated && phase.save
      puts "  🔄 Phase mise à jour: #{phase.name}"
      puts "     Documents obligatoires: #{phase.required_document_types.join(', ')}"
      puts "     Documents optionnels: #{phase.optional_document_types.join(', ')}"
    else
      puts "  ✅ Phase existante: #{phase.name} (aucune modification nécessaire)"
    end
  end
end

puts "📋 Phases de documents créées/vérifiées"
puts "📊 Résumé:"

DocumentPhase.chantier.ordered.each do |phase|
  puts "  #{phase.icon} #{phase.name}:"
  puts "    - Documents obligatoires (#{phase.required_document_types.count}): #{phase.required_document_types.join(', ')}"
  puts "    - Documents optionnels (#{phase.optional_document_types.count}): #{phase.optional_document_types.join(', ')}"
end

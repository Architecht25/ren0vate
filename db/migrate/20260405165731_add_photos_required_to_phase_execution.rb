class AddPhotosRequiredToPhaseExecution < ActiveRecord::Migration[8.0]
  PHOTO_TYPES = %w[photo_avant photo_pendant photo_apres].freeze

  def up
    phase = DocumentPhase.find_by(name: 'Phase Exécution')
    return unless phase

    new_required = (phase.required_document_types.to_a + PHOTO_TYPES).uniq
    new_optional  = phase.optional_document_types.to_a - PHOTO_TYPES

    phase.update!(required_document_types: new_required, optional_document_types: new_optional)

    puts "✅ Phase Exécution — requis : #{new_required.inspect}"
    puts "✅ Phase Exécution — optionnels : #{new_optional.inspect}"
  end

  def down
    phase = DocumentPhase.find_by(name: 'Phase Exécution')
    return unless phase

    new_required = phase.required_document_types.to_a - PHOTO_TYPES
    new_optional  = (phase.optional_document_types.to_a + PHOTO_TYPES).uniq

    phase.update!(required_document_types: new_required, optional_document_types: new_optional)
  end
end

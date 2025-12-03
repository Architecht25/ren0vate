class MigratePhotoDocumentsToNewTypes < ActiveRecord::Migration[8.0]
  def up
    # Migrer tous les documents de type 'photo' vers 'photo_avant' par défaut
    Document.where(type_document: 'photo').update_all(type_document: 'photo_avant')
    
    puts "Migration terminée : tous les documents 'photo' ont été migrés vers 'photo_avant'"
  end

  def down
    # Revenir en arrière : remettre tous les types photo spécifiques vers 'photo' générique
    Document.where(type_document: ['photo_avant', 'photo_pendant', 'photo_apres'])
            .update_all(type_document: 'photo')
    
    puts "Rollback terminé : tous les documents photo spécifiques ont été remis vers 'photo'"
  end
end

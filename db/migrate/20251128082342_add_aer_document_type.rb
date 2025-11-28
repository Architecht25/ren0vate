class AddAerDocumentType < ActiveRecord::Migration[8.0]
  def change
    # Cette migration est principalement documentaire car le type_document
    # est stocké comme string et l'ajout de 'aer' à l'enum ne nécessite
    # pas de modification de schéma
    puts "📋 Ajout du type de document 'aer' (Avertissements Extrait de Rôle)"
    puts "✅ Type 'aer' ajouté avec succès à l'énumération des types de documents"
  end
end

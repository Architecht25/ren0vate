class SeparatePebCertificates < ActiveRecord::Migration[8.0]
  def up
    # Mettre à jour les documents existants avec le type certificat_peb
    # en fonction de leur contexte ou de leur date de création
    
    # Pour simplifier, on va considérer que :
    # - Les certificats créés en début de projet sont "avant travaux"
    # - Les certificats créés plus récemment sont "après travaux"
    
    # Phase Administrative (phase 1) -> certificat_peb_avant
    execute <<-SQL
      UPDATE documents 
      SET type_document = 'certificat_peb_avant' 
      WHERE type_document = 'certificat_peb'
      AND (
        created_at <= (
          SELECT MIN(created_at) + INTERVAL '30 days'
          FROM documents d2 
          WHERE d2.property_id = documents.property_id 
          AND d2.type_document IN ('facture', 'etat_avancement')
        )
        OR NOT EXISTS (
          SELECT 1 FROM documents d3 
          WHERE d3.property_id = documents.property_id 
          AND d3.type_document IN ('facture', 'etat_avancement')
        )
      )
    SQL
    
    # Phase Réception (phase 4) -> certificat_peb_apres
    execute <<-SQL
      UPDATE documents 
      SET type_document = 'certificat_peb_apres' 
      WHERE type_document = 'certificat_peb'
    SQL
  end
  
  def down
    # Revenir à l'état précédent
    execute <<-SQL
      UPDATE documents 
      SET type_document = 'certificat_peb' 
      WHERE type_document IN ('certificat_peb_avant', 'certificat_peb_apres')
    SQL
  end
end

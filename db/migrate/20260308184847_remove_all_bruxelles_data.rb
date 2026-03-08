class RemoveAllBruxellesData < ActiveRecord::Migration[8.0]
  def up
    # Collecter tous les IDs Bruxelles
    puts "📊 Collecte des IDs Bruxelles..."
    bruxelles_prime_ids = Prime.where(region: 'bruxelles').pluck(:id)
    bruxelles_simulation_ids = Simulation.where(region: 'bruxelles').pluck(:id)
    bruxelles_request_ids = Request.where(region: 'bruxelles').pluck(:id)
    bruxelles_property_ids = Property.where(region: 'bruxelles').pluck(:id)

    # Nettoyer toutes les dépendances des primes
    if bruxelles_prime_ids.any?
      execute "DELETE FROM prime_document_templates WHERE prime_id IN (#{bruxelles_prime_ids.join(',')})"
      puts "✅ Prime document templates Bruxelles supprimés"
      
      execute "DELETE FROM request_progresses WHERE prime_id IN (#{bruxelles_prime_ids.join(',')})"
      puts "✅ Request progresses (prime_id) Bruxelles supprimés"
    end

    # Nettoyer toutes les dépendances des requests
    if bruxelles_request_ids.any?
      execute "DELETE FROM request_progresses WHERE request_id IN (#{bruxelles_request_ids.join(',')})"
      puts "✅ Request progresses (request_id) Bruxelles supprimés"
      
      execute "DELETE FROM documents WHERE request_id IN (#{bruxelles_request_ids.join(',')})"
      puts "✅ Documents (request_id) Bruxelles supprimés"
    end

    # Nettoyer toutes les dépendances des simulations
    if bruxelles_simulation_ids.any?
      execute "DELETE FROM documents WHERE simulation_id IN (#{bruxelles_simulation_ids.join(',')})"
      puts "✅ Documents (simulation_id) Bruxelles supprimés"
      
      execute "DELETE FROM notifications WHERE simulation_id IN (#{bruxelles_simulation_ids.join(',')})"
      puts "✅ Notifications (simulation_id) Bruxelles supprimées"
      
      execute "DELETE FROM requests WHERE simulation_id IN (#{bruxelles_simulation_ids.join(',')})"
      puts "✅ Requests (simulation_id) Bruxelles supprimées"
    end

    # Nettoyer toutes les dépendances des properties
    if bruxelles_property_ids.any?
      execute "DELETE FROM document_phase_statuses WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Document phase statuses Bruxelles supprimés"
      
      execute "DELETE FROM documents WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Documents (property_id) Bruxelles supprimés"
      
      execute "DELETE FROM factures WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Factures Bruxelles supprimées"
      
      execute "DELETE FROM notifications WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Notifications (property_id) Bruxelles supprimées"
      
      execute "DELETE FROM prime_submissions WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Prime submissions Bruxelles supprimées"
      
      execute "DELETE FROM projects WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Projects Bruxelles supprimés"
      
      execute "DELETE FROM requests WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Requests (property_id) Bruxelles supprimées"
      
      execute "DELETE FROM simulations WHERE property_id IN (#{bruxelles_property_ids.join(',')})"
      puts "✅ Simulations (property_id) Bruxelles supprimées"
    end

    # Supprimer les tables Bruxelles principales
    Prime.where(region: 'bruxelles').delete_all
    puts "✅ Primes Bruxelles supprimées"

    Category.where(region: 'bruxelles').delete_all
    puts "✅ Catégories Bruxelles supprimées"

    Simulation.where(region: 'bruxelles').delete_all
    puts "✅ Simulations Bruxelles supprimées"

    Request.where(region: 'bruxelles').delete_all
    puts "✅ Requests Bruxelles supprimées"

  end

  def down
    # Migration irréversible - les données sont perdues
    raise ActiveRecord::IrreversibleMigration
  end
end

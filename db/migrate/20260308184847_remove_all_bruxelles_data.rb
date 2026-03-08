class RemoveAllBruxellesData < ActiveRecord::Migration[8.0]
  def up
    say "�️ Suppression en cascade des données Bruxelles..."

    # Étape 1: Collecter tous les IDs
    bruxelles_prime_ids = connection.select_values("SELECT id FROM primes WHERE region = 'bruxelles'")
    bruxelles_cat_ids = connection.select_values("SELECT id FROM categories WHERE region = 'bruxelles'")
    bruxelles_sim_ids = connection.select_values("SELECT id FROM simulations WHERE region = 'bruxelles'")
    bruxelles_req_ids = connection.select_values("SELECT id FROM requests WHERE region = 'bruxelles'")
    bruxelles_prop_ids = connection.select_values("SELECT id FROM properties WHERE region = 'bruxelles'")

    return say "✅ Aucune donnée Bruxelles trouvée" if [bruxelles_prime_ids, bruxelles_cat_ids, bruxelles_sim_ids, bruxelles_req_ids, bruxelles_prop_ids].all?(&:empty?)

    # Étape 2: Supprimer les enfants des primes
    if bruxelles_prime_ids.any?
      execute "DELETE FROM prime_document_templates WHERE prime_id IN (#{bruxelles_prime_ids.join(',')})"
      execute "DELETE FROM request_progresses WHERE prime_id IN (#{bruxelles_prime_ids.join(',')})"
    end

    # Étape 3: Supprimer les enfants des requests
    if bruxelles_req_ids.any?
      execute "DELETE FROM request_progresses WHERE request_id IN (#{bruxelles_req_ids.join(',')})"
      execute "DELETE FROM documents WHERE request_id IN (#{bruxelles_req_ids.join(',')})"
    end

    # Étape 4: Supprimer les enfants des simulations
    if bruxelles_sim_ids.any?
      execute "DELETE FROM documents WHERE simulation_id IN (#{bruxelles_sim_ids.join(',')})"
      execute "DELETE FROM notifications WHERE simulation_id IN (#{bruxelles_sim_ids.join(',')})"
      execute "DELETE FROM requests WHERE simulation_id IN (#{bruxelles_sim_ids.join(',')})"
    end

    # Étape 5: Supprimer les enfants des properties (le plus complexe)
    if bruxelles_prop_ids.any?
      # D'abord supprimer les tables feuilles qui référencent property
      execute "DELETE FROM document_phase_statuses WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
      execute "DELETE FROM documents WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
      execute "DELETE FROM factures WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
      execute "DELETE FROM notifications WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
      execute "DELETE FROM prime_submissions WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"

      # Ensuite supprimer projects (qui pourrait avoir d'autres dépendances)
      property_project_ids = connection.select_values("SELECT id FROM projects WHERE property_id IN (#{bruxelles_prop_ids.join(',')})")
      if property_project_ids.any?
        # Supprimer ce qui référence project_id
        execute "DELETE FROM documents WHERE project_id IN (#{property_project_ids.join(',')})" rescue nil
        execute "DELETE FROM factures WHERE project_id IN (#{property_project_ids.join(',')})" rescue nil
        execute "DELETE FROM projects WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
      end

      # Puis requests et simulations qui référencent property
      execute "DELETE FROM requests WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
      execute "DELETE FROM simulations WHERE property_id IN (#{bruxelles_prop_ids.join(',')})"
    end

    # Étape 6: Enfin supprimer les tables principales
    execute "DELETE FROM primes WHERE region = 'bruxelles'"
    execute "DELETE FROM categories WHERE region = 'bruxelles'"
    execute "DELETE FROM simulations WHERE region = 'bruxelles'"
    execute "DELETE FROM requests WHERE region = 'bruxelles'"
    execute "DELETE FROM properties WHERE region = 'bruxelles'"

    say "✅ Toutes les données Bruxelles supprimées"
  end

  def down
    # Migration irréversible - les données sont perdues
    raise ActiveRecord::IrreversibleMigration
  end
end

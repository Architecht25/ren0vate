class RemoveAllBruxellesData < ActiveRecord::Migration[8.0]
  def up
    say "🔓 Désactivation temporaire des contraintes FK..."
    execute "SET session_replication_role = 'replica';"
    
    begin
      Prime.where(region: 'bruxelles').delete_all
      say "✅ Primes Bruxelles supprimées"

      Category.where(region: 'bruxelles').delete_all
      say "✅ Catégories Bruxelles supprimées"

      Simulation.where(region: 'bruxelles').delete_all
      say "✅ Simulations Bruxelles supprimées"

      Request.where(region: 'bruxelles').delete_all
      say "✅ Requests Bruxelles supprimées"

      Property.where(region: 'bruxelles').delete_all
      say "✅ Propriétés Bruxelles supprimées"
    ensure
      execute "SET session_replication_role = 'origin';"
      say "🔒 Contraintes FK réactivées"
    end
  end

  def down
    # Migration irréversible - les données sont perdues
    raise ActiveRecord::IrreversibleMigration
  end
end

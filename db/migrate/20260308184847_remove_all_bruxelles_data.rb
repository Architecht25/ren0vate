class RemoveAllBruxellesData < ActiveRecord::Migration[8.0]
  def up
    # Supprimer les primes Bruxelles
    Prime.where(region: 'bruxelles').destroy_all
    puts "✅ Primes Bruxelles supprimées"

    # Supprimer les catégories Bruxelles
    Category.where(region: 'bruxelles').destroy_all
    puts "✅ Catégories Bruxelles supprimées"

    # Supprimer les simulations Bruxelles
    Simulation.where(region: 'bruxelles').destroy_all
    puts "✅ Simulations Bruxelles supprimées"

    # Supprimer les requests Bruxelles
    Request.where(region: 'bruxelles').destroy_all
    puts "✅ Requests Bruxelles supprimées"

    # Supprimer les propriétés Bruxelles
    Property.where(region: 'bruxelles').destroy_all
    puts "✅ Propriétés Bruxelles supprimées"
  end

  def down
    # Migration irréversible - les données sont perdues
    raise ActiveRecord::IrreversibleMigration
  end
end

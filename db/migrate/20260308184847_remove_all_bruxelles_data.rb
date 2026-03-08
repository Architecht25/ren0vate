class RemoveAllBruxellesData < ActiveRecord::Migration[8.0]
  def up
    # Nettoyer les request_progresses qui référencent des primes Bruxelles
    bruxelles_prime_ids = Prime.where(region: 'bruxelles').pluck(:id)
    if bruxelles_prime_ids.any?
      execute "DELETE FROM request_progresses WHERE prime_id IN (#{bruxelles_prime_ids.join(',')})"
      puts "✅ Request progresses Bruxelles supprimés"
    end
    
    # Supprimer les primes Bruxelles
    Prime.where(region: 'bruxelles').delete_all
    puts "✅ Primes Bruxelles supprimées"

    # Supprimer les catégories Bruxelles
    Category.where(region: 'bruxelles').delete_all
    puts "✅ Catégories Bruxelles supprimées"

    # Supprimer les simulations Bruxelles
    Simulation.where(region: 'bruxelles').delete_all
    puts "✅ Simulations Bruxelles supprimées"

    # Supprimer les requests Bruxelles
    Request.where(region: 'bruxelles').delete_all
    puts "✅ Requests Bruxelles supprimées"

    # Supprimer les propriétés Bruxelles
    Property.where(region: 'bruxelles').delete_all
    puts "✅ Propriétés Bruxelles supprimées"
  end

  def down
    # Migration irréversible - les données sont perdues
    raise ActiveRecord::IrreversibleMigration
  end
end

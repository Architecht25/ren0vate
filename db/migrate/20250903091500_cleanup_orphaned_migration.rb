class CleanupOrphanedMigration < ActiveRecord::Migration[8.0]
  def up
    # Supprimer l'entrée orpheline de la migration vide
    execute "DELETE FROM schema_migrations WHERE version = '20250902091545'"
  end

  def down
    # Ne rien faire, on ne veut pas restaurer une migration vide
  end
end

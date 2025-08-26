class FixBceEnterprisesIndexes < ActiveRecord::Migration[8.0]
  def change
    # La table existe déjà, on ajoute juste les index manquants si nécessaire

    unless index_exists?(:bce_enterprises, :status)
      add_index :bce_enterprises, :status
    end

    unless index_exists?(:bce_enterprises, :juridical_form)
      add_index :bce_enterprises, :juridical_form
    end

    unless index_exists?(:bce_enterprises, :type_of_enterprise)
      add_index :bce_enterprises, :type_of_enterprise
    end
  end
end

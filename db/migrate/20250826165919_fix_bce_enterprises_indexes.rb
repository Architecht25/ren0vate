class FixBceEnterprisesIndexes < ActiveRecord::Migration[8.0]
  def change
    # Créer la table bce_enterprises si elle n'existe pas
    unless table_exists?(:bce_enterprises)
      create_table :bce_enterprises do |t|
        t.string :enterprise_number, null: false
        t.string :status
        t.string :juridical_situation
        t.string :type_of_enterprise
        t.string :juridical_form
        t.string :juridical_form_cac
        t.date :start_date

        t.timestamps
      end
    end

    # Ajouter les index seulement s'ils n'existent pas
    unless index_exists?(:bce_enterprises, :enterprise_number)
      add_index :bce_enterprises, :enterprise_number, unique: true
    end

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

class AddRegleMinimisToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :regle_minimis, :boolean, default: false, null: false, comment: "L'entreprise a-t-elle reçu plus de 300.000€ d'aides de minimis sur 3 ans ?"
  end
end

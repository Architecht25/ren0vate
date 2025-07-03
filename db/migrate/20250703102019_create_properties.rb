class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :titre
      t.string :adresse

      t.timestamps
    end
  end
end

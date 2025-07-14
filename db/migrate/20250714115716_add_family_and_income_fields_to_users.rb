class AddFamilyAndIncomeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :situation_familiale, :string
    add_column :users, :revenu_demandeur, :integer
    add_column :users, :annee_revenus_demandeur, :string
    add_column :users, :revenu_conjoint, :integer
    add_column :users, :annee_revenus_conjoint, :string
    add_column :users, :nombre_enfants, :integer
  end
end

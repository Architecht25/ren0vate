class AddQuoteAmountsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :architecte_devis_montant, :decimal, precision: 10, scale: 2
    add_column :projects, :contractor_devis_montant, :decimal, precision: 10, scale: 2
  end
end

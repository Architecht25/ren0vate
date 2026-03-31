class ChangeAerDonneeRevenusToDecimal < ActiveRecord::Migration[8.0]
  def change
    change_column :aer_donnees, :revenu_imposable_global, :decimal, precision: 12, scale: 2
    change_column :aer_donnees, :revenu_demandeur,        :decimal, precision: 12, scale: 2
    change_column :aer_donnees, :revenu_conjoint,         :decimal, precision: 12, scale: 2
  end
end

class AddWallonieDeductionsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :personnes_60_ans_et_plus, :integer
    add_column :users, :femme_enceinte, :boolean
  end
end

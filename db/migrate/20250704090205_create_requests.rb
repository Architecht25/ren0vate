class CreateRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :simulation, null: false, foreign_key: true
      t.float :montant_total
      t.string :status
      t.datetime :submitted_at
      t.datetime :validated_at
      t.datetime :confirmation_offre_at

      t.timestamps
    end
  end
end

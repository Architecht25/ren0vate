class CreateReferrals < ActiveRecord::Migration[8.0]
  def change
    create_table :referrals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email_ami
      t.string :code
      t.string :status

      t.timestamps
    end
  end
end

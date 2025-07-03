class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :nom
      t.string :email

      t.timestamps
    end
  end
end

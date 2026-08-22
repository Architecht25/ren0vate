class CreateRegulatorySources < ActiveRecord::Migration[8.1]
  def change
    create_table :regulatory_sources do |t|
      t.string :url, null: false
      t.string :label, null: false
      t.string :region
      t.text :notes
      t.string :last_content_hash
      t.datetime :last_checked_at
      t.datetime :last_changed_at
      t.boolean :active, default: true, null: false

      t.timestamps

      t.index :url, unique: true
    end
  end
end

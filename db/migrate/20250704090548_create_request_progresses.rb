class CreateRequestProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :request_progresses do |t|
      t.references :request, null: false, foreign_key: true
      t.references :prime, null: false, foreign_key: true
      t.integer :pourcentage
      t.string :step
      t.boolean :completed
      t.datetime :completed_at

      t.timestamps
    end
  end
end

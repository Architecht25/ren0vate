class CreateNpsResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :nps_responses do |t|
      t.references :user, null: false, foreign_key: true
      t.integer    :score, null: false
      t.text       :comment
      t.string     :trigger, default: 'day14'
      t.timestamps
    end

    add_column :users, :nps_prompted_at, :datetime
  end
end

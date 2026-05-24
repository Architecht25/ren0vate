class CreateIntelligenceReports < ActiveRecord::Migration[8.1]
  def change
    create_table :intelligence_reports do |t|
      t.string  :week_of,       null: false  # ex: "2026-W21"
      t.text    :raw_content                  # contenu brut agrégé des sources
      t.text    :analysis                     # analyse Claude
      t.string  :status,        default: 'pending', null: false  # pending/processing/completed/failed
      t.text    :error_message
      t.integer :sources_count, default: 0
      t.timestamps
    end

    add_index :intelligence_reports, :week_of, unique: true
    add_index :intelligence_reports, :status
  end
end

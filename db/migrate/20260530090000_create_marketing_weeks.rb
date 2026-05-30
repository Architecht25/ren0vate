class CreateMarketingWeeks < ActiveRecord::Migration[8.1]
  def change
    create_table :marketing_weeks do |t|
      t.string   :week_of,                null: false
      t.integer  :article_id                          # FK → articles (brouillon créé par l'agent)
      t.text     :linkedin_post
      t.text     :instagram_post
      t.text     :instagram_visual_brief
      t.text     :facebook_post
      t.text     :facebook_visual_brief
      t.string   :status,                 null: false, default: 'draft'
      t.datetime :generated_at
      t.timestamps
    end

    add_index :marketing_weeks, :week_of,    unique: true
    add_index :marketing_weeks, :article_id
    add_index :marketing_weeks, :status
  end
end

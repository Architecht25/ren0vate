class CreateVeilleArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :veille_articles do |t|
      t.string :titre
      t.string :source
      t.date :source_date
      t.string :region
      t.text :themes
      t.text :contenu
      t.text :admin_notes
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end

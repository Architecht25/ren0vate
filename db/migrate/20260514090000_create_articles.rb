class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string   :title,                null: false
      t.string   :slug,                 null: false
      t.text     :excerpt,              null: false
      t.text     :content,              null: false
      t.string   :category,             null: false, default: "conseils"
      t.string   :meta_description
      t.string   :author,               default: "L'équipe Ren0vate"
      t.integer  :reading_time_minutes, default: 3
      t.datetime :published_at
      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, :published_at
    add_index :articles, :category
  end
end

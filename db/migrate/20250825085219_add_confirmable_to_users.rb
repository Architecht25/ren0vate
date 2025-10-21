class AddConfirmableToUsers < ActiveRecord::Migration[8.0]
  def up
    # Ajouter les colonnes confirmable
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    # Ajouter les index
    add_index :users, :confirmation_token, unique: true

    # Confirmer automatiquement tous les utilisateurs existants (sans utiliser le modèle)
    execute "UPDATE users SET confirmed_at = NOW() WHERE confirmed_at IS NULL"
  end

  def down
    remove_index :users, :confirmation_token
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
  end
end

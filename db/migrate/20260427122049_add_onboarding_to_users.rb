class AddOnboardingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :user_profile, :integer, default: 0, null: false
    add_column :users, :onboarding_completed_at, :datetime
    add_column :users, :nom_cabinet, :string
    add_column :users, :num_bce, :string
    add_index :users, :user_profile

    # Backfill : marquer tous les comptes existants comme onboarding terminé
    # pour ne pas les rediriger vers le wizard au prochain déploiement
    reversible do |dir|
      dir.up { User.update_all(onboarding_completed_at: Time.current) }
    end
  end
end

class BackfillOnboardingCompletedAtForExistingUsers < ActiveRecord::Migration[8.1]
  def up
    # Les utilisateurs créés avant l'implémentation de l'onboarding n'ont pas
    # onboarding_completed_at. On les considère comme ayant terminé l'onboarding
    # afin qu'ils puissent accéder au dashboard normalement.
    User.where(onboarding_completed_at: nil).update_all(onboarding_completed_at: Time.current)
  end

  def down
    # Irreversible : on ne sait pas quels utilisateurs avaient réellement complété l'onboarding
  end
end

class Notification < ApplicationRecord
  self.inheritance_column = nil  # Désactiver l'héritage STI pour la colonne 'type'

  belongs_to :user
  belongs_to :property, optional: true

  validates :message, :type, presence: true

  # Scope pour récupérer les notifications récentes
  scope :recent, -> { order(created_at: :desc) }
end

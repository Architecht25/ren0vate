class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :simulations, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :projects, through: :properties, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :documents, dependent: :destroy

  belongs_to :last_active_simulation, class_name: "Simulation", optional: true

  # Méthodes pour la soumission et le paiement
  def can_submit?
    # Logique pour vérifier si l'utilisateur peut soumettre
    # À adapter selon votre modèle économique success fee
    has_active_subscription? || agreed_to_success_fee?
  end

  def has_active_subscription?
    # À implémenter avec votre système d'abonnement
    false
  end

  def agreed_to_success_fee?
    # À implémenter - vérifier si l'utilisateur a accepté les conditions success fee
    true # Pour l'instant, autoriser tous les utilisateurs
  end

  def submission_status
    if can_submit?
      'authorized'
    else
      'payment_required'
    end
  end
end

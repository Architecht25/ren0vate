class PrimeSubmission < ApplicationRecord
  belongs_to :property
  belongs_to :user

  enum :status, {
    draft: 0,
    submitted: 1,
    in_review: 2,
    additional_info_required: 3,
    approved: 4,
    rejected: 5,
    paid: 6
  }

  enum :region, {
    flandre: 0,
    wallonie: 1,
    bruxelles: 2
  }

  validates :dossier_number, presence: true, uniqueness: true
  validates :region, presence: true

  serialize :form_data, coder: JSON
  serialize :admin_response_data, coder: JSON

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: [:submitted, :in_review, :additional_info_required]) }

  def status_badge_class
    case status
    when 'submitted', 'in_review'
      'bg-primary'
    when 'additional_info_required'
      'bg-warning'
    when 'approved'
      'bg-success'
    when 'rejected'
      'bg-danger'
    when 'paid'
      'bg-success'
    else
      'bg-secondary'
    end
  end

  def status_text
    case status
    when 'submitted'
      'Soumise'
    when 'in_review'
      'En cours d\'instruction'
    when 'additional_info_required'
      'Informations complémentaires requises'
    when 'approved'
      'Approuvée'
    when 'rejected'
      'Refusée'
    when 'paid'
      'Prime versée'
    else
      'Brouillon'
    end
  end

  def estimated_amount
    # À calculer selon les travaux et la région
    case region
    when 'flandre'
      calculate_flandre_amount
    when 'wallonie'
      calculate_wallonie_amount
    when 'bruxelles'
      calculate_bruxelles_amount
    else
      0
    end
  end

  def success_fee_amount
    amount = estimated_amount
    case amount
    when 0...5000
      (amount * 0.10).round(2)
    when 5000...15000
      (amount * 0.08).round(2)
    when 15000...30000
      (amount * 0.06).round(2)
    else
      (amount * 0.05).round(2)
    end
  end

  def success_fee_percentage
    amount = estimated_amount
    case amount
    when 0...5000
      10
    when 5000...15000
      8
    when 15000...30000
      6
    else
      5
    end
  end

  private

  def calculate_flandre_amount
    # Utiliser le total de la simulation Flandre la plus récente de cette propriété
    simulation = property.simulations
                         .where(region: 'flandre')
                         .order(updated_at: :desc)
                         .first
    return simulation.total_complet_amount.to_f if simulation&.total_complet_amount&.positive?

    # Fallback sur form_data si disponible (clé total_simule sauvegardée lors de la soumission)
    form_data&.dig('total_simule').to_f
  end

  def calculate_wallonie_amount
    # Logique de calcul pour la Wallonie
    8000 # Exemple
  end

  def calculate_bruxelles_amount
    # Logique de calcul pour Bruxelles
    12000 # Exemple
  end
end

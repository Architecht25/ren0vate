class Lease < ApplicationRecord
  belongs_to :property
  belongs_to :tenant
  has_many :rent_payments, dependent: :destroy

  enum :lease_type, {
    residence_principale: 'residence_principale',
    courte_duree: 'courte_duree',
    meuble: 'meuble',
    commercial: 'commercial'
  }, prefix: false

  enum :status, {
    actif: 'actif',
    termine: 'termine',
    en_resiliation: 'en_resiliation'
  }, prefix: false

  validates :start_date, presence: true
  validates :rent_amount, presence: true, numericality: { greater_than: 0 }
  validates :lease_type, presence: true
  validates :status, presence: true

  # Durée minimale légale selon type de bail (en mois, droit belge)
  DUREE_MINIMALE = {
    'residence_principale' => 36,  # 3 ans
    'courte_duree' => 3,
    'meuble' => 1,
    'commercial' => 0
  }.freeze

  # Délai de préavis légal (mois) selon ancienneté — locataire
  def preavis_locataire_mois
    return 1 if courte_duree? || meuble?
    anciennete = anciennete_mois
    if anciennete < 12
      3
    elsif anciennete < 24
      4
    elsif anciennete < 36
      5
    else
      6
    end
  end

  # Délai de préavis légal (mois) — propriétaire (résidence principale)
  def preavis_proprietaire_mois(motif: :reprise_personnelle)
    return 1 if courte_duree? || meuble?
    anciennete = anciennete_mois
    case motif
    when :reprise_personnelle
      if anciennete < 36
        6
      elsif anciennete < 72
        9
      else
        12
      end
    when :travaux
      if anciennete < 36
        6
      elsif anciennete < 72
        9
      else
        12
      end
    when :sans_motif
      # Uniquement à l'échéance du bail (3-6-9)
      if anciennete < 36
        6
      elsif anciennete < 72
        9
      else
        6
      end
    else
      6
    end
  end

  def anciennete_mois
    fin = end_date || Date.current
    ((fin.year - start_date.year) * 12) + (fin.month - start_date.month)
  end

  def loyer_total
    (rent_amount || 0) + (charges_amount || 0)
  end

  # Calcul indexation selon indice santé belge
  # loyer_indexe = loyer_base * (indice_nouveau / indice_base)
  # Ici on expose la formule — l'indice réel est à récupérer sur statbel.fgov.be
  def mois_indexation_prochain
    return nil if indexation_month.blank?
    today = Date.current
    target = Date.new(today.year, indexation_month, 1)
    target = target.next_year if target <= today
    target
  end

  def statut_label
    case status
    when 'actif' then 'Actif'
    when 'termine' then 'Terminé'
    when 'en_resiliation' then 'En résiliation'
    end
  end

  def statut_badge_class
    case status
    when 'actif' then 'success'
    when 'termine' then 'secondary'
    when 'en_resiliation' then 'warning'
    end
  end

  def lease_type_label
    case lease_type
    when 'residence_principale' then 'Résidence principale'
    when 'courte_duree' then 'Courte durée (< 3 ans)'
    when 'meuble' then 'Meublé'
    when 'commercial' then 'Commercial'
    end
  end

  # Paiements du mois en cours
  def paiement_mois_courant
    rent_payments.where(
      due_date: Date.current.beginning_of_month..Date.current.end_of_month
    ).first
  end

  # Solde impayé total
  def montant_impaye
    rent_payments.where(status: %w[pending late]).sum(:amount)
  end
end

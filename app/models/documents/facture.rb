class Facture < ApplicationRecord
  belongs_to :document
  belongs_to :project
  belongs_to :property, optional: true

  # Validations
  validates :montant, numericality: { greater_than: 0 }, if: :valide_manuellement?
  validates :montant, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, unless: :valide_manuellement?
  validates :type_facture, presence: true, inclusion: { in: %w[devis facture acompte solde etat_avancement] }
  validates :statut_paiement, presence: true, inclusion: { in: %w[non_paye paye partiel] }
  validates :confiance_ocr, numericality: { in: 0..100 }, allow_nil: true

  # Validations pour le type d'intervenant
  validates :type_intervenant, inclusion: { in: %w[architecte entrepreneur autre] }, allow_nil: true

  # Scopes pour les requêtes courantes
  scope :devis, -> { where(type_facture: 'devis') }
  scope :factures, -> { where(type_facture: ['facture', 'acompte', 'solde', 'etat_avancement']) }
  scope :factures_solde, -> { where(facture_solde: true) }
  scope :payees, -> { where(statut_paiement: 'paye') }
  scope :non_payees, -> { where(statut_paiement: 'non_paye') }
  scope :extraction_validee, -> { where(valide_manuellement: true) }
  scope :extraction_complete, -> { where(extraction_complete: true) }
  scope :expiration_proche, -> { where('jours_avant_expiration <= ?', 90) }
  scope :expiration_critique, -> { where('jours_avant_expiration <= ?', 30) }
  scope :par_intervenant, ->(type) { where(type_intervenant: type) }
  scope :architecte, -> { where(type_intervenant: 'architecte') }
  scope :entrepreneur, -> { where(type_intervenant: 'entrepreneur') }
  scope :travaux_only, -> { where(type_facture: %w[facture acompte solde etat_avancement]) }

  # Callbacks
  before_save :calculer_date_limite_prime
  before_save :calculer_jours_avant_expiration
  before_save :detecter_facture_solde
  before_save :verifier_extraction_complete

  # Méthodes d'instance

  def devis?
    type_facture == 'devis'
  end

  def facture?
    %w[facture acompte solde].include?(type_facture)
  end

  def payee?
    statut_paiement == 'paye'
  end

  def extraction_fiable?
    confiance_ocr && confiance_ocr >= 75
  end

  def delai_prime_expire?
    date_limite_prime && Date.current > date_limite_prime
  end

  def delai_prime_critique?
    jours_avant_expiration && jours_avant_expiration <= 30
  end

  def delai_prime_proche?
    jours_avant_expiration && jours_avant_expiration <= 90
  end

  # Formatage pour affichage
  def montant_formate
    "#{montant&.to_f&.round(2)} €"
  end

  def numero_facture_display
    numero_facture.presence || "Non extrait"
  end

  def date_facture_display
    date_facture&.strftime("%d/%m/%Y") || "Non extraite"
  end

  def entreprise_display
    nom_entreprise.presence || "Non extraite"
  end

  def confiance_display
    confiance_ocr ? "#{confiance_ocr.round(1)}%" : "N/A"
  end

  def statut_badge_class
    case statut_paiement
    when 'paye' then 'bg-success'
    when 'partiel' then 'bg-warning'
    when 'non_paye' then 'bg-danger'
    else 'bg-secondary'
    end
  end

  def type_badge_class
    case type_facture
    when 'devis'            then 'bg-info'
    when 'facture'          then 'bg-primary'
    when 'acompte'          then 'bg-warning'
    when 'solde'            then 'bg-success'
    when 'etat_avancement'  then 'bg-info text-dark'
    else 'bg-secondary'
    end
  end

  def type_facture_display
    case type_facture
    when 'devis'            then 'Devis'
    when 'facture'          then 'Facture'
    when 'acompte'          then 'Acompte'
    when 'solde'            then 'Solde'
    when 'etat_avancement'  then "État d'avancement"
    else type_facture&.humanize
    end
  end

  def type_intervenant_display
    case type_intervenant
    when 'architecte'   then 'Architecte'
    when 'entrepreneur' then 'Entrepreneur'
    when 'autre'        then 'Autre'
    else 'Non classifié'
    end
  end

  # Méthodes pour les données extraites JSON
  def ajouter_donnee_extraite(cle, valeur)
    self.donnees_extraites ||= {}
    self.donnees_extraites[cle] = valeur
  end

  def obtenir_donnee_extraite(cle)
    donnees_extraites&.dig(cle)
  end

  # Alerte de délai
  def message_alerte_delai
    return nil unless date_limite_prime

    if delai_prime_expire?
      "⚠️ DÉLAI EXPIRÉ - La demande de prime devait être introduite avant le #{date_limite_prime.strftime('%d/%m/%Y')}"
    elsif delai_prime_critique?
      "🚨 URGENT - Plus que #{jours_avant_expiration} jours pour introduire la demande de prime"
    elsif delai_prime_proche?
      "⏰ ATTENTION - Plus que #{jours_avant_expiration} jours pour introduire la demande de prime"
    end
  end

  def couleur_alerte_delai
    return 'danger' if delai_prime_expire? || delai_prime_critique?
    return 'warning' if delai_prime_proche?
    'success'
  end

  private

  def calculer_date_limite_prime
    if date_facture.present? && facture_solde?
      self.date_limite_prime = date_facture + 12.months
    end
  end

  def calculer_jours_avant_expiration
    if date_limite_prime.present?
      self.jours_avant_expiration = (date_limite_prime - Date.current).to_i
    end
  end

  def detecter_facture_solde
    # Logique de détection automatique de facture de solde
    if texte_ocr_brut.present?
      texte_lower = texte_ocr_brut.downcase
      mots_cles_solde = ['solde', 'final', 'finale', 'dernier', 'dernière', 'complément', 'reliquat']

      self.facture_solde = mots_cles_solde.any? { |mot| texte_lower.include?(mot) } ||
                          type_facture == 'solde'
    end
  end

  def verifier_extraction_complete
    champs_requis = [montant, date_facture, type_facture]
    champs_optionnels_completes = [numero_facture, nom_entreprise].count(&:present?)

    self.extraction_complete = champs_requis.all?(&:present?) &&
                              champs_optionnels_completes >= 1 &&
                              (confiance_ocr.nil? || confiance_ocr >= 60)
  end
end

class Project < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :request, optional: true
  has_many :documents, dependent: :destroy
  has_many :chantier_analyses, dependent: :destroy
  has_many :simulations, dependent: :destroy  # Ajouter cette ligne

  # Suivi du dossier de prêt bonifié wallon (régime "reduction_pret", dès le 01/10/2026)
  has_one :pret_wallonie_dossier, dependent: :destroy

  # Collaboration — membres du projet
  has_many :project_members, dependent: :destroy
  has_many :member_users, through: :project_members, source: :user

  # Relations pour les factures
  has_many :factures, dependent: :destroy
  has_many :factures_devis, -> { where(type_facture: 'devis') }, class_name: 'Facture'
  has_many :factures_travaux, -> { where(type_facture: %w[facture acompte solde etat_avancement]) }, class_name: 'Facture'
  has_many :peb_donnees, -> { where(phase: 'apres_travaux') }, dependent: :nullify, foreign_key: :project_id

  # Devis scannés (OCR)
  has_many :devis_donnees,             dependent: :nullify
  has_many :bordereau_chassis_donnees, dependent: :nullify

  # Réserves de réception (punch list)
  has_many :reserves, class_name: 'Reserve', dependent: :destroy

  # PV de réception numérique
  has_one :pv_reception, dependent: :destroy

  # PV de visite de chantier (multiples, produits par l'architecte)
  has_many :pv_visites, dependent: :destroy

  # États d'avancement structurés (bordereaux)
  has_many :etats_avancement, class_name: 'EtatAvancement', foreign_key: :project_id, dependent: :destroy

  # Checklists d'inspection par phase
  has_many :project_checklists, dependent: :destroy

  # Carnet de bord — notes libres du user sur le chantier
  has_many :project_notes, dependent: :destroy

  validates :nom, presence: true
  validates :property_id, presence: true
  validates :project_type, presence: true, inclusion: { in: %w[renovation investment],
                                                       message: "doit être 'renovation' ou 'investment'" }

  # Définir un statut et type par défaut
  before_validation :set_default_status
  before_validation :set_default_project_type

  # Rappel légal (30 jours, art. 473 CIR92) — chantier marqué "terminé" manuellement
  # via le formulaire d'édition (voir _basic_fields.html.erb / project_params).
  # Voir aussi PvReception#check_and_finalise! pour le second déclencheur possible.
  after_update :notify_declaration_cadastrale, if: -> { saved_change_to_statut? && statut == 'termine' }

  # Sérialisation JSON pour les champs complexes
  serialize :architecte_specialites, coder: JSON
  serialize :entrepreneur_principal_certifications, coder: JSON
  serialize :corps_metiers, coder: JSON
  serialize :garanties_travaux, coder: JSON

  # Méthodes pour les types de projets
  def renovation?
    project_type == 'renovation'
  end

  def investment?
    project_type == 'investment'
  end

  def type_display
    case project_type
    when 'renovation'
      'Chantier de rénovation'
    when 'investment'
      'Investissement d\'entreprise'
    else
      project_type.humanize
    end
  end

  # Méthode pour affichage
  def name
    nom
  end

  # Méthode pour compatibilité
  def display_name
    "#{nom} (#{property&.name || 'Sans bien associé'})"
  end

  # Méthodes pour les professionnels
  def architecte_nom_complet
    [architecte_prenom, architecte_nom].compact.join(' ')
  end

  def architecte_complet?
    architecte_nom.present? && architecte_prenom.present? && architecte_email.present?
  end

  def entrepreneur_principal_complet?
    entrepreneur_principal_nom.present? && entrepreneur_principal_entreprise.present?
  end

  def has_coordinateur_securite?
    coordinateur_securite_nom.present?
  end

  # Méthodes pour gérer les corps de métiers (stockés en JSON)
  def corps_metiers_list
    corps_metiers || []
  end

  def add_corps_metier(nom:, entreprise:, contact: nil, specialite: nil)
    self.corps_metiers ||= []
    self.corps_metiers << {
      nom: nom,
      entreprise: entreprise,
      contact: contact,
      specialite: specialite,
      ajoute_le: Time.current
    }
  end

  def remove_corps_metier(index)
    return unless corps_metiers && corps_metiers[index]
    self.corps_metiers.delete_at(index)
  end

  # Gestion des types de travaux Flandre
  def type_travaux_array
    return [] if type_travaux.blank?
    type_travaux.split(',').map(&:strip)
  end

  def type_travaux_array=(array)
    self.type_travaux = array.reject(&:blank?).join(',')
  end

  # Méthodes virtuelles pour les checkboxes
  def type_travaux_isolation
    type_travaux_array.include?('isolation')
  end

  def type_travaux_isolation=(value)
    update_type_travaux('isolation', value == '1')
  end

  def type_travaux_chauffage
    type_travaux_array.include?('chauffage')
  end

  def type_travaux_chauffage=(value)
    update_type_travaux('chauffage', value == '1')
  end

  def type_travaux_ventilation
    type_travaux_array.include?('ventilation')
  end

  def type_travaux_ventilation=(value)
    update_type_travaux('ventilation', value == '1')
  end

  def type_travaux_fenetres
    type_travaux_array.include?('fenetres')
  end

  def type_travaux_fenetres=(value)
    update_type_travaux('fenetres', value == '1')
  end

  def type_travaux_toiture
    type_travaux_array.include?('toiture')
  end

  def type_travaux_toiture=(value)
    update_type_travaux('toiture', value == '1')
  end

  def type_travaux_autre
    type_travaux_array.include?('autre')
  end

  def type_travaux_autre=(value)
    update_type_travaux('autre', value == '1')
  end

  # Validations pour les montants de devis
  validates :architecte_devis_montant, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :contractor_devis_montant, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Méthodes pour les montants de devis
  def total_devis_montant
    ocr = total_devis_ocr
    ocr > 0 ? ocr : (architecte_devis_montant || 0) + (contractor_devis_montant || 0)
  end

  # ── Méthodes OCR devis ────────────────────────────────────────────────────
  def total_devis_ocr(categorie = nil)
    scope = devis_donnees.with_montant
    scope = scope.par_categorie(categorie) if categorie
    scope.sum(:montant_total_htva).to_f
  end

  def devis_ocr_architecte
    devis_donnees.par_categorie('architecte').avec_montant.order(created_at: :desc)
  end

  def devis_ocr_entrepreneur
    devis_donnees.par_categorie('entrepreneur').avec_montant.order(created_at: :desc)
  end

  # Montant effectif pour le suivi budgétaire (OCR > manuel)
  def architecte_devis_montant_effectif
    ocr = total_devis_ocr('architecte')
    ocr > 0 ? ocr : architecte_devis_montant&.to_f
  end

  def contractor_devis_montant_effectif
    ocr = total_devis_ocr('entrepreneur')
    ocr > 0 ? ocr : contractor_devis_montant&.to_f
  end

  def architecte_factures_total
    factures.travaux_only.architecte.sum(:montant).to_f
  end

  def contractor_factures_total
    factures.travaux_only.entrepreneur.sum(:montant).to_f
  end

  def architecte_devis_vs_factures_difference
    montant = architecte_devis_montant_effectif
    return nil unless montant
    architecte_factures_total - montant
  end

  def contractor_devis_vs_factures_difference
    montant = contractor_devis_montant_effectif
    return nil unless montant
    contractor_factures_total - montant
  end

  def total_devis_vs_factures_difference
    (architecte_devis_vs_factures_difference || 0) + (contractor_devis_vs_factures_difference || 0)
  end

  # Méthodes pour l'affichage formaté
  def architecte_devis_montant_formatted
    return "Non renseigné" unless architecte_devis_montant
    "#{architecte_devis_montant.to_f.round(2)} €"
  end

  def contractor_devis_montant_formatted
    return "Non renseigné" unless contractor_devis_montant
    "#{contractor_devis_montant.to_f.round(2)} €"
  end

  # ── Phases d'avancement du chantier ──────────────────────────────────────
  PHASES_CHANTIER = [
    { key: 'preparation',    label: 'Préparation',        icon: 'bi-clipboard-check' },
    { key: 'demolition',     label: 'Démolition/Dépose',  icon: 'bi-tools' },
    { key: 'installation',   label: 'Installation/Pose',  icon: 'bi-hammer' },
    { key: 'finitions',      label: 'Finitions',          icon: 'bi-brush' },
    { key: 'reception',      label: 'Réception',          icon: 'bi-file-earmark-check' }
  ].freeze

  def phase_pct(key)
    ((phases_avancement || {})[key.to_s].to_i).clamp(0, 100)
  end

  # Retourne le hash de validations numériques pour une phase.
  # Les clés de validation sont préfixées 'phase_' (ex: 'phase_preparation').
  # Les clés de PHASES_CHANTIER n'ont pas ce préfixe (ex: 'preparation', 'finitions').
  # On gère aussi la singularisation de 'finitions' → 'phase_finition'.
  def phase_validations(key)
    k       = key.to_s
    val_key = k.start_with?('phase_') ? k : "phase_#{k.delete_suffix('s')}"
    val     = (phases_avancement || {})[val_key]
    val.is_a?(Hash) ? val : {}
  end

  def avancement_global_pct
    return 0 if PHASES_CHANTIER.empty?
    total = PHASES_CHANTIER.sum { |p| phase_pct(p[:key]) }
    (total.to_f / PHASES_CHANTIER.length).round
  end

  def total_facture
    architecte_factures_total + contractor_factures_total
  end

  private

  def set_default_status
    self.statut ||= 'preparation'
  end

  def set_default_project_type
    self.project_type ||= 'renovation'
  end

  def notify_declaration_cadastrale
    Notification.create_declaration_cadastrale(user, self)
  end

  def update_type_travaux(type, should_include)
    current_types = type_travaux_array
    if should_include
      current_types << type unless current_types.include?(type)
    else
      current_types.delete(type)
    end
    self.type_travaux = current_types.join(',')
  end
end

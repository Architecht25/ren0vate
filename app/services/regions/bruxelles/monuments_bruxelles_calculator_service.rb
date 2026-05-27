# frozen_string_literal: true

# Calcul des subventions Monuments & Sites — Bruxelles
# Référence légale : AGovt 2 mai 2024 (COBAT — patrimoine architectural bruxellois)
# https://monument.heritage.brussels/fr/subventions/
class Regions::Bruxelles::MonumentsBruxellesCalculatorService
  # Taux de subvention selon le type de bénéficiaire (travaux hors études)
  TAUX = {
    "prive_bas_revenus" => 0.50,   # Personne physique, revenus ménage ≤ 40 000 € (+2 500 €/pers. à charge)
    "prive"             => 0.40,   # Personne physique (revenus normaux) — enveloppe extérieure
    "asbl"              => 0.60,   # ASBL, fondation, association
    "public"            => 0.80    # Commune, CPAS, SISP, institution d'enseignement, culte
  }.freeze

  # Études préalables : taux fixe 80% pour TOUS les types de bénéficiaires (AGovt 2 mai 2024, art. 22)
  TAUX_ETUDES = 0.80

  # Plafond subvention études préalables
  PLAFOND_ETUDES = 12_000

  # Plafond indicatif travaux (pas de plafond légal fixe, mais pour l'estimation)
  PLAFOND_TRAVAUX = 1_500_000

  def initialize(type_beneficiaire:, montant_travaux:, type_travaux: "conservation")
    @type_beneficiaire = type_beneficiaire.to_s
    @montant_travaux   = montant_travaux.to_f
    @type_travaux      = type_travaux.to_s
  end

  def calculate
    return ineligible("Type de bénéficiaire inconnu") unless TAUX.key?(@type_beneficiaire)
    return ineligible("Montant des travaux invalide") if @montant_travaux <= 0

    # Études préalables : toujours subventionnées à 80%, quel que soit le type de bénéficiaire
    taux            = @type_travaux == "etudes" ? TAUX_ETUDES : TAUX[@type_beneficiaire]
    montant_brut    = (@montant_travaux * taux).round(2)
    montant_estime  = apply_caps(montant_brut)

    {
      eligible:          true,
      type_beneficiaire: @type_beneficiaire,
      taux:              taux,
      taux_pct:          (taux * 100).to_i,
      montant_travaux:   @montant_travaux,
      montant_estime:    montant_estime,
      type_travaux:      @type_travaux,
      plafond_applique:  montant_estime < montant_brut,
      note:              note_legale
    }
  end

  private

  def apply_caps(montant)
    if @type_travaux == "etudes"
      [montant, PLAFOND_ETUDES].min
    else
      [montant, PLAFOND_TRAVAUX].min
    end
  end

  def note_legale
    if @type_travaux == "etudes"
      "Études préalables — taux fixe 80% pour tous les bénéficiaires, subvention max #{number_to_currency(PLAFOND_ETUDES)}"
    else
      "Conservation / restauration (enveloppe extérieure) — taux #{(TAUX[@type_beneficiaire] * 100).to_i}%. " \
        "Les travaux ne peuvent débuter qu'après accord du Gouvernement."
    end
  end

  def ineligible(reason)
    { eligible: false, reason: reason }
  end

  def number_to_currency(amount)
    "#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse} €"
  end
end

# frozen_string_literal: true

# Calcul des subventions Petit Patrimoine — Bruxelles
# Référence légale : AGRBC du 24 juin 2010, modifié par les AGRBC du 31 janvier 2013 et du 11 mars 2021
# https://patrimoine.brussels/
class Regions::Bruxelles::PetitPatrimoineBruxellesCalculatorService
  REFERENCE_LEGALE = "AGRBC du 24 juin 2010, modifié par les AGRBC du 31 janvier 2013 et du 11 mars 2021"

  # Taux et plafonds de subvention selon le type de bénéficiaire
  TAUX = {
    "public"                     => { taux: 0.75, plafond: 15_000 },
    "prive"                      => { taux: 0.50, plafond: 10_000 },
    "prive_revenus_bas"          => { taux: 0.75, plafond: 15_000 }, # revenus ménage < 40 000 € (+2 500 €/pers. à charge)
    "prive_zone_revitalisation"  => { taux: 0.75, plafond: 15_000 }
  }.freeze

  def initialize(type_beneficiaire:, montant_travaux_htva:)
    @type_beneficiaire    = type_beneficiaire.to_s
    @montant_travaux_htva = montant_travaux_htva.to_f
  end

  def calculate
    return ineligible("Type de bénéficiaire inconnu") unless TAUX.key?(@type_beneficiaire)
    return ineligible("Montant des travaux invalide") if @montant_travaux_htva <= 0

    config         = TAUX[@type_beneficiaire]
    montant_brut   = (@montant_travaux_htva * config[:taux]).round(2)
    montant_estime = apply_caps(montant_brut, config[:plafond])

    {
      eligible:          true,
      type_beneficiaire: @type_beneficiaire,
      taux:              config[:taux],
      taux_pct:          (config[:taux] * 100).to_i,
      montant_travaux:   @montant_travaux_htva,
      montant_estime:    montant_estime,
      plafond_applique:  config[:plafond],
      plafond_atteint:   montant_estime < montant_brut,
      note:              REFERENCE_LEGALE
    }
  end

  private

  def apply_caps(montant, plafond)
    [montant, plafond].min
  end

  def ineligible(reason)
    { eligible: false, reason: reason }
  end
end

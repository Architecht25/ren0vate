module Subsidies
  # PebRateImpactEstimatorService
  #
  # Traduit le score PEB d'un bien en impact indicatif sur le taux d'un prêt
  # hypothécaire, sur base de politiques bancaires publiées (pas de taux live,
  # pas d'API bancaire — cf. PebRateImpactEstimatorServiceTest).
  #
  # Source : Trends-Tendances, 24/09/2026, "Comment le certificat PEB impacte
  # votre prêt" (étude Sia Partners citant BNP Paribas Fortis, Belfius, CBC).
  class PebRateImpactEstimatorService
    SOURCE_NOTE = "Politiques publiées par les banques, citées dans Trends-Tendances du 24/09/2026 " \
                  "(étude Sia Partners) — à confirmer auprès de votre banque, ne constitue pas un engagement de taux.".freeze

    SEUIL_SCORE_EP = 150 # kWh/m²/an
    SEUIL_REDUCTION_PCT = 30 # % de réduction du score_ep entre avant/après travaux

    LABELS_ELIGIBLES_CBC = %w[A++ A+ A B C].freeze # labels D→A : réduction de 5 à 20 pts de base

    def initialize(peb_avant:, peb_apres: nil)
      @peb_avant = peb_avant
      @peb_apres = peb_apres
    end

    def call
      [bnp_paribas_fortis, belfius, cbc]
    end

    private

    attr_reader :peb_avant, :peb_apres

    def bnp_paribas_fortis
      eligible = score_disponible? ? score_ep_avant <= SEUIL_SCORE_EP : nil

      {
        banque:    "BNP Paribas Fortis",
        condition: "Score PEB ≤ #{SEUIL_SCORE_EP} kWh/m²/an fourni à l'achat",
        impact:    "-0,10 % sur le taux",
        eligible:  eligible,
        note:      eligible.nil? ? donnee_insuffisante_note(:score) : SOURCE_NOTE
      }
    end

    def belfius
      eligible = if score_disponible?
                   score_ep_avant <= SEUIL_SCORE_EP || reduction_score_suffisante?
                 end

      {
        banque:    "Belfius",
        condition: "Score PEB ≤ #{SEUIL_SCORE_EP} kWh/m²/an, ou rénovation réduisant le score d'au moins #{SEUIL_REDUCTION_PCT} % " \
                   "(réduction différée possible jusqu'à 6 ans après l'acte)",
        impact:    "-0,20 % sur le taux",
        eligible:  eligible,
        note:      eligible.nil? ? donnee_insuffisante_note(:score) : SOURCE_NOTE
      }
    end

    def cbc
      eligible = if label_disponible?
                   LABELS_ELIGIBLES_CBC.include?(peb_avant.label_peb.to_s.upcase) || amelioration_label_suffisante?
                 end

      {
        banque:    "CBC (KBC Wallonie)",
        condition: "Label D→A, réduction différée possible jusqu'à 7 ans après le début du crédit",
        impact:    "-5 à -20 points de base selon le label",
        eligible:  eligible,
        note:      eligible.nil? ? donnee_insuffisante_note(:label) : SOURCE_NOTE
      }
    end

    def score_disponible?
      peb_avant&.score_ep.present?
    end

    def label_disponible?
      peb_avant&.label_peb.present?
    end

    def score_ep_avant
      peb_avant.score_ep.to_f
    end

    def reduction_score_suffisante?
      return false unless peb_apres&.score_ep.present? && score_ep_avant.positive?

      reduction_pct = (score_ep_avant - peb_apres.score_ep.to_f) / score_ep_avant * 100
      reduction_pct >= SEUIL_REDUCTION_PCT
    end

    def amelioration_label_suffisante?
      return false unless peb_apres&.label_peb.present?

      peb_apres.score_label_numerique > peb_avant.score_label_numerique
    end

    def donnee_insuffisante_note(type)
      champ = type == :score ? "le score énergétique (kWh/m²/an)" : "le label PEB"
      "Donnée insuffisante sur le certificat scanné — #{champ} n'a pas été extrait."
    end
  end
end

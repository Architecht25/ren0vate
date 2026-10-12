# V2 — Lot 2 : comparateur de devis par lot (cahier des charges §5.C :
# "Comparateur de devis par lot (normalisation des postes)"). Version
# déterministe pour le MVP — regroupe par lot, classe par montant, et
# repère les postes présents chez certains entrepreneurs mais absents chez
# d'autres (rapprochement par description exacte, pas de normalisation
# sémantique). L'analyse assistée par IA (détection de postes manquants
# formulée en langage naturel, prix hors fourchette — cahier des charges
# §8.2) est un approfondissement possible de ce service, pas encore fait.
module ProjectQuotes
  class ComparatorService
    def initialize(lot)
      @lot = lot
    end

    def call
      quotes = @lot.project_quotes.includes(:lines).order(:montant_ttc)
      return { quotes: [], missing_lines_by_quote: {} } if quotes.empty?

      all_descriptions = quotes.flat_map { |q| q.lines.map(&:description) }.uniq

      missing_lines_by_quote = quotes.index_with do |quote|
        quote_descriptions = quote.lines.map(&:description)
        all_descriptions - quote_descriptions
      end

      {
        quotes: quotes.to_a,
        cheapest: quotes.min_by(&:montant_ttc),
        most_expensive: quotes.max_by(&:montant_ttc),
        missing_lines_by_quote: missing_lines_by_quote
      }
    end
  end
end

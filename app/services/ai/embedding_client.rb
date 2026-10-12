# V2 — Lot 5 : client d'embeddings Voyage AI (cahier des charges §2 :
# "pgvector pour les embeddings des documents"). Anthropic ne fournit pas
# d'API d'embeddings — Voyage AI est son partenaire officiellement
# recommandé, choisi avec Robin le 12/10/2026.
#
# Modèle "voyage-3" et dimension 1024 vérifiés par un appel réel le
# 12/10/2026 (clé VOYAGE_API_KEY fournie par Robin) — voir
# docs/QUESTIONS_OUVERTES.md Q15 pour l'historique. Implémenté en HTTP
# direct (httparty, déjà une dépendance) plutôt qu'un SDK dédié — Voyage
# AI n'a pas de gem Ruby officielle.
module Ai
  class EmbeddingClient
    ENDPOINT = "https://api.voyageai.com/v1/embeddings"
    MODEL = "voyage-3"
    DIMENSION = 1024

    def initialize
      @api_key = ENV["VOYAGE_API_KEY"]
    end

    # texts: Array<String>. Retourne Array<Array<Float>> (même ordre), ou nil
    # si la clé API est absente ou l'appel échoue — jamais d'exception
    # propagée, même logique défensive que Ai::Client.
    def embed(texts)
      return nil unless @api_key.present?
      return [] if texts.blank?

      response = HTTParty.post(
        ENDPOINT,
        headers: { "Authorization" => "Bearer #{@api_key}", "Content-Type" => "application/json" },
        body: { input: texts, model: MODEL }.to_json,
        timeout: 30
      )

      return nil unless response.success?

      response.parsed_response["data"].sort_by { |d| d["index"] }.map { |d| d["embedding"] }
    rescue StandardError => e
      Rails.logger.error "[Ai::EmbeddingClient] #{e.class} — #{e.message}"
      nil
    end
  end
end

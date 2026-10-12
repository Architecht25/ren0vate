# V2 — Lot 5 : découpe un texte OCR en segments pour l'indexation
# vectorielle. Découpage naïf par taille fixe avec chevauchement — pas de
# découpage sémantique (phrases/paragraphes), suffisant pour un MVP, à
# affiner si la qualité de recherche s'avère insuffisante en usage réel.
module ProjectDocuments
  class ChunkingService
    CHUNK_SIZE = 1500
    OVERLAP = 200

    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s.strip
    end

    def call
      return [] if @text.blank?
      return [@text] if @text.length <= CHUNK_SIZE

      chunks = []
      start = 0
      while start < @text.length
        chunk = @text[start, CHUNK_SIZE]
        chunks << chunk
        start += (CHUNK_SIZE - OVERLAP)
      end
      chunks
    end
  end
end

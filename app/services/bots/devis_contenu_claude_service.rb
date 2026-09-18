module Bots
  # DevisContenuClaudeService
  #
  # Analyse le CONTENU d'un devis entrepreneur (au-delà du seul montant total déjà
  # extrait par Bots::DevisClaudeService) : ventile le métré ligne par ligne pour
  # produire une répartition budgétaire par poste/catégorie de travaux, affichable
  # sous forme de graphique dans le comparateur de devis.
  #
  # Comme Bots::AuditEnergClaudeService, le PDF est envoyé à Claude en lecture
  # NATIVE (bloc "document" base64) plutôt qu'en texte OCR pré-extrait : un métré
  # est presque toujours mis en page en tableau (poste | quantité | prix unitaire |
  # sous-total), une mise en page que l'extraction texte linéaire de pdftotext/
  # Tesseract mélange fréquemment entre colonnes.
  #
  # Il n'existe pas de fallback regex pour cette ventilation (contrairement au
  # montant total ou à la date, Ocr::DevisOcrService ne détecte que des catégories
  # de travaux globales sans montant associé) : en cas d'échec, la répartition par
  # poste reste simplement indisponible, le reste du comparateur de devis (montant,
  # dates, types de travaux détectés) n'est pas affecté.
  #
  # Usage :
  #   result = DevisContenuClaudeService.new(file).extraire_postes
  #   # => { success: true, postes: [...], total_htva_calcule:, confiance: }

  class DevisContenuClaudeService < Ocr::OcrService
    require 'base64'

    MODEL      = 'claude-opus-4-5'
    MAX_TOKENS = 8_000

    def extraire_postes
      api_key = ENV['ANTHROPIC_API_KEY']
      unless api_key.present?
        Rails.logger.warn 'DevisContenuClaudeService: ANTHROPIC_API_KEY absent'
        return { success: false, error: 'Clé API Claude absente' }
      end

      validation = validate_file
      return { success: false, error: validation[:error] } unless validation[:success]

      unless file.content_type == 'application/pdf'
        Rails.logger.info 'DevisContenuClaudeService: fichier non-PDF → analyse de contenu non disponible'
        return { success: false, error: 'Analyse de contenu disponible uniquement pour les PDF' }
      end

      pdf_base64 = encode_pdf_base64
      unless pdf_base64
        return { success: false, error: 'Encodage du PDF échoué' }
      end

      raw_response = call_claude(pdf_base64, api_key)
      unless raw_response
        return { success: false, error: 'Pas de réponse de Claude' }
      end

      data = parse_claude_response(raw_response)
      unless data
        return { success: false, error: 'Réponse JSON invalide' }
      end

      build_result(data)

    rescue StandardError => e
      Rails.logger.error "DevisContenuClaudeService error: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def encode_pdf_base64
      file.rewind
      Base64.strict_encode64(file.read)
    rescue StandardError => e
      Rails.logger.warn "DevisContenuClaudeService: encode base64 échoué: #{e.message}"
      nil
    end

    def call_claude(pdf_base64, api_key)
      message = Anthropic::Client.new(api_key: api_key).messages.create(
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system_:    system_prompt,
        messages:   [{
          role:    'user',
          content: [
            {
              type:   'document',
              source: { type: 'base64', media_type: 'application/pdf', data: pdf_base64 }
            },
            {
              type: 'text',
              text: "Voici un devis/métré d'entrepreneur pour des travaux de rénovation en Belgique. " \
                    "Analyse-le intégralement et ventile chaque ligne du métré en JSON."
            }
          ]
        }],
        # tourne sur le worker Solid Queue (DevisContenuExtractionJob), pas de
        # contrainte de timeout routeur Heroku — cf. AuditEnergClaudeService
        request_options: { timeout: 300 }
      )

      if message.stop_reason == :max_tokens
        Rails.logger.warn "DevisContenuClaudeService: réponse tronquée (max_tokens=#{MAX_TOKENS} atteint)"
      end

      text_block = message.content.find { |b| b.type == :text }
      text_block&.text&.strip
    rescue Anthropic::Errors::APITimeoutError
      Rails.logger.warn 'DevisContenuClaudeService: timeout Claude'
      nil
    rescue Anthropic::Errors::APIError => e
      Rails.logger.error "DevisContenuClaudeService Claude error: #{e.message}"
      nil
    end

    def system_prompt
      categories = DevisDonnee::TYPES_TRAVAUX_VALIDES.join(', ')

      [{
        type: 'text',
        text: <<~PROMPT,
          Tu es métreur-déviseur, expert en devis d'entrepreneurs de rénovation en Belgique. Tu
          analyses un devis PDF (souvent un métré en tableau : poste, quantité, unité, prix
          unitaire, sous-total) et tu en extrais la ventilation ligne par ligne pour produire un
          graphique de répartition budgétaire.

          RÈGLES IMPORTANTES :
          - Une ligne du JSON de sortie = une ligne du métré (un poste de travaux avec son propre
            sous-total). Ignore les lignes qui ne sont pas des postes chiffrés (titres de section,
            conditions générales, mentions de garantie, signature…).
          - "categorie" doit être UNIQUEMENT l'une des valeurs suivantes (jamais une autre) :
            #{categories}. Choisis la catégorie la plus précise possible ; utilise "autre" seulement
            si aucune des catégories ci-dessus ne correspond.
          - "libelle" : le texte du poste tel qu'il apparaît sur le devis, raccourci si besoin
            (moins de 10 mots), jamais une reformulation générique.
          - "montant_htva" est le sous-total HTVA de la ligne (pas TVAC). Si seul un montant TVAC
            est visible sur la ligne, indique-le dans "montant_htva" quand même plutôt que de
            perdre la ligne (mieux vaut une répartition légèrement imprécise qu'un trou).
          - Si le devis ne détaille QUE des postes forfaitaires globaux sans métré ligne par ligne
            (ex: un seul total "Travaux de rénovation : 25 000 €"), retourne une seule ligne avec ce
            montant et la catégorie la plus pertinente déduite du contexte — ne retourne jamais un
            tableau vide si un montant total existe quelque part dans le document.
          - Tous les montants sont des nombres (pas de "€", pas de séparateur de milliers, virgule
            belge convertie en point décimal).
          - N'invente jamais de ligne qui n'est pas dans le document.

          Réponds UNIQUEMENT avec un objet JSON valide (pas de markdown, pas d'explication), avec
          exactement cette structure :
          {
            "postes": [
              { "libelle": "string", "categorie": "string", "quantite": nombre ou null, "unite": "string ou null", "prix_unitaire_htva": nombre ou null, "montant_htva": nombre }
            ],
            "confiance": entier 0-100
          }
        PROMPT
        cache_control: { type: 'ephemeral' }
      }]
    end

    def parse_claude_response(raw)
      json_str = raw[/\{.*\}/m]
      return nil unless json_str

      JSON.parse(json_str)
    rescue JSON::ParserError => e
      Rails.logger.warn "DevisContenuClaudeService JSON parse: #{e.message}"
      nil
    end

    def build_result(data)
      conf = [[data['confiance'].to_i, 0].max, 100].min

      postes = Array(data['postes']).filter_map do |p|
        montant = parse_float(p['montant_htva'])
        next if montant.nil? || montant <= 0

        {
          libelle:            p['libelle'].to_s.strip.presence || 'Poste sans libellé',
          categorie:          valider_categorie(p['categorie']),
          quantite:           parse_float(p['quantite']),
          unite:              p['unite']&.to_s&.strip.presence,
          prix_unitaire_htva: parse_float(p['prix_unitaire_htva']),
          montant_htva:       montant
        }
      end

      if postes.empty?
        return { success: false, error: 'Aucun poste chiffré détecté dans le devis' }
      end

      {
        success:             true,
        postes:              postes,
        total_htva_calcule:  postes.sum { |p| p[:montant_htva] }.round(2),
        confiance:           conf.to_f
      }
    end

    def valider_categorie(cat)
      DevisDonnee::TYPES_TRAVAUX_VALIDES.include?(cat.to_s) ? cat.to_s : 'autre'
    end

    def parse_float(val)
      return nil if val.nil? || val == 'null'
      val.is_a?(Numeric) ? val.to_f : val.to_s.tr(',', '.').to_f
    rescue StandardError
      nil
    end
  end
end

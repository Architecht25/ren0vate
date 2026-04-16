# BceVerificationService
# Vérifie un numéro TVA belge via l'API VIES de la Commission Européenne
# Endpoint : https://ec.europa.eu/taxation_customs/vies/rest-api/ms/BE/vat/{vatNumber}
#
# Retourne :
#   { valid: true,  nom: "DUPONT SPRL", adresse: "Rue...", statut: "valide" }
#   { valid: false, statut: "invalide", erreur: "..." }
#   { valid: nil,   statut: "indisponible", erreur: "service VIES indisponible" }
#
class BceVerificationService
  VIES_BASE_URL = "https://ec.europa.eu/taxation_customs/vies/rest-api/ms/BE/vat/"
  TIMEOUT_SECONDS = 8

  def initialize(numero_tva)
    @numero_tva_brut = numero_tva.to_s.strip
    @numero_normalise = normaliser(@numero_tva_brut)
  end

  def verifier
    return { valid: false, statut: "format_invalide", erreur: "Format TVA invalide" } unless format_valide?

    uri = URI("#{VIES_BASE_URL}#{@numero_normalise}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                               open_timeout: TIMEOUT_SECONDS,
                               read_timeout: TIMEOUT_SECONDS) do |http|
      http.get(uri.path, "Accept" => "application/json")
    end

    case response.code
    when "200"
      data = JSON.parse(response.body)
      if data["isValid"]
        {
          valid:   true,
          statut:  "valide",
          nom:     data["name"].presence,
          adresse: data["address"].presence
        }
      else
        { valid: false, statut: "invalide", erreur: "Numéro non reconnu par le registre TVA européen" }
      end
    when "404"
      { valid: false, statut: "invalide", erreur: "Numéro introuvable" }
    else
      { valid: nil, statut: "indisponible", erreur: "Service VIES indisponible (HTTP #{response.code})" }
    end

  rescue Net::OpenTimeout, Net::ReadTimeout
    { valid: nil, statut: "indisponible", erreur: "Délai d'attente dépassé" }
  rescue => e
    Rails.logger.warn "BceVerificationService error for #{@numero_tva_brut}: #{e.message}"
    { valid: nil, statut: "indisponible", erreur: "Erreur réseau" }
  end

  private

  # Normalise BE0123456789 ou BE 0123.456.789 ou 0123456789 → 0123456789 (10 chiffres sans BE)
  def normaliser(num)
    # Retirer le préfixe BE et tout séparateur
    num.gsub(/\ABE/i, '').gsub(/[\s.\-]/, '')
  end

  def format_valide?
    # Doit être 10 chiffres après normalisation
    @numero_normalise.match?(/\A\d{10}\z/)
  end
end

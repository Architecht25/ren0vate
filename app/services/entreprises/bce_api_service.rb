module Entreprises
  class BceApiService
    include HTTParty

    # API BCE officielle - Service Web Public Search
    PRODUCTION_ENDPOINT = 'https://kbopub.economie.fgov.be/kbopubws110000/services/wsKBOPub'
    TEST_ENDPOINT = 'https://kbopub-acc.economie.fgov.be/kbopubws110000/services/wsKBOPub'

    # Utiliser l'environnement de test pour le développement
    BASE_URL = Rails.env.production? ? PRODUCTION_ENDPOINT : TEST_ENDPOINT

  def self.search_company(enterprise_number)
    # Pour le moment, on garde la simulation jusqu'à obtenir les credentials d'authentification
    simulate_api_response(enterprise_number)

    # Code pour l'API officielle SOAP (nécessite credentials)
    # make_soap_request(enterprise_number)
  end

  private

  def self.make_soap_request(enterprise_number)
    begin
      soap_body = build_soap_request(enterprise_number)

      response = HTTParty.post(BASE_URL, {
        body: soap_body,
        headers: {
          'Content-Type' => 'text/xml; charset=utf-8',
          'SOAPAction' => 'http://economie.fgov.be/kbopub/webservices/v1/ReadEnterprise',
          'User-Agent' => 'Ren0vate/1.0'
        },
        timeout: 30
      })

      if response.success?
        parse_soap_response(response.body)
      else
        { success: false, error: "Erreur API SOAP: #{response.code}" }
      end
    rescue StandardError => e
      { success: false, error: "Erreur de connexion SOAP: #{e.message}" }
    end
  end

  def self.build_soap_request(enterprise_number)
    <<~SOAP
      <?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                        xmlns:mes="http://economie.fgov.be/kbopub/webservices/v1/messages"
                        xmlns:dat="http://economie.fgov.be/kbopub/webservices/v1/datamodel">
        <soapenv:Header>
          <!-- WS-Security authentication sera ajouté ici avec les credentials -->
          <mes:RequestContext>
            <mes:Id>ren0vate-#{Time.current.to_i}</mes:Id>
            <mes:Language>fr</mes:Language>
          </mes:RequestContext>
        </soapenv:Header>
        <soapenv:Body>
          <mes:ReadEnterpriseRequest>
            <dat:EnterpriseNumber>#{enterprise_number}</dat:EnterpriseNumber>
          </mes:ReadEnterpriseRequest>
        </soapenv:Body>
      </soapenv:Envelope>
    SOAP
  end

  def self.parse_soap_response(soap_xml)
    # Parser la réponse SOAP XML de l'API officielle BCE
    begin
      # Ici on parserait le XML SOAP pour extraire les données de l'entreprise
      # Documentation dans le cookbook BCE pour la structure des réponses
      { success: false, error: "Parser SOAP non implémenté - credentials d'authentification nécessaires" }
    rescue StandardError => e
      { success: false, error: "Erreur parsing SOAP: #{e.message}" }
    end
  end

  # Données simulées pour le développement - remplace l'API officielle temporairement
  def self.simulate_api_response(enterprise_number)
    # Nettoyage du numéro d'entreprise
    clean_number = enterprise_number.to_s.gsub(/[^0-9]/, '')

    case clean_number
    when '0681683138'
      {
        success: true,
        data: {
          enterprise_number: '0681.683.138',
          name: 'Manage-Green',
          legal_form: 'SRL',
          status: 'Actif',
          address: {
            street: 'Avenue des Cerisiers',
            number: '15',
            postal_code: '1000',
            city: 'Bruxelles'
          },
          activities: [
            {
              code: '70.220',
              description: 'Conseil pour les affaires et autres conseils de gestion'
            }
          ],
          vat_number: 'BE0681683138'
        }
      }
    when '0833618097'
      {
        success: true,
        data: {
          enterprise_number: '0833.618.097',
          name: 'EcoBuild Solutions',
          legal_form: 'SA',
          status: 'Actif',
          address: {
            street: 'Rue de la Rénovation',
            number: '42',
            postal_code: '1050',
            city: 'Ixelles'
          },
          activities: [
            {
              code: '41.200',
              description: 'Construction de bâtiments résidentiels et non résidentiels'
            }
          ],
          vat_number: 'BE0833618097'
        }
      }
    else
      { success: false, error: "Entreprise non trouvée dans la simulation (#{clean_number})" }
    end
  end

  private

  def self.valid_enterprise_number?(number)
    return false unless number.length == 10
    return false unless number.match?(/^\d{10}$/)

    # Pour l'instant, on accepte tous les numéros de 10 chiffres
    # La vraie API BCE fera la validation
    true
  end

  def self.parse_bce_response(data)
    return { error: 'Données invalides' } unless data && data['entreprise']

    enterprise = data['entreprise']

    # Déterminer la taille de l'entreprise
    taille = determine_company_size(enterprise)

    {
      numeroEntreprise: enterprise['numeroEntreprise'],
      formeLegale: enterprise['formeLegale'] || 'Non spécifiée',
      tailleEntreprise: taille,
      dateInscription: format_date(enterprise['dateInscription']),
      codesNace: format_nace_codes(enterprise['activites']),
      adresses: format_addresses(enterprise['adresses'])
    }
  end

  def self.determine_company_size(enterprise)
    # Logique pour déterminer la taille selon les critères EU
    # Cette information n'est pas toujours disponible dans l'API BCE
    # On peut essayer de l'inférer ou utiliser une valeur par défaut

    if enterprise['tailleEntreprise']
      enterprise['tailleEntreprise']
    elsif enterprise['chiffreAffaires'] || enterprise['nombreEmployes']
      # Logique basée sur les critères EU si disponible
      'Taille non déterminée'
    else
      'Petite entreprise' # Valeur par défaut
    end
  end

  def self.format_date(date_string)
    return 'Non spécifiée' unless date_string

    begin
      Date.parse(date_string).strftime('%d/%m/%Y')
    rescue
      date_string
    end
  end

  def self.format_nace_codes(activites)
    return 'Non spécifié' unless activites && activites.any?

    codes = activites.map { |activite| activite['codeNace'] }.compact
    codes.join(', ')
  end

  def self.format_addresses(adresses)
    return ['Adresse non disponible'] unless adresses && adresses.any?

    adresses.map do |adresse|
      parts = []
      parts << adresse['rue'] if adresse['rue']
      parts << adresse['numero'] if adresse['numero']
      parts << adresse['codePostal'] if adresse['codePostal']
      parts << adresse['commune'] if adresse['commune']

      parts.join(' ')
    end
  end
end

# ========================================
# INSTRUCTIONS POUR ACTIVER L'API OFFICIELLE BCE
# ========================================
#
# Pour remplacer la simulation par l'API officielle :
#
# 1. S'enregistrer sur le portail officiel :
#    https://kbopub.economie.fgov.be/kbo-open-data/login?lang=fr
#
# 2. Obtenir un compte de test gratuit pour développement
#
# 3. Acheter des crédits pour production (50€ = 2000 requêtes)
#
# 4. Ajouter les credentials dans les variables d'environnement :
#    BCE_USERNAME=votre_username
#    BCE_PASSWORD=votre_password
#
# 5. Implémenter l'authentification WS-Security avec PasswordDigest
#    dans build_soap_request()
#
# 6. Implémenter le parser XML SOAP dans parse_soap_response()
#
# 7. Remplacer simulate_api_response par make_soap_request
#    dans la méthode search_company()
#
# Documentation complète dans : cookbook-bce-public-search.pdf
# Support : kbo-bce-webservice@economie.fgov.be
  end
end

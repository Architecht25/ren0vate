require 'net/http'

module Properties
  # Vérifie si des coordonnées se situent dans une zone de monuments/sites classés
  # via le géoservice public IRISnet (Bruxelles).
  class HeritageCheckService
    class InvalidCoordinates < StandardError; end

    MARGIN = 0.0005

    def self.call(lat:, lon:)
      new(lat, lon).call
    end

    def initialize(lat, lon)
      @lat = lat.to_f
      @lon = lon.to_f
    end

    def call
      raise InvalidCoordinates unless valid_coordinates?

      uri = URI(request_url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.get(uri.request_uri)
      end
      JSON.parse(response.body)
    end

    private

    def valid_coordinates?
      @lat.between?(-90, 90) && @lon.between?(-180, 180) && @lat != 0 && @lon != 0
    end

    def request_url
      envelope = "#{@lon - MARGIN},#{@lat - MARGIN},#{@lon + MARGIN},#{@lat + MARGIN}"
      "https://geoservices.irisnet.be/arcgis/rest/services/UrbanInformation/Monuments_sites/MapServer/0/query" \
      "?f=json&returnGeometry=false&outFields=DENOMINATION,DATE_ARRETE,STATUT" \
      "&geometry=#{envelope}&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects"
    end
  end
end

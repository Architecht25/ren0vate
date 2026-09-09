ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"

# Geocoder ne doit jamais taper Nominatim (API externe) pendant les tests —
# ça rendait toute la suite dépendante du réseau et sujette au rate-limiting
# de l'API publique (surtout avec plusieurs jobs CI en parallèle).
Geocoder.configure(lookup: :test, ip_lookup: :test)
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      "latitude" => 50.8503,
      "longitude" => 4.3517,
      "address" => "Bruxelles, Belgique",
      "state" => "Bruxelles",
      "country" => "Belgique",
      "country_code" => "BE"
    }
  ]
)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Chaque test charge ses propres fixtures explicitement.
    # Ne pas mettre fixtures :all ici — certaines fixtures ont des colonnes NOT NULL
    # non renseignées qui provoquent des erreurs à l'insert.

    # Add more helper methods to be used by all tests here...
  end
end

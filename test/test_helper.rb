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

    # Remplace temporairement une méthode de classe/module (ex: Anthropic::Client.new,
    # HTTParty.get) par une valeur ou un objet appelable (proc/lambda), le temps du
    # bloc, puis restaure la méthode d'origine — même si le bloc lève une exception.
    #
    # Utilisé pour éviter tout vrai appel réseau (API Claude, scraping HTTP) dans les
    # tests, sans dépendre de minitest/mock (retiré de minitest 6) ni d'une gem de
    # mocking supplémentaire (mocha, webmock...).
    #
    #   stub_class_method(Anthropic::Client, :new, fake_client) { service.chat("...") }
    #   stub_class_method(HTTParty, :get, ->(*args, **kwargs) { fake_response }) { ... }
    def stub_class_method(receiver, method_name, replacement)
      original = receiver.method(method_name)

      receiver.define_singleton_method(method_name) do |*args, **kwargs, &block|
        if replacement.respond_to?(:call)
          replacement.call(*args, **kwargs, &block)
        else
          replacement
        end
      end

      yield
    ensure
      receiver.define_singleton_method(method_name, original)
    end
  end
end

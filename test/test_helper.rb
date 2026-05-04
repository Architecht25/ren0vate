ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Chaque test charge ses propres fixtures explicitement.
    # Ne pas mettre fixtures :all ici — certaines fixtures ont des colonnes NOT NULL
    # non renseignées qui provoquent des erreurs à l'insert.

    # Add more helper methods to be used by all tests here...
  end
end

# Classe de base pour tous les services de calcul régionaux
# Définit l'interface commune et les méthodes partagées

module Regions
  class BaseService
    def initialize(params, user: nil)
      @params = params
      @user = user
      @is_post_login = !user.nil?
    end

    protected

    attr_reader :params, :user, :is_post_login

    # Interface à implémenter par les classes filles
    def check_eligibility
      raise NotImplementedError, "#{self.class} doit implémenter #check_eligibility"
    end

    def determine_category
      raise NotImplementedError, "#{self.class} doit implémenter #determine_category"
    end

    def calculate_primes(category)
      raise NotImplementedError, "#{self.class} doit implémenter #calculate_primes"
    end

    # Méthodes utilitaires communes
    def eligible_response(category:, message: "Éligible aux primes", needs_refinement: false)
      {
        eligible: true,
        message: message,
        category: category,
        needs_refinement: needs_refinement
      }
    end

    def ineligible_response(message)
      {
        eligible: false,
        message: message,
        category: nil,
        needs_refinement: false
      }
    end

    def get_param(key)
      @params[key] || @params[key.to_s] || @params[key.to_sym]
    end

    def user_property
      return nil unless @user&.properties&.any?
      @user.properties.first # ou logique plus complexe
    end

    def log_calculation(step, data = {})
      Rails.logger.info "[#{self.class}] #{step}: #{data.inspect}" if Rails.env.development?
    end
  end
end

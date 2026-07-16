# Vérifications d'éligibilité communes aux régimes wallons (primes cash historiques
# et réduction de prêt bonifié) : région, destination habitation, propriété,
# résidence principale, âge du logement.
module Regions
  module Wallonie
    module CommonEligibilityChecks
      def get_property
        property_id = get_param(:property_id)
        return nil unless property_id

        @user.properties.find_by(id: property_id)
      end

      def user_project
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end

      def property_in_wallonie?(property)
        if property.region.present?
          region_clean = property.region.to_s.strip.downcase
          return true if region_clean == 'wallonie'
        end

        property_in_wallonie_by_address?(property)
      end

      def property_in_wallonie_by_address?(property)
        postal_code = property.code_postal || property.cp
        return false unless postal_code.present?

        postal_int = postal_code.to_i

        wallonie_ranges = [
          (1300..1499), # Brabant wallon
          (4000..4999), # Province de Liège
          (5000..5999), # Province de Namur
          (6000..6999), # Hainaut (Charleroi)
          (7000..7999), # Hainaut (Mons)
          (6700..6999)  # Luxembourg belge
        ]

        wallonie_ranges.any? { |range| range.include?(postal_int) }
      end

      def property_for_habitation?(property)
        if property.habitation_percentage.present?
          return property.habitation_percentage >= 50
        end

        if property.type_propriete_wallonie.present?
          habitation_types = %w[logement_unifamilial appartement maison residence_principale habitation]
          return property.type_propriete_wallonie.in?(habitation_types)
        end

        return true if property.occupation == 'residence_principale'

        property.type&.include?('logement') || property.type&.include?('maison') || property.type&.include?('appartement')
      end

      def user_is_owner?(property)
        proprietaire_types = %w[proprietaire_occupant proprietaire copropriétaire usufruitier nu_proprietaire plein_proprietaire]

        return true if property.type_propriete_wallonie.in?(proprietaire_types)
        return true if property.type_propriete.in?(proprietaire_types)

        property.user_id == @user.id
      end

      def residence_principale?(property)
        return true if property.occupation == 'residence_principale'

        property.occupation != 'residence_secondaire' && property.occupation != 'investissement'
      end

      def property_old_enough?(property)
        return false unless property.annee_construction

        (Date.current.year - property.annee_construction) > 15
      end
    end
  end
end

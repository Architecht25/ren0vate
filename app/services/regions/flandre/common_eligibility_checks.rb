# Vérifications d'éligibilité communes aux services Flandre (éligibilité et
# catégorie) : domiciliation. Extrait de la duplication entre
# FlandreEligibilityService et FlandreCategoryService (deux implémentations
# divergentes de #sera_domicilie? coexistaient avant unification).
#
# Champ réellement soumis par le formulaire Flandre (_form_flandre.html.erb) :
# `domicilie_flandre` (booléen, colonne properties.domicilie_flandre) — c'est
# la seule source fiable pour cette question en pratique. Les vérifications
# via `occupation` ('residence_principale' / 'hoofdverblijfplaats') et
# `adresse_principale` sont conservées comme fallbacks défensifs pour des
# données historiques/alternatives, mais `adresse_principale` n'existe pas
# comme colonne sur Property (le respond_to? les neutralise sans risque) et
# `occupation` n'est pas alimenté par le formulaire Flandre lui-même (champ
# partagé avec le formulaire Wallonie/Espagne).
module Regions
  module Flandre
    module CommonEligibilityChecks
      def sera_domicilie?(property)
        return false unless property

        # Question: "Êtes-vous ou serez-vous domicilié une fois le bien rénové?"
        # En Flandre, la domiciliation est obligatoire (impact sur la catégorie
        # plutôt que sur l'éligibilité stricte : non domicilié => catégorie 1).

        # Vérifier via occupation actuelle ou future
        if property.occupation == 'residence_principale' || property.occupation == 'hoofdverblijfplaats'
          return true
        end

        # Vérifier via champ spécifique domiciliation (champ réel du formulaire Flandre)
        if property.respond_to?(:domicilie_flandre) && property.domicilie_flandre == true
          return true
        end

        # Si c'est la propriété principale de l'utilisateur (adresse principale)
        if property.respond_to?(:adresse_principale) && property.adresse_principale == true
          return true
        end

        # Exclusions explicites
        if property.occupation == 'residence_secondaire' || property.occupation == 'investissement'
          return false
        end

        # Par défaut, on assume que l'utilisateur sera domicilié (sera vérifié à posteriori)
        true
      end
    end
  end
end

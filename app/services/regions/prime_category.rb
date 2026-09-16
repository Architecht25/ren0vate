module Regions
  # Catégorisation d'une prime à partir de son slug — partagée entre le
  # contrôleur (affichage des cartes) et les persisters de simulation par région.
  module PrimeCategory
    def self.from_slug(slug)
      case slug
      when /audit/
        'audit'
      when /certificat/
        'certificat'
      when /isolation/
        'isolation'
      when /chauffage/
        'chauffage'
      when /ventilation/
        'ventilation'
      when /solaire/
        'solaire'
      else
        'autres'
      end
    end
  end
end

module Factures
  # Détecte si une facture provient de l'architecte ou d'un entrepreneur en
  # comparant le nom d'entreprise extrait par OCR avec les données du projet.
  module TypeIntervenantDetector
    def self.call(nom_entreprise, project)
      return 'entrepreneur' if nom_entreprise.blank?

      nom = nom_entreprise.downcase.strip
      arch = project.architecte_entreprise&.downcase&.strip

      return 'architecte' if arch.present? && nom.include?(arch.split.first || '')

      'entrepreneur'
    end
  end
end

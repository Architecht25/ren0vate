# V2 — Lot 5 : traduction FR/NL/ES/EN (cahier des charges §8.8 : "avec
# affichage du texte original"). Volontairement sans persistance dédiée —
# appelé à la demande depuis la vue, le texte original reste la source de
# vérité affichée à côté de la traduction, jamais remplacée.
module Ai
  class TranslationService
    LOCALES = { "fr" => "français", "nl" => "néerlandais", "es" => "espagnol", "en" => "anglais" }.freeze

    def initialize(project:, actor: nil)
      @client = Ai::Client.new(project: project, actor: actor)
    end

    # Retourne le texte traduit, ou nil si le service est indisponible.
    # Ne traduit jamais vers la langue détectée comme étant déjà celle du texte
    # n'est PAS vérifié ici — à la charge de l'appelant de ne pas demander une
    # traduction inutile (pas de détection de langue source dans ce lot).
    def translate(text, to:)
      target = LOCALES.fetch(to.to_s) { raise ArgumentError, "langue cible inconnue : #{to}" }

      @client.run(
        :translation,
        system: "Tu traduis fidèlement le texte fourni en #{target}. Réponds UNIQUEMENT avec la traduction, sans commentaire ni guillemets.",
        messages: [{ role: "user", content: text.to_s }]
      )
    end
  end
end

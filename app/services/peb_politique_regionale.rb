# PebPolitiqueRegionale
#
# Module de référence pour la réglementation PEB des 3 régions belges.
# Horizon 2025-2050 — mis à jour sur base de :
#   - Directive européenne 2024/1275 (EPBD recast) : -16 % moy résidentielle / 2030,
#     -20-22 % / 2035 (vs baseline 2020), classe minimum F à éliminer d'ici 2030
#   - Bruxelles : cadre Renolution, obligations en vigueur, objectif 2050 quasi zéro énergie
#   - Wallonie  : Rénopack/Rénoprêt (lancement oct. 2026), glissement prime→prêt label-jump
#   - Flandre   : recul Diependaele 2025 (objectif A 2045 supprimé),
#                 obligation label D dans 6 ans pour achat E/F maintenue
#
# Utilisation :
#   analyse = PebPolitiqueRegionale.analyse(
#     region: 'wallonie', label_actuel: 'C',
#     label_avant: 'F', date_validite: Date.new(2034, 6, 1)
#   )
#   # => { contexte_regional:, milestones:, recommandations:, urgence_globale: }

module PebPolitiqueRegionale
  # ─────────────────────────────────────────────────────────────────
  # SEUILS DE LABEL (numériques pour comparaison)
  # ─────────────────────────────────────────────────────────────────
  SCORE_LABEL = {
    'A++' => 9, 'A+' => 8, 'A' => 7, 'B' => 6, 'C' => 5,
    'D'   => 4, 'E' => 3, 'F' => 2, 'G' => 1
  }.freeze

  def self.score(label)
    SCORE_LABEL.fetch(label.to_s.upcase, 0)
  end

  # ─────────────────────────────────────────────────────────────────
  # DONNÉES DE POLITIQUE PAR RÉGION
  # ─────────────────────────────────────────────────────────────────

  POLITIQUE = {

    # ═══════════════════════════════════════════════════════════════
    'bruxelles' => {
      nom_region:   'Région de Bruxelles-Capitale',
      cadre:        'Renolution',
      description:  "Bruxelles dispose du cadre réglementaire le plus prescriptif de Belgique. "\
                    "Les obligations de rénovation par paliers de label sont déjà en vigueur avec sanctions. "\
                    "L'objectif est un parc quasi zéro énergie d'ici 2050 via la stratégie Renolution.",

      milestones: [
        {
          annee: 2025,
          titre: "Certificat PEB obligatoire (vente & location)",
          description: "Toute mise en vente ou en location d'un bien requiert un certificat PEB valide. "\
                       "Amendes jusqu'à 50 000 € en cas d'infraction.",
          obligatoire: true,
          label_cible: nil
        },
        {
          annee: 2026,
          titre: "Label D minimum — nouveaux baux",
          description: "Les logements classés E, F ou G ne peuvent plus être loués si le bail est renouvelé "\
                       "ou si un nouveau bail est signé. Obligation de rénovation avant la mise en location.",
          obligatoire: true,
          label_cible: 'D'
        },
        {
          annee: 2030,
          titre: "Objectif label C — parc locatif",
          description: "Objectif de la stratégie Renolution : l'ensemble du parc locatif bruxellois doit "\
                       "atteindre au moins le label C d'ici 2030. Aligné sur la directive EU -16 %.",
          obligatoire: true,
          label_cible: 'C'
        },
        {
          annee: 2033,
          titre: "Label C obligatoire — tous baux locatifs",
          description: "Tous les logements en location (y compris baux en cours à renouveler) "\
                       "doivent atteindre le label C. Sanctions applicables.",
          obligatoire: true,
          label_cible: 'C'
        },
        {
          annee: 2035,
          titre: "Directive EU — réduction 20-22 % (vs 2020)",
          description: "Échéance EPBD 2024/1275 : réduction de 20 à 22 % de la consommation moyenne "\
                       "résidentielle. Bruxelles vise label B pour la grande majorité du parc.",
          obligatoire: false,
          label_cible: 'B'
        },
        {
          annee: 2045,
          titre: "Label A — nouveaux baux",
          description: "Les logements mis en location à partir de 2045 devront atteindre le label A, "\
                       "conformément à la feuille de route Renolution 2050.",
          obligatoire: true,
          label_cible: 'A'
        },
        {
          annee: 2050,
          titre: "Parc quasi zéro énergie",
          description: "Objectif final Renolution : l'ensemble du parc résidentiel bruxellois doit être "\
                       "quasi zéro énergie (label A ou A+). Fin des énergies fossiles pour le chauffage.",
          obligatoire: false,
          label_cible: 'A'
        }
      ],

      programmes: [
        {
          nom:         "Primes Énergie Bruxelles",
          organisme:   "Bruxelles Environnement / Homegrade",
          description: "Primes pour isolation, vitrage, chauffage, ventilation, audit énergétique. "\
                       "Montant indexé sur les revenus du ménage.",
          url_info:    "https://www.homegrade.brussels",
          actif:       true
        },
        {
          nom:         "Éco-prêt 0 % (prêt vert bruxellois)",
          organisme:   "Fonds du Logement / Bruxelles Environnement",
          description: "Prêt à taux zéro jusqu'à 50 000 € sur 20 ans pour travaux de rénovation "\
                       "énergétique des logements bruxellois.",
          url_info:    "https://fondsdulogement.be",
          actif:       true
        },
        {
          nom:         "Renolution Guidance",
          organisme:   "Homegrade / facilitateurs",
          description: "Accompagnement gratuit pour établir une trajectoire de rénovation par étapes, "\
                       "avec un facilitateur Renolution agréé.",
          url_info:    "https://renolution.brussels",
          actif:       true
        }
      ]
    },

    # ═══════════════════════════════════════════════════════════════
    'wallonie' => {
      nom_region:   'Région wallonne',
      cadre:        'Rénopack / Plan Air-Climat-Énergie',
      description:  "La Wallonie opère une transition structurelle de son système d'aides : "\
                    "les primes à l'acte unique sont progressivement remplacées par le dispositif "\
                    "Rénopack (audit + prêt label-jump à taux zéro), dont le lancement est prévu "\
                    "en octobre 2026. Des obligations locatives sans sanction prévues à partir de 2028.",

      milestones: [
        {
          annee: 2025,
          titre: "Certificat PEB obligatoire (vente & location)",
          description: "Le certificat PEB est obligatoire pour toute vente ou nouvelle mise en location "\
                       "d'un bien résidentiel en Wallonie.",
          obligatoire: true,
          label_cible: nil
        },
        {
          annee: 2026,
          titre: "Lancement Rénopack & Rénoprêt (oct. 2026)",
          description: "Octobre 2026 : remplacement des primes à l'acte par le dispositif Rénopack. "\
                       "Le Rénoprêt est un prêt à taux zéro conditionné à un saut de label (ex. F→C). "\
                       "L'audit logement devient le point d'entrée obligatoire pour accéder aux aides.",
          obligatoire: false,
          label_cible: nil
        },
        {
          annee: 2028,
          titre: "Label D visé — logements locatifs E/F",
          description: "Objectif wallon : les logements loués classés E ou F doivent atteindre le label D. "\
                       "Les sanctions ne sont pas encore formellement confirmées pour cette échéance.",
          obligatoire: false,
          label_cible: 'D'
        },
        {
          annee: 2030,
          titre: "Directive EU — réduction 16 % (vs 2020)",
          description: "Échéance EPBD 2024/1275 : réduction de 16 % de la consommation résidentielle moyenne. "\
                       "La Wallonie vise l'élimination progressive des labels F et G du marché locatif.",
          obligatoire: false,
          label_cible: 'E'
        },
        {
          annee: 2033,
          titre: "Label C visé — logements locatifs",
          description: "Trajectoire wallonne : les logements en location devront atteindre le label C "\
                       "d'ici 2033. Calendrier et sanctions à confirmer selon l'évolution législative.",
          obligatoire: false,
          label_cible: 'C'
        },
        {
          annee: 2035,
          titre: "Directive EU — réduction 20-22 % (vs 2020)",
          description: "Objectif européen EPBD : -20 à -22 % de consommation résidentielle moyenne. "\
                       "La Wallonie vise label B pour les logements rénovés dans ce cadre.",
          obligatoire: false,
          label_cible: 'B'
        },
        {
          annee: 2050,
          titre: "Zéro émission nette — objectif PNEC wallon",
          description: "Plan National Énergie-Climat wallon : parc résidentiel bas-carbone, "\
                       "label A pour les logements neufs et rénovés profondément. "\
                       "Fin du chauffage fossile dans le résidentiel neuf.",
          obligatoire: false,
          label_cible: 'A'
        }
      ],

      programmes: [
        {
          nom:         "Rénopack (dès octobre 2026)",
          organisme:   "SPW Énergie / Helpdesk Wallonie",
          description: "Dispositif intégré : audit logement obligatoire → plan de rénovation par étapes "\
                       "→ Rénoprêt à taux zéro selon saut de label atteint. Remplace les primes à l'acte.",
          url_info:    "https://energie.wallonie.be",
          actif:       false # lancement octobre 2026
        },
        {
          nom:         "Primes Énergie (actuelles — avant oct. 2026)",
          organisme:   "SPW Énergie",
          description: "Primes individuelles encore en vigueur jusqu'au basculement vers Rénopack : "\
                       "isolation toiture/murs/sol, vitrage, pompe à chaleur, chauffe-eau solaire.",
          url_info:    "https://energie.wallonie.be/primes",
          actif:       true
        },
        {
          nom:         "Audit logement agréé",
          organisme:   "SPW / auditeurs agréés",
          description: "Audit énergétique complet du logement — obligatoire pour accéder au Rénoprêt. "\
                       "Prime à l'audit disponible. Points d'entrée Guichet de l'Énergie.",
          url_info:    "https://energie.wallonie.be/audit",
          actif:       true
        },
        {
          nom:         "Chèque-Habitat (prêt social)",
          organisme:   "Société wallonne du crédit social",
          description: "Prêt hypothécaire à taux réduit pour travaux de rénovation ou achat+rénovation "\
                       "d'un bien en Wallonie, sous conditions de revenus.",
          url_info:    "https://swcs.be",
          actif:       true
        }
      ]
    },

    # ═══════════════════════════════════════════════════════════════
    'flandre' => {
      nom_region:   'Région flamande',
      cadre:        'Mijn VerbouwPlan / Woningpas',
      description:  "En 2025, le gouvernement Diependaele a supprimé l'objectif ambitieux "\
                    "d'atteindre le label A pour tous les logements d'ici 2045. "\
                    "L'obligation la plus ferme restante est l'atteinte du label D dans les 6 ans "\
                    "suivant l'achat d'un bien classé E ou F. Le cadre européen EPBD reste la "\
                    "principale contrainte réglementaire à horizon 2030-2035.",

      milestones: [
        {
          annee: 2025,
          titre: "Certificat EPC obligatoire (vente & location)",
          description: "L'EPC (Energieprestatiecertificaat) est obligatoire pour toute vente ou "\
                       "mise en location. Sanctions en cas d'absence (VEKA / Wooninspectie).",
          obligatoire: true,
          label_cible: nil
        },
        {
          annee: 2025,
          titre: "Recul politique : objectif A 2045 supprimé",
          description: "Le gouvernement Diependaele (2025) a retiré l'objectif d'un label A "\
                       "obligatoire pour tous les logements d'ici 2045, qui était la pierre "\
                       "angulaire du Renovatiepact flamand précédent.",
          obligatoire: false,
          label_cible: nil
        },
        {
          annee: 2028,
          titre: "Label D dans 6 ans — achat E/F (avant 2022)",
          description: "Obligation maintenue : tout bien classé E ou F acquis avant fin 2022 "\
                       "doit atteindre le label D avant 2028. Cette règle vaut pour tous les "\
                       "acheteurs de biens résidentiels.",
          obligatoire: true,
          label_cible: 'D'
        },
        {
          annee: 2030,
          titre: "Directive EU — réduction 16 % (vs 2020)",
          description: "Échéance EPBD 2024/1275 : réduction de 16 % de la consommation "\
                       "résidentielle moyenne en Flandre. Premier plancher clair malgré le recul local.",
          obligatoire: false,
          label_cible: 'E'
        },
        {
          annee: 2031,
          titre: "Label D dans 6 ans — achat E/F (2025-2028)",
          description: "Règle continue : toute acquisition d'un bien E/F à partir de 2025 déclenche "\
                       "une obligation de rénovation vers label D dans les 6 ans suivant l'achat.",
          obligatoire: true,
          label_cible: 'D'
        },
        {
          annee: 2035,
          titre: "Directive EU — réduction 20-22 % (vs 2020)",
          description: "Objectif EPBD : -20 à -22 % de consommation résidentielle. "\
                       "En l'absence d'objectif national flamand, la directive européenne "\
                       "reste la seule contrainte ferme à cet horizon.",
          obligatoire: false,
          label_cible: 'C'
        }
      ],

      programmes: [
        {
          nom:         "Mijn VerbouwLening",
          organisme:   "VMSW / Vlaams Woningfonds",
          description: "Prêt à taux réduit pour travaux de rénovation énergétique en Flandre. "\
                       "Accessible sous conditions de revenus, montant jusqu'à 60 000 €.",
          url_info:    "https://www.vlaanderen.be/mijn-verbouwlening",
          actif:       true
        },
        {
          nom:         "Mijn VerbouwPremie (réduite depuis 2024)",
          organisme:   "VEKA (Vlaams Energie- en Klimaatagentschap)",
          description: "Prime rénovation énergétique flamande, significativement réduite en 2024. "\
                       "Couvre : isolation, vitrage HR, pompe à chaleur, chauffe-eau thermodynamique.",
          url_info:    "https://www.vlaanderen.be/mijn-verbouwpremie",
          actif:       true
        },
        {
          nom:         "Woningpas (passeport logement)",
          organisme:   "Digitaal Vlaanderen",
          description: "Dossier numérique du logement regroupant l'EPC, les permis, l'inspection "\
                       "électrique. Base de suivi de la trajectoire de rénovation.",
          url_info:    "https://woningpas.vlaanderen.be",
          actif:       true
        }
      ]
    }

  }.freeze

  # ─────────────────────────────────────────────────────────────────
  # MÉTHODE PRINCIPALE : analyse complète
  # ─────────────────────────────────────────────────────────────────

  # Retourne un hash d'analyse complet :
  #   :contexte_regional  — description du cadre régional
  #   :milestones         — jalons filtrés par pertinence pour le label actuel
  #   :recommandations    — actions triées par urgence
  #   :urgence_globale    — :critique / :eleve / :modere / :faible
  #   :amelioration       — nombre de crans gagnés (avant→après), nil si non connu
  def self.analyse(region:, label_actuel:, label_avant: nil, date_validite: nil)
    region = region.to_s.downcase.strip
    politique = POLITIQUE[region]
    return analyse_vide unless politique

    score_actuel = score(label_actuel)
    score_avant  = label_avant.present? ? score(label_avant) : nil
    today        = Date.today
    annee_actuelle = today.year

    milestones   = milestones_pertinents(politique, label_actuel, score_actuel, annee_actuelle)
    recommandations = generer_recommandations(region, politique, label_actuel, score_actuel,
                                              date_validite, today, annee_actuelle)
    urgence_globale = calculer_urgence_globale(score_actuel, milestones, date_validite, today)
    amelioration    = score_avant ? (score_actuel - score_avant) : nil

    {
      region:            region,
      contexte_regional: politique[:description],
      cadre:             politique[:cadre],
      nom_region:        politique[:nom_region],
      milestones:        milestones,
      recommandations:   recommandations,
      programmes:        politique[:programmes],
      urgence_globale:   urgence_globale,
      amelioration:      amelioration,
      label_actuel:      label_actuel,
      label_avant:       label_avant,
      date_validite:     date_validite
    }
  end

  # ─────────────────────────────────────────────────────────────────
  # MÉTHODE : contexte seul (pour l'affichage timeline)
  # ─────────────────────────────────────────────────────────────────
  def self.contexte_regional(region)
    politique = POLITIQUE[region.to_s.downcase]
    return nil unless politique
    politique.slice(:nom_region, :cadre, :description, :milestones, :programmes)
  end

  # ─────────────────────────────────────────────────────────────────
  # PRIVATE
  # ─────────────────────────────────────────────────────────────────
  private_class_method def self.milestones_pertinents(politique, label_actuel, score_actuel, annee_actuelle)
    politique[:milestones].map do |m|
      cible_score = m[:label_cible] ? score(m[:label_cible]) : nil
      en_retard   = m[:obligatoire] && cible_score && score_actuel < cible_score && m[:annee] <= annee_actuelle
      a_venir     = m[:annee] > annee_actuelle
      concerne    = cible_score.nil? || score_actuel < cible_score

      next unless a_venir || en_retard

      m.merge(
        en_retard: en_retard,
        concerne:  concerne,
        annees_restantes: m[:annee] - annee_actuelle
      )
    end.compact.sort_by { |m| m[:annee] }
  end

  private_class_method def self.generer_recommandations(region, politique, label_actuel, score_actuel,
                                                         date_validite, today, annee_actuelle)
    recs = []

    # ── Validité du certificat ───────────────────────────────────────────────
    if date_validite.present?
      annees_restantes = ((date_validite - today) / 365.25).floor
      if annees_restantes <= 0
        recs << {
          urgence:      :critique,
          annee:        annee_actuelle,
          icone:        'bi-exclamation-triangle-fill',
          couleur:      'danger',
          titre:        "Certificat PEB expiré",
          description:  "Votre certificat PEB après travaux est arrivé à échéance. "\
                        "Un nouveau certificat est obligatoire pour toute vente ou bail.",
          action:       "Contacter un certificateur agréé pour établir un nouveau certificat PEB.",
          programme:    nil
        }
      elsif annees_restantes <= 2
        recs << {
          urgence:      :eleve,
          annee:        annee_actuelle + annees_restantes,
          icone:        'bi-clock-history',
          couleur:      'warning',
          titre:        "Certificat PEB bientôt expiré (#{annees_restantes} an#{'s' if annees_restantes > 1})",
          description:  "Le certificat arrive à échéance dans #{annees_restantes} an#{'s' if annees_restantes > 1}. "\
                        "Anticipez le renouvellement si des travaux ont été réalisés.",
          action:       "Mettre à jour le certificat PEB après travaux si des améliorations énergétiques "\
                        "supplémentaires ont été effectuées.",
          programme:    nil
        }
      end
    end

    # ── Obligations selon labels ─────────────────────────────────────────────
    politique[:milestones].each do |m|
      next unless m[:label_cible]
      cible_score = score(m[:label_cible])
      next unless score_actuel < cible_score

      annees_restantes = m[:annee] - annee_actuelle
      next if annees_restantes < 0

      urgence = case annees_restantes
                when 0..2   then :critique
                when 3..5   then :eleve
                when 6..10  then :modere
                else             :faible
                end
      couleur = case urgence
                when :critique then 'danger'
                when :eleve    then 'warning'
                when :modere   then 'primary'
                else                'secondary'
                end

      obligatoire_txt = m[:obligatoire] ? " (obligation)" : " (objectif)"

      recs << {
        urgence:     urgence,
        annee:       m[:annee],
        icone:       urgence == :critique ? 'bi-exclamation-triangle-fill' : 'bi-calendar-check',
        couleur:     couleur,
        titre:       "#{m[:titre]}#{obligatoire_txt}",
        description: m[:description],
        action:      action_pour_gap(label_actuel, m[:label_cible], region),
        programme:   programme_recommande(politique[:programmes], m[:label_cible], annee_actuelle, m[:annee])
      }
    end

    # ── Recommandation d'amélioration supplémentaire ─────────────────────────
    if score_actuel < 7 # label A
      prochain_label = label_suivant(label_actuel)
      if prochain_label
        recs << {
          urgence:     :faible,
          annee:       annee_actuelle + 5,
          icone:       'bi-graph-up-arrow',
          couleur:     'info',
          titre:       "Potentiel d'amélioration vers label #{prochain_label}",
          description: "Même en l'absence d'obligation immédiate, progresser vers le label #{prochain_label} "\
                       "augmentera la valeur du bien et anticipera les futures exigences réglementaires.",
          action:      action_pour_gap(label_actuel, prochain_label, region),
          programme:   politique[:programmes].find { |p| p[:actif] }&.slice(:nom, :url_info)
        }
      end
    end

    # Déduplique et trie par urgence puis par année
    ordre_urgence = { critique: 0, eleve: 1, modere: 2, faible: 3 }
    recs.uniq { |r| r[:titre] }
        .sort_by { |r| [ordre_urgence[r[:urgence]], r[:annee]] }
  end

  private_class_method def self.calculer_urgence_globale(score_actuel, milestones, date_validite, today)
    # Expiration certificat
    if date_validite.present? && date_validite < today
      return :critique
    end

    # Milestone obligatoire déjà dépassé
    if milestones.any? { |m| m[:en_retard] && m[:obligatoire] }
      return :critique
    end

    # Obligation dans < 3 ans
    proche = milestones.select { |m| m[:obligatoire] && m[:annees_restantes] < 3 }
    return :eleve unless proche.empty?

    # Label bas (E/F/G)
    return :eleve if score_actuel <= 3    # E ou moins

    # Obligation dans 3-6 ans
    moyen = milestones.select { |m| m[:obligatoire] && m[:annees_restantes].between?(3, 6) }
    return :modere unless moyen.empty?

    :faible
  end

  private_class_method def self.label_suivant(label)
    ordre = %w[G F E D C B A A+ A++]
    idx   = ordre.index(label.to_s.upcase)
    idx && idx < ordre.length - 1 ? ordre[idx + 1] : nil
  end

  private_class_method def self.action_pour_gap(label_actuel, label_cible, region)
    score_actuel = score(label_actuel)
    score_cible  = score(label_cible)
    gap          = score_cible - score_actuel

    base = case gap
           when 0 then "Aucun travail requis."
           when 1 then "Améliorer un poste majeur : isolation par l'extérieur (ITE), "\
                       "remplacement du système de chauffage, ou installation solaire thermique."
           when 2 then "Prévoir un programme de travaux en 2 étapes : chauffage décarbonné "\
                       "(pompe à chaleur / géothermie) + isolation des parois opaques."
           else        "Planifier une rénovation profonde par étapes : audit énergétique en priorité, "\
                       "puis isolation complète (toiture, murs, sol), remplacement chauffage décarbonné, "\
                       "vitrage haute performance, VMC double flux."
           end

    # complément régional
    complement = case region
                 when 'wallonie'  then " Démarche à coordonner avec l'audit Rénopack (dès oct. 2026)."
                 when 'bruxelles' then " Solliciter un facilitateur Renolution pour établir la trajectoire."
                 when 'flandre'   then " Utiliser le Woningpas pour tracer la trajectoire de rénovation."
                 else                  ""
                 end

    base + complement
  end

  private_class_method def self.programme_recommande(programmes, label_cible, annee_actuelle, annee_cible)
    # Renvoie le premier programme actif (ou bientôt actif)
    actif = programmes.find { |p| p[:actif] }
    inactif = programmes.reject { |p| p[:actif] }.first

    prog = actif || inactif
    return nil unless prog
    prog.slice(:nom, :url_info, :actif)
  end

  private_class_method def self.analyse_vide
    {
      region: nil, contexte_regional: nil, cadre: nil, nom_region: nil,
      milestones: [], recommandations: [], programmes: [],
      urgence_globale: :faible, amelioration: nil,
      label_actuel: nil, label_avant: nil, date_validite: nil
    }
  end

  # ─────────────────────────────────────────────────────────────────
  # UTILITAIRE : couleur Bootstrap selon urgence
  # ─────────────────────────────────────────────────────────────────
  URGENCE_COULEUR = {
    critique: 'danger',
    eleve:    'warning',
    modere:   'primary',
    faible:   'secondary'
  }.freeze

  def self.couleur_urgence(urgence)
    return 'secondary' if urgence.nil?
    URGENCE_COULEUR.fetch(urgence.to_sym, 'secondary')
  end

  def self.libelle_urgence(urgence)
    return '' if urgence.nil?
    {
      critique: "Action immédiate requise",
      eleve:    "Priorité élevée",
      modere:   "À planifier",
      faible:   "Long terme"
    }.fetch(urgence.to_sym, "")
  end
end

# IA #9 Assistant Juridique V1 — Checklist clauses obligatoires
# Analyse un texte de contrat de travaux belge et vérifie la présence
# des 10 clauses légales obligatoires selon le droit belge (Code civil,
# Loi Breyne, Loi sur les pratiques du marché, etc.)
#
# Usage :
#   service = ContratChecklistService.new(texte)
#   result  = service.analyser
#   # => { score: 7, total: 10, niveau: :satisfaisant, clauses: [...] }
class ContratChecklistService
  CLAUSES = [
    {
      id:          :identite_parties,
      label:       "Identité complète des parties",
      description: "Noms, adresses, numéros BCE/TVA de l'entrepreneur et du maître d'ouvrage.",
      obligatoire: true,
      patterns:    [
        /\bmaître d['']ouvrage\b/i,
        /\bentre[preneu|preneur]/i,
        /BE\s*0?[0-9]{9}/i,   # numéro BCE
        /\bTVA\b.*\bBE\b/i,
        /\bBCE\b/i
      ],
      seuil_patterns: 2
    },
    {
      id:          :description_travaux,
      label:       "Description précise des travaux",
      description: "Objet du contrat : nature, localisation et étendue des travaux à réaliser.",
      obligatoire: true,
      patterns:    [
        /\bobjet\b.*\btravaux\b/im,
        /\bdescription\b.*\btravaux\b/im,
        /\btravaux\s+(de|d[''])/i,
        /\bconsistent\s+[àa]\b/i,
        /\bprestations\b/i
      ],
      seuil_patterns: 2
    },
    {
      id:          :prix_devis,
      label:       "Prix ou devis détaillé",
      description: "Montant total HTVA/TVAC, ou bordereau de prix détaillé par poste.",
      obligatoire: true,
      patterns:    [
        /\bprix\s+(total|forfait|global)\b/i,
        /\bmontant\b.{0,30}[€$£]/,
        /[€$£]\s*[\d\s]{4,}/,
        /\bHTVA\b/i,
        /\bTVAC\b/i,
        /\bdevis\b.{0,30}\d/i,
        /\bforfait\b/i
      ],
      seuil_patterns: 2
    },
    {
      id:          :delai_execution,
      label:       "Délai d'exécution",
      description: "Date de début, durée en jours ouvrables ou date de fin prévue.",
      obligatoire: true,
      patterns:    [
        /\bdélai\b.{0,40}\bjour/i,
        /\bdurée\b.{0,40}\btravaux\b/i,
        /\bdate\s+de\s+début\b/i,
        /\bjours?\s+ouvr/i,
        /\bsemaines?\s+calendar/i,
        /\bcalendrier\b/i
      ],
      seuil_patterns: 1
    },
    {
      id:          :conditions_paiement,
      label:       "Conditions et échéancier de paiement",
      description: "Acomptes, % à la signature, paiements intermédiaires, solde à la réception.",
      obligatoire: true,
      patterns:    [
        /\bacompte\b/i,
        /\bpaiement\b.{0,40}(sign|réception|facturation)/i,
        /\béchéancier\b/i,
        /\b\d{1,3}\s*%\s*(à|au|lors)\b/i,
        /\bsolde\b.{0,20}(réception|livraison|fin)/i,
        /\bfacturation\b/i
      ],
      seuil_patterns: 2
    },
    {
      id:          :tva_6,
      label:       "Mention TVA 6% (si applicable)",
      description: "Clause TVA réduite à 6% + attestation propriétaire (logement > 10 ans, usage privé).",
      obligatoire: false,
      patterns:    [
        /\b6\s*%\b/,
        /taux\s+réduit/i,
        /attestation\s+TVA/i,
        /art(?:icle)?\.?\s*1(?:er)?\b.*TVA/i,
        /\bAR\b.*\bTVA\b/i
      ],
      seuil_patterns: 1
    },
    {
      id:          :garantie_decennale,
      label:       "Garantie décennale (Art. 1792 C.civ.)",
      description: "Clause mentionnant la garantie décennale sur la solidité de l'ouvrage.",
      obligatoire: true,
      patterns:    [
        /\bgara[nt]{1,2}ie\s+décennale\b/i,
        /\b1792\b/,
        /\bgaran[t]{1,2}ie\s+10\s+ans\b/i,
        /\bsolidité\b.{0,40}\bouvrage\b/i,
        /\bvice[s]?\s+cach[eé][s]?\b/i
      ],
      seuil_patterns: 1
    },
    {
      id:          :assurance_entrepreneur,
      label:       "Attestation d'assurance de l'entrepreneur",
      description: "RC professionnelle et/ou assurance décennale de l'entrepreneur.",
      obligatoire: true,
      patterns:    [
        /\bassurance\b.{0,40}(décennale|RC|responsabilité)/i,
        /\bRC\s+pro\b/i,
        /\bresponsabilité\s+civile\b/i,
        /\bpolice\s+d['']assurance\b/i,
        /\bcouverture\s+d['']assurance\b/i
      ],
      seuil_patterns: 1
    },
    {
      id:          :clause_resiliation,
      label:       "Clause de résiliation / force majeure",
      description: "Conditions de résiliation du contrat, pénalités, cas de force majeure.",
      obligatoire: false,
      patterns:    [
        /\brésiliation\b/i,
        /\bannulation\b.{0,30}contrat/i,
        /\bforce\s+majeure\b/i,
        /\bpénalité[s]?\b/i,
        /\bmettre\s+fin\b.{0,20}contrat/i
      ],
      seuil_patterns: 1
    },
    {
      id:          :loi_applicable,
      label:       "Droit applicable et compétence juridictionnelle",
      description: "Mention du droit belge applicable et du tribunal compétent en cas de litige.",
      obligatoire: false,
      patterns:    [
        /\bdroit\s+belge\b/i,
        /\bloi\s+belge\b/i,
        /\btribunal\b.{0,40}(compétent|Belgique)/i,
        /\bjuridiction\b/i,
        /\blitiges?\b.{0,40}(tribunal|cour|juridi)/i,
        /\barbitrage\b/i
      ],
      seuil_patterns: 1
    }
  ].freeze

  NIVEAUX = {
    excellent:     { min: 9,  label: 'Excellent',     color: 'success', icon: 'bi-shield-check' },
    satisfaisant:  { min: 7,  label: 'Satisfaisant',  color: 'primary', icon: 'bi-shield-half'  },
    incomplet:     { min: 5,  label: 'Incomplet',     color: 'warning', icon: 'bi-exclamation-triangle' },
    insuffisant:   { min: 0,  label: 'Insuffisant',   color: 'danger',  icon: 'bi-shield-x'     }
  }.freeze

  def initialize(texte)
    @texte = texte.to_s
  end

  def analyser
    resultats = CLAUSES.map do |clause|
      detected, extrait = detecter_clause(clause)
      {
        id:          clause[:id],
        label:       clause[:label],
        description: clause[:description],
        obligatoire: clause[:obligatoire],
        detected:    detected,
        extrait:     detected ? extrait : nil
      }
    end

    score_total = resultats.count { |r| r[:detected] }
    score_obligatoires = resultats.count { |r| r[:obligatoire] && r[:detected] }
    total_obligatoires = resultats.count { |r| r[:obligatoire] }

    niveau = determiner_niveau(score_total)

    {
      score:               score_total,
      total:               CLAUSES.size,
      score_obligatoires:  score_obligatoires,
      total_obligatoires:  total_obligatoires,
      niveau:              niveau[:label],
      niveau_color:        niveau[:color],
      niveau_icon:         niveau[:icon],
      clauses:             resultats
    }
  end

  private

  def detecter_clause(clause)
    matched_patterns = 0
    premier_extrait  = nil

    clause[:patterns].each do |pattern|
      m = @texte.match(pattern)
      if m
        matched_patterns += 1
        if premier_extrait.nil?
          start_pos = [m.begin(0) - 40, 0].max
          end_pos   = [m.end(0)   + 40, @texte.length].min
          premier_extrait = "…#{@texte[start_pos...end_pos].gsub(/\s+/, ' ').strip}…"
        end
      end
    end

    detected = matched_patterns >= clause[:seuil_patterns]
    [detected, premier_extrait]
  end

  def determiner_niveau(score)
    NIVEAUX.values.find { |n| score >= n[:min] } || NIVEAUX[:insuffisant]
  end
end

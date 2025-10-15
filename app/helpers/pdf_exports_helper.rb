module PdfExportsHelper
  def format_question_label(key)
    question_labels = {
      # === ÉLIGIBILITÉ GÉNÉRALE ===
      'eligible' => 'Éligible aux primes',
      'userType' => 'Type d\'utilisateur',
      'localisation' => 'Logement situé dans la région',
      'age_batiment' => 'Âge du logement',
      'usage' => 'Usage du bien (logement)',
      'proprietaire' => 'Êtes-vous propriétaire ?',
      'revenu_eligible' => 'Revenus conformes aux plafonds',
      'resident' => 'Résidence principale',
      'travaux_eligibles' => 'Travaux éligibles aux primes',

      # === PROPRIÉTÉ ET LOCATION ===
      'appartement' => 'Appartement',
      'maison' => 'Maison individuelle',
      'immeuble_appartements' => 'Immeuble d\'appartements',
      'autre_bien' => 'Autre type de bien',
      'locataire_social' => 'Logement social',
      'demande_autorisation' => 'Autorisation du propriétaire',

      # === DONNÉES TECHNIQUES ===
      'surface_logement' => 'Surface du logement (m²)',
      'type_chauffage' => 'Type de chauffage actuel',
      'isolation_existante' => 'Isolation existante',
      'annee_construction' => 'Année de construction',
      'certificat_peb' => 'Certificat PEB disponible',
      'classe_energetique' => 'Classe énergétique actuelle',

      # === SITUATION GÉOGRAPHIQUE ===
      'region' => 'Région',
      'code_postal' => 'Code postal',
      'commune' => 'Commune',
      'zone_rurale' => 'Zone rurale',
      'zone_urbaine' => 'Zone urbaine',

      # === DONNÉES FINANCIÈRES ET AFFINAGE ===
      'revenus_menage' => 'Revenus du ménage',
      'composition_familiale' => 'Composition familiale',
      'nombre_enfants' => 'Nombre d\'enfants à charge',
      'personne_handicapee' => 'Personne handicapée dans le ménage',
      'beneficiaire_cpas' => 'Bénéficiaire CPAS',
      'quotient_familial' => 'Quotient familial',
      'situation_familiale' => 'Situation familiale',
      'statut_familial' => 'Statut familial',
      'celibataire' => 'Célibataire',
      'marie' => 'Marié(e)',
      'couple' => 'En couple',
      'couple_enfant' => 'Couple avec enfants',
      'parent_isole' => 'Parent isolé',
      'veuf' => 'Veuf/Veuve',
      'divorce' => 'Divorcé(e)',
      'enfants_charge' => 'Enfants à charge',
      'enfants_mineurs' => 'Enfants mineurs à charge',
      'personnes_charge' => 'Personnes à charge',
      'montant_revenus' => 'Montant des revenus annuels',
      'revenus_nets' => 'Revenus nets imposables',
      'revenu_net' => 'Revenus nets',
      'revenus_bruts' => 'Revenus bruts',
      'revenus_bruts_imposables' => 'Revenus bruts imposables',
      'revenus_reference' => 'Revenus de référence',
      'revenus_totaux' => 'Revenus totaux du ménage',
      'revenus_annuels' => 'Revenus annuels',
      'prime_emploi' => 'Prime d\'emploi',
      'allocations_chomage' => 'Allocations de chômage',
      'pension_invalidite' => 'Pension d\'invalidité',
      'autres_revenus' => 'Autres revenus',
      'revenus_complementaires' => 'Revenus complémentaires',
      'categorie_revenus' => 'Catégorie de revenus déterminée',

      # === TRAVAUX SPÉCIFIQUES ===
      'devis_disponible' => 'Devis disponible',
      'entrepreneur_agree' => 'Entrepreneur agréé',
      'factures_acquittees' => 'Factures acquittées',
      'materiaux_conformes' => 'Matériaux conformes',
      'respect_normes' => 'Respect des normes',

      # === CATÉGORIES DE REVENUS ===
      'categorie' => 'Catégorie de revenus finale',
      'selected_category' => 'Catégorie sélectionnée',
      'estimated_category' => 'Catégorie estimée',
      'cat1' => 'Catégorie 1 (revenus très faibles)',
      'cat2' => 'Catégorie 2 (revenus faibles)',
      'cat3' => 'Catégorie 3 (revenus moyens)',
      'cat4' => 'Catégorie 4 (revenus élevés)',

      # === INFORMATIONS COMPLÉMENTAIRES ===
      'nb_logements' => 'Nombre de logements',
      'nombre_unites' => 'Nombre d\'unités',

      # === TYPES DE TRAVAUX ===
      'isolation_toiture' => 'Isolation de toiture',
      'isolation_murs' => 'Isolation des murs',
      'isolation_sol' => 'Isolation du sol',
      'chassis_fenetres' => 'Châssis et fenêtres',
      'chauffage' => 'Système de chauffage',
      'ventilation' => 'Système de ventilation',
      'panneau_solaire' => 'Panneaux solaires',
      'chauffe_eau' => 'Chauffe-eau',

      # === CHAMPS SPÉCIFIQUES FLANDRE ===
      'usage' => 'Usage du bien (logement)',
      'proprietaire' => 'Êtes-vous propriétaire ?',
      'annee' => 'Âge du logement (plus de 15 ans)',
      'appartement-copro' => 'Appartement en copropriété',
      'locataire_social' => 'Logement social',
      'revenus_trop_eleves' => 'Revenus conformes aux plafonds',
      'type' => 'Type de logement',
      'peb' => 'Certificat PEB',
      'domicile' => 'Résidence principale',
      'demolition' => 'Bâtiment à démolir',
      'travaux' => 'Travaux prévus',
      'protege' => 'Bâtiment protégé',
      'facture_solde' => 'Factures soldées',
      'voorbereiding_isolatie' => 'Préparation isolation',
      'voorbereiding_sanitair_elec' => 'Préparation sanitaire/électrique',
      'renovation_toiture' => 'Rénovation toiture',
      'renovation_murs' => 'Rénovation murs',
      'renovation_sol' => 'Rénovation sol',
      'amiante' => 'Enlèvement amiante',
      'isolation_murs_cat12' => 'Isolation murs (Cat. 1-2)',
      'isolation_murs_cat34' => 'Isolation murs (Cat. 3-4)',
      'ramen_deuren' => 'Châssis et portes',
      'warmtepomp' => 'Pompe à chaleur',
      'warmtepompboiler' => 'Boiler pompe à chaleur',

      # === CHAMPS SPÉCIFIQUES BRUXELLES ===
      'prime_energie' => 'Prime énergie',
      'travaux_isolation' => 'Travaux d\'isolation',
      'audit_energetique' => 'Audit énergétique',
      'etude_faisabilite' => 'Étude de faisabilité',
      'bruxelles_categorie' => 'Catégorie de revenus Bruxelles',
      'bruxelles_enfants_charge' => 'Enfants à charge (Bruxelles)',
      'bruxelles_situation_familiale' => 'Situation familiale (Bruxelles)',
      'bruxelles_revenus' => 'Revenus Bruxelles',
      'bruxelles_statut' => 'Statut familial Bruxelles',
      'bruxelles_statut_familial' => 'Statut familial (Bruxelles)',
      'bruxelles_revenu_estimation' => 'Estimation revenus (Bruxelles)',
      'demandeur_principal' => 'Demandeur principal',
      'conjoint_cohabitant' => 'Conjoint/cohabitant',
      'personnes_handicapees' => 'Personnes handicapées',
      'autres_personnes' => 'Autres personnes du ménage',

      # === CHAMPS SPÉCIFIQUES WALLONIE ===
      'habitation_1975' => 'Habitation antérieure à 1975',
      'permis_urbanisme' => 'Permis d\'urbanisme',
      'declaration_prealable' => 'Déclaration préalable',
      'entreprise_agreee' => 'Entreprise agréée',
      'materiaux_certifies' => 'Matériaux certifiés',
      'wallonie_categorie' => 'Catégorie de revenus Wallonie',
      'wallonie_enfants_charge' => 'Enfants à charge (Wallonie)',
      'wallonie_personnes_agees_charge' => 'Personnes âgées à charge (Wallonie)',
      'wallonie_situation_familiale' => 'Situation familiale (Wallonie)',
      'wallonie_revenus' => 'Revenus Wallonie',
      'wallonie_statut' => 'Statut familial Wallonie',
      'wallonie_statut_familial' => 'Statut familial (Wallonie)',
      'wallonie_revenu_estimation' => 'Estimation revenus (Wallonie)',
      'wallonie_revenu_tranche' => 'Tranche de revenus (Wallonie)',
      'revenus_r5' => 'Revenus supérieurs au plafond R5',
      'revenu_reference' => 'Revenu de référence',
      'nombre_personnes_charge' => 'Nombre de personnes à charge',
      'situation_particuliere' => 'Situation particulière',
      'handicap' => 'Personne en situation de handicap',
      'primo_accedant' => 'Primo-accédant',
      'age_demandeur' => 'Âge du demandeur',

      # === SLUGS PRIMES WALLONIE ===
      # Travaux Toiture
      'wallonie_toiture_remplacement_couverture' => 'Remplacement couverture (m²)',
      'wallonie_toiture_appropriation_charpente' => 'Appropriation charpente',
      'wallonie_toiture_evacuation_eaux_pluviales' => 'Évacuation eaux pluviales',
      'wallonie_toiture_isolation_thermique' => 'Isolation thermique (m²)',
      'wallonie_toiture_isolation_biosource' => 'Isolation biosourcée (m²)',

      # Travaux Murs
      'wallonie_assechement_murs_infiltration' => 'Assèchement infiltration (m²)',
      'wallonie_assechement_murs_humidite' => 'Assèchement humidité (m²)',
      'wallonie_renforcement_murs' => 'Renforcement murs (m²)',
      'wallonie_elimination_merule' => 'Élimination mérule',
      'wallonie_elimination_radon' => 'Élimination radon',
      'wallonie_isolation_murs' => 'Isolation thermique (m²)',
      'wallonie_isolation_murs_biosource' => 'Isolation biosourcée (m²)',

      # Travaux Sols
      'wallonie_isolation_sols' => 'Isolation sols (m²)',
      'wallonie_isolation_sols_biosource' => 'Isolation biosourcée (m²)',
      'wallonie_remplacement_supports_circulation' => 'Remplacement supports (m²)',
      'wallonie_isolation_finition_planchers' => 'Finition planchers (m²)',

      # Ventilation
      'wallonie_vmc_simple' => 'VMC simple flux (complète)',
      'wallonie_vmc_double' => 'VMC double flux (complète)',
      'wallonie_vmc_simple_partielle' => 'VMC simple (partielle)',
      'wallonie_vmc_double_partielle' => 'VMC double (partielle)',

      # Audit
      'wallonie_audit_energetique' => 'Audit énergétique',
    }

    question_labels[key] || key.humanize
  end

  def format_answer_value(value)
    return 'Non renseigné' if value.nil? || value == ''

    case value.to_s.downcase
    when 'oui', 'true', '1'
      'Oui'
    when 'non', 'false', '0'
      'Non'
    when 'prive'
      'Privé'
    when 'public'
      'Public'
    when 'entreprise'
      'Entreprise'
    when 'asbl'
      'ASBL'

    # Statuts familiaux
    when 'celibataire'
      'Célibataire'
    when 'couple'
      'En couple (sans enfants)'
    when 'couple-enfant'
      'En couple avec enfants'
    when 'parent-isole'
      'Parent isolé'
    when 'marie'
      'Marié(e)'
    when 'veuf'
      'Veuf/Veuve'
    when 'divorce'
      'Divorcé(e)'

    # Tranches de revenus
    when '-24320'
      'Moins de 24 320 €/an'
    when '24231-42340'
      'Entre 24 231 € et 42 340 €/an'
    when '42341-53880'
      'Entre 42 341 € et 53 880 €/an'
    when '53881+'
      'Plus de 53 881 €/an'
    when 'moins-36000'
      'Moins de 36 000 €/an'
    when '36000-59000'
      'Entre 36 000 € et 59 000 €/an'
    when '59000-77000'
      'Entre 59 000 € et 77 000 €/an'
    when 'plus-77000'
      'Plus de 77 000 €/an'

    # Catégories
    when 'cat1', '1'
      'Catégorie 1 (revenus très faibles)'
    when 'cat2', '2'
      'Catégorie 2 (revenus faibles)'
    when 'cat3', '3'
      'Catégorie 3 (revenus moyens)'
    when 'cat4', '4'
      'Catégorie 4 (revenus élevés)'
    when 'cat5', '5'
      'Catégorie 5 (revenus très élevés)'

    else
      value.to_s
    end
  end

  def format_price(amount)
    return '0,00 €' if amount.nil? || amount == 0
    "#{sprintf('%.2f', amount).gsub('.', ',')} €"
  end

  def format_region_name(region)
    case region.to_s.downcase
    when 'flandre'
      'Flandre'
    when 'bruxelles'
      'Bruxelles-Capitale'
    when 'wallonie'
      'Wallonie'
    else
      region.to_s.humanize
    end
  end

  def format_field_value(key, value, region = nil)
    return format_boolean_value(value) if [true, false, 'true', 'false'].include?(value)

    # Mapping spécial pour les tranches de revenus Wallonie
    if key == 'wallonie_revenu_tranche' && region == 'wallonie'
      case value.to_s
      when 'r1'
        'Moins de 26 900 €'
      when 'r2'
        '26 901 € – 38 300 €'
      when 'r3'
        '38 301 € – 50 600 €'
      when 'r4'
        '50 601 € – 114 400 €'
      when 'r5'
        'Plus de 114 401 €'
      else
        value.to_s
      end
    # Mapping pour les statuts familiaux
    elsif key.include?('statut_familial')
      case value.to_s
      when 'isole'
        'Isolé / Célibataire'
      when 'couple'
        'Couple'
      else
        value.to_s.humanize
      end
    else
      value.to_s
    end
  end
end

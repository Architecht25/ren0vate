# Service pour le remplissage automatique des formulaires Irisbox
# Permet de transférer les données de Ren0vate vers les plateformes administratives
class IrisboxAutofillService
  include ActionView::Helpers::JavaScriptHelper

  def initialize(property, user, project = nil)
    @property = property
    @user = user
    @project = project || @property.projects.first
    @form_data = build_form_data
  end

  # Génère un script JavaScript pour remplir automatiquement Irisbox
  def generate_autofill_script
    {
      script: build_javascript_autofill,
      data: @form_data,
      instructions: generate_user_instructions
    }
  end

  # Génère un objet JSON avec toutes les données nécessaires
  def export_for_browser_extension
    {
      personal_data: extract_personal_data,
      property_data: extract_property_data,
      project_data: extract_project_data,
      document_references: extract_document_references,
      timestamp: Time.current.iso8601
    }
  end

  # Génère un PDF pré-rempli téléchargeable
  def generate_prefilled_pdf
    # À implémenter avec Prawn ou WickedPDF
    # Retourne le chemin vers le PDF généré
  end

  private

  def build_form_data
    {
      # SECTION 1: Données personnelles du demandeur
      demandeur_civilite: map_civility(@user.gender),
      demandeur_nom: @user.last_name,
      demandeur_prenom: @user.first_name,
      demandeur_registre_national: @user.national_number,
      demandeur_telephone: @user.phone,
      demandeur_email: @user.email,

      # Adresse du demandeur
      demandeur_rue: @user.street,
      demandeur_numero: @user.number,
      demandeur_code_postal: @user.postal_code,
      demandeur_commune: @user.city,

      # SECTION 2: Données du bien immobilier
      bien_rue: @property.rue,
      bien_numero: @property.numero,
      bien_code_postal: @property.code_postal,
      bien_commune: @property.commune,
      bien_type: map_property_type(@property),
      bien_usage: map_property_usage(@property),
      bien_annee_construction: @property.annee_construction,
      bien_surface_totale: @property.surface_totale,
      bien_surface_habitable: @property.surface_habitable,

      # Données cadastrales
      bien_cadastre_section: extract_cadastral_section,
      bien_cadastre_division: extract_cadastral_division,
      bien_cadastre_parcelle: @property.numero_cadastre,

      # SECTION 3: Données financières
      demandeur_revenus: @user.household_income,
      demandeur_situation_familiale: @user.marital_status,
      demandeur_nombre_enfants: @user.children_count,

      # SECTION 4: Données du projet
      projet_type: map_project_type(@project),
      projet_description: @project&.description || generate_project_description,
      projet_montant_estime: calculate_estimated_amount,
      projet_date_debut: @project&.date_debut&.strftime('%d/%m/%Y'),

      # SECTION 5: Données de l'entrepreneur (si disponible)
      entrepreneur_nom: @project&.entrepreneur_principal_nom,
      entrepreneur_entreprise: @project&.entrepreneur_principal_entreprise,
      entrepreneur_numero_tva: @project&.entrepreneur_principal_numero_tva,
      entrepreneur_telephone: @project&.entrepreneur_principal_telephone,
      entrepreneur_email: @project&.entrepreneur_principal_email,
      entrepreneur_adresse: @project&.entrepreneur_principal_adresse,

      # SECTION 6: Métadonnées
      form_version: determine_form_version,
      submission_date: Date.current.strftime('%d/%m/%Y'),
      ren0vate_reference: generate_reference_number
    }
  end

  def build_javascript_autofill
    script_parts = []

    # Fonction utilitaire pour trouver et remplir les champs
    script_parts << <<~JS
      // Script d'auto-remplissage Ren0vate pour Irisbox
      function ren0vateAutofill() {
        console.log('🏠 Ren0vate AutoFill: Démarrage du remplissage automatique...');

        const data = #{@form_data.to_json};
        let fieldsFound = 0;
        let fieldsFilled = 0;

        // Fonction pour remplir un champ par différents sélecteurs
        function fillField(selectors, value) {
          if (!value) return false;

          for (const selector of selectors) {
            const field = document.querySelector(selector);
            if (field) {
              fieldsFound++;
              try {
                if (field.type === 'select-one') {
                  // Pour les select, chercher la bonne option
                  const option = Array.from(field.options).find(opt =>
                    opt.text.toLowerCase().includes(value.toString().toLowerCase()) ||
                    opt.value === value.toString()
                  );
                  if (option) {
                    field.value = option.value;
                    fieldsFilled++;
                  }
                } else {
                  field.value = value;
                  fieldsFilled++;
                }

                // Déclencher les événements de changement
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));

                // Marquer visuellement le champ rempli
                field.style.backgroundColor = '#e8f5e8';
                field.style.border = '2px solid #28a745';

                console.log('✅ Rempli:', selector, '=', value);
                return true;
              } catch (error) {
                console.warn('⚠️ Erreur lors du remplissage:', selector, error);
              }
            }
          }
          return false;
        }
    JS

    # Ajout des mappings de champs spécifiques à Irisbox
    @form_data.each do |key, value|
      next if value.blank?

      selectors = generate_field_selectors(key)
      script_parts << "fillField(#{selectors.to_json}, #{escape_javascript(value.to_s).inspect});"
    end

    # Finalisation du script
    script_parts << <<~JS
        // Résumé des résultats
        console.log(`🏠 Ren0vate AutoFill: ${fieldsFilled}/${fieldsFound} champs remplis avec succès`);

        // Afficher notification à l'utilisateur
        const notification = document.createElement('div');
        notification.innerHTML = `
          <div style="position: fixed; top: 20px; right: 20px; z-index: 10000;
                      background: #28a745; color: white; padding: 15px; border-radius: 5px;
                      box-shadow: 0 4px 8px rgba(0,0,0,0.3); font-family: Arial, sans-serif;">
            🏠 <strong>Ren0vate AutoFill</strong><br>
            ${fieldsFilled} champs remplis automatiquement
            <button onclick="this.parentElement.remove()"
                    style="float: right; background: none; border: none; color: white; font-size: 18px; cursor: pointer;">×</button>
          </div>
        `;
        document.body.appendChild(notification);

        // Supprimer la notification après 5 secondes
        setTimeout(() => {
          if (notification.parentElement) {
            notification.remove();
          }
        }, 5000);
      }

      // Lancer le remplissage automatique
      ren0vateAutofill();
    JS

    script_parts.join("\n")
  end

  def generate_field_selectors(field_key)
    # Mapping des champs Ren0vate vers les sélecteurs Irisbox probables
    field_mappings = {
      demandeur_nom: [
        'input[name*="nom"]',
        'input[name*="lastName"]',
        'input[id*="nom"]',
        'input[placeholder*="nom"]'
      ],
      demandeur_prenom: [
        'input[name*="prenom"]',
        'input[name*="firstName"]',
        'input[id*="prenom"]',
        'input[placeholder*="prénom"]'
      ],
      demandeur_email: [
        'input[type="email"]',
        'input[name*="email"]',
        'input[name*="mail"]'
      ],
      demandeur_telephone: [
        'input[type="tel"]',
        'input[name*="telephone"]',
        'input[name*="phone"]',
        'input[name*="gsm"]'
      ],
      demandeur_registre_national: [
        'input[name*="registre"]',
        'input[name*="national"]',
        'input[name*="nn"]',
        'input[placeholder*="registre national"]'
      ],
      bien_rue: [
        'input[name*="rue"]',
        'input[name*="street"]',
        'input[name*="adresse"]'
      ],
      bien_numero: [
        'input[name*="numero"]',
        'input[name*="number"]',
        'input[name*="num"]'
      ],
      bien_code_postal: [
        'input[name*="postal"]',
        'input[name*="zip"]',
        'input[name*="cp"]'
      ],
      bien_commune: [
        'input[name*="commune"]',
        'input[name*="city"]',
        'input[name*="ville"]',
        'select[name*="commune"]'
      ],
      bien_surface_totale: [
        'input[name*="surface"]',
        'input[name*="area"]',
        'input[name*="m2"]'
      ]
    }

    field_mappings[field_key] || ["input[name*=\"#{field_key}\"]"]
  end

  def extract_personal_data
    {
      civilite: map_civility(@user.gender),
      nom: @user.last_name,
      prenom: @user.first_name,
      email: @user.email,
      telephone: @user.phone,
      registre_national: @user.national_number,
      adresse: {
        rue: @user.street,
        numero: @user.number,
        code_postal: @user.postal_code,
        commune: @user.city
      },
      situation_familiale: @user.marital_status,
      revenus: @user.household_income,
      nombre_enfants: @user.children_count
    }
  end

  def extract_property_data
    {
      adresse: {
        rue: @property.rue,
        numero: @property.numero,
        code_postal: @property.code_postal,
        commune: @property.commune
      },
      caracteristiques: {
        type: map_property_type(@property),
        usage: map_property_usage(@property),
        annee_construction: @property.annee_construction,
        surface_totale: @property.surface_totale,
        surface_habitable: @property.surface_habitable
      },
      cadastre: {
        section: extract_cadastral_section,
        division: extract_cadastral_division,
        parcelle: @property.numero_cadastre
      },
      performance_energetique: {
        peb: @property.peb,
        audit_energetique: @property.audit_energetique
      }
    }
  end

  def extract_project_data
    return {} unless @project

    {
      type: map_project_type(@project),
      description: @project.description || generate_project_description,
      montant_estime: calculate_estimated_amount,
      dates: {
        debut: @project.date_debut,
        fin_prevue: @project.date_fin_prevue
      },
      entrepreneur: extract_entrepreneur_data
    }
  end

  def extract_entrepreneur_data
    return {} unless @project

    {
      nom: @project.entrepreneur_principal_nom,
      entreprise: @project.entrepreneur_principal_entreprise,
      numero_tva: @project.entrepreneur_principal_numero_tva,
      telephone: @project.entrepreneur_principal_telephone,
      email: @project.entrepreneur_principal_email,
      adresse: @project.entrepreneur_principal_adresse
    }
  end

  def extract_document_references
    @property.documents.approved.map do |doc|
      {
        type: doc.type_document,
        nom: doc.file_name || doc.title,
        date_upload: doc.created_at,
        taille: doc.file.attached? ? doc.file.byte_size : nil
      }
    end
  end

  def map_civility(gender)
    case gender&.downcase
    when 'male', 'homme', 'masculin'
      'Monsieur'
    when 'female', 'femme', 'feminin'
      'Madame'
    else
      'X'
    end
  end

  def map_property_type(property)
    case property.region&.downcase
    when 'bruxelles'
      property.type_bien_bruxelles
    when 'wallonie'
      property.type_propriete_wallonie
    when 'flandre'
      property.type_bien_flandre
    else
      property.type
    end
  end

  def map_property_usage(property)
    case property.region&.downcase
    when 'flandre'
      property.usage_flandre
    else
      property.usage || property.occupation
    end
  end

  def map_project_type(project)
    return nil unless project

    # Mapper les types de projets Ren0vate vers les catégories Irisbox
    case project.project_type
    when 'isolation'
      'Isolation thermique'
    when 'chauffage'
      'Installation de chauffage'
    when 'renovation_energetique'
      'Rénovation énergétique globale'
    else
      project.project_type&.humanize
    end
  end

  def extract_cadastral_section
    # Extraire la section du numéro cadastre si formaté correctement
    @property.numero_cadastre&.split('/')&.first
  end

  def extract_cadastral_division
    # Extraire la division du numéro cadastre si formaté correctement
    parts = @property.numero_cadastre&.split('/')
    parts&.length&.> 1 ? parts[1] : nil
  end

  def calculate_estimated_amount
    # Calculer le montant estimé basé sur les simulations ou projets
    @property.simulations.last&.total_amount || @project&.budget_estime || 0
  end

  def generate_project_description
    return nil unless @project

    "Projet de #{map_project_type(@project)} pour #{map_property_type(@property)} situé #{@property.full_address}"
  end

  def determine_form_version
    # Déterminer la version du formulaire basé sur la région et le type de prime
    case @property.region&.downcase
    when 'bruxelles'
      'Renolution 2024'
    when 'wallonie'
      'Primes Énergie Wallonie 2024'
    when 'flandre'
      'Vlaamse Renovatiepremie 2024'
    else
      'Standard'
    end
  end

  def generate_reference_number
    "REN#{@property.id}-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def generate_user_instructions
    {
      fr: {
        title: "Instructions d'utilisation - Remplissage automatique Irisbox",
        steps: [
          "1. Ouvrez votre navigateur et allez sur le site Irisbox",
          "2. Connectez-vous à votre compte et accédez au formulaire de demande de prime",
          "3. Copiez et collez le script JavaScript dans la console du navigateur (F12 → Console)",
          "4. Appuyez sur Entrée pour exécuter le script",
          "5. Vérifiez que tous les champs ont été correctement remplis",
          "6. Complétez manuellement les champs non remplis automatiquement",
          "7. Attachez les documents requis depuis votre dossier Ren0vate",
          "8. Soumettez votre demande"
        ],
        warnings: [
          "⚠️ Vérifiez toujours les données remplies automatiquement",
          "⚠️ Certains champs peuvent nécessiter une vérification manuelle",
          "⚠️ Gardez une copie de votre dossier Ren0vate comme référence"
        ]
      }
    }
  end
end

module ShowHelper
  # ==========================================
  # MÉTHODES POUR LES DONNÉES SIMULATION
  # ==========================================

  def simulation_region_data(simulation)
    return nil unless simulation&.region.present?

    {
      region: simulation.region.downcase,
      formatted_region: simulation.region.capitalize,
      created_date: simulation.created_at.strftime("%d/%m/%Y")
    }
  end

  def simulation_category_data(simulation)
    return nil unless simulation.parameters.present?

    begin
      params_data = JSON.parse(simulation.parameters)
      category_used = params_data['category_used']

      if category_used.present?
        category_used.start_with?('wallonie_') ? category_used : 'wallonie_' + category_used.downcase
      end
    rescue JSON::ParserError
      nil
    end
  end

  def prepare_saved_inputs(simulation)
    return {} unless simulation.parameters.present?

    saved_inputs = {}
    begin
      params_data = JSON.parse(simulation.parameters)

      if params_data['prime_cards'].present?
        params_data['prime_cards'].each do |category_key, category_data|
          next unless category_data['primes']

          category_data['primes'].each do |prime|
            if prime['user_input_value'].present? &&
               prime['user_input_value'] != 0 &&
               prime['user_input_value'] != "0"
              saved_inputs[prime['slug']] = prime['user_input_value']
            end
          end
        end
      end
    rescue JSON::ParserError
      # Si le JSON est invalide, on ignore
    end

    saved_inputs
  end

  # NB : `finalite` a été supprimée de `projects` (migration 20260308164557,
  # abandon de la fonctionnalité "Entreprises Bruxelles") — cette méthode n'est
  # plus appelée nulle part, gardée résiliente pour éviter un crash si jamais
  # ré-utilisée.
  def project_finalite(_simulation)
    "residentielle"
  end

  # ==========================================
  # MÉTHODES POUR LES DONNÉES JSON
  # ==========================================

  def wallonie_primes_json(primes)
    return '{}' unless primes.present?

    data = primes.each_with_object({}) do |prime, hash|
      hash[prime.slug] = {
        titre: prime.titre,
        valeurs_par_categorie: prime.valeurs_par_categorie || {},
        eligible_categories: prime.eligible_categories || []
      }
    end
    # json_escape empêche les séquences </script> ou <!-- dans un contexte HTML
    json_escape(data.to_json)
  end

  def primes_data_script(primes)
    return '' unless primes.present?

    json_escape(primes.to_json(
      only: [:slug, :titre, :unite, :type_de_valeur, :valeurs_par_categorie,
             :placeholder, :condition, :conseil, :document, :eligible_categories]
    ))
  end

  # ==========================================
  # MÉTHODES POUR LES SCRIPTS
  # ==========================================

  def generate_category_script(simulation_category)
    return '' unless simulation_category.present?

    # Encoder en JSON pour éviter l'injection JS par interpolation directe dans une string JS
    category_json = json_escape(simulation_category.to_json)
    <<~JAVASCRIPT
      // 🎯 Forcer la catégorie avant la connexion des contrôleurs
      localStorage.setItem('selectedWallonieCategory', #{category_json});
      console.log('🎯 Catégorie simulation définie:', #{category_json});
    JAVASCRIPT
  end

  def generate_saved_inputs_script(saved_inputs)
    return '' if saved_inputs.empty?

    # json_escape pr\u00e9vient l'\u00e9chappement de balises </script> dans le contexte HTML
    inputs_json = json_escape(saved_inputs.to_json)
    <<~JAVASCRIPT
      // 🔄 Restaurer les valeurs sauvegardées des inputs
      const savedInputs = #{inputs_json};
      let restorationApplied = false;

      // Marquer temporairement qu'on est en phase de restauration
      window.isRestoringValues = true;
      window.restorationStartTime = Date.now(); // Timer de sécurité

      function restoreSavedInputs() {
        // Éviter les restaurations multiples sur la même page
        if (restorationApplied) {
          console.log('🔄 Restauration déjà appliquée, ignorée');
          window.isRestoringValues = false;
          return;
        }

        console.log('🔄 Démarrage restauration des valeurs sauvegardées:', savedInputs);
        window.isRestoringValues = true;

        // Mapping des slugs des primes vers les targets Stimulus
        const primeTargetMapping = #{prime_target_mapping.to_json.html_safe};

        function attemptRestore() {
          let restoredCount = 0;

          Object.entries(savedInputs).forEach(([slug, value]) => {
            console.log('🔍 Recherche input pour slug:', slug, 'valeur:', value);

            // Méthode 1: Utiliser le mapping
            const targetName = primeTargetMapping[slug];
            if (targetName) {
              const input = document.querySelector(`[data-wallonie-prime-card-target="${targetName}"]`);
              if (input && input.value !== value.toString()) {
                console.log('✅ Input trouvé par mapping:', targetName, input);
                if (input.type === 'checkbox') {
                  input.checked = (value === '1' || value === 1 || value === true);
                } else {
                  input.value = value;
                }
                input.dispatchEvent(new Event('change', { bubbles: true }));
                input.dispatchEvent(new Event('input', { bubbles: true }));
                console.log('✅ Valeur restaurée par mapping:', slug, '=', value);
                restoredCount++;
                return;
              }
            }

            // Méthode 2: Chercher par data-wallonie-prime-card-slug-value
            const cardWithSlug = document.querySelector(`[data-wallonie-prime-card-slug-value="${slug}"]`);
            if (cardWithSlug) {
              console.log('✅ Carte trouvée pour', slug, ':', cardWithSlug);
              const input = cardWithSlug.querySelector('input[type="checkbox"], input[type="number"]');
              if (input && input.value !== value.toString()) {
                console.log('📝 Input trouvé dans la carte:', input);
                if (input.type === 'checkbox') {
                  input.checked = (value === '1' || value === 1 || value === true);
                } else {
                  input.value = value;
                }
                input.dispatchEvent(new Event('change', { bubbles: true }));
                input.dispatchEvent(new Event('input', { bubbles: true }));
                console.log('✅ Valeur restaurée par carte:', slug, '=', value);
                restoredCount++;
                return;
              }
            }

            console.log('❌ Aucun input trouvé pour:', slug);
          });

          if (restoredCount > 0) {
            restorationApplied = true;
            console.log(`🎉 Restauration terminée: ${restoredCount} valeurs restaurées`);
          }

          setTimeout(() => {
            window.isRestoringValues = false;
            console.log('🔄 Restauration terminée, auto-save réactivé');
          }, 200);

          return restoredCount;
        }

        setTimeout(() => {
          const restored = attemptRestore();
          if (restored === 0) {
            let attempts = 0;
            const retryInterval = setInterval(() => {
              attempts++;
              const retryRestored = attemptRestore();
              if (retryRestored > 0 || attempts >= 3) {
                clearInterval(retryInterval);
                if (retryRestored === 0) {
                  console.log('❌ Aucune valeur n\\'a pu être restaurée après 3 tentatives');
                  window.isRestoringValues = false;
                }
              }
            }, 500);
          }
        }, 1000);
      }

      // Écouter les événements de navigation
      document.addEventListener('DOMContentLoaded', restoreSavedInputs);
      document.addEventListener('turbo:load', () => {
        restorationApplied = false;
        restoreSavedInputs();
      });
      document.addEventListener('turbo:render', () => {
        restorationApplied = false;
        restoreSavedInputs();
      });
    JAVASCRIPT
  end

  # ==========================================
  # MÉTHODES UTILITAIRES
  # ==========================================

  def region_display_name(region)
    case region&.downcase
    when 'wallonie' then 'Wallonie'
    when 'flandre' then 'Flandre'
    when 'bruxelles' then 'Bruxelles-Capitale'
    else 'Région inconnue'
    end
  end

  def simulation_property_address(simulation)
    return nil unless simulation.property.present?

    if simulation.property.respond_to?(:address)
      simulation.property.address
    else
      "#{simulation.property.rue} #{simulation.property.numero}"
    end
  end

  private

  def prime_target_mapping
    {
      'wallonie_realisation_audit_logement' => 'inputAudit',
      'wallonie_toiture_remplacement_couverture' => 'inputCouverture',
      'wallonie_toiture_appropriation_charpente' => 'inputCharpente',
      'wallonie_toiture_evacuation_eaux_pluviales' => 'inputEauxPluviales',
      'wallonie_toiture_isolation_thermique' => 'inputIsolationToiture',
      'wallonie_toiture_isolation_biosource' => 'inputIsolationToitureBio',
      'wallonie_isolation_sols' => 'inputIsolationSols',
      'wallonie_isolation_sols_biosource' => 'inputIsolationSolsBio',
      'wallonie_remplacement_supports_circulation' => 'inputSupportsCirculation',
      'wallonie_isolation_finition_planchers' => 'inputFinitionPlanchers',
      'wallonie_menuiseries_vitrages' => 'inputMenuiseries',
      'wallonie_installation_electrique' => 'inputElectrique',
      'wallonie_installation_gaz' => 'inputGaz'
    }
  end
end

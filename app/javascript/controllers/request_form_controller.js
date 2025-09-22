import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["regionSelect", "formTypeSection", "formTypeSelect", "formTypeDescription", "formTypeButtons"]

  connect() {
    console.log('🚀 Request form controller connecté');

    // Écouter l'événement de bien pré-sélectionné
    this.element.addEventListener('propertyPreselected', this.handlePropertyPreselected.bind(this));

    // Exposer la méthode pour accès externe
    this.element.initializeForRegion = this.initializeForRegion.bind(this);

    // Note: selectConsultanceForm est maintenant définie directement dans le HTML

    this.initializeRegionalForms();
  }

  // Nouvelle méthode pour gérer les clics de soumission
  handleSubmit(event) {
    const button = event.target;
    const debugType = button.dataset.debug;

    console.log('🔴 BOUTON CLIQUÉ:', debugType);
    console.log('📋 Form data avant soumission:', new FormData(this.element));

    // Laisser la soumission normale se poursuivre
    return true;
  }

  // Gestionnaire pour l'événement de bien pré-sélectionné
  handlePropertyPreselected(event) {
    const { region } = event.detail;
    console.log('🏠 Bien pré-sélectionné - région:', region);
    this.initializeForRegion(region);
  }

  initializeForRegion(region) {
    console.log('🔧 initializeForRegion appelée avec:', region);

    if (this.hasFormTypeSectionTarget) {
      // Afficher la section de type de formulaire
      this.formTypeSectionTarget.style.display = 'block';

      // Mettre à jour les options selon la région
      this.updateFormTypeOptions(region);

      // Afficher les boutons de soumission quand une propriété est pré-sélectionnée
      const buttonSection = document.getElementById('submission-buttons');
      if (buttonSection) {
        buttonSection.style.display = 'flex';
        console.log('✅ Boutons de soumission affichés pour propriété pré-sélectionnée');
      }

      console.log('✅ Section formulaire initialisée pour', region);
    } else {
      console.log('❌ formTypeSectionTarget non trouvé');
    }
  }

  // Fonction pour initialiser les formulaires régionaux
  initializeRegionalForms() {
    const sections = document.querySelectorAll('.region-section');

    console.log('Found sections:', sections.length);
    sections.forEach((section, index) => {
      console.log(`Section ${index}:`, section.id, section);
    });

    if (!this.hasRegionSelectTarget) {
      console.log('❌ regionSelectTarget non trouvé');
      return;
    }

    const selectedRegion = this.regionSelectTarget.value;
    console.log('Selected region:', selectedRegion);

    if (selectedRegion) {
      this.initializeForRegion(selectedRegion);
    } else {
      console.log('❌ Aucune région sélectionnée au démarrage');
    }
  }

  regionChanged() {
    this.showRegionalSection();
  }

  formTypeChanged() {
    this.showFormTypeSection();
  }

  showRegionalSection() {
    if (!this.hasRegionSelectTarget) {
      console.log('❌ regionSelectTarget non trouvé');
      return;
    }

    const selectedRegion = this.regionSelectTarget.value;
    console.log('Selected region:', selectedRegion);

    // Masquer toutes les sections régionales
    const sections = document.querySelectorAll('.region-section');
    sections.forEach(section => {
      section.style.display = 'none';
    });

    if (selectedRegion) {
      this.initializeForRegion(selectedRegion);
    } else if (this.hasFormTypeSectionTarget) {
      // Masquer la section de type de formulaire
      this.formTypeSectionTarget.style.display = 'none';
      if (this.hasFormTypeSelectTarget) {
        this.formTypeSelectTarget.innerHTML = '<option value="">-- Sélectionnez le type de formulaire --</option>';
      }
    }
  }

  updateFormTypeOptions(region) {
    console.log('🔄 updateFormTypeOptions appelée pour région:', region);
    console.log('Type de region:', typeof region);
    console.log('Région brute:', JSON.stringify(region));
    console.log('hasFormTypeButtonsTarget:', this.hasFormTypeButtonsTarget);
    console.log('hasFormTypeDescriptionTarget:', this.hasFormTypeDescriptionTarget);

    // Debug spécial pour la Wallonie
    if (region === 'wallonie') {
      console.log('🔍 WALLONIE DÉTECTÉE - région exacte:', region);
    }

    if (!this.hasFormTypeButtonsTarget) {
      console.log('❌ formTypeButtonsTarget non trouvé');
      return;
    }

    // Nettoyer et normaliser la région
    const normalizedRegion = region ? region.toLowerCase().trim() : '';
    console.log('🔧 Région normalisée:', normalizedRegion);

    const formOptions = {
      flandre: [
        { value: 'regional', label: 'Primes régionales flamandes', icon: '�', description: 'Primes My Renovation Premium' },
        { value: 'monuments', label: 'Monuments & Sites', icon: '🏛️', description: 'Primes pour biens protégés' },
        { value: 'communal', label: 'Primes communales', icon: '🏛️', description: 'Primes spécifiques de votre commune' }
      ],
      bruxelles: [
        { value: 'regional', label: 'Primes régionales bruxelloises', icon: '�', description: 'Primes Renolution' },
        { value: 'monuments', label: 'Monuments & Sites', icon: '🏛️', description: 'Conservation du patrimoine classé' },
        { value: 'petit_patrimoine', label: 'Petit patrimoine', icon: '�️', description: 'Conservation patrimoine non protégé' },
        { value: 'communal', label: 'Primes communales', icon: '🏛️', description: 'Primes des 19 communes' }
      ],
      wallonie: [
        { value: 'regional', label: 'Primes régionales wallonnes', icon: '🏡', description: 'Primes habitation + énergie' },
        { value: 'audit', label: 'Audit énergétique', icon: '⚡', description: 'Remboursement partiel de l\'audit énergétique' },
        { value: 'monuments', label: 'Monuments & Sites', icon: '🏛️', description: 'Primes pour biens classés ou en zone protégée' },
        { value: 'communal', label: 'Primes communales', icon: '🏛️', description: 'Primes spécifiques de votre commune' }
      ]
    };

    console.log('Configuration trouvée pour', normalizedRegion, ':', formOptions[normalizedRegion]);
    console.log('Toutes les clés disponibles:', Object.keys(formOptions));
    console.log('Test égalité avec "wallonie":', normalizedRegion === 'wallonie');
    console.log('Test égalité avec "flandre":', normalizedRegion === 'flandre');
    console.log('Test égalité avec "bruxelles":', normalizedRegion === 'bruxelles');

    // Debug spécial pour la configuration Wallonie
    console.log('🔍 Configuration Wallonie directe:', formOptions['wallonie']);
    console.log('🔍 Clé région nettoyée:', normalizedRegion.trim().toLowerCase());

    // Vérifier si c'est un profil entreprise
    const profilField = document.querySelector('input[name*="profil_demandeur"]');
    const isEntreprise = profilField && profilField.value === 'entreprise';

    console.log('🏢 Profil détecté lors updateFormTypeOptions:', profilField ? profilField.value : 'non trouvé');
    console.log('🏢 Est entreprise lors updateFormTypeOptions:', isEntreprise);

    // Vider le container des boutons
    this.formTypeButtonsTarget.innerHTML = '';

    // Si c'est une entreprise, afficher seulement les formulaires entreprises
    if (isEntreprise) {
      console.log('🏢 Création des boutons pour entreprises');

      const entrepriseOptions = [
        { value: 'entreprise', label: 'Formulaires Entreprises', icon: '🏢', description: 'Aides spécialisées pour entreprises (consultance, investissements, etc.)' }
      ];

      entrepriseOptions.forEach((option, index) => {
        console.log(`Création bouton entreprise ${index}:`, option);

        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'form-type-btn col-md-6 mb-3'; // Plus large pour moins d'options
        button.dataset.formType = option.value;
        button.innerHTML = `
          <div class="card border-success h-100 text-center hover-shadow">
            <div class="card-body d-flex flex-column justify-content-center">
              <div class="text-success mb-3 fs-2">${option.icon}</div>
              <h6 class="card-title text-success">${option.label}</h6>
              <p class="card-text small text-muted">${option.description}</p>
            </div>
          </div>
        `;

        // Gestionnaire de clic
        button.addEventListener('click', () => {
          this.selectFormType(option.value);
        });

        this.formTypeButtonsTarget.appendChild(button);
      });

      console.log('✅ Boutons entreprises créés');
      return; // Sortir de la fonction pour ne pas créer les boutons régionaux
    }

    // Créer les boutons pour la région sélectionnée (particuliers)
    if (formOptions[normalizedRegion]) {
      console.log('✅ Création des boutons pour', normalizedRegion);

      formOptions[normalizedRegion].forEach((option, index) => {
        console.log(`Création bouton ${index}:`, option);

        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'form-type-btn col-md-3 mb-3';
        button.dataset.formType = option.value;

        button.innerHTML = `
          <div class="card h-100 border-primary shadow-sm" style="cursor: pointer; transition: transform 0.2s;">
            <div class="card-body text-center d-flex flex-column">
              <div class="display-4 mb-3">${option.icon}</div>
              <h5 class="card-title">${option.label}</h5>
              <p class="card-text small text-muted flex-grow-1">${option.description}</p>
            </div>
          </div>
        `;

        // Effet hover
        button.addEventListener('mouseenter', () => {
          button.querySelector('.card').style.transform = 'translateY(-2px)';
        });
        button.addEventListener('mouseleave', () => {
          button.querySelector('.card').style.transform = 'translateY(0)';
        });

        // Gestionnaire de clic
        button.addEventListener('click', () => {
          this.selectFormType(option.value);
        });

        this.formTypeButtonsTarget.appendChild(button);
      });

      console.log('✅ Tous les boutons créés pour', normalizedRegion);
    } else {
      console.log('❌ Aucune configuration trouvée pour la région:', normalizedRegion);
    }
  }

  selectFormType(formType) {
    console.log('🎯 Type de formulaire sélectionné:', formType);
    console.log('🎯 Region actuelle:', this.hasRegionSelectTarget ? this.regionSelectTarget.value : 'AUCUNE');

    // Marquer le bouton comme sélectionné
    this.formTypeButtonsTarget.querySelectorAll('.form-type-btn').forEach(btn => {
      const card = btn.querySelector('.card');
      card.classList.remove('border-success', 'bg-light');
      card.classList.add('border-primary');
    });

    const selectedButton = this.formTypeButtonsTarget.querySelector(`[data-form-type="${formType}"]`);
    if (selectedButton) {
      const card = selectedButton.querySelector('.card');
      card.classList.remove('border-primary');
      card.classList.add('border-success', 'border');
      console.log('✅ Bouton sélectionné visuellement:', formType);
    } else {
      console.log('❌ Bouton non trouvé pour:', formType);
    }

    // Mettre à jour le champ caché
    if (this.hasFormTypeSelectTarget) {
      this.formTypeSelectTarget.value = formType;
      console.log('✅ Champ caché mis à jour:', this.formTypeSelectTarget.value);
    } else {
      console.log('❌ Champ caché formTypeSelect non trouvé');
    }

    // Déclencher l'affichage de la section appropriée
    console.log('🔄 Appel de showFormTypeSection...');
    this.showFormTypeSection();
  }

  showFormTypeSection() {
    const selectedFormType = this.hasFormTypeSelectTarget ? this.formTypeSelectTarget.value : null;
    const selectedRegion = this.hasRegionSelectTarget ? this.regionSelectTarget.value : null;

    console.log('📋 showFormTypeSection - Type:', selectedFormType, 'Région:', selectedRegion);

    // Gérer le cas spécial entreprise
    if (selectedFormType === 'entreprise') {
      console.log('🏢 Affichage section entreprise directement');

      // Masquer toutes les sections
      const allSections = document.querySelectorAll('.region-section, .entreprise-section');
      allSections.forEach(section => {
        section.style.display = 'none';
      });

      // Afficher la section entreprise
      const entrepriseSection = document.getElementById('entreprise-section');
      if (entrepriseSection) {
        entrepriseSection.style.display = 'block';
        console.log('✅ Section entreprises affichée');
      }
      return;
    }

    if (!selectedFormType || !selectedRegion) {
      console.log('❌ Type de formulaire ou région manquant');
      return;
    }

    // Normaliser la région
    const normalizedRegion = selectedRegion.toLowerCase();

    // Masquer toutes les sections
    const flandreSections = document.querySelectorAll('#flandre-section, #flandre-monuments-section, #flandre-communal-section');
    const bruxellesSections = document.querySelectorAll('#bruxelles-section, #bruxelles-monuments-section, #bruxelles-petit_patrimoine-section, #bruxelles-communal-section');
    const wallonieSections = document.querySelectorAll('#wallonie-section, #wallonie-audit-section, #wallonie-monuments-section, #wallonie-communal-section');
    const entrepriseSections = document.querySelectorAll('#entreprise-section');

    flandreSections.forEach(section => {
      section.style.display = 'none';
    });
    bruxellesSections.forEach(section => {
      section.style.display = 'none';
    });
    wallonieSections.forEach(section => {
      section.style.display = 'none';
    });
    entrepriseSections.forEach(section => {
      section.style.display = 'none';
    });

    // Vérifier si c'est un profil entreprise
    const profilField = document.querySelector('input[name*="profil_demandeur"]');
    const isEntreprise = profilField && profilField.value === 'entreprise';

    console.log('🏢 Profil détecté:', profilField ? profilField.value : 'non trouvé');
    console.log('🏢 Est entreprise:', isEntreprise);

    // Si c'est une entreprise, afficher la section entreprises et ignorer les formulaires régionaux
    if (isEntreprise) {
      console.log('🏢 Affichage de la section entreprises');
      const entrepriseSection = document.getElementById('entreprise-section');
      if (entrepriseSection) {
        entrepriseSection.style.display = 'block';
        console.log('✅ Section entreprises affichée');
      }
      return; // Sortir de la fonction pour ne pas afficher les sections régionales
    }

    // Afficher la section appropriée selon le type et la région
    if (selectedFormType && selectedRegion) {
      let targetSectionId = '';

      console.log('🔍 DEBUG - selectedFormType:', selectedFormType);
      console.log('🔍 DEBUG - selectedRegion:', selectedRegion);
      console.log('🔍 DEBUG - normalizedRegion:', normalizedRegion);

      // Logique uniforme pour toutes les régions
      if (selectedFormType === 'regional') {
        targetSectionId = normalizedRegion + '-section';
      } else if (selectedFormType === 'audit') {
        targetSectionId = normalizedRegion + '-audit-section';
      } else if (selectedFormType === 'communal') {
        targetSectionId = normalizedRegion + '-communal-section';
      } else if (selectedFormType === 'monuments') {
        targetSectionId = normalizedRegion + '-monuments-section';
      } else if (selectedFormType === 'petit_patrimoine') {
        targetSectionId = normalizedRegion + '-petit_patrimoine-section';
      }

      console.log('🔍 DEBUG - targetSectionId calculé:', targetSectionId);

      const targetSection = document.getElementById(targetSectionId);
      console.log('🔍 DEBUG - targetSection trouvé:', !!targetSection);

      if (targetSection) {
        console.log('🔍 DEBUG - avant affichage, style.display:', targetSection.style.display);
        targetSection.style.display = 'block';
        console.log('🔍 DEBUG - après affichage, style.display:', targetSection.style.display);
        console.log('🔍 DEBUG - computed style:', window.getComputedStyle(targetSection).display);

        // Test immédiat pour voir si quelque chose remet display: none
        setTimeout(() => {
          console.log('🔍 DEBUG - style après 100ms:', targetSection.style.display);
          console.log('🔍 DEBUG - computed style après 100ms:', window.getComputedStyle(targetSection).display);
        }, 100);

        console.log('✅ Section affichée:', targetSectionId);
        console.log('🔍 Section DOM element:', targetSection);
        console.log('🔍 Section visibility:', window.getComputedStyle(targetSection).display);
        console.log('🔍 Section HTML preview:', targetSection.innerHTML.substring(0, 200) + '...');

        // Force l'affichage avec !important
        targetSection.style.setProperty('display', 'block', 'important');
        console.log('🔍 DEBUG - après setProperty important:', window.getComputedStyle(targetSection).display);
      } else {
        console.log('❌ Section non trouvée:', targetSectionId);
        console.log('🔍 Sections disponibles:', Array.from(document.querySelectorAll('.region-section')).map(s => s.id));

        // Fallback vers la section régionale principale
        const fallbackSection = document.getElementById(normalizedRegion + '-section');
        if (fallbackSection) {
          fallbackSection.style.display = 'block';
          console.log('✅ Fallback vers section régionale:', normalizedRegion + '-section');
        }
      }
    }

    // Mettre à jour la description selon l'option sélectionnée
    const selectedOption = this.formTypeSelectTarget.querySelector(`option[value="${selectedFormType}"]`);

    if (selectedOption && selectedOption.dataset.description && this.hasFormTypeDescriptionTarget) {
      this.formTypeDescriptionTarget.textContent = selectedOption.dataset.description;
    }

    // Gérer l'affichage des boutons spécifiques aux régions
    this.updateRegionalButtons(selectedRegion, selectedFormType);

    // Afficher les boutons de soumission génériques quand une section est affichée
    this.showSubmissionButtons(selectedFormType, selectedRegion);
  }

  showSubmissionButtons(formType, region) {
    // Trouver la section des boutons d'action génériques
    const buttonSection = document.getElementById('submission-buttons');
    if (buttonSection && formType && region) {
      buttonSection.style.display = 'flex';
      console.log('✅ Boutons de soumission affichés pour:', formType, region);
    }
  }

  updateRegionalButtons(region, formType) {
    // Normaliser la région pour les comparaisons
    const normalizedRegion = region ? region.toLowerCase() : '';

    // Masquer tous les boutons régionaux
    const buttons = ['flandre-continue-btn', 'wallonie-continue-btn', 'bruxelles-continue-btn'];
    buttons.forEach(btnId => {
      const btn = document.getElementById(btnId);
      if (btn) btn.style.display = 'none';
    });

    // Afficher le bouton approprié pour le formulaire régional
    if (formType === 'regional' && normalizedRegion) {
      const targetBtn = document.getElementById(normalizedRegion + '-continue-btn');
      if (targetBtn) {
        targetBtn.style.display = 'inline-block';
        console.log('✅ Bouton régional affiché:', normalizedRegion + '-continue-btn');
      }
    }
  }
}

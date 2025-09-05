import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["regionSelect", "formTypeSection", "formTypeSelect", "formTypeDescription", "formTypeButtons"]

  connect() {
    console.log('🚀 Request form controller connecté');

    // Écouter l'événement de bien pré-sélectionné
    this.element.addEventListener('propertyPreselected', this.handlePropertyPreselected.bind(this));

    // Exposer la méthode pour accès externe
    this.element.initializeForRegion = this.initializeForRegion.bind(this);

    this.initializeRegionalForms();
  }

  // Gestionnaire pour bien pré-sélectionné
  handlePropertyPreselected(event) {
    const region = event.detail.region;
    console.log('🏠 Bien pré-sélectionné pour région:', region);

    // Initialiser directement avec cette région
    this.initializeForRegion(region);
  }

  // Initialiser pour une région spécifique
  initializeForRegion(region) {
    console.log('🎯 Initialisation pour région:', region);

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
      console.log('Region select not found');
      return;
    }

    // Initialiser immédiatement
    console.log('Initial region value:', this.regionSelectTarget.value);
    this.showRegionalSection();

    // Réessayer après un court délai pour s'assurer que tout est chargé
    setTimeout(() => {
      console.log('Delayed initialization - region value:', this.regionSelectTarget.value);
      this.showRegionalSection();
    }, 100);
  }

  regionChanged() {
    this.showRegionalSection();
  }

  formTypeChanged() {
    this.showFormTypeSection();
  }

  showRegionalSection() {
    // Pour les cas où on a un select de région visible
    if (!this.hasRegionSelectTarget) {
      console.log('No region select found');
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
      console.log('🔍 WALLONIE - longueur région:', region.length);
      console.log('🔍 WALLONIE - codes char:', [...region].map(c => c.charCodeAt(0)));
    }

    if (!this.hasFormTypeButtonsTarget || !this.hasFormTypeDescriptionTarget) {
      console.log('❌ Targets manquants pour updateFormTypeOptions');
      return;
    }

    console.log('✅ Début mise à jour des boutons de formulaire');

    // Normaliser la région en minuscules pour la correspondance
    const normalizedRegion = region.toLowerCase();
    console.log('🔧 Région normalisée:', normalizedRegion);

    // Configurations des formulaires par région avec icônes
    const formOptions = {
      'flandre': [
        { value: 'regional', label: 'Primes régionales flamandes', icon: '🏠', description: 'Primes régionales (énergie + rénovation)' },
        { value: 'monuments', label: 'Monuments & Sites', icon: '🏛️', description: 'Monuments et sites classés' },
        { value: 'communal', label: 'Primes communales', icon: '🏛️', description: 'Primes complémentaires de votre commune' }
      ],
      'bruxelles': [
        { value: 'regional', label: 'Primes Énergie Bruxelles', icon: '🏢', description: 'Primes régionales bruxelloises' },
        { value: 'monuments', label: 'Monuments & Sites', icon: '🏛️', description: 'Primes pour biens classés' },
        { value: 'petit_patrimoine', label: 'Petit patrimoine', icon: '🎨', description: 'Éléments du petit patrimoine non protégé' },
        { value: 'communal', label: 'Primes communales', icon: '🏛️', description: 'Primes complémentaires de votre commune' }
      ],
      'wallonie': [
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

    // Vider le container des boutons
    this.formTypeButtonsTarget.innerHTML = '';

    // Créer les boutons pour la région sélectionnée
    if (formOptions[normalizedRegion]) {
      console.log('✅ Création des boutons pour', normalizedRegion);

      formOptions[normalizedRegion].forEach((option, index) => {
        console.log(`Création bouton ${index}:`, option);

        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'form-type-btn col-md-6 mb-3';
        button.dataset.formType = option.value;
        button.innerHTML = `
          <div class="btn-content">
            <div class="btn-icon">${option.icon}</div>
            <div class="btn-text">
              <h5>${option.label}</h5>
              <p>${option.description}</p>
            </div>
          </div>
        `;

        // Ajouter l'écouteur d'événement
        button.addEventListener('click', () => {
          console.log('🎯 Bouton cliqué:', option.value);
          this.selectFormType(option.value);
        });

        this.formTypeButtonsTarget.appendChild(button);
      });

      console.log('✅ Boutons créés avec succès');

      // Mettre à jour la description
      this.formTypeDescriptionTarget.textContent = 'Choisissez le type de formulaire adapté à votre situation.';
    } else {
      console.log('❌ Aucune configuration trouvée pour la région:', normalizedRegion);
      this.formTypeDescriptionTarget.textContent = 'Aucun formulaire disponible pour cette région.';
    }
  }

  selectFormType(formType) {
    console.log('🎯 selectFormType appelée avec:', formType);

    // Mettre à jour le champ caché pour le type de formulaire
    if (this.hasFormTypeSelectTarget) {
      this.formTypeSelectTarget.value = formType;
      console.log('✅ Type de formulaire mis à jour:', formType);
    }

    // Mettre à jour les classes visuelles des boutons
    const buttons = this.formTypeButtonsTarget.querySelectorAll('.form-type-btn');
    buttons.forEach(btn => {
      btn.classList.remove('selected');
      if (btn.dataset.formType === formType) {
        btn.classList.add('selected');
      }
    });

    // Déclencher l'affichage de la section appropriée
    this.showFormTypeSection();
  }

  showFormTypeSection() {
    const selectedFormType = this.formTypeSelectTarget.value;
    const selectedRegion = this.regionSelectTarget.value;

    // Normaliser la région pour comparaison cohérente
    const normalizedRegion = selectedRegion ? selectedRegion.toLowerCase() : '';

    console.log('Selected form type:', selectedFormType, 'for region:', selectedRegion);
    console.log('Normalized region for section logic:', normalizedRegion);

    // Masquer toutes les sections régionales
    const sections = document.querySelectorAll('.region-section');
    sections.forEach(section => {
      section.style.display = 'none';
    });

    // Masquer toutes les sections wallonnes spécifiquement
    const wallonieSections = document.querySelectorAll('.wallonie-prime-section');
    wallonieSections.forEach(section => {
      section.style.display = 'none';
    });

    // Afficher la section appropriée selon le type et la région
    if (selectedFormType && selectedRegion) {
      let targetSectionId = '';

      // Logique spéciale pour la Wallonie
      if (normalizedRegion === 'wallonie') {
        // Pour la Wallonie, on affiche directement la section spécifique
        if (selectedFormType === 'communal') {
          targetSectionId = 'wallonie-communal-section';
        } else if (selectedFormType === 'monuments') {
          targetSectionId = 'wallonie-monuments-section';
        } else {
          // Pour audit et regional, on affiche la section wallonie principale
          const wallonieMasterSection = document.getElementById('wallonie-section');
          if (wallonieMasterSection) {
            wallonieMasterSection.style.display = 'block';
            console.log('Showing wallonie master section');
          }

          // Puis afficher la sous-section spécifique selon le type
          if (selectedFormType === 'audit') {
            const targetSection = document.getElementById('audit-section');
            if (targetSection) {
              targetSection.style.display = 'block';
              console.log('Showing wallonie subsection: audit-section');
            }
          } else if (selectedFormType === 'regional') {
            const targetSection = document.getElementById('regionale-section');
            if (targetSection) {
              targetSection.style.display = 'block';
              console.log('Showing wallonie subsection: regionale-section');
            }
          }
        }

        // Afficher la section spécifique si targetSectionId est défini pour la Wallonie
        if (targetSectionId) {
          const targetSection = document.getElementById(targetSectionId);
          if (targetSection) {
            targetSection.style.display = 'block';
            console.log('Showing wallonie specific section:', targetSectionId);
          }
        }
      } else {
        // Pour les autres régions, logique normale
        if (selectedFormType === 'regional') {
          targetSectionId = normalizedRegion + '-section';
        } else if (selectedFormType === 'communal') {
          targetSectionId = normalizedRegion + '-communal-section';
        } else if (selectedFormType === 'monuments') {
          targetSectionId = normalizedRegion + '-monuments-section';
        } else if (selectedFormType === 'petit_patrimoine') {
          targetSectionId = normalizedRegion + '-petit_patrimoine-section';
        }

        const targetSection = document.getElementById(targetSectionId);
        if (targetSection) {
          targetSection.style.display = 'block';
          console.log('Showing section:', targetSectionId);
        } else {
          // Fallback vers la section régionale principale
          const fallbackSection = document.getElementById(normalizedRegion + '-section');
          if (fallbackSection) {
            fallbackSection.style.display = 'block';
            console.log('Fallback to regional section:', normalizedRegion + '-section');
          }
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

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["regionSelect", "formTypeSection", "formTypeSelect", "formTypeDescription"]

  connect() {
    console.log('🚀 Request form controller connecté');
    this.initializeRegionalForms();
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
    const selectedRegion = this.regionSelectTarget.value;
    console.log('Selected region:', selectedRegion);

    // Masquer toutes les sections régionales
    const sections = document.querySelectorAll('.region-section');
    sections.forEach(section => {
      section.style.display = 'none';
    });

    if (selectedRegion && this.hasFormTypeSectionTarget) {
      // Afficher la section de type de formulaire
      this.formTypeSectionTarget.style.display = 'block';

      // Mettre à jour les options selon la région
      this.updateFormTypeOptions(selectedRegion);
    } else if (this.hasFormTypeSectionTarget) {
      // Masquer la section de type de formulaire
      this.formTypeSectionTarget.style.display = 'none';
      if (this.hasFormTypeSelectTarget) {
        this.formTypeSelectTarget.innerHTML = '<option value="">-- Sélectionnez le type de formulaire --</option>';
      }
    }
  }

  updateFormTypeOptions(region) {
    if (!this.hasFormTypeSelectTarget || !this.hasFormTypeDescriptionTarget) return;

    // Vider les options existantes
    this.formTypeSelectTarget.innerHTML = '<option value="">-- Sélectionnez le type de formulaire --</option>';

    // Définir les options selon la région
    const formTypes = {
      'flandre': [
        { value: 'regional', text: 'Formulaire régional', description: 'Prime régionale flamande standard' },
        { value: 'communal', text: 'Formulaires communaux', description: 'Primes complémentaires de votre commune' },
        { value: 'monuments', text: 'Monuments & Sites', description: 'Prime spéciale pour biens classés' }
      ],
      'bruxelles': [
        { value: 'regional', text: 'Formulaire régional', description: 'Prime régionale bruxelloise standard' },
        { value: 'monuments', text: 'Monuments & Sites', description: 'Prime spéciale pour biens classés' },
        { value: 'petit_patrimoine', text: 'Petit patrimoine', description: 'Prime pour éléments du petit patrimoine non protégé' },
        { value: 'communal', text: 'Primes communales', description: 'Primes complémentaires proposées par votre commune' }
      ],
      'wallonie': [
        { value: 'audit', text: 'Prime Audit Énergétique', description: 'Remboursement partiel de l\'audit énergétique' },
        { value: 'regionale', text: 'Prime Régionale', description: 'Primes habitation + énergie' },
        { value: 'communale', text: 'Primes Communales', description: 'Primes spécifiques de votre commune' },
        { value: 'monument', text: 'Prime Monument & Site', description: 'Primes pour biens classés ou en zone protégée' }
      ]
    };

    // Ajouter les options pour la région sélectionnée
    if (formTypes[region]) {
      formTypes[region].forEach(option => {
        const optionElement = document.createElement('option');
        optionElement.value = option.value;
        optionElement.textContent = option.text;
        optionElement.dataset.description = option.description;
        this.formTypeSelectTarget.appendChild(optionElement);
      });
    }

    // Mettre à jour la description
    this.formTypeDescriptionTarget.textContent = 'Choisissez le type de formulaire adapté à votre situation.';
  }

  showFormTypeSection() {
    const selectedFormType = this.formTypeSelectTarget.value;
    const selectedRegion = this.regionSelectTarget.value;

    console.log('Selected form type:', selectedFormType, 'for region:', selectedRegion);

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
      if (selectedRegion === 'wallonie') {
        // Pour la Wallonie, on affiche directement la section spécifique
        if (selectedFormType === 'communale') {
          targetSectionId = 'wallonie-communal-section';
        } else if (selectedFormType === 'monument') {
          targetSectionId = 'wallonie-monuments-section';
        } else {
          // Pour audit et regionale, on affiche la section wallonie principale
          const wallonieMasterSection = document.getElementById('wallonie-section');
          if (wallonieMasterSection) {
            wallonieMasterSection.style.display = 'block';
            console.log('Showing wallonie master section');
          }

          // Puis afficher la sous-section spécifique selon le type
          if (selectedFormType === 'audit' || selectedFormType === 'regionale') {
            const targetSection = document.getElementById(selectedFormType + '-section');
            if (targetSection) {
              targetSection.style.display = 'block';
              console.log('Showing wallonie subsection:', selectedFormType + '-section');
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
          targetSectionId = selectedRegion + '-section';
        } else if (selectedFormType === 'communal') {
          targetSectionId = selectedRegion + '-communal-section';
        } else if (selectedFormType === 'monuments') {
          targetSectionId = selectedRegion + '-monuments-section';
        } else if (selectedFormType === 'petit_patrimoine') {
          targetSectionId = selectedRegion + '-petit_patrimoine-section';
        }

        const targetSection = document.getElementById(targetSectionId);
        if (targetSection) {
          targetSection.style.display = 'block';
          console.log('Showing section:', targetSectionId);
        } else {
          // Fallback vers la section régionale principale
          const fallbackSection = document.getElementById(selectedRegion + '-section');
          if (fallbackSection) {
            fallbackSection.style.display = 'block';
            console.log('Fallback to regional section:', selectedRegion + '-section');
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
  }

  updateRegionalButtons(region, formType) {
    // Masquer tous les boutons régionaux
    const buttons = ['flandre-continue-btn', 'wallonie-continue-btn', 'bruxelles-continue-btn'];
    buttons.forEach(btnId => {
      const btn = document.getElementById(btnId);
      if (btn) btn.style.display = 'none';
    });

    // Afficher le bouton approprié pour le formulaire régional
    if (formType === 'regional' && region) {
      const targetBtn = document.getElementById(region + '-continue-btn');
      if (targetBtn) {
        targetBtn.style.display = 'inline-block';
      }
    }
  }
}

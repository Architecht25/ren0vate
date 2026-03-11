import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["regionSelect", "formTypeSection", "formTypeSelect", "formTypeDescription", "formTypeButtons"]

  connect() {

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


    // Laisser la soumission normale se poursuivre
    return true;
  }

  // Gestionnaire pour l'événement de bien pré-sélectionné
  handlePropertyPreselected(event) {
    const { region } = event.detail;
    this.initializeForRegion(region);
  }

  initializeForRegion(region) {

    if (this.hasFormTypeSectionTarget) {
      // Afficher la section de type de formulaire
      this.formTypeSectionTarget.style.display = 'block';

      // Mettre à jour les options selon la région
      this.updateFormTypeOptions(region);

      // Afficher les boutons de soumission quand une propriété est pré-sélectionnée
      const buttonSection = document.getElementById('submission-buttons');
      if (buttonSection) {
        buttonSection.style.display = 'flex';
      }

    } else {
    }
  }

  // Fonction pour initialiser les formulaires régionaux
  initializeRegionalForms() {
    const sections = document.querySelectorAll('.region-section');

    sections.forEach((section, index) => {
    });

    if (!this.hasRegionSelectTarget) {
      return;
    }

    const selectedRegion = this.regionSelectTarget.value;

    if (selectedRegion) {
      this.initializeForRegion(selectedRegion);
    } else {
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
      return;
    }

    const selectedRegion = this.regionSelectTarget.value;

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

    // Debug spécial pour la Wallonie
    if (region === 'wallonie') {
    }

    if (!this.hasFormTypeButtonsTarget) {
      return;
    }

    // Nettoyer et normaliser la région
    const normalizedRegion = region ? region.toLowerCase().trim() : '';

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


    // Debug spécial pour la configuration Wallonie

    // Vérifier si c'est un profil entreprise
    const profilField = document.querySelector('input[name*="profil_demandeur"]');
    const isEntreprise = profilField && profilField.value === 'entreprise';


    // Vider le container des boutons
    this.formTypeButtonsTarget.innerHTML = '';

    // Si c'est une entreprise, afficher seulement les formulaires entreprises
    if (isEntreprise) {

      const entrepriseOptions = [
        { value: 'entreprise', label: 'Formulaires Entreprises', icon: '🏢', description: 'Aides spécialisées pour entreprises (consultance, investissements, etc.)' }
      ];

      entrepriseOptions.forEach((option, index) => {

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

      return; // Sortir de la fonction pour ne pas créer les boutons régionaux
    }

    // Créer les boutons pour la région sélectionnée (particuliers)
    if (formOptions[normalizedRegion]) {

      formOptions[normalizedRegion].forEach((option, index) => {

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

    } else {
    }
  }

  selectFormType(formType) {

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
    } else {
    }

    // Mettre à jour le champ caché
    if (this.hasFormTypeSelectTarget) {
      this.formTypeSelectTarget.value = formType;
    } else {
    }

    // Déclencher l'affichage de la section appropriée
    this.showFormTypeSection();
  }

  showFormTypeSection() {
    const selectedFormType = this.hasFormTypeSelectTarget ? this.formTypeSelectTarget.value : null;
    const selectedRegion = this.hasRegionSelectTarget ? this.regionSelectTarget.value : null;


    // Gérer le cas spécial entreprise
    if (selectedFormType === 'entreprise') {

      // Masquer toutes les sections
      const allSections = document.querySelectorAll('.region-section, .entreprise-section');
      allSections.forEach(section => {
        section.style.display = 'none';
      });

      // Afficher la section entreprise
      const entrepriseSection = document.getElementById('entreprise-section');
      if (entrepriseSection) {
        entrepriseSection.style.display = 'block';
      }
      return;
    }

    if (!selectedFormType || !selectedRegion) {
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


    // Si c'est une entreprise, afficher la section entreprises et ignorer les formulaires régionaux
    if (isEntreprise) {
      const entrepriseSection = document.getElementById('entreprise-section');
      if (entrepriseSection) {
        entrepriseSection.style.display = 'block';
      }
      return; // Sortir de la fonction pour ne pas afficher les sections régionales
    }

    // Afficher la section appropriée selon le type et la région
    if (selectedFormType && selectedRegion) {
      let targetSectionId = '';


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


      const targetSection = document.getElementById(targetSectionId);

      if (targetSection) {
        targetSection.style.display = 'block';

        // Test immédiat pour voir si quelque chose remet display: none
        setTimeout(() => {
        }, 100);


        // Force l'affichage avec !important
        targetSection.style.setProperty('display', 'block', 'important');
      } else {

        // Fallback vers la section régionale principale
        const fallbackSection = document.getElementById(normalizedRegion + '-section');
        if (fallbackSection) {
          fallbackSection.style.display = 'block';
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
      }
    }
  }
}

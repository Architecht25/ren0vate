import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="entreprise-forms"
export default class extends Controller {
  static targets = ["consultanceForm", "comingSoonSection", "selectionMessage"]

  connect() {
    console.log('🏢 Entreprise forms controller connected!')
    console.log('🏢 Element:', this.element)
    this.setupFormSelectors()

    // Ajouter la fonction globale pour onclick
    window.selectConsultanceForm = this.selectConsultanceForm.bind(this)
  }

  selectConsultanceForm() {
    console.log('🏢 Consultance clicked!');

    // Masquer le message de sélection
    const selectionMessage = document.getElementById('form-selection-message');
    if (selectionMessage) {
      selectionMessage.style.display = 'none';
    }

    // Afficher le formulaire consultance
    const consultanceSection = document.getElementById('consultance-form-section');
    if (consultanceSection) {
      consultanceSection.style.display = 'block';
      console.log('✅ Formulaire consultance affiché');

      // Scroll vers le formulaire
      setTimeout(() => {
        consultanceSection.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }, 100);
    } else {
      console.log('❌ Section consultance non trouvée');
    }
  }

  setupFormSelectors() {
    console.log('🏢 Setting up form selectors...')
    // Ajouter les événements de clic sur les cartes de sélection
    const formCards = this.element.querySelectorAll('.form-selector-card')
    console.log('🏢 Found', formCards.length, 'form cards:', formCards)

    formCards.forEach(card => {
      console.log('🏢 Setting up card:', card, 'with data-form-type:', card.dataset.formType)

      card.addEventListener('click', (event) => {
        console.log('🏢 Card clicked!', card)
        const formType = card.dataset.formType
        console.log('🏢 Form type:', formType)

        if (formType) {
          this.selectForm(formType, card)
        } else {
          console.log('❌ No form type found on card')
        }
      })

      // Effet hover
      card.addEventListener('mouseenter', () => {
        if (!card.classList.contains('opacity-50')) {
          card.style.transform = 'translateY(-2px)'
          card.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)'
        }
      })

      card.addEventListener('mouseleave', () => {
        if (!card.classList.contains('opacity-50')) {
          card.style.transform = 'translateY(0)'
          card.style.boxShadow = ''
        }
      })
    })
  }

  selectForm(formType, selectedCard) {
    // Masquer tous les formulaires
    this.hideAllForms()

    // Réinitialiser les styles des cartes
    this.resetCardStyles()

    // Marquer la carte sélectionnée
    this.markSelectedCard(selectedCard)

    // Afficher le formulaire correspondant
    switch(formType) {
      case 'consultance':
        this.showConsultanceForm()
        break
      default:
        this.showComingSoonMessage()
    }

    // Scroll vers le formulaire
    this.scrollToForm()
  }

  hideAllForms() {
    // Masquer le message de sélection
    const selectionMessage = this.element.querySelector('#form-selection-message')
    if (selectionMessage) {
      selectionMessage.style.display = 'none'
    }

    // Masquer tous les formulaires
    const consultanceSection = this.element.querySelector('#consultance-form-section')
    const comingSoonSection = this.element.querySelector('#coming-soon-section')

    if (consultanceSection) consultanceSection.style.display = 'none'
    if (comingSoonSection) comingSoonSection.style.display = 'none'
  }

  resetCardStyles() {
    const formCards = this.element.querySelectorAll('.form-selector-card')
    formCards.forEach(card => {
      card.classList.remove('border-success', 'bg-success', 'bg-opacity-10')
      card.classList.add('border-primary')
    })
  }

  markSelectedCard(selectedCard) {
    selectedCard.classList.remove('border-primary')
    selectedCard.classList.add('border-success', 'bg-success', 'bg-opacity-10')
  }

  showConsultanceForm() {
    const consultanceSection = this.element.querySelector('#consultance-form-section')
    if (consultanceSection) {
      consultanceSection.style.display = 'block'
    }
  }

  showComingSoonMessage() {
    const comingSoonSection = this.element.querySelector('#coming-soon-section')
    if (comingSoonSection) {
      comingSoonSection.style.display = 'block'
    }
  }

  scrollToForm() {
    // Attendre un peu pour que l'affichage soit effectif
    setTimeout(() => {
      const activeForm = this.element.querySelector('#consultance-form-section[style*="block"], #coming-soon-section[style*="block"]')
      if (activeForm) {
        activeForm.scrollIntoView({
          behavior: 'smooth',
          block: 'start',
          inline: 'nearest'
        })
      }
    }, 100)
  }

  // Méthode pour réinitialiser la sélection
  resetSelection() {
    this.hideAllForms()
    this.resetCardStyles()

    // Réafficher le message de sélection
    const selectionMessage = this.element.querySelector('#form-selection-message')
    if (selectionMessage) {
      selectionMessage.style.display = 'block'
    }
  }
}

// app/javascript/logic/flandre_calculations.js

export class FlandreCalculations {
  constructor() {
    this.initializeEventListeners();
    this.debounceTimer = null;
    this.currentSimulationId = this.getSimulationId();
  }

  initializeEventListeners() {
    // Écouter les changements sur tous les inputs de primes
    document.addEventListener('input', (e) => {
      if (e.target.matches('.prime-input')) {
        this.handleInputChange(e.target);
      }
    });

    // Écouter les changements sur les checkboxes (forfaits)
    document.addEventListener('change', (e) => {
      if (e.target.matches('.prime-checkbox')) {
        this.handleCheckboxChange(e.target);
      }
    });
  }

  getSimulationId() {
    const pathParts = window.location.pathname.split('/');
    const simulationIndex = pathParts.indexOf('simulations');
    if (simulationIndex !== -1 && pathParts[simulationIndex + 1]) {
      return pathParts[simulationIndex + 1];
    }
    return null;
  }

  handleInputChange(input) {
    // Debounce pour éviter trop d'appels API
    clearTimeout(this.debounceTimer);

    this.debounceTimer = setTimeout(() => {
      this.calculatePrime(input);
    }, 500); // Attendre 500ms après la dernière frappe
  }

  handleCheckboxChange(checkbox) {
    this.calculatePrime(checkbox);
  }

  async calculatePrime(inputElement) {
    const primeSlug = inputElement.dataset.primeSlug;
    const inputValue = inputElement.value;
    const inputType = inputElement.dataset.inputType;

    if (!primeSlug) return;

    try {
      const response = await fetch('/api/flandre/calculate_prime', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          prime_slug: primeSlug,
          input_value: inputValue,
          input_type: inputType
        })
      });

      const result = await response.json();

      if (result.error) {
        console.error('Erreur calcul:', result.error);
        return;
      }

      this.updatePrimeDisplay(primeSlug, result);
      this.updateGroupTotals();

    } catch (error) {
      console.error('Erreur lors du calcul:', error);
    }
  }

  updatePrimeDisplay(primeSlug, result) {
    const primeCard = document.querySelector(`[data-prime-slug="${primeSlug}"]`).closest('.prime-card');
    if (!primeCard) return;

    // Mettre à jour le montant calculé
    const resultElement = primeCard.querySelector('.calculated-result');
    if (resultElement) {
      if (result.amount > 0) {
        resultElement.textContent = `${result.amount.toFixed(0)}€`;
        resultElement.classList.add('text-success', 'fw-bold');
        resultElement.classList.remove('text-muted');
      } else {
        resultElement.textContent = '0€';
        resultElement.classList.remove('text-success', 'fw-bold');
        resultElement.classList.add('text-muted');
      }
    }

    // Mettre à jour les détails si disponibles
    const detailsElement = primeCard.querySelector('.calculation-details');
    if (detailsElement && result.details) {
      detailsElement.textContent = result.details;
      detailsElement.style.display = result.amount > 0 ? 'block' : 'none';
    }

    // Stocker le résultat pour les totaux
    primeCard.dataset.calculatedAmount = result.amount || 0;
  }

  updateGroupTotals() {
    // Calculer les totaux par groupe
    const groups = ['isolation_enveloppe', 'menuiserie', 'chauffage', 'travaux_preparatoires', 'renovation_associee'];
    let grandTotal = 0;

    groups.forEach(groupKey => {
      const groupElement = document.querySelector(`[data-group="${groupKey}"]`);
      if (!groupElement) return;

      // Calculer le total du groupe
      const primeCards = groupElement.querySelectorAll('.prime-card');
      let groupTotal = 0;

      primeCards.forEach(card => {
        const amount = parseFloat(card.dataset.calculatedAmount) || 0;
        groupTotal += amount;
      });

      // Mettre à jour l'affichage du total du groupe
      const totalElement = groupElement.querySelector('.group-total');
      if (totalElement) {
        if (groupTotal > 0) {
          totalElement.textContent = `${groupTotal.toFixed(0)}€`;
          totalElement.classList.add('text-success', 'fw-bold');
        } else {
          totalElement.textContent = '0€';
          totalElement.classList.remove('text-success', 'fw-bold');
        }
      }

      grandTotal += groupTotal;
    });

    // Mettre à jour le total général
    this.updateGrandTotal(grandTotal);
  }

  updateGrandTotal(total) {
    const grandTotalElements = document.querySelectorAll('.grand-total');
    grandTotalElements.forEach(element => {
      if (total > 0) {
        element.textContent = `${total.toFixed(0)}€`;
        element.classList.add('text-success', 'fw-bold');
      } else {
        element.textContent = '0€';
        element.classList.remove('text-success', 'fw-bold');
      }
    });
  }

  getCSRFToken() {
    const tokenElement = document.querySelector('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.getAttribute('content') : '';
  }

  // Méthode pour calculer tous en une fois (optionnel)
  async calculateAll() {
    const inputs = {};

    // Collecter tous les inputs
    document.querySelectorAll('.prime-input, .prime-checkbox').forEach(input => {
      const primeSlug = input.dataset.primeSlug;
      if (primeSlug && (input.value || input.checked)) {
        inputs[primeSlug] = {
          value: input.type === 'checkbox' ? (input.checked ? 1 : 0) : input.value,
          type: input.dataset.inputType
        };
      }
    });

    try {
      const response = await fetch('/api/flandre/calculate_all', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ inputs })
      });

      const results = await response.json();

      // Mettre à jour tous les résultats
      Object.entries(results.prime_results).forEach(([primeSlug, result]) => {
        this.updatePrimeDisplay(primeSlug, result);
      });

      // Mettre à jour les totaux
      this.updateGroupTotalsFromAPI(results.group_totals);
      this.updateGrandTotal(results.grand_total);

    } catch (error) {
      console.error('Erreur lors du calcul global:', error);
    }
  }

  updateGroupTotalsFromAPI(groupTotals) {
    Object.entries(groupTotals).forEach(([groupKey, total]) => {
      const groupElement = document.querySelector(`[data-group="${groupKey}"]`);
      if (!groupElement) return;

      const totalElement = groupElement.querySelector('.group-total');
      if (totalElement) {
        if (total > 0) {
          totalElement.textContent = `${total.toFixed(0)}€`;
          totalElement.classList.add('text-success', 'fw-bold');
        } else {
          totalElement.textContent = '0€';
          totalElement.classList.remove('text-success', 'fw-bold');
        }
      }
    });
  }
}

// Initialiser automatiquement sur les pages de simulation Flandre
document.addEventListener('DOMContentLoaded', () => {
  if (window.location.pathname.includes('/simulations/') &&
      document.querySelector('.flandre-primes')) {
    new FlandreCalculations();
  }
});

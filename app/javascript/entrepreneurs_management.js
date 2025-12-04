// FALLBACK SCRIPT - Utilisé si Stimulus ne fonctionne pas
// Remplacé par le contrôleur Stimulus mais conservé comme backup

/*
// Gestion des entrepreneurs multiples
document.addEventListener('DOMContentLoaded', function() {
  console.log('🏗️ Script entrepreneurs_management chargé');
  let entrepreneurCount = 1; // Commence à 1 car l'entrepreneur principal existe déjà

  // Fonction pour mettre à jour les numéros d'entrepreneurs
  function updateEntrepreneurNumbers() {
    const entrepreneurs = document.querySelectorAll('#additional-entrepreneurs-container .entrepreneur-item');
    entrepreneurs.forEach((entrepreneur, index) => {
      const numberElement = entrepreneur.querySelector('h6');
      if (numberElement) {
        numberElement.innerHTML = `<i class="bi bi-hammer me-2"></i>Entrepreneur ${index + 2}`;
      }
    });
  }

  // Fonction pour afficher/masquer les boutons de suppression
  function toggleRemoveButtons() {
    const removeButtons = document.querySelectorAll('#additional-entrepreneurs-container .remove-entrepreneur');
    if (removeButtons.length <= 1) {
      removeButtons.forEach(btn => btn.style.display = 'none');
    } else {
      removeButtons.forEach(btn => btn.style.display = 'inline-block');
    }
  }

  // Template pour un nouvel entrepreneur
  function getEntrepreneurTemplate(number) {
    return `
      <div class="entrepreneur-item border rounded p-3 mb-3" style="background-color: #f8f9fa;">
        <div class="d-flex justify-content-between align-items-start mb-3">
          <h6 class="text-warning-emphasis mb-0 fw-semibold">
            <i class="bi bi-hammer me-2"></i>Entrepreneur ${number}
          </h6>
          <button type="button" class="btn btn-sm btn-outline-danger remove-entrepreneur">
            <i class="bi bi-trash"></i> Supprimer
          </button>
        </div>

        <!-- Première rangée : informations principales -->
        <div class="row g-2 mb-3">
          <div class="col">
            <label class="form-label">Nom</label>
            <input type="text" class="form-control" name="additional_entrepreneurs[][nom]" placeholder="Ex: Pierre Martin">
          </div>
          <div class="col">
            <label class="form-label">Entreprise</label>
            <input type="text" class="form-control" name="additional_entrepreneurs[][entreprise]" placeholder="Ex: Entreprise Martin SPRL">
          </div>
          <div class="col">
            <label class="form-label">N° TVA</label>
            <input type="text" class="form-control" name="additional_entrepreneurs[][numero_tva]" placeholder="Ex: BE0123456789">
          </div>
          <div class="col">
            <label class="form-label">Téléphone</label>
            <input type="tel" class="form-control" name="additional_entrepreneurs[][telephone]" placeholder="Ex: +32 123 45 67 89">
          </div>
          <div class="col">
            <label class="form-label">Email</label>
            <input type="email" class="form-control" name="additional_entrepreneurs[][email]" placeholder="Ex: contact@entreprise-martin.be">
          </div>
        </div>

        <!-- Seconde rangée : montant du devis -->
        <div class="row">
          <div class="col-md-6">
            <div class="mb-3">
              <label class="form-label">Montant du devis</label>
              <div class="input-group">
                <input type="number" step="0.01" min="0" class="form-control" name="additional_entrepreneurs[][devis_montant]" placeholder="Ex: 25000.00">
                <span class="input-group-text">€</span>
              </div>
              <small class="form-text text-muted">
                Montant HT du devis pour comparer avec les factures
              </small>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // Bouton pour ajouter un entrepreneur
  const addButton = document.getElementById('add-entrepreneur');
  console.log('🔍 Fallback - Bouton add-entrepreneur trouvé:', addButton);
  if (addButton) {
    // Vérifier si Stimulus ne gère pas déjà ce bouton
    if (!addButton.closest('[data-controller*="entrepreneurs-management"]')) {
      console.log('⚠️ Stimulus non détecté, utilisation du fallback');
    // Calculer le nombre actuel d'entrepreneurs additionnels
    const existingEntrepreneurs = document.querySelectorAll('#additional-entrepreneurs-container .entrepreneur-item');
    entrepreneurCount = existingEntrepreneurs.length + 1; // +1 pour l'entrepreneur principal
    console.log('📊 Nombre d\'entrepreneurs existants:', entrepreneurCount);

    addButton.addEventListener('click', function() {
      console.log('👆 Clic sur ajouter entrepreneur');
      entrepreneurCount++;
      const container = document.getElementById('additional-entrepreneurs-container');
      console.log('📦 Container trouvé:', container);
      const newEntrepreneur = document.createElement('div');
      newEntrepreneur.innerHTML = getEntrepreneurTemplate(entrepreneurCount);

      // Extraire le contenu du div temporaire
      const entrepreneurElement = newEntrepreneur.firstElementChild;
      container.appendChild(entrepreneurElement);

      // Ajouter l'événement de suppression au nouveau bouton
      const removeButton = entrepreneurElement.querySelector('.remove-entrepreneur');
      removeButton.addEventListener('click', function() {
        entrepreneurElement.remove();
        entrepreneurCount--;
        updateEntrepreneurNumbers();
        toggleRemoveButtons();
      });

      toggleRemoveButtons();

      // Animation d'apparition
      entrepreneurElement.style.opacity = '0';
      setTimeout(() => {
        entrepreneurElement.style.transition = 'opacity 0.3s ease-in';
        entrepreneurElement.style.opacity = '1';
      }, 10);
    });
    } else {
      console.log('✅ Stimulus détecté, pas de fallback nécessaire')
    }
  } else {
    console.log('❌ Bouton add-entrepreneur non trouvé dans le DOM');
  }

  // Gestion des boutons de suppression existants
  document.addEventListener('click', function(e) {
    if (e.target.closest('.remove-entrepreneur')) {
      const entrepreneurItem = e.target.closest('.entrepreneur-item');
      entrepreneurItem.remove();
      entrepreneurCount--;
      updateEntrepreneurNumbers();
      toggleRemoveButtons();
    }
  });

  // Initialiser l'état des boutons au chargement
  toggleRemoveButtons();
});
*/

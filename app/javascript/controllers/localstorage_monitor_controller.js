import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output", "emailInput"];

  connect() {
    console.log('🔗 LocalstorageMonitor controller connecté !');
    console.log('📊 Élément trouvé:', this.element);
    console.log('📊 Target output:', this.hasOutputTarget ? 'Trouvé' : 'Non trouvé');
    console.log('📧 Target emailInput:', this.hasEmailInputTarget ? 'Trouvé' : 'Non trouvé');
    this.displayLocalStorageData();
  }

  displayLocalStorageData() {
    console.log('📋 Début de displayLocalStorageData');
    const order = ["region", "user-type", "eligibiliteRenovate", "categorie_estimee", "statut_familial", "personnes_charge", "revenu_net", "categorie_badge","total_primes", "details_primes"];
    const localStorageData = order.map(key => {
      const value = localStorage.getItem(key);
      return value ? { key, value } : null;
    }).filter(data => data !== null);

    console.log('📊 Données localStorage trouvées:', localStorageData);

    // Debug spécifique pour details_primes
    const detailsPrimes = localStorageData.find(data => data.key === 'details_primes');
    if (detailsPrimes) {
      console.log('🔍 details_primes trouvé:', detailsPrimes.value);
      console.log('📏 Longueur de details_primes:', detailsPrimes.value.length);
      try {
        const parsed = JSON.parse(detailsPrimes.value);
        console.log('🎯 details_primes parsé:', parsed);
        console.log('📊 Nombre de clés dans details_primes:', Object.keys(parsed).length);
        console.log('🔑 Clés de details_primes:', Object.keys(parsed));
      } catch (e) {
        console.log('❌ Erreur parsing details_primes:', e);
      }
    } else {
      console.log('❌ details_primes non trouvé dans localStorage');
    }

    this.outputTarget.innerHTML = `
      <div class="localStorage-export">
        <h2>Données du localStorage</h2>
        <div class="table-responsive">
          <table class="table table-bordered table-striped">
            <thead class="table-dark">
              <tr>
                <th style="width: 25%; min-width: 200px;">Clé</th>
                <th style="width: 75%;">Valeur</th>
              </tr>
            </thead>
        <tbody>
          ${localStorageData.map(data => {
            let valueHTML;

            // Si c’est un JSON parsable (ex: eligibiliteRenovate)
            try {
              const parsed = JSON.parse(data.value);
              if (typeof parsed === 'object' && parsed !== null) {
                valueHTML = `
                  <div class="json-container">
                    ${Object.entries(parsed).map(([k, v]) =>
                      `<div class="json-entry mb-1">
                        <span class="badge bg-secondary me-2">${k}</span>
                        <span class="fw-bold text-success">${v}</span>
                      </div>`
                    ).join('')}
                  </div>
                `;
              } else {
                valueHTML = `<span class="text-success fw-bold">${data.value}</span>`;
              }
            } catch {
              valueHTML = `<span class="text-info">${data.value}</span>`; // Pas du JSON, affichage brut
            }

            return `
              <tr>
                <td class="fw-bold text-primary align-top">${data.key}</td>
                <td class="value-cell">${valueHTML}</td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    </div>
  </div>

  <style>
    .json-container {
      max-width: 100%;
      overflow-wrap: break-word;
    }
    .json-entry {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.25rem;
      margin-bottom: 0.5rem;
      width: 100%;
    }
    .value-cell {
      word-wrap: break-word;
      max-width: none !important;
      overflow-wrap: break-word;
      white-space: normal;
      min-height: auto;
    }
    .table-responsive {
      overflow-x: auto;
    }
    .table td {
      vertical-align: top;
      max-width: none !important;
      overflow: visible !important;
    }
    @media (max-width: 768px) {
      .json-entry {
        flex-direction: column;
        align-items: flex-start;
      }
    }
  </style>
    `;
  }

  clearLocalStorage() {
    if (confirm("Êtes-vous sûr de vouloir vider le localStorage ?")) {
      localStorage.clear();
      this.displayLocalStorageData();
    }
  }

  sendByEmail() {
    const email = this.emailInputTarget.value.trim();

    if (!email) {
      alert('⚠️ Veuillez saisir une adresse email valide');
      return;
    }

    // Validation basique de l'email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      alert('⚠️ Format d\'email invalide');
      return;
    }

    console.log('📧 Envoi des données localStorage par email à:', email);

    // Préparer les données localStorage
    const order = ["region", "user-type", "eligibiliteRenovate", "categorie_estimee", "statut_familial", "personnes_charge", "revenu_net", "categorie_badge","total_primes", "details_primes"];
    const localStorageData = {};

    order.forEach(key => {
      const value = localStorage.getItem(key);
      if (value) {
        localStorageData[key] = value;
      }
    });

    // Désactiver le bouton pendant l'envoi
    const sendButton = this.element.querySelector('[data-action*="sendByEmail"]');
    const originalText = sendButton.textContent;
    sendButton.disabled = true;
    sendButton.textContent = 'Envoi en cours...';

    // Envoyer les données au backend
    fetch('/api/send_results_email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      },
      body: JSON.stringify({
        email: email,
        localStorage_data: localStorageData
      })
    })
    .then(response => {
      if (response.ok) {
        return response.json();
      } else {
        throw new Error(`Erreur ${response.status}: ${response.statusText}`);
      }
    })
    .then(data => {
      console.log('✅ Email envoyé avec succès:', data);
      alert('✅ Les résultats ont été envoyés par email avec succès !');
      this.emailInputTarget.value = ''; // Vider le champ email
    })
    .catch(error => {
      console.error('❌ Erreur lors de l\'envoi de l\'email:', error);
      alert('❌ Erreur lors de l\'envoi de l\'email. Veuillez réessayer.');
    })
    .finally(() => {
      // Réactiver le bouton
      sendButton.disabled = false;
      sendButton.textContent = originalText;
    });
  }

  sendLocalStorageToBackend() {
    const localStorageData = {};
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      const value = localStorage.getItem(key);
      localStorageData[key] = value;
    }

    fetch('/api/save_localstorage', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(localStorageData),
    })
    .then(response => {
      if (response.ok) {
        localStorage.clear();
        this.displayLocalStorageData();
      } else {
        console.error('❌ Échec de l’envoi des données au backend');
      }
    })
    .catch(error => {
      console.error('❌ Erreur lors de l’envoi des données au backend :', error);
    });
  }
}

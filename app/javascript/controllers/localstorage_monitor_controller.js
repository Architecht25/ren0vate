import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"];

  connect() {
    console.log('🔗 LocalstorageMonitor controller connecté !');
    console.log('📊 Élément trouvé:', this.element);
    console.log('📊 Target output:', this.hasOutputTarget ? 'Trouvé' : 'Non trouvé');
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

                // Si c'est un JSON parsable (ex: eligibiliteRenovate)
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

        <div class="mt-4">
          <button class="btn btn-warning" data-action="click->localstorage-monitor#clearLocalStorage">
            🗑️ Vider le localStorage
          </button>
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
}

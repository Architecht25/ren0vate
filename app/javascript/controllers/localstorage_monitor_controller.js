import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"];

  connect() {
    console.log('🔗 LocalstorageMonitor controller connecté !');
    this.displayLocalStorageData();
  }

  displayLocalStorageData() {
    const order = ["region", "user-type", "eligibiliteRenovate", "categorie_estimee", "statut_familial", "personnes_charge", "revenu_net", "categorie_badge","total_primes", "details_primes"];
    const localStorageData = order.map(key => {
      const value = localStorage.getItem(key);
      return value ? { key, value } : null;
    }).filter(data => data !== null);

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
                try {
                  const parsed = JSON.parse(data.value);
                  if (typeof parsed === 'object' && parsed !== null) {
                    valueHTML = \`
                      <div class="json-container">
                        \${Object.entries(parsed).map(([k, v]) =>
                          \`<div class="json-entry mb-1">
                            <span class="badge bg-secondary me-2">\${k}</span>
                            <span class="fw-bold text-success">\${v}</span>
                          </div>\`
                        ).join('')}
                      </div>
                    \`;
                  } else {
                    valueHTML = \`<span class="text-success fw-bold">\${data.value}</span>\`;
                  }
                } catch {
                  valueHTML = \`<span class="text-info">\${data.value}</span>\`;
                }
                return \`
                  <tr>
                    <td class="fw-bold text-primary align-top">\${data.key}</td>
                    <td class="value-cell">\${valueHTML}</td>
                  </tr>
                \`;
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
    `;
  }

  clearLocalStorage() {
    if (confirm("Êtes-vous sûr de vouloir vider le localStorage ?")) {
      localStorage.clear();
      this.displayLocalStorageData();
    }
  }
}

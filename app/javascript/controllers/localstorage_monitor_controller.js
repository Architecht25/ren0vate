import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"];

  connect() {
    console.log("📊 Contrôleur de surveillance du localStorage connecté");
    this.displayLocalStorageData();
  }

  displayLocalStorageData() {
    const order = ["region", "user-type", "eligibiliteRenovate", "categorie_estimee"];
    const localStorageData = order.map(key => {
      const value = localStorage.getItem(key);
      return value ? { key, value } : null;
    }).filter(data => data !== null);

    this.outputTarget.innerHTML = `
      <h2>Données du localStorage</h2>
      <table class="table table-bordered">
        <thead>
          <tr>
            <th>Clé</th>
            <th>Valeur</th>
          </tr>
        </thead>
        <tbody>
          ${localStorageData.map(data => `
            <tr>
              <td>${data.key}</td>
              <td>${data.value}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
    console.log("🔍 Vérification du outputTarget :", this.outputTarget);
  }

  clearLocalStorage() {
    if (confirm("Êtes-vous sûr de vouloir vider le localStorage ?")) {
      localStorage.clear();
      this.displayLocalStorageData();
    }
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
        console.log('✅ Données du localStorage envoyées au backend avec succès');
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

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"];

  connect() {
    console.log("📊 Contrôleur de surveillance du localStorage connecté");
    this.displayLocalStorageData();
  }

  displayLocalStorageData() {
    const localStorageData = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      const value = localStorage.getItem(key);
      const type = typeof value;
      localStorageData.push({ key, value, type });
    }

    this.outputTarget.innerHTML = `
      <h2>Données du localStorage</h2>
      <table class="table table-bordered">
        <thead>
          <tr>
            <th>Clé</th>
            <th>Valeur</th>
            <th>Type</th>
          </tr>
        </thead>
        <tbody>
          ${localStorageData.map(data => `
            <tr>
              <td>${data.key}</td>
              <td>${data.value}</td>
              <td>${data.type}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  clearLocalStorage() {
    if (confirm("Êtes-vous sûr de vouloir vider le localStorage ?")) {
      localStorage.clear();
      this.displayLocalStorageData();
    }
  }
}

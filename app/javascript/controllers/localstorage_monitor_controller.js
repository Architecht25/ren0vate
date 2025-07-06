import { Controller } from "@hotwired/stimulus";
import * as html2pdf from "html2pdf";



export default class extends Controller {
  static targets = ["output"];

  connect() {
    console.log("📊 Contrôleur de surveillance du localStorage connecté");
    this.displayLocalStorageData();
  }

  displayLocalStorageData() {
    const order = ["region", "user-type", "eligibiliteRenovate", "categorie_estimee", "statut_familial", "personnes_charge", "revenu_net", "categorie_badge","total_primes", "details_primes"];
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
          ${localStorageData.map(data => {
            let valueHTML;

            // Si c’est un JSON parsable (ex: eligibiliteRenovate)
            try {
              const parsed = JSON.parse(data.value);
              if (typeof parsed === 'object' && parsed !== null) {
                valueHTML = Object.entries(parsed).map(([k, v]) =>
                  `<div><strong>${k}:</strong> ${v}</div>`
                ).join('');
              } else {
                valueHTML = data.value;
              }
            } catch {
              valueHTML = data.value; // Pas du JSON, affichage brut
            }

            return `
              <tr>
                <td><strong>${data.key}</strong></td>
                <td>${valueHTML}</td>
              </tr>
            `;
          }).join('')}
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

  exportPDF() {
    console.log("📄 exportPDF déclenché");
    const element = this.outputTarget;

    const opt = {
      margin:       0.5,
      filename:     'donnees-localStorage.pdf',
      image:        { type: 'jpeg', quality: 0.98 },
      html2canvas:  { scale: 2 },
      jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
    };

    html2pdf().set(opt).from(element).save();
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

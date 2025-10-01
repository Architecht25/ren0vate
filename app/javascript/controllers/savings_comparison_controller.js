// Contrôleur Stimulus pour gérer l'affichage dynamique du composant d'économie
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    console.log("💰 SavingsComparison controller connected")
    
    // Écouter l'événement de mise à jour des données de simulation
    document.addEventListener('savings:update', this.updateSavings.bind(this))
  }

  disconnect() {
    document.removeEventListener('savings:update', this.updateSavings.bind(this))
  }

  // Méthode appelée quand les données de simulation changent
  updateSavings(event) {
    const data = event.detail
    
    if (data.savings_data && data.savings_data.savings_amount > 500) {
      this.showSavingsComponent(data.savings_data, data.total_amount)
    } else {
      this.hideSavingsComponent()
    }
  }

  showSavingsComponent(savingsData, totalAmount) {
    console.log("💰 Showing savings component", savingsData)
    
    const html = this.generateSavingsHTML(savingsData, totalAmount)
    
    if (this.hasContainerTarget) {
      this.containerTarget.innerHTML = html
      this.containerTarget.style.display = 'block'
    }
  }

  hideSavingsComponent() {
    console.log("💰 Hiding savings component")
    
    if (this.hasContainerTarget) {
      this.containerTarget.innerHTML = ''
      this.containerTarget.style.display = 'none'
    }
  }

  generateSavingsHTML(savingsData, totalAmount) {
    return `
      <div class="position-relative mb-4">
        <div class="alert border-0 shadow-lg position-relative overflow-hidden" 
             style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%); border-radius: 15px;">
          
          <!-- Badge "Nouveau" -->
          <div class="position-absolute top-0 end-0 bg-warning text-dark px-3 py-1 small fw-bold" 
               style="border-radius: 0 15px 0 10px;">
            <i class="bi bi-star-fill me-1"></i>NOUVEAU
          </div>

          <div class="position-relative">
            <!-- En-tête principal -->
            <div class="text-center mb-4 pt-2">
              <h2 class="text-white mb-2 fw-bold">
                <i class="bi bi-piggy-bank-fill me-2"></i>
                Économisez <span class="text-warning">${this.formatCurrency(savingsData.savings_amount)}</span>
              </h2>
              <p class="text-white opacity-90 h5 mb-0">vs un chasseur de primes traditionnel</p>
            </div>

            <!-- Comparaison visuelle -->
            <div class="row align-items-center mb-4">
              <!-- Chasseur de primes -->
              <div class="col-12 col-md-5 mb-3 mb-md-0">
                <div class="bg-dark bg-opacity-25 rounded-3 p-4 text-center border border-white border-opacity-25">
                  <div class="text-white">
                    <i class="bi bi-person-x" style="font-size: 2.5rem; opacity: 0.7;"></i>
                    <h6 class="mt-2 mb-1 opacity-75">Chasseur de primes</h6>
                    <div class="h4 mb-2 text-decoration-line-through opacity-75">
                      ${this.formatCurrency(savingsData.chasseur_cost)}
                    </div>
                    <div class="small opacity-75">
                      <strong>12,5% HTVA + 21% TVA</strong><br>
                      = 15,125% du montant total
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Séparateur VS -->
              <div class="col-12 col-md-2 text-center mb-3 mb-md-0">
                <div class="h2 text-white fw-bold">VS</div>
              </div>

              <!-- Notre solution -->
              <div class="col-12 col-md-5">
                <div class="bg-white rounded-3 p-4 text-center" 
                     style="box-shadow: 0 0 30px rgba(255,255,255,0.3);">
                  <i class="bi bi-rocket-takeoff text-success" style="font-size: 2.5rem;"></i>
                  <h6 class="mt-2 mb-1 text-success">Avec Ren0vate</h6>
                  <div class="h4 mb-2 fw-bold text-success">
                    ${this.formatCurrency(savingsData.saas_cost)}
                  </div>
                  <div class="small text-muted">
                    <strong>${savingsData.subscription_details.monthly_price}€/mois</strong><br>
                    pendant ${savingsData.subscription_details.duration_months} mois
                  </div>
                </div>
              </div>
            </div>

            <!-- Résultat de l'économie -->
            <div class="row mb-4">
              <div class="col-12">
                <div class="bg-warning rounded-3 p-4 text-center text-dark">
                  <h4 class="mb-2">
                    <i class="bi bi-trophy-fill me-2"></i>
                    <strong>RÉSULTAT : Vous économisez ${this.formatCurrency(savingsData.savings_amount)}</strong>
                  </h4>
                  <p class="mb-0 h6">
                    Soit <strong>${savingsData.savings_percentage}% d'économie</strong> sur les frais d'intermédiation !
                  </p>
                </div>
              </div>
            </div>

            <!-- Message et bouton d'action -->
            <div class="row">
              <div class="col-12">
                <div class="bg-white bg-opacity-15 rounded-3 p-4">
                  <div class="row align-items-center">
                    <div class="col-12 col-md-8 mb-3 mb-md-0">
                      <div class="text-white">
                        <h6 class="mb-2">
                          <i class="bi bi-check-circle-fill me-2"></i>
                          <strong>Pourquoi payer un intermédiaire ?</strong>
                        </h6>
                        <p class="mb-0">
                          Gérez vous-même vos dossiers de primes et gardez <strong>${savingsData.savings_percentage}% de plus</strong> dans votre poche !
                        </p>
                      </div>
                    </div>
                    <div class="col-12 col-md-4 text-center text-md-end">
                      <a href="/pricing" class="btn btn-warning btn-lg fw-bold px-4 py-3 shadow">
                        <i class="bi bi-rocket-takeoff me-2"></i>
                        Économiser maintenant !
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }
}
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.autoSaveTimeout = null
    this.requestId = this.element.dataset.requestId
    this.storageKey = `request_draft_${this.requestId || 'new'}`

    // Écouter les changements sur tous les inputs
    this.element.addEventListener('input', this.debouncedAutoSave.bind(this))
    this.element.addEventListener('change', this.debouncedAutoSave.bind(this))

    console.log("🔄 Request auto-save controller connecté pour request:", this.requestId)

    // Restaurer les données du localStorage au chargement
    this.restoreFromLocalStorage()
  }

  disconnect() {
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
  }

  debouncedAutoSave() {
    // Annuler la sauvegarde précédente
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }

    // Programmer une nouvelle sauvegarde dans 2 secondes
    this.autoSaveTimeout = setTimeout(() => {
      this.performAutoSave()
    }, 2000)
  }

  performAutoSave() {
    // Collecter les données du formulaire
    const formData = this.collectFormData()

    if (Object.keys(formData).length === 0) {
      console.log("📝 Aucune donnée à sauvegarder")
      return
    }

    console.log('💾 Auto-save request (localStorage):', Object.keys(formData).length, 'champs')

    // 1. Toujours sauvegarder dans localStorage (rapide et fiable)
    this.saveToLocalStorage(formData)

    // 2. Si c'est une demande existante, aussi sauvegarder en DB
    if (this.requestId && this.requestId !== 'new') {
      this.saveToDatabase(formData)
    }
  }

  saveToLocalStorage(formData) {
    try {
      // Ajouter un timestamp
      const dataToSave = {
        ...formData,
        _timestamp: Date.now(),
        _requestId: this.requestId
      }

      localStorage.setItem(this.storageKey, JSON.stringify(dataToSave))
      console.log("✅ Sauvegarde localStorage réussie")
      this.showSaveIndicator('success')

      // Déclencher l'événement pour l'indicateur d'état
      window.dispatchEvent(new CustomEvent('autosave-success'))
    } catch (error) {
      console.error("❌ Erreur localStorage:", error)
      this.showSaveIndicator('error')
      window.dispatchEvent(new CustomEvent('autosave-error'))
    }
  }

  saveToDatabase(formData) {
    // Pour les nouvelles demandes, créer d'abord la demande
    if (this.requestId === 'new' || !this.requestId) {
      this.createNewRequest(formData)
    } else {
      // Pour les demandes existantes, utiliser l'endpoint autosave
      fetch(`/requests/${this.requestId}/autosave`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ request: formData })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          console.log("✅ Auto-save DB réussi")
          // Effacer le localStorage une fois sauvé en DB
          localStorage.removeItem(this.storageKey)
        } else {
          console.error("❌ Erreur auto-save DB:", data.error)
        }
      })
      .catch(error => {
        console.error("❌ Erreur réseau auto-save DB:", error)
      })
    }
  }

  createNewRequest(formData) {
    // Créer une nouvelle demande via l'endpoint create
    fetch('/requests', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        request: {
          ...formData,
          status: 'draft',
          title: formData.title || `Brouillon ${new Date().toLocaleDateString('fr-FR')} ${new Date().toLocaleTimeString('fr-FR', {hour: '2-digit', minute: '2-digit'})}`,
          description: formData.description || "Brouillon en cours de rédaction"
        },
        commit: "Sauvegarder en brouillon"
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success && data.request_id) {
        console.log("✅ Nouvelle demande créée:", data.request_id)
        // Mettre à jour l'ID pour les futures sauvegardes
        this.requestId = data.request_id
        this.element.dataset.requestId = data.request_id
        this.storageKey = `request_draft_${data.request_id}`
        // Effacer le localStorage de 'new'
        localStorage.removeItem('request_draft_new')
      } else {
        console.error("❌ Erreur création demande:", data.error)
      }
    })
    .catch(error => {
      console.error("❌ Erreur réseau création demande:", error)
    })
  }

  restoreFromLocalStorage() {
    try {
      const savedData = localStorage.getItem(this.storageKey)
      if (!savedData) return

      const data = JSON.parse(savedData)
      const timeDiff = Date.now() - (data._timestamp || 0)

      // Ignorer les données trop anciennes (plus de 24h)
      if (timeDiff > 24 * 60 * 60 * 1000) {
        localStorage.removeItem(this.storageKey)
        return
      }

      console.log("🔄 Restauration depuis localStorage")

      // Restaurer les champs
      Object.keys(data).forEach(fieldName => {
        if (fieldName.startsWith('_')) return // Ignorer les métadonnées

        const input = this.formTarget.querySelector(`[name="request[${fieldName}]"]`)
        if (input && data[fieldName] !== null && data[fieldName] !== '') {
          if (input.type === 'checkbox') {
            input.checked = data[fieldName]
          } else if (input.type === 'radio') {
            if (input.value === data[fieldName]) {
              input.checked = true
            }
          } else {
            input.value = data[fieldName]
          }

          // Déclencher l'événement change pour les contrôleurs qui écoutent
          input.dispatchEvent(new Event('change', { bubbles: true }))
        }
      })

      this.showSaveIndicator('restored')
      console.log("✅ Données restaurées depuis localStorage")

      // Déclencher l'événement pour l'indicateur d'état
      window.dispatchEvent(new CustomEvent('autosave-restored'))

    } catch (error) {
      console.error("❌ Erreur restauration localStorage:", error)
      localStorage.removeItem(this.storageKey)
    }
  }  collectFormData() {
    const formData = {}
    const form = this.formTarget

    // Collecter tous les champs du formulaire
    const inputs = form.querySelectorAll('input, select, textarea')

    inputs.forEach(input => {
      const name = input.name
      if (!name || name === 'commit' || name === 'utf8' || name === 'authenticity_token') {
        return
      }

      let value = null

      if (input.type === 'checkbox') {
        value = input.checked
      } else if (input.type === 'radio') {
        if (input.checked) {
          value = input.value
        } else {
          return // Skip unchecked radio buttons
        }
      } else if (input.type === 'file') {
        // Skip file inputs for auto-save
        return
      } else {
        value = input.value
      }

      // Convertir le nom du champ Rails en format simple
      const fieldName = name.replace(/^request\[/, '').replace(/\]$/, '')

      if (value !== null && value !== '') {
        formData[fieldName] = value
      }
    })

    return formData
  }

  showSaveIndicator(status) {
    // Créer ou mettre à jour l'indicateur de sauvegarde
    let indicator = document.getElementById('autosave-indicator')

    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'autosave-indicator'
      indicator.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 1000;
        padding: 8px 12px;
        border-radius: 4px;
        font-size: 14px;
        transition: opacity 0.3s;
      `
      document.body.appendChild(indicator)
    }

    if (status === 'success') {
      indicator.className = 'bg-success text-white'
      indicator.innerHTML = '<i class="bi bi-check-circle me-1"></i>Sauvegardé (Local)'
    } else if (status === 'restored') {
      indicator.className = 'bg-info text-white'
      indicator.innerHTML = '<i class="bi bi-arrow-clockwise me-1"></i>Données restaurées'
    } else {
      indicator.className = 'bg-danger text-white'
      indicator.innerHTML = '<i class="bi bi-exclamation-triangle me-1"></i>Erreur sauvegarde'
    }

    indicator.style.opacity = '1'

    // Masquer après 3 secondes
    setTimeout(() => {
      indicator.style.opacity = '0'
    }, 3000)
  }

  // Méthode pour nettoyer le localStorage (utile pour les tests)
  clearLocalStorage() {
    localStorage.removeItem(this.storageKey)
    console.log("🧹 localStorage nettoyé pour:", this.storageKey)
  }
}

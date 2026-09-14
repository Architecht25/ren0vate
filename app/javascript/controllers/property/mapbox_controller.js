import { Controller } from "@hotwired/stimulus"

// Connecte ce contrôleur au nom "mapbox"
export default class extends Controller {
  static values = {
    apiKey: String,
    properties: Array
  }

  static targets = ["map"]

  connect() {

    // Vérifier que Mapbox GL JS est chargé
    if (typeof mapboxgl === 'undefined') {
      this.loadMapboxScript()
      return
    }

    // Attendre un peu pour que le DOM soit complètement rendu
    setTimeout(() => {
      this.initializeMap()
    }, 100)
  }

  loadMapboxScript() {
    // Charger dynamiquement Mapbox GL JS si pas encore chargé
    const script = document.createElement('script')
    script.src = 'https://api.mapbox.com/mapbox-gl-js/v3.0.1/mapbox-gl.js'
    script.onload = () => {
      const link = document.createElement('link')
      link.href = 'https://api.mapbox.com/mapbox-gl-js/v3.0.1/mapbox-gl.css'
      link.rel = 'stylesheet'
      document.head.appendChild(link)

      setTimeout(() => this.initializeMap(), 100)
    }
    document.head.appendChild(script)
  }

  initializeMap() {

    mapboxgl.accessToken = this.apiKeyValue

    // Masquer le spinner de chargement
    const loadingSpinner = this.element.querySelector('.spinner-border')
    if (loadingSpinner) {
      loadingSpinner.parentElement.style.display = 'none'
    }

    // Centrer la carte sur la Belgique
    this.map = new mapboxgl.Map({
      container: this.element,
      style: 'mapbox://styles/mapbox/streets-v12',
      center: [4.3517, 50.8503], // Bruxelles
      zoom: 7,
      attributionControl: false // Retirer les attributions par défaut pour gagner de l'espace
    })

    this.map.on('load', () => {
      this.addPropertiesToMap()
      this.setupEventListeners()

      // Forcer un resize de la carte après un court délai
      setTimeout(() => {
        this.map.resize()
      }, 300)
    })

    // Ajouter les contrôles de navigation
    this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')

    // Ajouter un contrôle d'attribution compact
    this.map.addControl(new mapboxgl.AttributionControl({
      compact: true
    }), 'bottom-right')
  }

  addPropertiesToMap() {
    if (!this.propertiesValue || this.propertiesValue.length === 0) {
      return
    }


    this.propertiesValue.forEach(property => {
      if (property.latitude && property.longitude) {
        this.addPropertyMarker(property)
      }
    })

    // Ajuster la vue pour inclure tous les marqueurs
    this.fitMapToProperties()
  }

  addPropertyMarker(property) {
    const popupContent = this.createPopupContent(property)

    // Déterminer la couleur du marqueur selon les critères
    let markerColor = '#6366f1' // bleu par défaut

    if (property.map_popup_content && property.map_popup_content.peb_value) {
      markerColor = '#10b981' // vert si PEB présent
    } else {
      markerColor = '#f59e0b' // orange si pas de PEB
    }

    if (property.valeur_achat && property.valeur_achat > 200000) {
      markerColor = '#3b82f6' // bleu foncé si prix > 200k€
    }

    // Créer le marqueur personnalisé
    const el = document.createElement('div')
    el.className = 'custom-marker'
    el.style.cssText = `
      background-color: ${markerColor};
      width: 20px;
      height: 20px;
      border: 2px solid white;
      border-radius: 50%;
      cursor: pointer;
      box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    `

    // Ajouter le marqueur à la carte
    new mapboxgl.Marker(el)
      .setLngLat([property.longitude, property.latitude])
      .setPopup(new mapboxgl.Popup({ offset: 25 })
        .setHTML(popupContent))
      .addTo(this.map)
  }

  createPopupContent(property) {
    const popupData = property.map_popup_content || {}
    const price = property.valeur_achat ?
      new Intl.NumberFormat('fr-BE', {
        style: 'currency',
        currency: 'EUR',
        maximumFractionDigits: 0
      }).format(property.valeur_achat) : 'Non renseigné'

    return `
      <div class="property-popup">
        <h6 class="mb-2 text-primary">${popupData.name || 'Propriété'}</h6>
        <div class="mb-2">
          <small class="text-muted d-block">
            <i class="bi bi-geo-alt me-1"></i>${popupData.address || 'Adresse non disponible'}
          </small>
        </div>
        <div class="row g-2 mb-2">
          <div class="col-6">
            <div class="bg-light p-2 rounded">
              <small class="text-muted d-block">Prix d'acquisition</small>
              <strong class="text-success">${price}</strong>
            </div>
          </div>
          <div class="col-6">
            <div class="bg-light p-2 rounded">
              <small class="text-muted d-block">Certificat PEB</small>
              <strong class="text-info">${popupData.peb_value || 'Non renseigné'}</strong>
            </div>
          </div>
        </div>
        <small class="text-muted">
          <i class="bi bi-person me-1"></i>Propriétaire: ${popupData.user_email || 'Non disponible'}
        </small>
      </div>
    `
  }

  fitMapToProperties() {
    if (!this.propertiesValue || this.propertiesValue.length === 0) return

    const coordinates = this.propertiesValue
      .filter(p => p.latitude && p.longitude)
      .map(p => [p.longitude, p.latitude])

    if (coordinates.length === 0) return

    const bounds = new mapboxgl.LngLatBounds()
    coordinates.forEach(coord => bounds.extend(coord))

    this.map.fitBounds(bounds, {
      padding: 50,
      maxZoom: 12
    })
  }

  setupEventListeners() {
    // Écouter les boutons de contrôle
    document.getElementById('show-all-properties')?.addEventListener('click', () => {
      this.showAllProperties()
    })

    document.getElementById('show-geocoded-properties')?.addEventListener('click', () => {
      this.showGeocodedProperties()
    })

    document.getElementById('show-not-geocoded-properties')?.addEventListener('click', () => {
      this.showNotGeocodedProperties()
    })

    document.getElementById('center-map')?.addEventListener('click', () => {
      this.fitMapToProperties()
    })

    document.getElementById('geocode-all-properties')?.addEventListener('click', () => {
      this.geocodeAllProperties()
    })

    // Écouter les changements d'onglets pour redimensionner la carte
    document.getElementById('maps-tab')?.addEventListener('shown.bs.tab', () => {
      setTimeout(() => {
        if (this.map) {
          this.map.resize()
        }
      }, 100)
    })
  }

  showAllProperties() {
    // Recharger tous les marqueurs
    this.clearMarkers()
    this.addPropertiesToMap()
  }

  showGeocodedProperties() {
    // Afficher seulement les propriétés géocodées
    this.clearMarkers()
    const geocodedProperties = this.propertiesValue.filter(p => p.latitude && p.longitude)
    geocodedProperties.forEach(property => this.addPropertyMarker(property))
  }

  showNotGeocodedProperties() {
    // Afficher la liste des propriétés non géocodées
    const notGeocoded = this.propertiesValue.filter(p => !p.latitude || !p.longitude)

    if (notGeocoded.length === 0) {
      alert('Toutes les propriétés sont géocodées !')
      return
    }

    const message = notGeocoded.map(p =>
      `${p.numero} ${p.rue}, ${p.code_postal} ${p.commune}`
    ).join('\\n')

    alert(`Propriétés non géocodées (${notGeocoded.length}):\\n\\n${message}`)
  }

  clearMarkers() {
    // Nettoyer tous les marqueurs existants
    document.querySelectorAll('.custom-marker').forEach(marker => {
      marker.remove()
    })
  }

  async geocodeAllProperties() {
    if (!confirm('Voulez-vous géocoder toutes les propriétés non géocodées ? Cette opération peut prendre du temps.')) {
      return
    }

    try {
      const response = await fetch('/admin/geocode_properties', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (data.success) {
        alert(`Succès ! ${data.message}`)
        // Recharger la page pour afficher les nouvelles données
        window.location.reload()
      } else {
        alert(`Erreur : ${data.error}`)
      }
    } catch (error) {
      alert('Une erreur est survenue lors du géocodage.')
    }
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}

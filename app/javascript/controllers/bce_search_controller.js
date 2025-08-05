import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "searchButton", "results", "error",
                   "numeroEntreprise", "formeLegale", "tailleEntreprise",
                   "dateInscription", "codesNace", "adresses"]

  connect() {
    console.log("🏢 BCE Search controller connected")
  }

  rechercher() {
    const numeroEntreprise = this.inputTarget.value.trim()

    // Validation du format
    if (!this.validerNumero(numeroEntreprise)) {
      this.afficherErreur("Le numéro d'entreprise doit contenir exactement 10 chiffres")
      return
    }

    // Désactiver le bouton pendant la recherche
    this.searchButtonTarget.disabled = true
    this.searchButtonTarget.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Recherche...'

    // Masquer les résultats précédents
    this.masquerResultats()
    this.masquerErreur()

    // Appel à la vraie API BCE
    this.rechercherBCE(numeroEntreprise)
  }

  validerNumero(numero) {
    // Vérifier que c'est exactement 10 chiffres
    if (!/^\d{10}$/.test(numero)) {
      return false
    }

    // Pour l'instant, on accepte tous les numéros de 10 chiffres
    // La validation stricte du checksum sera faite côté serveur
    return true
  }

  async rechercherBCE(numero) {
    try {
      const response = await fetch('/api/bce/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({ enterprise_number: numero })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.afficherResultats(data.data)
      } else {
        this.afficherErreur(data.error || 'Entreprise non trouvée dans la BCE')
      }
    } catch (error) {
      console.error('Erreur lors de la recherche BCE:', error)
      this.afficherErreur('Erreur de connexion. Veuillez réessayer.')
    } finally {
      // Réactiver le bouton
      this.searchButtonTarget.disabled = false
      this.searchButtonTarget.innerHTML = '<i class="fas fa-search me-2"></i>Rechercher'
    }
  }

  // Garder la simulation en fallback pour les tests
  simulerRechercheBCE(numero) {
    // Simulation d'un délai d'API
    setTimeout(() => {
      // Données de test basées sur votre exemple
      const donneesTest = {
        "0833618097": {
          numeroEntreprise: "0833618097",
          formeLegale: "Société à responsabilité limitée",
          tailleEntreprise: "Petite entreprise",
          dateInscription: "10/02/2011",
          codesNace: "82990",
          adresses: [
            "Rue Beckers 19, 1040 Etterbeek",
            "Rue Middelbourg 66, 1170 Watermael-Boitsfort"
          ]
        },
        "0681683138": {
          numeroEntreprise: "0681683138",
          formeLegale: "Société à responsabilité limitée",
          tailleEntreprise: "Petite entreprise",
          dateInscription: "15/03/2017",
          codesNace: "70220",
          adresses: [
            "Avenue Louise 475, 1050 Ixelles"
          ]
        }
      }

      const donnees = donneesTest[numero]

      if (donnees) {
        this.afficherResultats(donnees)
      } else {
        this.afficherErreur()
      }

      // Réactiver le bouton
      this.searchButtonTarget.disabled = false
      this.searchButtonTarget.innerHTML = '<i class="fas fa-search me-2"></i>Rechercher'
    }, 1500)
  }

  afficherResultats(donnees) {
    this.masquerErreur()

    // Remplir les champs avec la structure de notre API
    this.numeroEntrepriseTarget.textContent = donnees.enterprise_number || 'Non spécifié'
    this.formeLegaleTarget.textContent = donnees.legal_form || 'Non spécifiée'
    this.tailleEntrepriseTarget.textContent = 'Non déterminée' // Notre API ne retourne pas cette info
    this.dateInscriptionTarget.textContent = 'Non spécifiée' // Notre API ne retourne pas cette info

    // Codes NACE depuis les activités
    if (donnees.activities && donnees.activities.length > 0) {
      const codes = donnees.activities.map(activity => `${activity.code} - ${activity.description}`).join(', ')
      this.codesNaceTarget.textContent = codes
    } else {
      this.codesNaceTarget.textContent = 'Non spécifié'
    }

    // Remplir les adresses
    this.adressesTarget.innerHTML = ""
    if (donnees.address) {
      const adresseFormatee = `${donnees.address.street || ''} ${donnees.address.number || ''}, ${donnees.address.postal_code || ''} ${donnees.address.city || ''}`.trim()
      const li = document.createElement("li")
      li.innerHTML = `<i class="fas fa-map-marker-alt text-success me-2"></i>${adresseFormatee}`
      li.className = "mb-1"
      this.adressesTarget.appendChild(li)
    } else {
      const li = document.createElement("li")
      li.innerHTML = `<i class="fas fa-map-marker-alt text-muted me-2"></i>Adresse non disponible`
      li.className = "mb-1 text-muted"
      this.adressesTarget.appendChild(li)
    }

    // Afficher la section résultats
    this.resultsTarget.style.display = "block"

    // Pré-remplir le formulaire d'éligibilité si possible
    this.preremplirFormulaire(donnees)
  }

  afficherErreur(message = null) {
    this.masquerResultats()

    if (message) {
      const alertContent = this.errorTarget.querySelector(".alert p")
      alertContent.textContent = message
    }

    this.errorTarget.style.display = "block"
  }

  masquerResultats() {
    this.resultsTarget.style.display = "none"
  }

  masquerErreur() {
    this.errorTarget.style.display = "none"
  }

  preremplirFormulaire(donnees) {
    // Pré-remplir automatiquement certains champs du formulaire d'éligibilité

    // Pour l'instant, nous n'avons pas l'info taille d'entreprise dans notre API
    // On peut l'inférer plus tard ou utiliser une valeur par défaut

    // Si nous avons des champs à pré-remplir dans le formulaire d'éligibilité
    // par exemple le nom de l'entreprise, l'adresse, etc.

    if (donnees.name) {
      const champNom = document.querySelector('input[name="nom_entreprise"]')
      if (champNom) {
        champNom.value = donnees.name
      }
    }

    if (donnees.address) {
      const champAdresse = document.querySelector('input[name="adresse_entreprise"]')
      if (champAdresse) {
        const adresseComplete = `${donnees.address.street || ''} ${donnees.address.number || ''}, ${donnees.address.postal_code || ''} ${donnees.address.city || ''}`.trim()
        champAdresse.value = adresseComplete
      }
    }

    // Ajouter d'autres pré-remplissages selon les besoins
    console.log("📝 Formulaire pré-rempli avec les données BCE", donnees)
  }
}

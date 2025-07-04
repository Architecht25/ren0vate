// === 3. app/javascript/logique/choix-categorie.js ===
export function choixCategorie({
  revenuAnnuel,
  statut,
  personnesACharge = 0,
  autreBienEnPleinePropriete = false,
  loueViaWoonmaatschappij = false
}) {
  const categories = JSON.parse(
    document.getElementById("categories-data")?.textContent || "[]"
  )

  for (const categorie of categories) {
    const cond = categorie.conditions
    if (cond.autre_bien_interdit && autreBienEnPleinePropriete) continue

    const expression = cond[statut]
    const montantParPersonne = 4320
    const plafondSup = extrairePlafondMax(expression)
    const plafondMajore = plafondSup ? plafondSup + personnesACharge * montantParPersonne : null

    if (verifieRevenu(expression, revenuAnnuel, plafondMajore)) {
      if (categorie.id === "categorie_4" && loueViaWoonmaatschappij) return categorie
      if (!loueViaWoonmaatschappij || categorie.location_sociale_autorisee) return categorie
    }
  }

  return {
    id: "hors_categorie",
    description: "Catégorie non éligible",
    eligible_pour_verbouwlening: false
  }
}

function extrairePlafondMax(expression) {
  if (expression.includes("\u2264")) {
    const matches = expression.match(/\u2264\s?([\d.]+)/)
    return matches ? parseFloat(matches[1]) : null
  }
  return null
}

function verifieRevenu(expression, revenu, plafondMajore = null) {
  const nombres = expression.match(/[\d.]+/g).map(Number)
  if (expression.includes("\u2264") && !expression.includes(">")) {
    return revenu <= plafondMajore
  }
  if (expression.includes(">") && expression.includes("\u2264")) {
    const [min, max] = nombres
    return revenu > min && revenu <= (plafondMajore ?? max)
  }
  if (expression.includes(">")) {
    return revenu > nombres[0]
  }
  return false
}


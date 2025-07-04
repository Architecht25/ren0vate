// === 4. app/javascript/logique/calcul-categories.js ===
export function getCategorieId() {
  const stored = sessionStorage.getItem("categorie")
  if (stored) return stored

  const span = document.getElementById("categorie-prime")
  const texte = span?.textContent.trim() ?? ""
  const match = texte.match(/\d+/)
  return match ? match[0] : "4"
}

export function calculerTotalToutesCartes() {
  let total = 0

  const resultats = document.querySelectorAll(".prime-result")

  resultats.forEach(span => {
    const texte = span.textContent.replace("€", "").trim()
    const montant = parseFloat(texte) || 0
    total += montant
  })

  const totalElt = document.getElementById("total-primes-affiche")
  if (totalElt) {
    totalElt.textContent = `${total.toFixed(2)} €`
  }
}

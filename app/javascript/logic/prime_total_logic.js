export function calculerTotalToutesCartes() {
  let total = 0;
  const primes = {};

  const resultats = document.querySelectorAll(".prime-result");

  resultats.forEach(span => {
    const slug = span.dataset.slug; // nécessite data-slug="..." dans chaque .prime-result
    const texte = span.textContent.replace("€", "").trim();
    const montant = parseFloat(texte) || 0;
    total += montant;

    if (slug) {
      primes[slug] = montant;
    }
  });

  localStorage.setItem("total_primes", total.toFixed(2));
  localStorage.setItem("details_primes", JSON.stringify(primes));
  console.log("🧮 Fonction calculerTotalToutesCartes appelée");
  console.log("✅ total:", total);
  console.log("📦 détails:", primes);

  const totalElt = document.getElementById("total-primes-affiche");
  if (totalElt) {
    totalElt.textContent = `${total.toFixed(2)} €`;
  }
}

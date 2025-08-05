// Test de l'API BCE depuis la console du navigateur
// Ouvrez la console (F12) et exécutez ce code pour tester

async function testBCE() {
  console.log('🧪 Test de l\'API BCE...')

  try {
    const response = await fetch('/api/bce/search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ enterprise_number: '0681683138' })
    })

    const data = await response.json()
    console.log('📡 Réponse API:', data)

    if (data.success) {
      console.log('✅ API BCE fonctionne correctement!')
      console.log('🏢 Entreprise:', data.data.name)
      console.log('📍 Adresse:', data.data.address)
      console.log('⚡ Activités:', data.data.activities)
    } else {
      console.error('❌ Erreur API:', data.error)
    }
  } catch (error) {
    console.error('💥 Erreur réseau:', error)
  }
}

// Exécuter le test
testBCE()

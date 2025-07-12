// Diagnostic des imports Stimulus
console.log('🔍 Diagnostic des imports Stimulus')
console.log('=================================')

// Test d'import d'application
try {
  import('./application.js').then(module => {
    console.log('✅ application.js importé avec succès')
    console.log('📦 Contenu:', module)
  })
} catch (error) {
  console.error('❌ Erreur application.js:', error)
}

// Test d'import des contrôleurs
try {
  import('./controllers/index.js').then(module => {
    console.log('✅ controllers/index.js importé avec succès')
    console.log('📦 Contenu:', module)
  })
} catch (error) {
  console.error('❌ Erreur controllers/index.js:', error)
}

// Test d'import du contrôleur UserType
try {
  import('./controllers/user_type_controller.js').then(module => {
    console.log('✅ user_type_controller.js importé avec succès')
    console.log('📦 Contenu:', module)
  })
} catch (error) {
  console.error('❌ Erreur user_type_controller.js:', error)
}

// Vérifier si Stimulus est disponible
if (typeof window !== 'undefined' && window.Stimulus) {
  console.log('✅ Stimulus disponible dans window')
  console.log('📊 Contrôleurs enregistrés:', window.Stimulus.router.modules)
} else {
  console.log('❌ Stimulus non disponible dans window')
}

console.log('🔍 Diagnostic terminé')

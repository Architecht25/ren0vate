// Test simple des imports
console.log('🧪 Test de chargement des contrôleurs Stimulus')

// Test de UserTypeController
try {
  const userTypeModule = await import('./user_type_controller')
  console.log('✅ UserTypeController importé avec succès:', userTypeModule.default)

  // Test de la structure des contrôleurs
  const controllersModule = await import('./index')
  console.log('✅ Module des contrôleurs importé:', controllersModule)

  // Test de l'application
  const appModule = await import('../application')
  console.log('✅ Module application importé:', appModule)

} catch (error) {
  console.error('❌ Erreur lors du test:', error)
}

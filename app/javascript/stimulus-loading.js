import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application

console.log('✅ Stimulus application started with auto-loading')

// Auto-load controllers from importmap
const context = import.meta.glob("./controllers/**/*_controller.js", { eager: true })
console.log('📁 Auto-loading controllers:', context)

for (const path in context) {
  const module = context[path]
  const controllerName = path
    .replace("./controllers/", "")
    .replace("_controller.js", "")
    .replace(/_/g, "-")

  console.log(`🔗 Registering controller: ${controllerName}`)
  application.register(controllerName, module.default)
}

console.log('✅ All controllers auto-loaded')

export { application }

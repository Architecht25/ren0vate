import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "stimulus-loading"

export const application = Application.start()

const context = import.meta.glob("./**/*_controller.js", { eager: true })
application.load(definitionsFromContext(context))

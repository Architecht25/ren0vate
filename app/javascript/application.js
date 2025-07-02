import "@hotwired/turbo-rails"
import "bootstrap"

import { Application } from "@hotwired/stimulus"
import { autoload } from "@hotwired/stimulus-loading"

window.Stimulus = Application.start()
autoload("controllers", window.Stimulus)

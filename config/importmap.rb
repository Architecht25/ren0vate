# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "bootstrap", to: "bootstrap.bundle.min.js"

pin "logic/categorie_choix_logic", to: "logic/categorie_choix_logic.js"
pin "logic/categorie_utilitaire_logic", to: "logic/categorie_utilitaire_logic.js"
pin "logic/prime_total_logic", to: "logic/prime_total_logic.js"

pin "sweetalert2", to: "https://cdn.skypack.dev/sweetalert2"

# pin "bootstrap", to: "bootstrap.min.js", preload: true
# pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
# pin "@popperjs/core", to: "popper.js", preload: true

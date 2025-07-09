# Pin npm packages by running ./bin/importmap

pin "application"

# Note: stimulus-loading supprimé - utilisation d'imports manuels dans application.js
# Hotwired libs avec des CDN plus fiables
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.5/app/assets/javascripts/turbo.min.js"
pin "@hotwired/turbo", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.5/dist/turbo.es2017-esm.js"
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap via CDN
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"

# External libraries via CDN
pin "html2pdf", to: "https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"

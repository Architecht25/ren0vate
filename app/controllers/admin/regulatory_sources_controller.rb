class Admin::RegulatorySourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    @sources = RegulatorySource.order(:region, :label)
  end

  # Déclenche une vérification immédiate (hors cadence mensuelle), pratique
  # pour tester après ajout d'une source ou avant de fermer le sujet sur un
  # dossier en cours.
  def check_now
    results = RegulatoryWatchService.check_all
    changed = results.count(&:changed?)
    errored = results.count(&:error?)

    message = "#{results.size} source(s) vérifiée(s)"
    message += " — #{changed} modifiée(s)" if changed > 0
    message += " — #{errored} en échec" if errored > 0

    redirect_to admin_regulatory_sources_path, notice: message
  end

  private

  def ensure_admin
    redirect_to root_path, alert: "Accès réservé aux administrateurs." unless current_user.admin?
  end
end

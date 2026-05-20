class EnrichPvVisites < ActiveRecord::Migration[8.1]
  def change
    change_table :pv_visites do |t|
      t.string  :heure_visite              # "09:30"
      t.string  :meteo                     # Ensoleillé / Nuageux / Pluvieux / Neige / Vent
      t.text    :absents                   # Absents / excusés
      t.string  :coordinateur_sps          # Nom coordinateur sécurité SPS
      t.date    :prochaine_visite
      t.string  :prochaine_visite_heure    # "10:00"
      t.jsonb   :lots,      null: false, default: []   # Avancement par lot
      t.jsonb   :decisions, null: false, default: []   # Décisions actées lors de la visite
    end
  end
end

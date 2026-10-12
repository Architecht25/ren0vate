# V2 — Lot 4 : planning par lot avec dépendances (cahier des charges §4-5.D :
# "ScheduleItem (tâches par lot, dépendances, dates)"). Version simplifiée
# pour ce lot : liste de tâches avec une dépendance simple (une tâche
# attend la fin d'une autre), pas de rendu Gantt graphique — Projects::
# GanttBuilder (V1) construit un diagramme à partir des dates de devis/
# états d'avancement existants, pas un vrai graphe de tâches ; pas repris
# tel quel ici, modèle de données neuf.
class CreateScheduleItems < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_items do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true
      t.references :depends_on, null: true, foreign_key: { to_table: :schedule_items }

      t.string :label, null: false
      t.date :start_date
      t.date :end_date
      t.string :status, null: false, default: "a_faire"

      t.timestamps
    end
  end
end

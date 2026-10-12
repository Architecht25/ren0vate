# V2 — Lot 4 : messagerie par lot (cahier des charges §4-5.D : "Message /
# Thread (par lot, rattachés au chantier)"). Nouveau — aucun équivalent V1.
#
# Tables message_threads/messages (PAS threads/thread_messages) : `Thread`
# est une classe native Ruby (primitive de concurrence), utilisée dans tout
# Rails (Thread.current pour l'état par requête, pools de connexions...) —
# nommer un modèle ainsi l'aurait masquée partout dans l'app, un bug
# quasi indétectable. Piège découvert avant d'écrire le modèle, migration
# jamais poussée sous le mauvais nom.
class CreateMessaging < ActiveRecord::Migration[8.1]
  def change
    create_table :message_threads do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end

    create_table :messages do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end
  end
end

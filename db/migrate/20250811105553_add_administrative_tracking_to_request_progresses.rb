class AddAdministrativeTrackingToRequestProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :request_progresses, :numero_dossier, :string
    add_column :request_progresses, :email_suivi, :string, null: false
    add_column :request_progresses, :status_administratif, :string, default: 'en_preparation'
    add_column :request_progresses, :montant_demande, :decimal, precision: 10, scale: 2
    add_column :request_progresses, :montant_accorde, :decimal, precision: 10, scale: 2
    add_column :request_progresses, :prime_accordee, :string
    add_column :request_progresses, :date_soumission, :date
    add_column :request_progresses, :date_derniere_maj, :date
    add_column :request_progresses, :commentaires_admin, :text
    add_column :request_progresses, :document_recu, :boolean, default: false

    # Index pour améliorer les performances
    add_index :request_progresses, :numero_dossier, unique: true, where: "numero_dossier IS NOT NULL"
    add_index :request_progresses, :email_suivi, unique: true
    add_index :request_progresses, :status_administratif
    add_index :request_progresses, :date_soumission
  end
end

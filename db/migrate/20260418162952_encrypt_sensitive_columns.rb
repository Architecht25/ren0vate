class EncryptSensitiveColumns < ActiveRecord::Migration[8.0]
  # Chiffrement at-rest des données personnelles sensibles (RGPD A02)
  # ActiveRecord Encryption stocke un JSON chiffré dans la colonne — les string courtes
  # doivent être converties en text pour accueillir le blob chiffré (~200-300 chars).
  #
  # PRÉREQUIS : définir les 3 variables d'environnement AR_ENCRYPTION_* avant d'appliquer.
  # ROLLBACK : les colonnes sont reconverties en string, données décryptées via decrypt_attributes.

  def up
    # users : national_number (11 chars → ~250 chars chiffré), iban (~34 chars → ~250 chars)
    change_column :users, :national_number, :text
    change_column :users, :iban, :text

    # rib_donnees : iban complet + nom_titulaire
    change_column :rib_donnees, :iban, :text
    change_column :rib_donnees, :nom_titulaire, :text
  end

  def down
    change_column :users, :national_number, :string
    change_column :users, :iban, :string
    change_column :rib_donnees, :iban, :string
    change_column :rib_donnees, :nom_titulaire, :string
  end
end

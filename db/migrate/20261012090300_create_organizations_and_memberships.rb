# V2 — Lot 0 : Organization (cabinet d'architecture, entreprise) et Membership
# sont optionnels (cahier des charges V2 §4) — posés en fondation minimale,
# sans usage actif avant un lot qui en a réellement besoin.
class CreateOrganizationsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :kind, null: false # "architecture_firm" / "contractor_company"

      t.timestamps
    end

    create_table :memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :memberships, [:organization_id, :user_id], unique: true
  end
end

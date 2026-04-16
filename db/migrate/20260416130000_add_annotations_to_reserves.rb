class AddAnnotationsToReserves < ActiveRecord::Migration[8.0]
  def change
    add_column :reserves, :pin_x,           :float   # % position horizontal 0-100
    add_column :reserves, :pin_y,           :float   # % position vertical 0-100
    add_column :reserves, :plan_document_id, :bigint  # FK vers Document de type :plan
    add_column :reserves, :etage,           :string  # ex: "Rez-de-chaussée", "1er étage"

    add_index  :reserves, :plan_document_id
    add_foreign_key :reserves, :documents, column: :plan_document_id
  end
end

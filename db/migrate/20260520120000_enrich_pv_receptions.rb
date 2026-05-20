class EnrichPvReceptions < ActiveRecord::Migration[8.1]
  def change
    add_column :pv_receptions, :heure_reception,  :string
    add_column :pv_receptions, :meteo,            :string
    add_column :pv_receptions, :presents,         :text
    add_column :pv_receptions, :absents,          :text
    add_column :pv_receptions, :coordinateur_sps, :string
    add_column :pv_receptions, :lots_reception,   :jsonb, default: []
  end
end

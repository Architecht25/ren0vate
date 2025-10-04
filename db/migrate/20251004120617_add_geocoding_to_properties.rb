class AddGeocodingToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :latitude, :decimal, precision: 10, scale: 6
    add_column :properties, :longitude, :decimal, precision: 10, scale: 6
    add_column :properties, :geocoded_at, :datetime

    add_index :properties, [:latitude, :longitude]
  end
end

class AddLegalArchiveUntilToPvReceptions < ActiveRecord::Migration[8.1]
  def change
    add_column :pv_receptions, :legal_archive_until, :date
  end
end

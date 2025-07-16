class MakeProjectIdOptionalInRequests < ActiveRecord::Migration[8.0]
  def change
    change_column_null :requests, :project_id, true
  end
end

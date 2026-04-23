class CreateSolidQueueRecurringTables < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:solid_queue_recurring_tasks)
      create_table :solid_queue_recurring_tasks do |t|
        t.string :key, null: false
        t.string :schedule, null: false
        t.string :command, limit: 2048
        t.string :class_name
        t.text :arguments
        t.string :queue_name
        t.integer :priority, default: 0
        t.boolean :static, default: true, null: false
        t.text :description
        t.timestamps

        t.index [:key], name: "index_solid_queue_recurring_tasks_on_key", unique: true
        t.index [:static], name: "index_solid_queue_recurring_tasks_on_static"
      end
    end

    unless table_exists?(:solid_queue_recurring_executions)
      create_table :solid_queue_recurring_executions do |t|
        t.bigint :job_id, null: false
        t.string :task_key, null: false
        t.datetime :run_at, null: false
        t.datetime :created_at, null: false

        t.index [:job_id], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
        t.index [:task_key, :run_at], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
      end

      add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs,
                      column: :job_id, on_delete: :cascade
    end
  end
end

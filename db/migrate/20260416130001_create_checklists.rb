class CreateChecklists < ActiveRecord::Migration[8.0]
  def change
    # ── Templates de checklists (données de référence) ──────────────────────
    create_table :checklist_templates do |t|
      t.string  :name,        null: false
      t.string  :phase,       null: false  # gros_oeuvre | second_oeuvre | finitions | reception
      t.text    :description
      t.integer :position,    default: 0
      t.timestamps
    end

    # ── Items d'un template ──────────────────────────────────────────────────
    create_table :checklist_items do |t|
      t.bigint  :checklist_template_id, null: false
      t.text    :description,           null: false
      t.boolean :required,              default: false
      t.integer :position,              default: 0
      t.timestamps

      t.index :checklist_template_id
    end

    # ── Checklists lancées sur un projet ────────────────────────────────────
    create_table :project_checklists do |t|
      t.bigint   :project_id,             null: false
      t.bigint   :checklist_template_id,  null: false
      t.datetime :completed_at
      t.timestamps

      t.index :project_id
      t.index :checklist_template_id
    end

    # ── Réponses aux items ───────────────────────────────────────────────────
    create_table :project_checklist_items do |t|
      t.bigint   :project_checklist_id, null: false
      t.bigint   :checklist_item_id,    null: false
      t.boolean  :checked,              default: false
      t.text     :notes
      t.datetime :checked_at
      t.timestamps

      t.index :project_checklist_id
    end

    add_foreign_key :checklist_items,         :checklist_templates
    add_foreign_key :project_checklists,      :projects
    add_foreign_key :project_checklists,      :checklist_templates
    add_foreign_key :project_checklist_items, :project_checklists
    add_foreign_key :project_checklist_items, :checklist_items
  end
end

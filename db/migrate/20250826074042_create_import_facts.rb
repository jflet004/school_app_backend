# db/migrate/XXXXXXXXXXXXXX_create_import_facts.rb
class CreateImportFacts < ActiveRecord::Migration[7.1]
  def change
    create_table :import_facts do |t|
      t.references :import_batch, null: false, foreign_key: true
      t.string  :teacher_name, null: false
      t.string  :course_name,  null: false
      t.string  :student_name, null: false
      t.date    :on_date,      null: false
      t.string  :start_time    # "HH:MM"
      t.string  :end_time      # "HH:MM"
      t.string  :room
      t.integer :attendance_status, null: false, default: 3 # unknown
      t.json    :raw           # whole transformed row for audit

      t.timestamps
    end

    add_index :import_facts, :on_date
    add_index :import_facts, [:course_name, :on_date]
    add_index :import_facts, [:teacher_name, :on_date]

    # Avoid duplicates within the same batch; across batches we allow stacking
    add_index :import_facts,
      [:import_batch_id, :teacher_name, :student_name, :course_name, :on_date, :start_time, :end_time, :room, :attendance_status],
      unique: true,
      name: "idx_import_facts_unique_per_batch_row"
  end
end

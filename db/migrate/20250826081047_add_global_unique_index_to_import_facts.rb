class AddGlobalUniqueIndexToImportFacts < ActiveRecord::Migration[7.1]
  def change
    add_index :import_facts,
      [:teacher_name, :student_name, :course_name, :on_date, :start_time, :end_time, :room],
      unique: true,
      name: "idx_import_facts_global_unique_row"
  end
end

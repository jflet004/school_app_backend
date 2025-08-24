class CreateCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.references :teacher, null: false, foreign_key: true

      t.timestamps
    end

    add_index :courses, [:teacher_id, :name]
  end
end

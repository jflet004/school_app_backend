class CreateEnrollments < ActiveRecord::Migration[7.1]
  def change
    create_table :enrollments do |t|
      t.references :course_offering, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.integer :status, null: false, default: 0  # 0=active, 1=paused, 2=canceled, 3=completed
      t.date :started_on
      t.date :ended_on
      t.integer :monthly_rate_cents  # snapshot or override; default to course.price_cents in model
      t.text :notes
      t.timestamps
    end

    add_index :enrollments, [:course_offering_id, :student_id], unique: true
  end
end

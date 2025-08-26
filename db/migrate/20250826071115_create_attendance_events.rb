class CreateAttendanceEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_events do |t|
      t.references :course_offering, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.date :on_date
      t.integer :status
      t.string :raw_time

      t.timestamps
    end
  end
end

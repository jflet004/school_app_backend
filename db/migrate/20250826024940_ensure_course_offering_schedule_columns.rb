class EnsureCourseOfferingScheduleColumns < ActiveRecord::Migration[7.1]
  def change
    change_table :course_offerings, bulk: true do |t|
      t.integer :day_of_week unless column_exists?(:course_offerings, :day_of_week) # 0..6
      t.time    :start_time  unless column_exists?(:course_offerings, :start_time)
      t.time    :end_time    unless column_exists?(:course_offerings, :end_time)
      t.string  :room        unless column_exists?(:course_offerings, :room)
      t.references :teacher, foreign_key: true unless column_exists?(:course_offerings, :teacher_id)
    end

    add_index :course_offerings, [:day_of_week, :start_time] unless index_exists?(:course_offerings, [:day_of_week, :start_time])
  end
end

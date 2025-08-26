# app/models/import_fact.rb
class ImportFact < ApplicationRecord
  belongs_to :import_batch

  enum attendance_status: { present: 0, absent: 1, excused: 2, unknown: 3 }

  validates :on_date, :teacher_name, :student_name, :course_name, presence: true
end

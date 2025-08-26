class AttendanceEvent < ApplicationRecord
  belongs_to :course_offering
  belongs_to :student

  enum status: { present: 0, absent: 1, excused: 2, unknown: 3 }

  validates :on_date, presence: true
  validates :student_id, uniqueness: { scope: [:course_offering_id, :on_date],
                                       message: "already has an attendance record for that date" }
end

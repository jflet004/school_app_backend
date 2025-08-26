class CourseOffering < ApplicationRecord
  belongs_to :course
  belongs_to :teacher

  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments

  # Optional enums if you added them earlier:
  enum :day_of_week, {
    sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
    thursday: 4, friday: 5, saturday: 6
  }, prefix: true, allow_nil: true

  validates :course_id, :teacher_id, presence: true
  validates :room, length: { maximum: 255 }, allow_nil: true

  validate :time_window_is_valid

  def time_window_is_valid
    return if start_time.blank? || end_time.blank?
    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end

  # Utility: count how many sessions occur in a given month (for billing)
  def occurrences_in_month(year, month)
    return 0 if day_of_week.nil?
    first_day = Date.new(year, month, 1)
    last_day  = first_day.end_of_month
    (first_day..last_day).count { |d| d.wday == day_of_week_before_type_cast }
  end
end

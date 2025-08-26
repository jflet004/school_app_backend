class CourseOffering < ApplicationRecord
  belongs_to :course
  belongs_to :teacher

  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments

  enum :day_of_week, {
    sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
    thursday: 4, friday: 5, saturday: 6
  }, prefix: true, allow_nil: true

  # ---- capacity helpers ----
  
  def active_status_value
    Enrollment.respond_to?(:statuses) ? Enrollment.statuses['active'] : 0
  end

  def active_enrollments_relation
    # Treat NULL as active to be defensive with legacy rows
    enrollments.where('status = ? OR status IS NULL', active_status_value)
  end
  
  def active_enrollments_count
    enrollments.active.count
  end

  def full?
    capacity.present? && active_enrollments_count >= capacity
  end

  def seats_left
    return nil if capacity.nil?
    [capacity - active_enrollments_count, 0].max
  end
end

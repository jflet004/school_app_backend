# app/models/enrollment.rb
class Enrollment < ApplicationRecord
  belongs_to :course_offering
  belongs_to :student

  enum :status, { active: 0, paused: 1, canceled: 2, completed: 3 }, prefix: true

  validates :course_offering_id, :student_id, presence: true
  validates :monthly_rate_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :offering_has_capacity, on: :create
  
  before_validation :default_monthly_rate

  def default_monthly_rate
    self.monthly_rate_cents ||= course_offering.course.price_cents if course_offering&.course
  end

  def charge_cents_for(year:, month:)
    per_class = monthly_rate_cents || course_offering.course.price_cents
    classes_in_month = course_offering.occurrences_in_month(year, month)
    per_class.to_i * classes_in_month
  end

   private

def offering_has_capacity
    return if course_offering.nil? || course_offering.capacity.blank?
    # Count active + NULL as active
    active_val = Enrollment.respond_to?(:statuses) ? Enrollment.statuses['active'] : 0
    active_count = course_offering.enrollments
                                 .where('status = ? OR status IS NULL', active_val)
                                 .count
    if active_count >= course_offering.capacity
      errors.add(:base, "This class is full (capacity reached).")
    end
end
end

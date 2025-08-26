class Course < ApplicationRecord
  has_many :course_offerings, dependent: :destroy

  enum :course_type, { group: 0, individual: 1 }, prefix: true

  validates :name, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
end

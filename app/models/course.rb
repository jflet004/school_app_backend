class Course < ApplicationRecord
  enum course_type: { group: 0, individual: 1 }, _prefix: :course_type
  enum department:  { art: 0, music: 1, drama: 2, dance: 3, summer: 4, tuition_free: 5 }, _prefix: :department

  has_many :course_offerings, dependent: :destroy
  belongs_to :teacher, optional: true

  validates :name, presence: true
  validates :department, presence: true, on: :create

end

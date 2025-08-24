class Course < ApplicationRecord
  belongs_to :teacher
  validates :name, presence: true
end

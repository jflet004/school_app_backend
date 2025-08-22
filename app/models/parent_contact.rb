class ParentContact < ApplicationRecord
   belongs_to :student

  validates :parent_first_name, :parent_last_name, presence: true
  validates :student, presence: true
end

class Teacher < ApplicationRecord
  has_many :courses, dependent: :destroy

  # Basic validations
  validates :first_name, :last_name, :email, :hire_date, :base_rate, presence: true
  validates :email, uniqueness: true
  validates :base_rate, numericality: { greater_than_or_equal_to: 0 }

  # Simple name search (case-insensitive)
  scope :search, ->(term) {
    next all if term.blank?
    where("first_name LIKE :q OR last_name LIKE :q", q: "%#{sanitize_sql_like(term)}%")
  }
end

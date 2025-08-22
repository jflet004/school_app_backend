class Student < ApplicationRecord
  has_many :parent_contacts, dependent: :destroy
  accepts_nested_attributes_for :parent_contacts, allow_destroy: true

  # student_type
  enum student_type: { adult: 0, child: 1 }

  # gender
  enum gender: {
    male: 0,
    female: 1,
    nonbinary: 2,
    prefer_not_to_say: 3
  }

  # experience_years
  enum experience_years: {
    zero: 0,
    one_two: 1,    # "1–2"
    three_four: 2, # "3–4"
    five_plus: 3   # "5+"
  }

  # ethnicity
  enum ethnicity: {
    hispanic_latino: 0,
    asian_pacific_islander: 1,
    caucasian: 2,
    native_american: 3,
    african_american: 4,
    other: 5,
    prefer_not_to_respond: 6
  }

  # household_size (1..10+)
  enum household_size: {
    size_1: 1, size_2: 2, size_3: 3, size_4: 4, size_5: 5,
    size_6: 6, size_7: 7, size_8: 8, size_9: 9, size_10_plus: 10
  }, _prefix: :household

  # household_income
  enum household_income: {
    under_20k: 0,
    between_20k_34_999: 1,
    between_35k_49_999: 2,
    between_50k_74_999: 3,
    between_75k_99_999: 4,
    _100k_or_more: 5
  }

  # heard_about
  enum heard_about: {
    walk_in: 0,
    web: 1,
    event: 2,
    other_source: 3
  }

  # Validations common to both adult & child
  validates :student_type, presence: true
  validates :first_name, :last_name, presence: true
  validates :gender, :experience_years, :ethnicity, presence: true

  # Conditional validations for address/email/phone—
  # these were included in both adult and child specs so we require them:
  with_options if: :adult? do
    validates :email, :phone_number, :home_address, :city, :state, :postal_code,
              :household_size, :household_income, :heard_about, presence: true
  end

with_options if: :child? do
  validates :current_school_name, presence: true
  # Boolean must be either true or false (not nil)
  validates :current_school_offers_arts, inclusion: { in: [true, false] }
  validates :email, :phone_number, :home_address, :city, :state, :postal_code,
            :household_size, :household_income, :heard_about, presence: true
end

# Simple "like" search across first/last name
scope :search, ->(term) {
  next all if term.blank?
  where("first_name LIKE :q OR last_name LIKE :q", q: "%#{sanitize_sql_like(term)}%")
}

# Filter helpers for enum-backed fields (accepts string enum keys)
scope :filter_enum, ->(attr, value) {
  next all if value.blank?
  # Safely map string value to enum integer; ignore if invalid
  enum_map = public_send(attr.to_s.pluralize)
  return none unless enum_map.key?(value.to_s) # unknown value
  where(attr => value)
}

scope :filter_student_type,   ->(v) { filter_enum(:student_type, v) }
scope :filter_gender,         ->(v) { filter_enum(:gender, v) }
scope :filter_ethnicity,      ->(v) { filter_enum(:ethnicity, v) }
scope :filter_experience,     ->(v) { filter_enum(:experience_years, v) }
scope :filter_heard_about,    ->(v) { filter_enum(:heard_about, v) }

end

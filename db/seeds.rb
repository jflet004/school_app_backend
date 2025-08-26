# db/seeds.rb
require "faker"

# Make results reproducible when re-running seeds
srand(1234)
Faker::Config.random = Random.new(1234)

puts "Clearing existing data..."
ParentContact.delete_all
Student.delete_all

# Helpers
def random_phone
  Faker::PhoneNumber.phone_number
end

def random_address
  {
    home_address: Faker::Address.street_address,
    city: Faker::Address.city,
    state: Faker::Address.state_abbr,
    postal_code: Faker::Address.zip_code
  }
end

def random_household_size
  # enum keys defined in Student: size_1..size_10_plus
  keys = Student.household_sizes.keys
  keys.sample
end

def random_household_income
  Student.household_incomes.keys.sample
end

def random_heard_about
  Student.heard_abouts.keys.sample # walk_in, web, event, other_source
end

def random_gender
  Student.genders.keys.sample
end

def random_experience
  Student.experience_years.keys.sample
end

def random_ethnicity
  Student.ethnicities.keys.sample
end

def make_parent_contact!(student)
  ParentContact.create!(
    student: student,
    parent_first_name: Faker::Name.first_name,
    parent_last_name:  Faker::Name.last_name,
    email: Faker::Internet.email,
    phone_number: random_phone,
    **random_address
  )
end

def make_child_student!
  first = Faker::Name.first_name
  last  = Faker::Name.last_name

  s = Student.create!(
    student_type: :child,
    first_name: first,
    last_name: last,
    birthday: Faker::Date.birthday(min_age: 5, max_age: 17),
    instrument_preference: %w[Violin Viola Cello Bass Piano Guitar Flute Clarinet Drums Voice].sample,
    gender: random_gender,
    experience_years: random_experience,
    ethnicity: random_ethnicity,
    email: Faker::Internet.email(name: "#{first}.#{last}"),
    phone_number: random_phone,
    **random_address,
    household_size: random_household_size,
    household_income: random_household_income,
    heard_about: random_heard_about,
    current_school_name: "#{Faker::Address.city} #{%w[Elementary Middle High].sample} School",
    current_school_offers_arts: [true, false].sample
  )

  # 1–3 parents/guardians
  rand(1..3).times { make_parent_contact!(s) }

  s
end

def make_adult_student!
  first = Faker::Name.first_name
  last  = Faker::Name.last_name

  Student.create!(
    student_type: :adult,
    first_name: first,
    last_name: last,
    birthday: Faker::Date.birthday(min_age: 18, max_age: 80),
    instrument_preference: %w[Piano Guitar Voice Drums Violin Saxophone Trumpet].sample,
    gender: random_gender,
    experience_years: random_experience,
    ethnicity: random_ethnicity,
    email: Faker::Internet.email(name: "#{first}.#{last}"),
    phone_number: random_phone,
    **random_address,
    household_size: random_household_size,
    household_income: random_household_income,
    heard_about: random_heard_about
  )
end

puts "Creating students..."
# Adjust counts as you like
child_count = ENV.fetch("CHILDREN", "12").to_i
adult_count = ENV.fetch("ADULTS", "8").to_i

child_count.times { make_child_student! }
adult_count.times { make_adult_student! }

puts "Done! #{Student.child.count} child students, #{Student.adult.count} adult students."
puts "Total parent contacts: #{ParentContact.count}"



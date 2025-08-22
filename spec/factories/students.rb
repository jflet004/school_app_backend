FactoryBot.define do
  factory :student do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    birthday   { Date.new(2000, 1, 1) }
    instrument_preference { %w[Piano Guitar Violin Voice Drums].sample }
    gender { Student.genders.keys.sample }
    experience_years { Student.experience_years.keys.sample }
    ethnicity { Student.ethnicities.keys.sample }

    email        { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
    home_address { Faker::Address.street_address }
    city         { Faker::Address.city }
    state        { Faker::Address.state_abbr }
    postal_code  { Faker::Address.zip_code }

    household_size   { Student.household_sizes.keys.sample }
    household_income { Student.household_incomes.keys.sample }
    heard_about      { Student.heard_abouts.keys.sample }

    trait :adult do
      student_type { :adult }
    end

    trait :child do
      student_type { :child }
      current_school_name { "#{Faker::Address.city} Elementary School" }
      current_school_offers_arts { [true, false].sample }
    end

    factory :adult_student,  traits: [:adult]
    factory :child_student,  traits: [:child]
  end
end

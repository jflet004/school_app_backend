FactoryBot.define do
  factory :parent_contact do
    association :student, factory: :child_student

    parent_first_name { Faker::Name.first_name }
    parent_last_name  { Faker::Name.last_name }
    email        { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
    home_address { Faker::Address.street_address }
    city         { Faker::Address.city }
    state        { Faker::Address.state_abbr }
    postal_code  { Faker::Address.zip_code }
  end
end

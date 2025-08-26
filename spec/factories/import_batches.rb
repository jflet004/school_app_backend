FactoryBot.define do
  factory :import_batch do
    source { "MyString" }
    status { 1 }
    metadata { "" }
  end
end

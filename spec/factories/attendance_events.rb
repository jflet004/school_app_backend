FactoryBot.define do
  factory :attendance_event do
    course_offering { nil }
    student { nil }
    on_date { "2025-08-26" }
    status { 1 }
    raw_time { "MyString" }
  end
end

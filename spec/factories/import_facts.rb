FactoryBot.define do
  factory :import_fact do
    import_batch { nil }
    teacher_name { "MyString" }
    course_name { "MyString" }
    student_name { "MyString" }
    on_date { "2025-08-26" }
    start_time { "MyString" }
    end_time { "MyString" }
    room { "MyString" }
    attendance_status { 1 }
    raw { "" }
  end
end

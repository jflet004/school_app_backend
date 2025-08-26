FactoryBot.define do
  factory :enrollment do
    course_offering { nil }
    student { nil }
    status { 1 }
    started_on { "2025-08-25" }
    ended_on { "2025-08-25" }
    monthly_rate_cents { 1 }
    notes { "MyText" }
  end
end

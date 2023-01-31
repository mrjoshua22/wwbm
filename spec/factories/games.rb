FactoryBot.define do
  factory :game do
    user { nil }
    finished_ad { "2023-01-31 20:26:59" }
    current_level { 1 }
    is_failed { false }
    prize { 1 }
  end
end

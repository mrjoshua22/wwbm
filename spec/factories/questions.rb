FactoryBot.define do
  factory :question do
    sequence(:level) { |n| n % 15 }
    sequence(:text) { |n| "В каком году была космическая одиссея #{n}?" }
    answer1 { "#{rand(2001)}" }
    answer2 { "#{rand(2001)}" }
    answer3 { "#{rand(2001)}" }
    answer4 { "#{rand(2001)}" }
  end
end

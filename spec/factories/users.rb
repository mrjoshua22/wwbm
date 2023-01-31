FactoryBot.define do
  factory :user do
    name { "MyString" }
    email { "MyString" }
    is_admin { false }
    balance { 1 }
  end
end

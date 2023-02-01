module MySpecHelper
  def generate_questions(number)
    number.times do
      FactoryBot.create(:question)
    end
  end
end

RSpec.configure do |config|
  config.include MySpecHelper
end

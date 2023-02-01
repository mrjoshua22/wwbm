require 'rails_helper'

RSpec.describe Question, type: :model do
  context 'validations should be' do
    it { is_expected.to validate_presence_of :text }
    it { is_expected.to validate_presence_of :level }

    it { is_expected.to validate_inclusion_of(:level).in_range(0..14) }

    it { is_expected.to allow_value(14).for(:level) }
    it { is_expected.not_to allow_value(15).for(:level) }
  end
end

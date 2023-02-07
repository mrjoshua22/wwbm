require 'rails_helper'

RSpec.describe "users/show", type: :view do
  let(:user) { create(:user, name: 'Dale') }
  let(:another_user) { create(:user) }
  subject { rendered }

  before do
    assign(:user, user)
    assign(:games, [ double(prize: 32000), double(prize: 64000) ])
    stub_template 'users/_game.html.erb' => '<%= game.prize %>'
    render
  end

  it { is_expected.to match('Dale') }
  it { is_expected.to match('32000') }
  it { is_expected.to match('64000') }

  context 'when users own profile' do
    before do
      sign_in user
      render
    end

    it { is_expected.to match('Сменить имя и пароль') }
  end

  context 'when another user profile' do
    before do
      sign_in another_user
      render
    end

    it { is_expected.not_to match('Сменить имя и пароль') }
  end
end

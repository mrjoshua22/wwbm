require 'rails_helper'

RSpec.describe "users/index", type: :view do
  before(:example) do
    assign(:users, [
      build_stubbed(:user, name: 'Dale', balance: 5000),
      build_stubbed(:user, name: 'Gordon', balance: 3000)
    ])

    render
  end

  it 'renders player names' do
    expect(rendered).to match('Dale')
    expect(rendered).to match('Gordon')
  end

  it 'renders player balances' do
    expect(rendered).to match('5 000 ₽')
    expect(rendered).to match('3 000 ₽')
  end

  it 'renders player names in right order' do
    expect(rendered).to match(/Dale.*Gordon/m)
  end
end

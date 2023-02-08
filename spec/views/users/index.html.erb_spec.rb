require 'rails_helper'

RSpec.describe "users/index", type: :view do
  before(:example) do
    assign(:users, [
      build_stubbed(:user, name: 'Dale', balance: 5000),
      build_stubbed(:user, name: 'Gordon', balance: 3000)
    ])

    render
  end

  it 'renders first player name' do
    expect(rendered).to match('Dale')
  end

  it 'renders second player name' do
    expect(rendered).to match('Gordon')
  end

  it 'renders first player balance' do
    expect(rendered).to match('5 000 ₽')
  end

  it 'renders second player balance' do
    expect(rendered).to match('3 000 ₽')
  end

  it 'renders player names in right order' do
    expect(rendered).to match(/Dale.*Gordon/m)
  end
end

require 'rails_helper'

RSpec.feature 'User views another user profile', type: :feature do
  let(:user) { create(:user) }
  let!(:another_user) { create(:user, name: 'Dale') }
  let!(:game) do
    create(
    :game,
    user_id: another_user.id,
    created_at: Time.parse('2023.02.06, 20:00'),
    finished_at: Time.parse('2023.02.06, 20:12'),
    is_failed: false,
    current_level: 10,
    prize: 32000
    )
  end

  let!(:another_game) do
    create(
    :game,
    user_id: another_user.id,
    created_at: Time.parse('2023.02.06, 22:00'),
    finished_at: Time.parse('2023.02.06, 22:22'),
    is_failed: true,
    current_level: 8,
    prize: 1000
    )
  end

  before do
    login_as user
  end

  scenario 'success' do
    visit user_path(another_user)

    expect(page).to have_content('Dale')
    expect(page).to have_content('06 февр., 20:00')
    expect(page).to have_content('проигрыш')
    expect(page).to have_content('32 000 ₽')
    expect(page).to have_content('10')
    expect(page).to have_content('06 февр., 22:00')
    expect(page).to have_content('деньги')
    expect(page).to have_content('1 000 ₽')
    expect(page).to have_content('8')
    expect(page).not_to have_content('Сменить имя и пароль')
  end
end

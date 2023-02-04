require 'rails_helper'

RSpec.describe "Games", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  context 'Anonymous' do
    it 'kicks from #show' do
      get game_path(game_w_questions)

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  context 'Usual user' do
    before(:example) do
      sign_in user
    end

    it 'creates game' do
      generate_questions(60)

      post games_path

      game = @controller.view_assigns['game']

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it 'shows game' do
      get game_path(game_w_questions)

      game = @controller.view_assigns['game']

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200)
    end

    it 'answer correct' do
      put answer_game_path(game_w_questions),
        params: {
          letter: game_w_questions.current_game_question.correct_answer_key
        }

      game = @controller.view_assigns['game']

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy
    end
  end
end

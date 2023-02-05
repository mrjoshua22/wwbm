require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe "Games", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  context 'Anonymous user' do
    it 'kicks from #create' do
      expect { post games_path }.not_to change(Game,:count)

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicks from #show' do
      get game_path(game_w_questions)

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicks from #answer' do
      expect { put answer_game_path(game_w_questions),
        params: {
          letter: game_w_questions.current_game_question.correct_answer_key
        }}.not_to change { game_w_questions.current_level }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicks from #take_money' do
      expect { put take_money_game_path(game_w_questions) }.
        not_to change { game_w_questions.finished_at }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicks from #help' do
      expect { put take_money_game_path(game_w_questions) }.
        to not_change { game_w_questions.fifty_fifty_used }.
        and not_change { game_w_questions.audience_help_used }.
        and not_change { game_w_questions.friend_call_used }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  context 'Usual user' do
    let(:another_game) { create(:game_with_questions) }

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

    it 'forbids to create game before finish another' do
      expect(game_w_questions.finished?).to be_falsey

      expect { post games_path }.not_to change(Game,:count)

      game = @controller.view_assigns['game']

      expect(game).to be_nil
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    it 'shows game' do
      get game_path(game_w_questions)

      game = @controller.view_assigns['game']

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200)
    end

    it 'forbids to access someone elses game' do
      get game_path(another_game)

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'answer is correct' do
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

    it 'answer is incorrect' do
      put answer_game_path(game_w_questions), params: { letter: 'a' }

      game = @controller.view_assigns['game']

      expect(game.finished?).to be_truthy
      expect(game.is_failed).to be_truthy
      expect(response).to redirect_to(user_path(user))
      expect(flash[:alert]).to be
    end

    it 'takes money' do
      game_w_questions.update(current_level: 4)

      put take_money_game_path(game_w_questions)

      game = @controller.view_assigns['game']

      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(500)

      user.reload.balance

      expect(user.balance).to eq(game.prize)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end
  end
end

require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe "Games", type: :request do
  let(:user) { create(:user) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  context 'Unregistered user' do
    describe '#create' do
      before(:context) do
        post games_path
      end

      it { expect { post games_path }.not_to change(Game,:count) }
      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be }
    end

    describe '#show' do
      before(:example) do
        get game_path(game_w_questions)
      end

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be }
    end

    describe '#answer' do
      before(:example) do
        put answer_game_path(game_w_questions), params: {
          letter: game_w_questions.current_game_question.correct_answer_key
        }
      end

      it 'does not change game level' do
        expect { put answer_game_path(game_w_questions), params: {
          letter: game_w_questions.current_game_question.correct_answer_key
          }}.not_to change { game_w_questions.current_level }
      end

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be }
    end

    describe '#take_money' do
      before(:example) do
        put take_money_game_path(game_w_questions)
      end

      it 'does not finish game' do
        expect { put take_money_game_path(game_w_questions) }.
          not_to change { game_w_questions.finished_at }
      end

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be }
    end

    describe '#help' do
      before(:example) do
        put help_game_path(game_w_questions)
      end

      it 'does not change help status' do
        expect { put help_game_path(game_w_questions) }.
          to not_change { game_w_questions.fifty_fifty_used }.
          and not_change { game_w_questions.audience_help_used }.
          and not_change { game_w_questions.friend_call_used }
      end

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be }
    end
  end

  context 'Registered user' do
    let(:admin) { create(:user, is_admin: true) }
    let(:another_game) { create(:game_with_questions) }

    before(:example) do
      sign_in user
    end

    describe '#create' do
      context 'user has no unfinished game' do
        it 'creates game' do
          generate_questions(60)

          post games_path

          game = controller.view_assigns['game']

          expect(game.finished?).to be_falsey
          expect(game.user).to eq(user)

          expect(response).to redirect_to(game_path(game))
          expect(flash[:notice]).to be
        end
      end

      context 'user has unfinished game' do
        it 'forbids to create game before finish another' do
          expect(game_w_questions.finished?).to be_falsey

          expect { post games_path }.not_to change(Game,:count)

          game = controller.view_assigns['game']

          expect(game).to be_nil
          expect(response.status).not_to eq(200)
          expect(response).to redirect_to(game_path(game_w_questions))
          expect(flash[:alert]).to be
        end
      end
    end

    describe '#show' do
      context 'when users own game' do
        let(:game) { controller.view_assigns['game'] }

        before(:example) do
          get game_path(game_w_questions)
        end

        it { expect(game.finished?).to be_falsey }
        it { expect(game.user).to eq(user) }
        it { expect(response.status).to eq(200) }
      end

      context 'when other users game' do
        before(:example) do
          get game_path(another_game)
        end

        it { expect(response.status).not_to eq(200) }
        it { expect(response).to redirect_to(root_path) }
        it { expect(flash[:alert]).to be }
      end
    end

    describe '#answer' do
      context 'when answer is correct' do
        let(:game) { game = controller.view_assigns['game'] }

        before(:example) do
          put answer_game_path(game_w_questions), params: {
            letter: game_w_questions.current_game_question.correct_answer_key
          }
        end

        it { expect(game.finished?).to be_falsey }
        it { expect(game.current_level).to be > 0 }
        it { expect(response).to redirect_to(game_path(game)) }
        it { expect(flash.empty?).to be_truthy }
      end

      context 'when answer is incorrect' do
        let(:game) { game = controller.view_assigns['game'] }

        before(:example) do
          put answer_game_path(game_w_questions), params: { letter: 'a' }
        end

        it { expect(game.finished?).to be_truthy }
        it { expect(game.is_failed).to be_truthy }
        it { expect(response).to redirect_to(user_path(user)) }
        it { expect(flash[:alert]).to be }
      end
    end

    describe '#take_money' do
      let(:game) { game = controller.view_assigns['game'] }

      before(:example) do
        game_w_questions.update(current_level: 4)
        put take_money_game_path(game_w_questions)
      end

      it { expect(game.finished?).to be_truthy }
      it { expect(game.prize).to eq(500) }
      it { expect(response).to redirect_to(user_path(user)) }
      it { expect(flash[:warning]).to be }

      it 'adds correct sum tousers balance' do
        user.reload.balance
        expect(user.balance).to eq(game.prize)
      end
    end

    it 'audience help' do
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).
        not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      put help_game_path(game_w_questions),
        params: { help_type: :audience_help }

      game = controller.view_assigns['game']

      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).
        to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game_w_questions))
    end

    it 'fifty fifty' do
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).
        not_to be
      expect(game_w_questions.fifty_fifty_used).to be_falsey

      put help_game_path(game_w_questions),
        params: { help_type: :fifty_fifty }

      game = controller.view_assigns['game']

      expect(game.finished?).to be_falsey
      expect(game.fifty_fifty_used).to be_truthy
      expect(game.current_game_question.help_hash[:fifty_fifty]).to be
      expect(game.current_game_question.help_hash[:fifty_fifty].size).
        to eq(2)
      expect(game.current_game_question.help_hash[:fifty_fifty]).
       to include(game.current_game_question.correct_answer_key)
      expect(response).to redirect_to(game_path(game_w_questions))
    end
  end
end

require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe "Games", type: :request do
  let(:user) { create(:user) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#create' do
    context 'when unregistered user' do
      before(:context) { post games_path }

      it { expect { post games_path }.not_to change(Game,:count) }
      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be_truthy }
    end

    context 'when registered user' do
      before { sign_in user }

      context 'when user has no unfinished game' do
        context 'when creates game' do
          let!(:questions) { generate_questions(15) }
          let(:game) { controller.view_assigns['game'] }

          before { post games_path }

          it { expect(game.finished?).to be_falsey }
          it { expect(game.user).to eq(user) }
          it { expect(response).to redirect_to(game_path(game)) }
          it { expect(flash[:notice]).to be_truthy }
        end
      end

      context 'when user has unfinished game' do
        context 'when forbids to create game' do
          let!(:questions) { generate_questions(15) }
          let(:game) { game = controller.view_assigns['game'] }

          before do
            game_w_questions.finished_at = nil
            post games_path
          end

          it { expect { post games_path }.not_to change(Game,:count) }
          it { expect(game).to be_nil }
          it { expect(response.status).not_to eq(200) }
          it { expect(response).to redirect_to(game_path(game_w_questions)) }
          it { expect(flash[:alert]).to be_truthy }
        end
      end
    end
  end

  describe '#show' do
    context 'when unregistered user' do
      before { get game_path(game_w_questions) }

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be_truthy }
    end

    context 'when registered user' do
      before { sign_in user }

      context 'when users own game' do
        let(:game) { controller.view_assigns['game'] }

        before { get game_path(game_w_questions) }

        it { expect(game.finished?).to be_falsey }
        it { expect(game.user).to eq(user) }
        it { expect(response.status).to eq(200) }
      end

      context 'when other users game' do
        let(:another_game) { create(:game_with_questions) }

        before { get game_path(another_game) }

        it { expect(response.status).not_to eq(200) }
        it { expect(response).to redirect_to(root_path) }
        it { expect(flash[:alert]).to be_truthy }
      end
    end
  end

  describe '#answer' do
    context 'when unregistered user' do
      before do
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
      it { expect(flash[:alert]).to be_truthy }
    end

    context 'when registered user' do
      before { sign_in user }

      context 'when answer is correct' do
        let(:game) { game = controller.view_assigns['game'] }

        before do
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

        before do
          put answer_game_path(game_w_questions), params: { letter: 'a' }
        end

        it { expect(game.finished?).to be_truthy }
        it { expect(game.is_failed).to be_truthy }
        it { expect(response).to redirect_to(user_path(user)) }
        it { expect(flash[:alert]).to be_truthy }
      end
    end
  end

  describe '#take_money' do
    context 'when unregistered user' do
      before { put take_money_game_path(game_w_questions) }

      it 'does not finish game' do
        expect { put take_money_game_path(game_w_questions) }.
          not_to change { game_w_questions.finished_at }
      end

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be_truthy }
    end

    context 'when registered user' do
      let(:game) { game = controller.view_assigns['game'] }

      before do
        sign_in user
        game_w_questions.update(current_level: 4)
        put take_money_game_path(game_w_questions)
      end

      it { expect(game.finished?).to be_truthy }
      it { expect(game.prize).to eq(500) }
      it { expect(response).to redirect_to(user_path(user)) }
      it { expect(flash[:warning]).to be_truthy }

      it 'adds correct sum tousers balance' do
        user.reload.balance
        expect(user.balance).to eq(game.prize)
      end
    end
  end

  describe '#help' do
    context 'when unregistered user' do
      before { put help_game_path(game_w_questions) }

      it 'does not change help status' do
        expect { put help_game_path(game_w_questions) }.
          to not_change { game_w_questions.fifty_fifty_used }.
          and not_change { game_w_questions.audience_help_used }.
          and not_change { game_w_questions.friend_call_used }
      end

      it { expect(response.status).not_to eq(200) }
      it { expect(response).to redirect_to(new_user_session_path) }
      it { expect(flash[:alert]).to be_truthy }
    end

    context 'when registered user' do
      before { sign_in user }

      context 'when audience help' do
        context 'when not used' do
          it 'not exists in help hash' do
            expect(game_w_questions.current_game_question.
              help_hash[:audience_help]).
              to be_falsey
          end

          it { expect(game_w_questions.audience_help_used).to be_falsey }
        end

        context 'when used' do
          let(:game) { game = controller.view_assigns['game'] }

          before do
            put help_game_path(game_w_questions),
              params: { help_type: :audience_help }
          end

          it { expect(game.finished?).to be_falsey }
          it { expect(game.audience_help_used).to be_truthy }
          it { expect(response).to redirect_to(game_path(game_w_questions)) }

          it 'exists in help hash' do
            expect(game.current_game_question.help_hash[:audience_help]).
              to be_truthy
          end

          it 'contains correct set of keys' do
            expect(game.current_game_question.help_hash[:audience_help].keys).
              to contain_exactly('a', 'b', 'c', 'd')
          end
        end
      end

      context 'when fifty fifty' do
        context 'when not used' do
          it 'not exists in help hash' do
            expect(game_w_questions.current_game_question.
              help_hash[:fifty_fifty]).to be_falsey
          end

          it { expect(game_w_questions.fifty_fifty_used).to be_falsey }
        end

        context 'when used' do
          let(:game) { game = controller.view_assigns['game'] }

          before do
            put help_game_path(game_w_questions),
              params: { help_type: :fifty_fifty }
          end

          it { expect(game.finished?).to be_falsey }
          it { expect(game.fifty_fifty_used).to be_truthy }
          it { expect(response).to redirect_to(game_path(game_w_questions)) }

          it 'exists in help hash' do
            expect(game.current_game_question.help_hash[:fifty_fifty]).
              to be_truthy
          end

          it 'contains correct number of keys' do
            expect(game.current_game_question.help_hash[:fifty_fifty].size).
              to eq(2)
          end

          it 'includes correct answer key' do
            expect(game.current_game_question.help_hash[:fifty_fifty]).
              to include(game.current_game_question.correct_answer_key)
          end
        end
      end

      context 'when friend call' do
        context 'when not used' do
          it 'not exists in help hash' do
            expect(game_w_questions.current_game_question.
              help_hash[:friend_call]).to be_falsey
          end

          it { expect(game_w_questions.friend_call_used).to be_falsey }
        end

        context 'when used' do
          let(:game) { game = controller.view_assigns['game'] }

          before do
            put help_game_path(game_w_questions),
              params: { help_type: :friend_call }
          end

          it { expect(game.finished?).to be_falsey }
          it { expect(game.friend_call_used).to be_truthy }
          it { expect(response).to redirect_to(game_path(game_w_questions)) }

          it 'exists in help hash' do
            expect(game.current_game_question.help_hash[:friend_call]).
              to be_truthy
          end
        end
      end
    end
  end
end

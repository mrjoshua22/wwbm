require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }
  let(:game) { create(:game_with_questions, user: user) }

  describe '.create_game_for_user!' do
    let!(:questions) { generate_questions(15) }
    let(:new_game) { Game.create_game_for_user!(user) }

    it { expect { new_game }.to change(Game, :count).by(1) }
    it { expect { new_game }.to change(GameQuestion, :count).by(15) }
    it { expect(new_game.user).to eq(user) }
    it { expect(new_game.status).to eq(:in_progress) }
    it { expect(new_game.game_questions.size).to eq(15) }
    it { expect(new_game.game_questions.map(&:level)).to eq((0..14).to_a) }
  end

  describe '#take_money!' do
    context 'when game is timed out' do
      it 'changes is_failed attribute and exits from method' do
        game.created_at = 1.hour.ago

        expect { game.take_money! }.to change { game.is_failed }
      end
    end

    context 'when game is finished' do
      before do
        game.finished_at = 1.hour.ago
        game.prize = 1000
      end

      it { expect { game.take_money! }.to_not change { game.prize } }
      it { expect { game.take_money! }.to_not change { game.is_failed } }
    end

    context 'when game in progress' do
      before do
        game.current_level = 4
        game.take_money!
        user.reload.balance
      end

      it { expect(game.prize).to eq(500) }
      it { expect(game.status).to eq(:money) }
      it { expect(game.is_failed).to be_falsey }
      it { expect(game.finished?).to be_truthy }
      it { expect(user.balance).to eq(game.prize) }
    end
  end

  describe '#status' do
    it 'returns in progress' do
      expect(game.status).to eq(:in_progress)
    end

    it 'returns fail' do
      game.is_failed = true
      game.finished_at = 1.hour.ago

      expect(game.status).to eq(:fail)
    end

    it 'returns timeout' do
      game.is_failed = true
      game.created_at = 1.hour.ago
      game.finished_at = Time.now

      expect(game.status).to eq(:timeout)
    end

    it 'returns won' do
      game.current_level = 15
      game.finished_at = Time.now

      expect(game.status).to eq(:won)
    end

    it 'returns money' do
      game.finished_at = Time.now

      expect(game.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'returns correct object type' do
      expect(game.current_game_question).to be_a(GameQuestion)
    end

    it 'returns correct question after create' do
      expect(game.current_game_question).
        to eq(game.game_questions.first)
    end

    it 'returns coorect question after answer' do
      game.answer_current_question!(
        game.current_game_question.correct_answer_key
      )

      expect(game.current_game_question).
        to eq(game.game_questions.second)
    end
  end

  describe '#previous_level' do
    it { expect(game.previous_level).to eq(-1) }
  end

  describe '#answer_current_question!' do
    let(:correct_answer) { game.current_game_question.correct_answer_key }
    let(:answer_question) { game.answer_current_question!(correct_answer) }

    context 'when time is out' do
      before { game.created_at = 1.hour.ago }

      it { expect(answer_question).to be_falsey }
      it { expect { answer_question }.to_not change { game.current_level } }
      
      it 'returns correct game status' do
        answer_question

        expect(game.status).to eq(:timeout)
      end
    end

    context 'when game is finished' do
      before do
        game.finished_at = 1.hour.ago
        game.is_failed = false
      end

      it { expect(answer_question).to be_falsey }
      it { expect { answer_question }.to_not change { game.current_level } }
      it { expect(game.status).to eq(:money) }
    end

    context 'when answer is correct' do
      context 'when last question' do
        before do
          game.current_level = 14
          answer_question
          user.reload.balance
        end

        it { expect(game.current_level).to eq(15) }
        it { expect(game.finished?).to be_truthy }
        it { expect(game.is_failed).to be_falsey }
        it { expect(user.balance).to eq(1000000) }
        it { expect(game.status).to eq(:won) }
      end

      context 'when not last question' do
        before do
          game.current_level = 5
          answer_question
        end

        it { expect(game.current_level).to eq(6) }
        it { expect(game.finished?).to be_falsey }
        it { expect(game.is_failed).to be_falsey }
        it { expect(game.status).to eq(:in_progress) }
      end
    end

    context 'when answer is wrong' do
      let(:incorrect_answer) { game.answer_current_question!('a') }

      it 'not change game current level' do
        expect { incorrect_answer }.to_not change { game.current_level }
      end

      it 'finishes the game' do
        incorrect_answer
        expect(game.finished?).to be_truthy
      end

      it 'finishes the game as failed' do
        incorrect_answer
        expect(game.is_failed).to be_truthy
      end

      it 'returns correct game status' do
        incorrect_answer

        expect(game.status).to eq(:fail)
      end
    end
  end
end

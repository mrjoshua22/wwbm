require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }
  let(:game) { create(:game_with_questions, user: user) }

  describe '#create_game_for_user!' do
    it 'creates new correct game' do
      generate_questions(60)

      game = nil

      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  describe '.take_money!' do
    context 'when game is timed out' do
      it 'changes is_failed attribute and exits from method' do
        game.created_at = 1.hour.ago

        expect { game.take_money! }.to change { game.is_failed }
      end
    end

    context 'when game is finished' do
      before(:example) do
        game.finished_at = 1.hour.ago
        game.prize = 1000
      end

      it { expect { game.take_money! }.to_not change { game.prize } }
      it { expect { game.take_money! }.to_not change { game.is_failed } }
    end

    context 'when game in progress' do
      before(:example) do
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

  describe '.status' do
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

  describe '.current_game_question' do
    it 'returns correct object type' do
      expect(game.current_game_question).to be_a(GameQuestion)
    end

    it 'returns question with correct level' do
      expect(game.current_game_question.question.level).
        to eq(game.current_level)
    end
  end

  describe '.previous_level' do
    it { expect(game.previous_level).to eq(-1) }
  end

  describe '.answer_current_question!' do
    let(:correct_answer) { game.current_game_question.correct_answer_key }
    let(:answer_question) { game.answer_current_question!(correct_answer) }

    context 'when time is out' do
      before(:example) do
        game.created_at = 1.hour.ago
      end

      it { expect(answer_question).to be_falsey }
      it { expect { answer_question }.to_not change { game.current_level } }
    end

    context 'when game is finished' do
      before(:example) do
        game.finished_at = 1.hour.ago
      end

      it { expect(answer_question).to be_falsey }
      it { expect { answer_question }.to_not change { game.current_level } }
    end

    context 'when answer is correct' do
      context 'when last question' do
        before(:example) do
          game.current_level = 14
          answer_question
          user.reload.balance
        end

        it { expect(game.current_level).to eq(15) }
        it { expect(game.finished?).to be_truthy }
        it { expect(game.is_failed).to be_falsey }
        it { expect(user.balance).to eq(1000000) }
      end

      context 'when not last question' do
        before(:example) do
          game.current_level = 5
          answer_question
        end

        it { expect(game.current_level).to eq(6) }
        it { expect(game.finished?).to be_falsey }
        it { expect(game.is_failed).to be_falsey }
      end
    end

    context 'when answer is wrong' do
      context 'finishes game' do
        it 'not change game current level' do
        expect { game.answer_current_question!('a')}.
          to_not change { game.current_level }
        end

        it  'finishes the game' do
          game.answer_current_question!('a')
          expect(game.finished?).to be_truthy
        end

        it 'finishes the game as failed' do
          game.answer_current_question!('a')
          expect(game.is_failed).to be_truthy
        end
      end
    end
  end

  context 'when answer is correct' do
    it 'goes to next question' do
      level = game.current_level
      current_question = game.current_game_question

      expect(game.status).to eq(:in_progress)

      game.answer_current_question!(current_question.correct_answer_key)

      expect(game.current_level).to eq(level + 1)
      expect(game.previous_game_question).to eq(current_question)
      expect(game.current_game_question).not_to eq(current_question)
      expect(game.status).to eq(:in_progress)
      expect(game.finished?).to be_falsey
    end
  end
end

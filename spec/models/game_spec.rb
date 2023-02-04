require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

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
      subject { create(:game, created_at: Time.now - 1.hour) }

      it 'changes is_failed attribute and exits from method' do
        expect { subject.take_money! }.to change { subject.is_failed }
      end
    end

    context 'when game is finished' do
      subject { create(:game, prize: 1000, finished_at: Time.now - 1.hour) }

      it 'returns from method without game prize changes' do
        expect { subject.take_money! }.to_not change { subject.prize }
      end

      it 'returns from method without game is_failed changes' do
        expect { subject.take_money! }.to_not change { subject.is_failed }
      end
    end

    context 'when game in progress' do
      let(:user) { create(:user) }
      subject { create(:game, user_id: user.id, current_level: 4) }

      before(:example) do
        subject.take_money!
      end

      it 'returns correct prize value' do
        expect(subject.prize).to eq(500)
      end

      it 'returns correct game status' do
        expect(subject.status).to eq(:money)
      end

      it 'returns false to is_failed attribute' do
        expect(subject.is_failed).to be_falsey
      end

      it 'returns true for finished?' do
        expect(subject.finished?).to be_truthy
      end

      it 'changes users balance' do
        user.reload.balance
        expect(user.balance).to eq(subject.prize)
      end
    end
  end

  describe '.status' do
    context 'when in progress' do
      subject { create(:game) }
      it { expect(subject.status).to eq(:in_progress) }
    end

    context 'when fail' do
      subject { create(:game, is_failed: true, finished_at: Time.now) }
      it { expect(subject.status).to eq(:fail) }
    end

    context 'when timeout' do
      subject do
        create(
          :game, is_failed: true, created_at: Time.now - 1.hour,
          finished_at: Time.now
        )
      end

      it { expect(subject.status).to eq(:timeout)}
    end

    context 'when win' do
      subject { create(:game, current_level: 15, finished_at: Time.now) }
      it { expect(subject.status).to eq(:won) }
    end

    context 'when money' do
      subject { create(:game, finished_at: Time.now) }
      it { expect(subject.status).to eq(:money) }
    end
  end

  describe '.current_game_question' do
    it 'returns correct object type' do
      expect(game_w_questions.current_game_question).to be_a(GameQuestion)
    end

    it 'returns question with correct level' do
      expect(game_w_questions.current_game_question.question.level).
        to eq(game_w_questions.current_level)
    end
  end

  describe '.previous_level' do
    it { expect(game_w_questions.previous_level).to eq(-1) }
  end

  context 'when answer is correct' do
    it 'goes to next question' do
      level = game_w_questions.current_level
      current_question = game_w_questions.current_game_question

      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(current_question.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)
      expect(game_w_questions.previous_game_question).to eq(current_question)
      expect(game_w_questions.current_game_question).not_to eq(current_question)
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end
end

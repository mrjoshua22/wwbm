require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe '.text' do
    it { expect(game_question.text).to eq(game_question.question.text) }
  end

  describe '.level' do
    it { expect(game_question.level).to eq(game_question.question.level) }
  end

  describe '.variants' do
    it 'returns correct variants' do
      expect(game_question.variants).to eq({
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      })
    end
  end

  describe '.answer_correct?' do
    it { expect(game_question.answer_correct?('b')).to be_truthy }
  end

  describe '.correct_answer_key' do
    it { expect(game_question.correct_answer_key).to eq('b') }
  end

  context 'user helpers' do
    it 'help hash' do
      expect(game_question.help_hash).to be_empty

      game_question.help_hash[:audience_help] = 'audience help'
      game_question.help_hash[:fifty_fifty] = 'fifty fifty'
      game_question.help_hash[:friend_call] = 'friend call'

      expect(game_question.save).to be_truthy

      saved_question = GameQuestion.find(game_question.id)

      expect(saved_question.help_hash.size).to eq(3)
      expect(saved_question.help_hash[:audience_help]).to eq('audience help')
      expect(saved_question.help_hash[:fifty_fifty]).to eq('fifty fifty')
      expect(saved_question.help_hash[:friend_call]).to eq('friend call')
    end

    it 'correct audience help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)
      expect(game_question.help_hash[:audience_help].keys).
        to contain_exactly('a', 'b', 'c', 'd')
    end

    it 'correct fifty fifty help' do
      expect(game_question.help_hash).not_to include(:fifty_fifty)

      game_question.add_fifty_fifty

      expect(game_question.help_hash).to include(:fifty_fifty)
      expect(game_question.help_hash[:fifty_fifty].size).to eq(2)
      expect(game_question.help_hash[:fifty_fifty]).to include('b')
    end

    it 'correct friend call help' do
      expect(game_question.help_hash).not_to include(:friend_call)

      game_question.add_friend_call

      expect(game_question.help_hash).to include(:friend_call)
      expect(game_question.help_hash[:friend_call]).to be_a(String)
      expect(game_question.variants.keys).
        to include(game_question.help_hash[:friend_call].split.last.downcase)
    end
  end
end

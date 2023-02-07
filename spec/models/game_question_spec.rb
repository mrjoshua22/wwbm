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

  context 'when there are user help' do
    context 'when help not added' do
      it { expect(game_question.help_hash).to be_empty }
    end

    context 'when help added' do
      before do
        game_question.help_hash[:audience_help] = 'audience help'
        game_question.help_hash[:fifty_fifty] = 'fifty fifty'
        game_question.help_hash[:friend_call] = 'friend call'
      end

      it { expect(game_question.save).to be_truthy }
      it { expect(game_question.help_hash.size).to eq(3) }
      it { expect(game_question.help_hash[:audience_help]).to eq('audience help') }
      it { expect(game_question.help_hash[:fifty_fifty]).to eq('fifty fifty') }
      it { expect(game_question.help_hash[:friend_call]).to eq('friend call') }
    end
  end

  context 'when correct audience help' do
    context 'when help not added' do
      it { expect(game_question.help_hash).not_to include(:audience_help) }
    end

    context 'when help added' do
      before do
        game_question.add_audience_help
      end

      it { expect(game_question.help_hash).to include(:audience_help) }

      it 'contains all answer keys' do
        expect(game_question.help_hash[:audience_help].keys).
          to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end

  context 'correct fifty fifty help' do
    context ' when help not added' do
      it { expect(game_question.help_hash).not_to include(:fifty_fifty) }
    end

    context 'when help added' do
      before do
        game_question.add_fifty_fifty
      end

      it { expect(game_question.help_hash).to include(:fifty_fifty) }
      it { expect(game_question.help_hash[:fifty_fifty].size).to eq(2) }
      it { expect(game_question.help_hash[:fifty_fifty]).to include('b') }
    end
  end

  context 'correct friend call help' do
    context 'when help not added' do
      it { expect(game_question.help_hash).not_to include(:friend_call) }
    end

    context 'when help added' do
      before do
        game_question.add_friend_call
      end

      it { expect(game_question.help_hash).to include(:friend_call) }
      it { expect(game_question.help_hash[:friend_call]).to be_a(String) }

      it 'friend call contains answer key' do
        expect(game_question.variants.keys).
          to include(game_question.help_hash[:friend_call].split.last.downcase)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Matchmaker do
  let(:preferences) do
    {
      participant_1: %i[group_a group_b group_c],
      participant_2: %i[group_c group_a],
      participant_3: %i[group_a group_c group_b]
    }
  end

  it 'gets the best match' do
    expected = {
      participant_1: :group_b,
      participant_2: :group_c,
      participant_3: :group_a
    }

    expect(Matchmaker.match(preferences)).to eq(expected)
  end

  describe Matchmaker::MatchResult do
    subject(:match_result) { described_class.new(group_matchings, preferences) }
    let(:group_matchings) do
      {
        participant_1: :group_b,
        participant_2: :group_c,
        participant_3: :group_a
      }
    end

    it 'knows its match score' do
      expect(match_result.score).to match([1, be_within(0.1).of(0.22)])
    end

    it 'provides a summary' do
      expected = <<~EOSUMMARY
        Choice 1: 2
        Choice 2: 1

        Total score: 1
        Variance: 0.22.*
      EOSUMMARY
      expect(match_result.summary).to match(/#{expected}/)
    end

    context 'without full preferences' do
      let(:preferences) do
        {
          participant_1: [],
          participant_2: [],
          participant_3: []
        }
      end

      it 'knows its match score' do
        expect(match_result.score).to eq([3, 0.0])
      end
    end
  end

  describe Matchmaker::SimpleMatch do
    let(:discriminator) { Random.new(1) }
    subject(:single_match) { described_class.new(preferences, discriminator: discriminator) }

    it 'matches preferences' do
      expected = {
        participant_1: :group_b,
        participant_2: :group_c,
        participant_3: :group_a
      }

      expect(single_match.match_result.matches).to eq(expected)
    end

    context 'with a different discriminator' do
      let(:discriminator) { Random.new(321) }

      it 'resolves ties differently' do
        expected = {
          participant_1: :group_a,
          participant_2: :group_c,
          participant_3: :group_b
        }

        expect(single_match.match_result.matches).to eq(expected)
      end
    end
  end

  describe Matchmaker::MultiMatch do
    let(:discriminator) { Random.new(1) }
    let(:preferences) do
      {
        participant_1: %i[group_a group_b],
        participant_2: %i[group_b group_a],
        participant_3: %i[group_a],
        participant_4: %i[group_b]
      }
    end

    subject(:multi_match) { described_class.new(preferences, discriminator: discriminator, group_size: 2) }

    it 'matches preferences' do
      expected = {
        participant_1: :group_a,
        participant_2: :group_b,
        participant_3: :group_a,
        participant_4: :group_b
      }

      expect(multi_match.match_result.matches).to eq(expected)
    end

  end

end

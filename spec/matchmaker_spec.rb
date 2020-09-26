RSpec.describe Matchmaker do
  let(:preferences) do
    {
      participant_1: [:group_a, :group_b, :group_c],
      participant_2: [:group_c, :group_a],
      participant_3: [:group_a, :group_c, :group_b],
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


  describe Matchmaker::Match do
    let(:discriminator) { Random.new(1) }
    subject(:single_match) { described_class.new(preferences, discriminator: discriminator) }

    it 'matches preferences' do
      expected = {
        participant_1: :group_b,
        participant_2: :group_c,
        participant_3: :group_a
      }

      expect(single_match.match).to eq(expected)
    end

    it 'knows its match score' do
      expect(single_match.score).to match([1, be_within(0.1).of(0.22)])
    end

    context 'with a different discriminator' do
      let(:discriminator) { Random.new(321) }

      it 'resolves ties differently' do
        expected = {
          participant_1: :group_a,
          participant_2: :group_c,
          participant_3: :group_b
        }

        expect(single_match.match).to eq(expected)
      end

      it 'has a differenty match score' do
        expect(single_match.score).to match([2, be_within(0.1).of(0.88)])
      end
    end
  end
end

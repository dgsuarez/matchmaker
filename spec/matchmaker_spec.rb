RSpec.describe Matchmaker do
  it 'matches preferences' do
    preferences = {
      person_1: [:group_a, :group_b, :group_c],
      person_2: [:group_c, :group_a],
      person_3: [:group_a, :group_c, :group_b],
    }

    expected = {
      person_1: :group_b,
      person_2: :group_c,
      person_3: :group_a
    }

    actual = Matchmaker.generate_match(preferences, discriminator: Random.new(1))

    expect(actual).to eq(expected)
  end
end

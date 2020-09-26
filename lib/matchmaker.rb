require "matchmaker/version"

module Matchmaker
  class Error < StandardError; end

  def self.match(preferences, rounds: 100, print_summary: false)
    all_matches = 1.upto(rounds).map do |i|
      Match.new(preferences, discriminator: Random.new(i))
    end.sort

    best_match = all_matches.first
    worst_match = all_matches.last

    if print_summary
      puts "Did #{rounds} rounds, found #{all_matches.uniq.length} unique matches"
      puts "Best match:\n#{best_match.summary}"
      puts
      puts "Worst match:\n#{worst_match.summary}"
    end

    best_match.match
  end

  class Match
    def initialize(preferences, discriminator: Random.new)
      @preferences = preferences
      @discriminator = discriminator
      @matches = nil
    end

    def match
      return matches if matches
      self.matches = {}

      groups.each do |current_group|
        best_participant, = preferences.
          transform_values {|groups| [groups.index(current_group) || missing_group_score, discriminator.rand] }
          .sort_by { |_, group_score| group_score }
          .reject { |participant,| matches[participant] }
          .first

        matches[best_participant] = current_group
      end

      matches
    end

    def score
      @score ||= begin
                   individual_scores = match.map { |participant, group| preferences[participant].index(group) }

                   [individual_scores.reduce(&:+), variance(individual_scores)]
                 end
    end

    def summary
      choices = Hash.new(0)
      match.each do |participant, group|
        group_index = preferences[participant].index(group)
        choices[group_index+1] += 1
      end

      choices_summary = choices.sort.map {|choice, count| "Choice #{choice}: #{count}" }.join("\n")

      <<~EOSUMMARY
        #{choices_summary}

        Total score: #{score.first}
        Variance: #{score.last}
      EOSUMMARY
    end

    def <=>(other)
      score <=> other.score
    end

    def eql?(other)
      match == other.match
    end

    def hash
      match.hash
    end

    private

    attr_accessor :matches
    attr_reader :preferences, :discriminator

    def groups
      @groups ||= preferences.values.flatten.uniq
    end

    def missing_group_score
      groups.length + 1
    end

    def variance(scores)
      mean_score = scores.reduce(&:+) / scores.length.to_f
      squared_diff_sum = scores.map { |score| (score - mean_score)**2 }.reduce(&:+)
      squared_diff_sum/scores.size
    end

  end

  def self.generate_match(preferences, discriminator:)
    Match.new(preferences, discriminator: discriminator).match
  end
end

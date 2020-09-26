require "matchmaker/version"

module Matchmaker
  class Error < StandardError; end

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
      individual_scores = match.map { |participant, group| preferences[participant].index(group) }

      [individual_scores.reduce(&:+), variance(individual_scores)]
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

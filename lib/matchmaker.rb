# frozen_string_literal: true

require 'matchmaker/version'

# Bruteforce matchmaking
module Matchmaker
  class Error < StandardError; end

  def self.match(preferences, rounds: 100, group_size: 1, print_summary: false)
    all_matches = 1.upto(rounds).map do |i|
      MultiMatch.new(preferences, discriminator: Random.new(i), group_size: group_size).match_result
    end

    best_match = all_matches.first
    worst_match = all_matches.last

    if print_summary
      puts "Did #{rounds} rounds, found #{all_matches.uniq.length} unique matches"
      puts "Best match:\n#{best_match.summary}"
      puts
      puts "Worst match:\n#{worst_match.summary}"
    end

    best_match.matches
  end

  class MatchResult

    attr_reader :matches, :preferences

    def initialize(matches, preferences)
      @matches = matches
      @preferences = preferences
    end

    def score
      @score ||= begin
                   individual_scores = participants.map { |participant| participant_index(participant) }

                   [individual_scores.reduce(&:+), variance(individual_scores)]
                 end
    end

    def summary
      choices = Hash.new(0)
      participants.each do |participant|
        group_index = participant_index(participant)
        choices[group_index + 1] += 1
      end

      choices_summary = choices.sort.map { |choice, count| "Choice #{choice}: #{count}" }.join("\n")

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
      matches == other.matches
    end

    def hash
      matches.hash
    end

    private

    def participants
      matches.keys
    end

    def variance(scores)
      mean_score = scores.reduce(&:+) / scores.length.to_f
      squared_diff_sum = scores.map { |score| (score - mean_score)**2 }.reduce(&:+)
      squared_diff_sum / scores.size
    end

    def participant_index(participant)
      group = matches[participant]
      preferences[participant].index(group) || preferences[participant].length + 1
    end
  end

  # Single deterministic match
  class SimpleMatch
    def initialize(preferences, discriminator: Random.new)
      @preferences = preferences
      @discriminator = discriminator
    end

    def match_result
      matches = {}

      groups.each do |current_group|
        best_participant, = preferences
                            .transform_values { |groups| [groups.index(current_group) || missing_group_score, discriminator.rand] }
                            .sort_by { |_, group_score| group_score }
                            .reject { |participant,| matches[participant] }
                            .first

        matches[best_participant] = current_group
      end

      MatchResult.new(matches, preferences)
    end

    private

    attr_reader :preferences, :discriminator

    def groups
      @groups ||= preferences.values.flatten.uniq
    end

    def missing_group_score
      groups.length + 1
    end
  end

  # Multiple slots per group matching
  class MultiMatch

    def initialize(preferences, discriminator: Random.new, group_size: 1)
      @preferences = preferences
      @discriminator = discriminator
      @group_size = group_size
    end

    def match_result
      slotted_prefs = preferences.transform_values do |groups|
        groups.flat_map do |group|
          group_size.times.map { |slot| {group: group, slot: slot} }
        end
      end

      slotted_matches = SimpleMatch.new(slotted_prefs, discriminator: discriminator).match_result.matches
      matches = slotted_matches.transform_values do |slotted_group|
        slotted_group[:group]
      end

      MatchResult.new(matches, preferences)
    end

    private

    attr_reader :preferences, :discriminator, :group_size
  end
end

require "matchmaker/version"

module Matchmaker
  class Error < StandardError; end

  def self.generate_match(preferences, discriminator: Randon.new)
    matches = {}

    preferences.values.flatten.each do |current_group|
      scores = preferences.transform_values {|groups| groups.index(current_group) || 1000 }

      until matches[current_group]
        best_participant, best_participant_score = scores
          .reject { |participant,| matches.values.include?(participant) }
          .sort_by {|_, score| [score, discriminator.rand] }
          .first

        existing_participant = matches[current_group]

        if existing_participant
          existing_participant_score = scores[existing_participant]
          if best_participant_score < existing_participant_score
            matches[current_group] = best_participant
          end
        else
          matches[current_group] = best_participant
        end
      end
    end

    matches.map { |key, value| [value, key] }.to_h
  end
end

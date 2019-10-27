require 'csv'

require_relative 'entity/event'
require_relative 'entity/event_set'
require_relative 'entity/player'

class CsvReader

    def read_players(path)
        players = []

        CSV.foreach(path, headers: true) do |row|
            players.push(Player.new(row["id"], row["name"]))
        end

        return players
    end

    def read_events(path)
        events = []

        CSV.foreach(path, headers: true) do |row|
            events.push(Event.new(row["id"], row["name"]))
        end

        return events
    end

    def read_sets(path)
        sets = []

        CSV.foreach(path, headers: true) do |row|
            sets.push(EventSet.new(row["event_id"],
                                   row["player1_id"],
                                   row["player2_id"],
                                   row["winner"],
                                   row["day"].to_i))
        end

        return sets
    end

end
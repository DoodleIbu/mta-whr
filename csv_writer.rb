require 'csv'

class CsvWriter

    def write_players(path, players)
        CSV.open(path, "w+") do |csv|
            csv << ["id", "name"]

            players.each do |player|
                csv << [player.id, player.name]
            end
        end
    end

    def write_events(path, events)
        CSV.open(path, "w+") do |csv|
            csv << ["id", "name"]

            events.each do |event|
                csv << [event.id, event.name]
            end
        end
    end

    def write_sets(path, sets)
        CSV.open(path, "w+") do |csv|
            csv << ["event_id", "player1_id", "player2_id", "winner", "day"]

            sets.each do |set|
                csv << [set.event_id, set.player1_id, set.player2_id, set.winner, set.day_number]
            end
        end
    end

    def write_ratings(path, whr)
        CSV.open(path, "w+") do |csv|
            csv << ["player_id", "day", "rating"]

            whr.players.values.each do |player|
                player.days.each do |day|
                    csv << [player.name, day.day, day.elo]
                end
            end
        end
    end

end
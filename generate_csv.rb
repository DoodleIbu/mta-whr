# Used for hosting the page at kernelthree.github.io
def generate_player_csv(players)
    file = File.new("csv/players.csv", "w+")
    lines = ["id,name"]

    players.each do |player|
        lines.push([player.id, player.name].join(","))
    end

    file.write(lines.join("\n"))
    file.close()
end

def generate_event_csv(events)
    file = File.new("csv/events.csv", "w+")
    lines = ["id,name"]

    events.each do |event|
        lines.push([event.id, event.name].join(","))
    end

    file.write(lines.join("\n"))
    file.close()
end

def generate_set_csv(sets)
    file = File.new("csv/sets.csv", "w+")
    lines = ["event_id,player1_id,player2_id,winner,day"]

    sets.each do |set|
        lines.push([set.event_id, set.player1_id, set.player2_id, set.winner, set.day_number].join(","))
    end

    file.write(lines.join("\n"))
    file.close()
end

def generate_rating_csv(whr)
    file = File.new("csv/ratings.csv", "w+")
    lines = ["player_id,day,rating"]

    whr.players.values.each do |player|
        player.days.each do |day|
            lines.push([player.name, day.day, day.elo].join(","))
        end
    end

    file.write(lines.join("\n"))
    file.close()
end

# Used for hosting the page at kernelthree.github.io
# Format (players): id, name
def generate_player_csv(players)
    player_file = File.new("player.csv", "w+")

    players.each do |player|
        player_file.write(
            [player.id.to_s, player.name].join(",") + "\n"
        )
    end

    player_file.close()
end

# Format (player rating): player_id, day, rating
# TODO: Generate
def generate_rating_csv(whr)
    rating_file = File.new("rating.csv", "w+")
    rating_file.close()
end

# Format (sets): player1_id, player2_id, winner, day
def generate_set_csv(sets)
    sets_file = File.new("sets.csv", "w+")

    sets.each do |set|
        sets_file.write(
            [set.player1_id.to_s, set.player2_id.to_s, set.winner, set.day_number].join(",") + "\n"
        )
    end

    sets_file.close()
end

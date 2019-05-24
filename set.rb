class Set
    def initialize(player1_id, player2_id, player1_name, player2_name, day_number, winner)
        @player1_id = player1_id
        @player2_id = player2_id
        @player1_name = player1_name
        @player2_name = player2_name
        @day_number = day_number
        @winner = winner # B (player 1) or W (player 2)
    end

    attr_reader :player1_id, :player2_id, :player1_name, :player2_name, :day_number, :winner
end


class EventSet

    def initialize(event_id, player1_id, player2_id, winner, day_number)
        @event_id = event_id
        @player1_id = player1_id
        @player2_id = player2_id
        @day_number = day_number

        if winner == "B" or winner == "W"
            @winner = winner
        else
            raise ArgumentError, "Winner is an invalid value %s and only accepts 'B' or 'W'." % winner
        end
    end

    attr_reader :event_id, :winner, :day_number
    attr_accessor :player1_id, :player2_id
end

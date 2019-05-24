require 'set'
require 'whole_history_rating'

# TODO: this smells like doodoo
require_relative 'smashgg_client'
require_relative 'generate_csv'

# TODO: Clean up messy awful doodoo code. :Bill:
# TODO: Remove games with DQs.

# Some players have multiple accounts. In this case, combine them.
ACCOUNT_ID_MAP = {
    419570 => 1030534, # Pelupelu
    1112712 => 733592, # ibuprofen
}

# TODO: Rate limit or store results locally so we don't need to refetch everything
SMASHGG_EVENT_IDS = [

    # Season 1: HEEHEE~
    218231, # PKHat's Weejapahlooza
    225693, # PKHat's Warmupahlooza!
    209015, # Aces Championship Series: Qualifier 1
    231973, # PKHat's Birdopalooza
    237695, # PKHat's JesusChompahlooza!
    213935, # Aces Championship Series: Qualifier 2
    246018, # PKHat's DaisyPeluza
    249405, # Drops 'n Lobs 2
    213937, # Aces Championship Series: Qualifier 3
    248397, # Double Bagel Fridays 1
    258092, # PKHat's Comebackpahlooza!
    213942, # Aces Championship Series: Qualifier 4
    258067, # Double Bagel Fridays 2
    213943, # Aces Championship Series: FINALE

    # Season 2: NEW SEASON, NEW CHARACTERS
    267731, # Hookshotz Replacementpaluza
    265099, # Cross-Court Chaos #1
    273743, # Cross-Court Chaos #2
    268984, # Double Bagel Fridays 3
    268639, # Aces Club Holiday Extravaganza!
    281197, # Double Bagel Fridays 4
    229370, # FellowsTV Open Circuit 2
    314488, # Cross-Court Chaos #3
    274465, # Heart of Battle
    319430, # MariTeni: Boom Boom's Day Off
    323798, # 2 Good Guys impromptu open
    330947, # MariTeni: Luigisuccapalooza
    327824, # Mario Tennis Aces Club Open #4

    # Season 3: I DON'T WANT THE NEW CHARACTERS NO MORE
    229370, # GatorLAN Spring 2019
    341744, # MariTeni: Bill (Standard Singles)
    341746, # MariTeni: Bill (Low Tier Standard)
    352416, # Mario Tennis Aces - Swiss!

]

# TODO: Actually implement if we want to, but we usually don't host on Challonge.
CHALLONGE_EVENT_IDS = [
    # STT11
    # STT12
    # STT13
]

def create_whr_games(whr, sets)
    sets.each do |set|
        player1_id = if ACCOUNT_ID_MAP.key?(set.player1_id)
            ACCOUNT_ID_MAP[set.player1_id]
        else
            set.player1_id
        end

        player2_id = if ACCOUNT_ID_MAP.key?(set.player2_id)
            ACCOUNT_ID_MAP[set.player2_id]
        else
            set.player2_id
        end

        whr.create_game(player1_id.to_s,
                        player2_id.to_s,
                        set.winner,
                        set.day_number,
                        0)
    end
end

# Concatenate players and sets from all tournaments.
players = Set.new()
sets = []

SMASHGG_EVENT_IDS.each do |smashgg_event_id|
    event_players, event_sets = get_smashgg_event(smashgg_event_id)
    players.merge(event_players)
    sets.concat(event_sets)
end

# Sort games by the day they have occurred.
sets.sort! { |a, b| a.day_number <=> b.day_number }

# w2 is the variability of the ratings over time.
# The default value of 300 is considered fairly high, but given the relatively few tournaments we have,
# it may be necessary.
whr = WholeHistoryRating::Base.new
create_whr_games(whr, sets)

# Iterate the WHR algorithm towards convergence.
# TODO: Implement a threshold to stop iterating.
whr.iterate(100)
whr.print_ordered_ratings()

# Generate CSV files.
generate_player_csv(players)
generate_rating_csv(whr)
generate_set_csv(sets)
puts "Generated CSV files. Commit them into kernelthree.github.io."

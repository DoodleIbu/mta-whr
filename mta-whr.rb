require 'net/http'
require 'uri'
require 'json'
require 'whole_history_rating'

# TODO: Clean up messy awful doodoo code. :Bill:
# TODO: Remove games with DQs.
MTA_RELEASE_TIME = Time.utc(2018, 6, 22)
API_TOKEN = "roflmymao" # stick this somewhere else lolol
SETS_PER_PAGE = 99 # Query complexity of 991

class Set
    def initialize(player1_id, player2_id, player1_name, player2_name, day_number, winner)
        @player1_id = player1_id
        @player2_id = player2_id
        @player1_name = player1_name
        @player2_name = player2_name
        @day_number = day_number
        @winner = winner # 1 or 2
    end

    attr_reader :player1_id, :player2_id, :player1_name, :player2_name, :day_number, :winner
end

def parse_smashgg_sets(map)
    # Treat all sets as if they started on the same day.
    event_start_time = Time.at(map["data"]["event"]["startAt"])
    event_day_number = (event_start_time - MTA_RELEASE_TIME).to_i / (24 * 60 * 60)

    smashgg_sets = map["data"]["event"]["sets"]["nodes"]
    sets = []

    smashgg_sets.each do |smashgg_set|

        # Ensure there are two participants.
        if smashgg_set["slots"].length != 2
            next
        end

        # Create the set.
        player1 = smashgg_set["slots"][0]
        player2 = smashgg_set["slots"][1]

        player1_id = player1["entrant"]["participants"][0]["playerId"]
        player2_id = player2["entrant"]["participants"][0]["playerId"]
        player1_name = player1["entrant"]["name"]
        player2_name = player2["entrant"]["name"]
        winner = if player1["standing"]["placement"] == 1 then
            "B" # Player 1
        else
            "W" # Player 2
        end

        sets.push(Set.new(player1_id, player2_id, player1_name, player2_name, event_day_number, winner))
    end

    return sets
end

def get_sets_from_smashgg_event(event_id)
    sets = []
    page = 0
    total_sets = 2147483647

    while page * SETS_PER_PAGE < total_sets
        smashgg_operation_name = "EventSets"
        smashgg_query = "
            query EventSets($eventId: ID!, $page:Int!, $perPage:Int!){
              event(id:$eventId){
                startAt
                sets(
                  page: $page
                  perPage: $perPage
                  sortType: STANDARD
                ){
                  pageInfo {
                    total
                  }
                  nodes {
                    completedAt
                    slots {
                      standing {
                        placement
                      }
                      entrant {
                        name
                        participants {
                          playerId
                        }
                      }
                    }
                  }
                }
              }
            }
        "
        smashgg_variables = {
            "eventId" => event_id,
            "page" => page + 1,
            "perPage" => SETS_PER_PAGE
        }

        uri = URI("https://api.smash.gg/gql/alpha")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = {
            "operationName" => smashgg_operation_name,
            "query" => smashgg_query,
            "variables" => smashgg_variables     
        }.to_json
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer " + API_TOKEN
        response = http.request(request)
        
        # Parse response and continue querying if not all sets have been processed.
        response_map = JSON.parse(response.body)
        sets.concat(parse_smashgg_sets(response_map))

        total_sets = response_map["data"]["event"]["sets"]["pageInfo"]["total"]
        page += 1
    end

    return sets
end

def get_sets_from_challonge_event(event_id)
    # TODO: Implement.
end

# Some players may have multiple accounts. In this case, combine them.
account_id_mapping = {
    419570 => 1030534, # Pelupelu
    1112712 => 733592, # ibuprofen
}

# TODO: Rate limit or store results locally so we don't need to refetch everything
smashgg_event_ids = [

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

# TODO: Actually implement if we want to.
challonge_event_ids = [
    # STT11
    # STT12
    # STT13
]

# Concatenate sets from all tournaments.
sets = []
smashgg_event_ids.each do |smashgg_event_id|
    sets.concat(get_sets_from_smashgg_event(smashgg_event_id))
end

# Sort games by the day they have occurred.
sets.sort! { |a, b| a.day_number <=> b.day_number }

# w2 is the variability of the ratings over time.
# The default value of 300 is considered fairly high, but given the relatively few tournaments we have,
# it may be necessary.
@whr = WholeHistoryRating::Base.new

# Collect player names as player names may differ per tournament.
player_names = {}
sets.each do |set|
    if !player_names.key?(set.player1_id)
        player_names[set.player1_id] = set.player1_name
    end

    if !player_names.key?(set.player2_id)
        player_names[set.player2_id] = set.player2_name
    end
end

# Create WHR games.
sets.each do |set|
    player1_id = if account_id_mapping.key?(set.player1_id)
        account_id_mapping[set.player1_id]
    else
        set.player1_id
    end

    player2_id = if account_id_mapping.key?(set.player2_id)
        account_id_mapping[set.player2_id]
    else
        set.player2_id
    end

    @whr.create_game(player1_id.to_s + ": " + player_names[player1_id],
                     player2_id.to_s + ": " + player_names[player2_id],
                     set.winner,
                     set.day_number,
                     0)
end

# Iterate the WHR algorithm towards convergence.
# TODO: Implement a threshold to stop iterating.
@whr.iterate(100)

puts @whr.print_ordered_ratings()

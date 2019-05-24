require 'net/http'
require 'uri'
require 'json'
require 'set'

require_relative 'entity/player'
require_relative 'entity/event_set'

MTA_RELEASE_TIME = Time.utc(2018, 6, 22)
API_TOKEN = ENV["SMASHGG_API_TOKEN"]
SETS_PER_PAGE = 99

EVENT_SET_OPERATION_NAME = "EventSets"
EVENT_SET_QUERY = "
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

# Retrieve smash.gg sets and players from an event.
def get_smashgg_event(event_id)
    players = Set.new()
    sets = []

    page = 1
    total_sets = 2147483647

    while (page - 1) * SETS_PER_PAGE < total_sets
        response_map = JSON.parse(query_smashgg_event(event_id, page))
        new_players, new_sets = transform_smashgg_event(response_map)

        players.merge(new_players)
        sets.concat(new_sets)        

        total_sets = response_map["data"]["event"]["sets"]["pageInfo"]["total"]
        page += 1
    end

    return players, sets
end

def query_smashgg_event(event_id, page)
    smashgg_variables = {
        "eventId" => event_id,
        "page" => page,
        "perPage" => SETS_PER_PAGE
    }

    uri = URI("https://api.smash.gg/gql/alpha")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = {
        "operationName" => EVENT_SET_OPERATION_NAME,
        "query" => EVENT_SET_QUERY,
        "variables" => smashgg_variables     
    }.to_json
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer " + API_TOKEN
    return http.request(request).body
end

def transform_smashgg_event(map)
    event_start_time = Time.at(map["data"]["event"]["startAt"])
    event_day_number = (event_start_time - MTA_RELEASE_TIME).to_i / (24 * 60 * 60)

    smashgg_sets = map["data"]["event"]["sets"]["nodes"]

    players = Set.new()
    sets = []

    smashgg_sets.each do |smashgg_set|

        # Ensure there are two participants.
        if smashgg_set["slots"].length != 2
            next
        end

        player1_slot = smashgg_set["slots"][0]
        player2_slot = smashgg_set["slots"][1]
        player1_id = player1_slot["entrant"]["participants"][0]["playerId"]
        player2_id = player2_slot["entrant"]["participants"][0]["playerId"]
        player1_name = player1_slot["entrant"]["name"]
        player2_name = player2_slot["entrant"]["name"]
        winner = if player1_slot["standing"]["placement"] == 1 then
            "B" # Player 1
        else
            "W" # Player 2
        end

        # Create sets.
        sets.push(EventSet.new(player1_id, player2_id, winner, event_day_number))

        # Create players.
        players.add(Player.new(player1_id, player1_name))
        players.add(Player.new(player2_id, player2_name))
    end

    return players, sets
end

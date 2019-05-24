require 'net/http'
require 'uri'
require 'json'

require_relative 'set'

MTA_RELEASE_TIME = Time.utc(2018, 6, 22)
API_TOKEN = ENV["SMASHGG_API_TOKEN"]
SETS_PER_PAGE = 99

def get_smashgg_event_sets(event_id)
    sets = []
    page = 1
    total_sets = 2147483647

    while (page - 1) * SETS_PER_PAGE < total_sets
        response_map = JSON.parse(query_smashgg_event_sets(event_id, page, SETS_PER_PAGE))
        sets.concat(transform_smashgg_event_sets(response_map))

        total_sets = response_map["data"]["event"]["sets"]["pageInfo"]["total"]
        page += 1
    end

    return sets
end

def query_smashgg_event_sets(event_id, page, sets_per_page)
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
        "page" => page,
        "perPage" => sets_per_page
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
    return http.request(request).body
end

def transform_smashgg_event_sets(map)
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

require 'net/http'
require 'uri'
require 'json'
require 'set'
require 'time'

require_relative '../entity/event'
require_relative '../entity/player'
require_relative '../entity/event_set'

# TODO: Hastily factored this out into a class to avoid conflicts with constants. Review this.
class ChallongeClient

    # Challonge player IDs and event IDs are prefixed with S.
    ID_TEMPLATE = "C%s"
    MTA_RELEASE_TIME = Time.utc(2018, 6, 22)
    API_TOKEN = ENV["CHALLONGE_API_TOKEN"]

    def query_challonge_event(event_id)
        uri = URI("https://api.challonge.com/v1/tournaments/%s.json?api_key=%s" % [event_id, API_TOKEN])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.request_uri)

        response = http.request(request)
        return response.body
    end

    def query_challonge_event_participants(event_id)
        uri = URI("https://api.challonge.com/v1/tournaments/%s/participants.json?api_key=%s" % [event_id, API_TOKEN])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.request_uri)

        response = http.request(request)
        return response.body
    end

    def query_challonge_event_matches(event_id)
        uri = URI("https://api.challonge.com/v1/tournaments/%s/matches.json?api_key=%s" % [event_id, API_TOKEN])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.request_uri)

        response = http.request(request)
        return response.body
    end

    # Retrieve Challonge sets and players from an event.
    def get_challonge_event(event_id)
        event_map = JSON.parse(query_challonge_event(event_id))
        participants_map = JSON.parse(query_challonge_event_participants(event_id))
        matches_map = JSON.parse(query_challonge_event_matches(event_id))

        return transform_challonge_event(event_map, participants_map, matches_map)
    end

    def generate_player_id_to_name_map(participants_map)
        map = {}

        participants_map.each do |participant_map|
            participant = participant_map["participant"]
            map[ID_TEMPLATE % participant["id"]] = participant["challonge_username"]
        end

        return map
    end

    def transform_challonge_event(event_map, participants_map, matches_map)
        player_id_to_name_map = generate_player_id_to_name_map(participants_map)

        tournament = event_map["tournament"]
        event_start_time = Time.parse(tournament["started_at"])
        event_day_number = (event_start_time - MTA_RELEASE_TIME).to_i / (24 * 60 * 60)

        event_id = ID_TEMPLATE % tournament["id"]
        event_name = tournament["name"]

        event = Event.new(event_id, event_name)
        players = Set.new()
        sets = []

        matches_map.each do |match_map|
            match = match_map["match"]
            player1_id = ID_TEMPLATE % match["player1_id"]
            player2_id = ID_TEMPLATE % match["player2_id"]

            player1_score, player2_score = match["scores_csv"].match(/(-?\d+)-(-?\d+)/).captures()
            player1_score = player1_score.to_i()
            player2_score = player2_score.to_i()

            # Ignore games that have negative scores, i.e. they have not been played out.
            if player1_score < 0 or player2_score < 0
                next
            end

            winner_id = ID_TEMPLATE % match["winner_id"]
            winner = if winner_id == player1_id then
                "B"
            else
                "W"
            end

            # Create sets.
            sets.push(EventSet.new(event_id, player1_id, player2_id, winner, event_day_number))

            # Create players.
            players.add(Player.new(player1_id, player_id_to_name_map[player1_id]))
            players.add(Player.new(player2_id, player_id_to_name_map[player2_id]))
        end

        return event, players, sets
    end
end

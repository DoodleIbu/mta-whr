require 'net/http'
require 'uri'
require 'json'
require 'set'

require_relative '../entity/event'
require_relative '../entity/player'
require_relative '../entity/event_set'

API_TOKEN = ENV["CHALLONGE_API_TOKEN"]

# Retrieve Challonge sets and players from an event.
def get_challonge_event(event_id)
    event = nil
    players = Set.new()
    sets = []

    response_map = JSON.parse(query_challonge_event(event_id))
    print response_map

    return event, players, sets
end

def query_challonge_event(event_id)
    uri = URI("https://api.challonge.com/v1/tournaments/%s/matches.json?api_key=%s" % [event_id, API_TOKEN])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
    return response.body
end
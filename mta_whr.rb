require 'set'
require 'whole_history_rating'
require 'fileutils'

# TODO: Not a fan of require_relative since it can be hard to trace the path.
require_relative 'client/smashgg_client'
require_relative 'client/challonge_client'
require_relative 'csv_reader'
require_relative 'csv_writer'

# Some players have multiple accounts. In this case, combine them.
PLAYER_ID_MAP = {
    # Challonge to smash.gg
    "C105677281" => "S1259099", # LukeFlow
    "C105669947" => "S1259790", # NatRop2
    "C123652763" => "S1259790", # NatRop2
    "C140058883" => "S1259790", # NatRop2
    "C155153410" => "S1259790", # NatRop2
    "C105656521" => "S1151677", # krispy.jin
    "C105964270" => "S1039897", # Pito
    "C105962886" => "S804769",  # PkKirby
    "C105960969" => "S875683",  # mtadavid
    "C105806128" => "S1011138", # Vee
    "C105963851" => "S981358",  # Nintendart
    "C105638687" => "S875600",  # Angie
    "C105635165" => "S804800",  # Hooky
    "C105952954" => "S812825",  # PieHat
    "C107324989" => "S812825",  # PieHat
    "C105637494" => "S802340",  # Schwell
    "C105781624" => "S898077",  # IT!Darki
    "C105759168" => "S296273",  # Saburo
    "C139801749" => "S296273",  # Saburo
    "C105702926" => "S1152788", # Macman
    "C105635893" => "S877501",  # lilbigestjake
    "C105760412" => "S830764",  # crispy jr
    "C107063457" => "S1466323", # lxpu
    "C107064251" => "S494940",  # Ghostgodzilla
    "C107063608" => "S1499888", # Danguitos
    "C105635170" => "S1584255", # Breazzy
    "C124103167" => "S840485",  # Marcus
    "C124112756" => "S803914",  # Bad Joe
    "C123726084" => "S1809282", # Zelgodez
    "C140165366" => "S1809282", # Zelgodez
    "C158314692" => "S1809282", # Zelgodez
    "C124115427" => "S1582596", # Gordolo
    "C124071402" => "S1107203", # Igney
    "C124115187" => "S1638615", # Guntz
    "C140143569" => "S1063941", # Niki
    "C158652896" => "S1063941", # Niki
    "C154831727" => "S929825",  # Joey
    "C158657707" => "S1259099", # LukeFlow
    "C140455988" => "S1677661", # Me, Ed
    "C140167075" => "S2227966", # Icepixel28
    "C140446987" => "S824927",  # Lanzius
    "C140456243" => "S1235295", # Laggy
    "C140291245" => "S1843786", # LaBast
    "C158545735" => "S1843786", # LaBast
    "C140434991" => "S1638615", # Guntz
    "C140440706" => "S1721999", # Joshua
    "C158642742" => "S2181459", # Navy
    "C158645497" => "S2348736", # duuk?
    "C158660349" => "S2500436", # Oualors4

    # smash.gg duplicates
    "S419570" => "S1030534",  # Pelupelu
    "S1112712" => "S733592",  # ibuprofen
    "S880718" => "S1085661",  # Statsdotzip
    "S963723" => "S1252257",  # Xeno
    "S1256064" => "S1153395", # Benny Burrito
    "S877308" => "S1245341",  # OmeGa 0oF
    "S1041169" => "S906275",  # michaelcarca6
    "S1889941" => "S840485",  # Marcus
    "S2604270" => "S1063941", # Niki

    # Challonge duplicates
    "C123799326" => "C107683058", # PatoGw
}

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
    352416, # Mario Tennis Aces - Swiss!
    354814, # Mario Tennis Aces Club Open 5 - The Finale
    364952, # Switchfest 2
    401039, # PKHat Peteypahlooza
    406125, # Trick Shot Tourney #3
    411090, # Trick Shot Tourney #4
    417786, # Trick Shot Tourney #5
    421480, # Trick Shot Tourney #6
    424688, # Aces Club Holiday Extravaganza: The Second Coming
    439357, # Trick Shot Tourney #8
    464814, # Trick Shot Tourney #10
    469993, # Trick Shot Tourney #11
    474435, # Trick Shot Tourney #12
    478929, # Trick Shot Tourney #13
    483234, # Trick Shot Tourney #14
    478096, # Switch to Save Lives
    489979, # Trick Shot Tourney #15
    490573, # ARMS of Smash: Trick Shot
    498408, # Trick Shot Tourney #16
    498412, # Trick Shot Tourney #16 (Amateur)
    502471, # Trick Shot Tourney #17
    502473, # Trick Shot Tourney #17 (Amateur)
    504524, # Mario Tennis Aces European Open
    506211, # Trick Shot Tourney #18
    506213, # Trick Shot Tourney #18 (Amateur)
    513662, # Trick Shot Tourney #19
    513664, # Trick Shot Tourney #19 (Amateur)
    517341, # Trick Shot Tourney #20
    522590, # Trick Shot Tourney #21
    526032, # Trick Shot Tourney #22
    521897, # Spooktacular
    538595, # Trick Shot Tourney #23
    540610, # Aces Club Holiday Extravaganza: The Three Wise Chomps
    544482, # Trick Shot Tourney #24
    562008, # Trick Shot Tourney #25
    562010, # Trick Shot Tourney #25 (Amateur)
    569209, # Trick Shot Tourney #26
    572821, # May the Slice be With You!
    576772, # Zelcadia Cup (Experienced)
    576769, # Zelcadia Cup (Amateur)
    584678, # Trick Shot Tourney #27
    589026, # MTA 3rd Anniversary
    600278, # Trick Shot Tourney #28
    609472, # Trick Shot Tourney #29
    618224, # Trick Shot Tourney #30
    628093, # 2nd Zelcadia Cup (Experienced)
    628092, # 2nd Zelcadia Cup (Amateur)
    657843, # Aces Club Holiday Extravaganza: Four Calling Birdos
]

CHALLONGE_EVENT_IDS = [
    "7453651",                   # Trick Shot Tournament 1
    "wfcsnku7",                  # Torneo Mansion Espejismo
    "8541013",                   # Quarantined Rapport 2
    "quarterlyrapport-quar3mta", # Quarantined Rapport 3
    "quarterlyrapport-quar4mta", # Quarantined Rapport 4
]

def sort_by_date(sets)
    sets.sort! { |a, b| a.day_number <=> b.day_number }
end

def map_player_ids(players, sets)
    PLAYER_ID_MAP.keys.each do |player_id|
        players.delete(Player.new(player_id))
    end

    sets.each do |set|
        if PLAYER_ID_MAP.key?(set.player1_id)
            set.player1_id = PLAYER_ID_MAP[set.player1_id]
        end

        if PLAYER_ID_MAP.key?(set.player2_id)
            set.player2_id = PLAYER_ID_MAP[set.player2_id]
        end
    end
end

def create_whr_games(whr, sets)
    sets.each do |set|
        whr.create_game(set.player1_id,
                        set.player2_id,
                        set.winner,
                        set.day_number,
                        0)
    end
end

# Concatenate players and sets from all tournaments.
events = Set.new()
players = Set.new()
sets = []

challonge_client = ChallongeClient.new(ENV['CHALLONGE_API_KEY'])
smashgg_client = SmashggClient.new(ENV['SMASHGG_API_KEY'])
csv_reader = CsvReader.new()
csv_writer = CsvWriter.new()

# TODO: Create a class to do all of this and dedupe.
CHALLONGE_EVENT_IDS.each do |challonge_event_id|
    event = nil
    event_players = []
    event_sets = []

    directory = "csv/C%s" % challonge_event_id
    if File.directory?(directory)
        event = csv_reader.read_events(directory + "/events.csv")[0]
        event_players = csv_reader.read_players(directory + "/players.csv")
        event_sets = csv_reader.read_sets(directory + "/sets.csv")
    else
        event, event_players, event_sets = challonge_client.get_event(challonge_event_id)
        FileUtils.mkdir_p(directory)
        csv_writer.write_events(directory + "/events.csv", [event])
        csv_writer.write_players(directory + "/players.csv", event_players)
        csv_writer.write_sets(directory + "/sets.csv", event_sets)
    end

    events.add(event)
    players.merge(event_players)
    sets.concat(event_sets)
end

SMASHGG_EVENT_IDS.each do |smashgg_event_id|
    event = nil
    event_players = []
    event_sets = []

    directory = "csv/S%d" % smashgg_event_id
    if File.directory?(directory)
        event = csv_reader.read_events(directory + "/events.csv")[0]
        event_players = csv_reader.read_players(directory + "/players.csv")
        event_sets = csv_reader.read_sets(directory + "/sets.csv")
    else
        event, event_players, event_sets = smashgg_client.get_event(smashgg_event_id)
        FileUtils.mkdir_p(directory)
        csv_writer.write_events(directory + "/events.csv", [event])
        csv_writer.write_players(directory + "/players.csv", event_players)
        csv_writer.write_sets(directory + "/sets.csv", event_sets)
    end
    
    events.add(event)
    players.merge(event_players)
    sets.concat(event_sets)
end

# w2 is the variability of the ratings over time.
# The default value of 300 is considered fairly high, but given the relatively few tournaments we have,
# it may be necessary.
whr = WholeHistoryRating::Base.new(:w2 => 100)

map_player_ids(players, sets)
sort_by_date(sets)
create_whr_games(whr, sets)

whr.iterate(100)
whr.print_ordered_ratings()

csv_writer.write_players("csv/players.csv", players)
csv_writer.write_events("csv/events.csv", events)
csv_writer.write_sets("csv/sets.csv", sets)
csv_writer.write_ratings("csv/ratings.csv", whr)
puts "Generated CSV files. Commit them into mta-whr."

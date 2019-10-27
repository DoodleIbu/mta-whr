require 'csv'

# TODO: Implement
class CsvReader

    def read_players(path)
        csv = CSV.read(path, :headers => true)
    end

    def read_events(path)
        csv = CSV.read(path, :headers => true)
    end

    def read_sets(path)
        csv = CSV.read(path, :headers => true)
    end

end
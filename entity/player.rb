class Player

    def initialize(id, name=nil)
        @id = id # Account ID prefixed by its source (C for Challonge, S for smash.gg).
        @name = name
    end

    def hash()
        @id.hash
    end

    def eql?(other)
        self.hash == other.hash
    end

    attr_reader :id, :name
end

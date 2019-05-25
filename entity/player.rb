class Player

    def initialize(id, name=nil)
        @id = id # smash.gg numeric ID
        @name = name
    end

    def hash()
        @id
    end

    def eql?(other)
        self.hash == other.hash
    end

    attr_reader :id, :name
end

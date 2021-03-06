class Event

    def initialize(id, name)
        @id = id
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

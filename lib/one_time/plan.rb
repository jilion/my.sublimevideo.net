module OneTime
  module Plan

    class << self
      def create_plans
        plans_attributes = [
          { name: "dev",        cycle: "none",  player_hits: 0,          price: 0 },
          { name: "sponsored",  cycle: "none",  player_hits: 0,          price: 0 },
          { name: "beta",       cycle: "none",  player_hits: 0,          price: 0 },
          { name: "comet",      cycle: "month", player_hits: 3_000,      price: 990 },
          { name: "planet",     cycle: "month", player_hits: 50_000,     price: 1990 },
          { name: "star",       cycle: "month", player_hits: 200_000,    price: 4990 },
          { name: "galaxy",     cycle: "month", player_hits: 1_000_000,  price: 9990 },
          { name: "comet",      cycle: "year",  player_hits: 3_000,      price: 9900 },
          { name: "planet",     cycle: "year",  player_hits: 50_000,     price: 19900 },
          { name: "star",       cycle: "year",  player_hits: 200_000,    price: 49900 },
          { name: "galaxy",     cycle: "year",  player_hits: 1_000_000,  price: 99900 }
        ]
        plans_attributes.each { |attributes| ::Plan.create(attributes) }
      end
    end

  end
end

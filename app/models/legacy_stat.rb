module LegacyStat
  extend ActiveSupport::Concern

  included do

    # DateTime periods
    field :s, type: DateTime # Second
    field :m, type: DateTime # Minute
    field :h, type: DateTime # Hour
    field :d, type: DateTime # Day

    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}
  end

end

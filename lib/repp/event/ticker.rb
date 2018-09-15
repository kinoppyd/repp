module Repp
  module Event
    class Ticker < Base
      event_type :ticker
      interface :body
    end
  end
end

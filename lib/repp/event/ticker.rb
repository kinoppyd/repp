module Repp
  module Event
    class Ticker < Base
      event_type :ticker
      interface :body, :reply_to, :bot?
    end
  end
end

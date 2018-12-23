module Repp
  module Event
    class Trigger < Receive
      event_type :trigger
      interface :body, :payload, :original
    end
  end
end

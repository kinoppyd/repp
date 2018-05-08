module Repp
  module Event
    class Receive < Base
      event_type :message
      interface :body
    end
  end
end

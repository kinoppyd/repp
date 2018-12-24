require 'eventmachine'

module Repp
  module Handler
    class Shell
      module KeyboardHandler
        include EM::Protocols::LineText2
        def initialize(app) @app = app; end
        def receive_line(data)
          reply_to = /@\w+/.match(data)&.[](1)
          message = Event::Receive.new(body: data, reply_to: reply_to, bot?: false)
          res = process_message(message)
          process_trigger(res, message)
        end

        def process_message(message)
          res = @app.call(message)
          if res.any?
            $stdout.puts res.first
          end
          res
        end

        def process_trigger(res, message)
          if res[1][:trigger]
            payload = res[1][:trigger][:payload]
            res[1][:trigger][:names].each do |name|
              trigger = Event::Trigger.new(body: name, payload: payload, original: message)
              Thread.new do
                trigger_res = process_message(trigger)
                process_trigger(trigger_res, message)
              end
            end
          end
        end
      end

      def self.run(app, options = {})
        yield self if block_given?

        application = app.new
        @ticker = Ticker.task(application) do |res|
          if res.any? && res.first
            $stdout.puts res.first
          end
        end

        @ticker.run!
        EM.run { EM.open_keyboard(KeyboardHandler, application) }
      end

      def self.stop
        EM.run { EM.stop }
      end
    end
  end
end

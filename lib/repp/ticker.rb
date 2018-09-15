require 'concurrent'
module Repp
  class Ticker
    def self.task(app, &block)
      Task.app = app
      new(&block)
    end

    class Task
      include Concurrent::Async

      class << self
        def app=(app); @app = app end
        def app; @app end
      end

      def tick(event)
        Task.app.call(event)
      end
    end

    def initialize(&block)
      @block = block
    end

    def run!
      @task = Concurrent::TimerTask.new(execution_interval: 1) do
        @block.call(Task.new.tick(Event::Ticker.new(body: Time.now)))
      end
      @task.execute
    end
  end
end

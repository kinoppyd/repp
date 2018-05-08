module Repp
  module Handler
    class Slack
      require 'slack-ruby-client'

      class SlackReceive < Event::Receive
        interface :channel, :user, :type, :ts
      end

      module SlackMessageHandler
        def self.handle(client, web_client, app)
          client.on :message do |data|
            receive = SlackReceive.new(
              body: data.text,
              channel: data.channel,
              user: data.user,
              type: data.type,
              ts: data.ts
            )
            res = app.call(receive)
            if res.first
              channel_to_post = res.last&.[](:channel) || receive.channel
              web_client.chat_postMessage(text: res.first, channel: channel_to_post, as_user: true)
            end
          end
        end
      end

      class << self
        def run(app, options = {})
          yield self if block_given?

          ::Slack.configure do |config|
            config.token = detect_token
          end
          @client = ::Slack::RealTime::Client.new
          @web_client = ::Slack::Web::Client.new
          SlackMessageHandler.handle(@client, @web_client, app.new)
          @client.start!
        end

        def stop!
          @client.stop!
        end

        private

        def detect_token
          return ENV['SLACK_TOKEN'] if ENV['SLACK_TOKEN']
          token_file = "#{ENV['HOME']}/.slack/token"
          return File.read(token_file).chomp if File.exist?(token_file)
          fail "Can't find Slack token"
        end
      end
    end
  end
end

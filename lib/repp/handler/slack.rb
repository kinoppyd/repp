module Repp
  module Handler
    class Slack
      require 'slack-ruby-client'

      REPLY_REGEXP = /<@(\w+?)>/

      class SlackReceive < Event::Receive
        interface :channel, :user, :type, :ts, :reply_to

        def bot?; !!@is_bot;  end
        def bot=(switch); @is_bot = switch; end
      end

      class SlackMessageHandler
        attr_reader :client, :web_client, :app
        def initialize(client, web_client, app)
          @client = client
          @web_client = web_client
          @app = app
        end

        def users(refresh = false)
          @users = @web_client.users_list.members if refresh
          @users ||= @web_client.users_list.members
        end

        def handle
          client.on :message do |data|
            reply_to = (data.text || "").scan(REPLY_REGEXP).map do |node|
              user = users.find { |u| u.id == node.first }
              user ? user.name : nil
            end

            receive = SlackReceive.new(
              body: data.text,
              channel: data.channel,
              user: data.user,
              type: data.type,
              ts: data.ts,
              reply_to: reply_to.compact
            )

            user = users.find { |u| u.id == data.user } || users(true).find { |u| u.id == data.user }
            receive.bot = (data['subtype'] == 'bot_message' || user.nil? || user['is_bot'])

            res = app.call(receive)
            if res.first
              channel_to_post = res.last && res.last[:channel] || receive.channel
              attachments = res.last && res.last[:attachments]
              web_client.chat_postMessage(text: res.first, channel: channel_to_post, as_user: true, attachments: attachments)
            end
          end

          client.start!
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

          application = app.new
          @ticker = Ticker.task(application) do |res|
            if res.first
              if res.last && res.last[:dest_channel]
                channel_to_post = res.last[:dest_channel]
                attachments = res.last[:attachments]
                @web_client.chat_postMessage(text: res.first, channel: channel_to_post, as_user: true, attachments: attachments)
              else
                message = "Need 'dest_to:' option to every or cron job like:\n" +
                  "every 1.hour, dest_to: 'channel_name' do"
                $stderr.puts(message)
              end
            end
          end
          @ticker.run!
          handler = SlackMessageHandler.new(@client, @web_client, application)
          handler.handle
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

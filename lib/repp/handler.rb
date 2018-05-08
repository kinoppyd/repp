module Repp
  module Handler
    class << self
      def get(service)
        return unless service
        service = service.to_s

        unless @handlers[service]
          load_error = try_require('repp/handler', service)
        end

        if klass = @handlers[service]
          klass.split('::').inject(Object) { |o, x| o.const_get(x) }
        else
          const_get(service, false)
        end

      rescue => name_error
        raise load_error || name_error
      end

      def self.pick(service_names)
        service_names = Array(service_names)
        service_names.each do |service_name|
          begin
            return get(service_name.to_s)
          rescue LoadError, NameError
          end
        end

        raise LoadError, "Couldn't find handler for: #{service_names.join(', ')}."
      end

      def self.default
        # Guess.
        if  ENV.include?("REPP_HANDLER")
          self.get(ENV["REPP_HANDLER"])
        else
          pick ['shell']
        end
      end

      def self.try_require(prefix, const_name)
        file = const_name.gsub(/^[A-Z]+/) { |pre| pre.downcase }.
          gsub(/[A-Z]+[^A-Z]/, '_\&').downcase

        require(::File.join(prefix, file))
        nil
      rescue LoadError => error
        error
      end

      def register(service, klass)
        @handlers ||= {}
        @handlers[service.to_s] = klass.to_s
      end
    end

    autoload :Shell, "repp/handler/shell"
    register 'shell', 'Repp::Handler::Shell'

    autoload :Slack, "repp/handler/slack"
    register 'slack', 'Repp::Handler::Slack'
  end
end

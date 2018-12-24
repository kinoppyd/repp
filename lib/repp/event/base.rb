module Repp
  module Event
    module Attributes
      EVENT_TYPE = :event_type
      RECERVED_WORDS = [EVENT_TYPE]

      def event_type(setting)
        define_method(EVENT_TYPE) { setting }
      end

      def interface(*names)
        names.each do |name|
          name = name.to_s
          next if RECERVED_WORDS.include?(name.to_sym)
          writer = (name.end_with?("?") ? name[0...-1] : name) + "="
          define_method(name) { @attributes[name] }
          define_method(writer) { |val| @attributes[name] }
        end
      end
    end

    class Base
      extend Attributes
      def initialize(params = {})
        @attributes = {}
        return unless params.respond_to?(:each_pair)
        params.each_pair do |k, v|
          @attributes[k.to_s] = v
        end
      end
    end
  end
end

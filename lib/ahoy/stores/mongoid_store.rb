module Ahoy
  module Stores
    class MongoidStore < BaseStore
      def track_visit(info, &block)
        @visit =
          visit_model.new do |v|
            v.id = binary(ahoy.visit_id)
            v.visitor_id = binary(ahoy.visitor_id)
            v.user = user if v.respond_to?(:user=) && user
            v.started_at = info[:started_at]
          end

        set_visit_properties(visit, info)

        yield(visit) if block_given?

        visit.upsert
        geocode(visit)
      end

      def track_event(info, &block)
        event =
          event_model.new do |e|
            e.id = binary(info[:event_token])
            e.visit_id = binary(ahoy.visit_id)
            e.user = user if e.respond_to?(:user)
            e.name = info[:name]
            e.properties = info[:properties]
            e.time = info[:time]
          end

        yield(event) if block_given?

        event.upsert
      end

      def visit
        @visit ||= visit_model.where(_id: binary(ahoy.visit_id)).first if ahoy.visit_id
      end

      protected

      def visit_model
        ::Visit
      end

      def event_model
        ::Ahoy::Event
      end

      def binary(token)
        token = token.delete("-")
        if defined?(::BSON)
          ::BSON::Binary.new(token, :uuid)
        elsif defined?(::Moped::BSON)
          ::Moped::BSON::Binary.new(:uuid, token)
        else
          token
        end
      end
    end
  end
end

module Ahoy
  module Stores
    class ActiveRecordTokenStore < BaseStore
      def track_visit(info, &block)
        @visit =
          visit_model.new do |v|
            v.visit_token = info[:visit_token]
            v.visitor_token = info[:visitor_token]
            v.user = user if v.respond_to?(:user=)
            v.started_at = info[:time] if v.respond_to?(:started_at)
            v.created_at = info[:time] if v.respond_to?(:created_at)
          end

        set_visit_properties(visit, info)

        yield(visit) if block_given?

        begin
          visit.save!
          geocode(visit)
        rescue *unique_exception_classes
          # do nothing
        end
      end

      def track_event(info, &block)
        event =
          event_model.new do |e|
            e.visit_id = visit.try(:id)
            e.user = user
            e.name = info[:name]
            e.properties = info[:properties]
            e.time = info[:time]
          end

        yield(event) if block_given?

        event.save!
      end

      def visit
        @visit ||= visit_model.where(visit_token: ahoy.visit_token).first if ahoy.visit_token
      end

      protected

      def visit_model
        ::Visit
      end

      def event_model
        ::Ahoy::Event
      end
    end
  end
end

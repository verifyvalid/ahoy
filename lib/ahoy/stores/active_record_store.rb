module Ahoy
  module Stores
    class ActiveRecordStore < BaseStore
      def track_visit(info, &block)
        @visit =
          visit_model.new do |v|
            v.id = ahoy.visit_id
            v.visitor_id = ahoy.visitor_id
            v.user = user if v.respond_to?(:user=)
            v.started_at = info[:started_at]
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
            e.id = options[:event_token]
            e.visit_id = ahoy.visit_id
            e.user = user if e.respond_to?(:user=)
            e.name = info[:name]
            e.properties = info[:properties]
            e.time = info[:time]
          end

        yield(event) if block_given?

        begin
          event.save!
        rescue *unique_exception_classes
          # do nothing
        end
      end

      def visit
        @visit ||= visit_model.where(id: ahoy.visit_id).first if ahoy.visit_id
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
